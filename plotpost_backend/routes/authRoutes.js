const express = require("express");
const router = express.Router();

const auth = require("../controllers/authController");
const { protect } = require("../middleware/authMiddleware");
const { authLimiter } = require("../middleware/rateLimiter");
const validate = require("../middleware/validate");
const v = require("../validators/authValidators");

// Account creation and login
router.post("/register", authLimiter, validate({ body: v.registerSchema }), auth.registerUser);
router.post("/login", authLimiter, validate({ body: v.loginSchema }), auth.loginUser);
router.post("/google", authLimiter, validate({ body: v.googleSchema }), auth.googleSignIn);

// Sessions
router.post("/refresh", validate({ body: v.refreshSchema }), auth.refreshTokens);
router.post("/logout", validate({ body: v.logoutSchema }), auth.logoutUser);
router.post("/logout-all", protect, auth.logoutAllDevices);

// Email verification
router.post("/verify-email", protect, authLimiter, validate({ body: v.verifyEmailSchema }), auth.verifyEmail);
router.post("/resend-verification", protect, authLimiter, auth.resendVerification);

// Passwords
router.post("/forgot-password", authLimiter, validate({ body: v.forgotPasswordSchema }), auth.forgotPassword);
router.post("/reset-password", authLimiter, validate({ body: v.resetPasswordSchema }), auth.resetPassword);
router.post("/change-password", protect, authLimiter, validate({ body: v.changePasswordSchema }), auth.changePassword);

module.exports = router;
