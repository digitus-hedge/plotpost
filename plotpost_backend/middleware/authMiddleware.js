const User = require("../models/User");
const { verifyAccessToken } = require("../services/tokenService");

const unauthorized = (res, message) => res.status(401).json({ success: false, message });

const readBearer = (req) => {
  const header = req.headers.authorization;
  if (!header || !header.startsWith("Bearer ")) return null;
  return header.slice(7).trim() || null;
};

// Loads the logged-in user from the access token, or answers 401.
// The app treats 401 as "refresh the token, then retry once".
const protect = async (req, res, next) => {
  const token = readBearer(req);
  if (!token) return unauthorized(res, "Not authorized. Token missing.");

  let decoded;
  try {
    decoded = verifyAccessToken(token);
  } catch (error) {
    return unauthorized(res, "Invalid or expired token.");
  }

  const user = await User.findById(decoded.id).select("+passwordChangedAt");
  if (!user) return unauthorized(res, "User not found.");

  // A password change ends sessions that started before it.
  if (user.passwordChangedAt && decoded.iat * 1000 < user.passwordChangedAt.getTime() - 1000) {
    return unauthorized(res, "Your password was changed. Please log in again.");
  }

  req.user = user;
  return next();
};

// Like protect, but lets guests through (req.user stays undefined).
// A token that is present but invalid still gets a 401, so the app refreshes it.
const optionalAuth = (req, res, next) => {
  if (!readBearer(req)) return next();
  return protect(req, res, next);
};

// Use after protect: authorize("admin").
const authorize =
  (...roles) =>
  (req, res, next) => {
    if (!req.user || !roles.includes(req.user.role)) {
      return res.status(403).json({ success: false, message: "You are not allowed to do this." });
    }
    return next();
  };

module.exports = { protect, optionalAuth, authorize };
