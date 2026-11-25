const bcrypt = require("bcryptjs");
const User = require("../models/User");
const AppError = require("../utils/AppError");
const { config } = require("../config/env");
const { serializeUser } = require("../utils/serializeUser");
const tokenService = require("../services/tokenService");
const codeService = require("../services/codeService");
const emailService = require("../services/emailService");
const googleAuthService = require("../services/googleAuthService");

const hashPassword = (password) => bcrypt.hash(password, config.bcryptRounds);

// Compared against when the email is unknown, so a wrong email takes as long
// as a wrong password and can't be used to discover which emails exist.
const DUMMY_HASH = bcrypt.hashSync("plotpost-timing-guard", 10);

const authResponse = (res, status, message, user, tokens, extra = {}) =>
  res.status(status).json({
    success: true,
    message,
    ...tokens,
    user: serializeUser(user),
    ...extra,
  });

// Sends the verification email without making the request wait or fail.
const sendVerificationInBackground = (user, code) => {
  emailService.sendVerificationCode(user, code).catch((error) => {
    if (!config.isTest) console.warn("Verification email failed:", error.message);
  });
};

// ================= REGISTER =================
const registerUser = async (req, res) => {
  const { name, email, password } = req.body;

  if (await User.exists({ email })) {
    throw AppError.conflict("An account with this email already exists.");
  }

  const user = new User({ name, email, password: await hashPassword(password) });
  const code = emailService.canSend() ? codeService.issueCode(user, "emailVerification") : null;
  user.lastLoginAt = new Date();
  await user.save();
  if (code) sendVerificationInBackground(user, code);

  const tokens = await tokenService.issueAuthTokens(user, req);
  return authResponse(res, 201, "User registered successfully", user, tokens, {
    verificationEmailSent: Boolean(code),
  });
};

// ================= LOGIN =================
const loginUser = async (req, res) => {
  const { email, password } = req.body;
  const user = await User.findOne({ email }).select("+password");

  const passwordOk = await bcrypt.compare(password, user?.password || DUMMY_HASH);
  if (!user || !user.password || !passwordOk) {
    throw AppError.unauthorized("Invalid email or password");
  }

  user.lastLoginAt = new Date();
  await user.save();
  const tokens = await tokenService.issueAuthTokens(user, req);
  return authResponse(res, 200, "Login successful", user, tokens);
};

// ================= GOOGLE SIGN-IN =================
// The app signs in with Google and sends us the ID token. We check it with
// Google, then log in the matching account or create a new one.
const googleSignIn = async (req, res) => {
  const profile = await googleAuthService.verifyGoogleIdToken(req.body.idToken);

  let user = await User.findOne({ googleId: profile.googleId });
  let created = false;

  if (!user) {
    const sameEmail = await User.findOne({ email: profile.email });
    if (sameEmail) {
      // Only link when Google has confirmed the person owns this email.
      if (!profile.emailVerified) {
        throw AppError.conflict("An account with this email already exists. Please log in with your password.");
      }
      user = sameEmail;
      user.googleId = profile.googleId;
      if (!user.isEmailVerified) {
        user.isEmailVerified = true;
        user.emailVerifiedAt = new Date();
      }
      if (!user.profileImage && profile.picture) user.profileImage = profile.picture;
    } else {
      created = true;
      user = new User({
        name: profile.name.slice(0, 80),
        email: profile.email,
        googleId: profile.googleId,
        isEmailVerified: profile.emailVerified,
        emailVerifiedAt: profile.emailVerified ? new Date() : undefined,
        profileImage: profile.picture,
      });
    }
  }

  user.lastLoginAt = new Date();
  await user.save();
  const tokens = await tokenService.issueAuthTokens(user, req);
  return authResponse(res, created ? 201 : 200, "Login successful", user, tokens, { isNewUser: created });
};

// ================= REFRESH =================
const refreshTokens = async (req, res) => {
  const { user, tokens } = await tokenService.rotateRefreshToken(req.body.refreshToken, req);
  return authResponse(res, 200, "Session refreshed", user, tokens);
};

// ================= LOGOUT =================
// Ends this device's session. Always succeeds, so the app can clear its
// tokens even when it is offline or the token was already invalid.
const logoutUser = async (req, res) => {
  await tokenService.revokeRefreshToken(req.body.refreshToken);
  res.status(200).json({ success: true, message: "Logged out" });
};

