const { rateLimit } = require("express-rate-limit");
const { config } = require("../config/env");

const passThrough = (req, res, next) => next();

const build = (max, message) => {
  if (!config.rateLimit.enabled) return passThrough;
  return rateLimit({
    windowMs: config.rateLimit.windowMinutes * 60 * 1000,
    limit: max,
    standardHeaders: "draft-8",
    legacyHeaders: false,
    message: { success: false, message },
  });
};

// Every API request, per IP address.
const apiLimiter = build(
  config.rateLimit.max,
  "Too many requests. Please wait a few minutes and try again."
);

// Login, register, password reset and similar: much stricter, to slow down
// password guessing and email flooding.
const authLimiter = build(
  config.rateLimit.authMax,
  "Too many attempts. Please wait a few minutes and try again."
);

module.exports = { apiLimiter, authLimiter };