// Ends every session on every device.
const logoutAllDevices = async (req, res) => {
  await tokenService.revokeAllForUser(req.user._id);
  res.status(200).json({ success: true, message: "Logged out of all devices" });
};

// ================= EMAIL VERIFICATION =================
const resendVerification = async (req, res) => {
  const user = await User.findById(req.user._id).select("+emailVerification");
  if (user.isEmailVerified) {
    return res.status(200).json({ success: true, message: "Your email is already verified." });
  }
  if (!emailService.canSend()) {
    throw AppError.unavailable("Verification emails aren't set up yet. Please try again later.");
  }
  const code = codeService.issueCode(user, "emailVerification");
  await user.save();
  await emailService.sendVerificationCode(user, code);
  return res.status(200).json({ success: true, message: `We've sent a code to ${user.email}.` });
};

const verifyEmail = async (req, res) => {
  const user = await User.findById(req.user._id).select("+emailVerification");
  if (!user.isEmailVerified) {
    await codeService.verifyCode(user, "emailVerification", req.body.code);
    user.isEmailVerified = true;
    user.emailVerifiedAt = new Date();
    await user.save();
  }
  return res.status(200).json({
    success: true,
    message: "Your email is verified.",
    user: serializeUser(user),
  });
};

// ================= FORGOT / RESET PASSWORD =================
const GENERIC_RESET_MESSAGE = "If an account exists for that email, we've sent a 6-digit code to it.";

const forgotPassword = async (req, res) => {
  if (!emailService.canSend()) {
    throw AppError.unavailable("Password reset emails aren't set up yet. Please try again later.");
  }
  const user = await User.findOne({ email: req.body.email }).select("+passwordReset");
  if (user) {
    try {
      const code = codeService.issueCode(user, "passwordReset");
      await user.save();
      await emailService.sendPasswordResetCode(user, code);
    } catch (error) {
      // A cooldown hit or a mail failure must not reveal that the account exists.
      if (!(error instanceof AppError) && !config.isTest) {
        console.warn("Password reset email failed:", error.message);
      }
    }
  }
  return res.status(200).json({ success: true, message: GENERIC_RESET_MESSAGE });
};

const resetPassword = async (req, res) => {
  const { email, code, newPassword } = req.body;
  const user = await User.findOne({ email }).select("+passwordReset +password");
  if (!user) {
    throw AppError.badRequest("That code is wrong or has expired. Please request a new one.");
  }

  await codeService.verifyCode(user, "passwordReset", code);
  user.password = await hashPassword(newPassword);
  user.passwordChangedAt = new Date();
  // Receiving the code proves they own the email address.
  if (!user.isEmailVerified) {
    user.isEmailVerified = true;
    user.emailVerifiedAt = new Date();
  }
  user.lastLoginAt = new Date();
  await user.save();

  await tokenService.revokeAllForUser(user._id);
  const tokens = await tokenService.issueAuthTokens(user, req);
  return authResponse(res, 200, "Your password has been reset.", user, tokens);
};

// ================= CHANGE PASSWORD =================
const changePassword = async (req, res) => {
  const { currentPassword, newPassword } = req.body;
  const user = await User.findById(req.user._id).select("+password");

  if (user.password) {
    if (!currentPassword || !(await bcrypt.compare(currentPassword, user.password))) {
      throw AppError.badRequest("Your current password is incorrect.");
    }
    if (await bcrypt.compare(newPassword, user.password)) {
      throw AppError.badRequest("Your new password must be different from the current one.");
    }
  }

  user.password = await hashPassword(newPassword);
  user.passwordChangedAt = new Date();
  await user.save();

  // Other devices are logged out; this one gets fresh tokens.
  await tokenService.revokeAllForUser(user._id);
  const tokens = await tokenService.issueAuthTokens(user, req);
  return authResponse(res, 200, "Your password has been changed.", user, tokens);
};

module.exports = {
  registerUser,
  loginUser,
  googleSignIn,
  refreshTokens,
  logoutUser,
  logoutAllDevices,
  resendVerification,
  verifyEmail,
  forgotPassword,
  resetPassword,
  changePassword,
};
