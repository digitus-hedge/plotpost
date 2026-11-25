// Builds the Express app. server.js starts it; tests load it directly.
const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
const helmet = require("helmet");
const morgan = require("morgan");

const { config } = require("./config/env");
const { apiLimiter } = require("./middleware/rateLimiter");
const { sanitizeRequest } = require("./middleware/sanitize");
const { notFound, errorHandler } = require("./middleware/errorHandler");

const app = express();

app.disable("x-powered-by");
app.set("trust proxy", config.trustProxy);

app.use(helmet());

// The Flutter mobile app sends no Origin header, so it is always allowed.
// Browsers (e.g. the Flutter web build) must be listed in CORS_ORIGINS.
// With CORS_ORIGINS empty, development allows any origin; production allows none.
app.use(
  cors({
    origin(origin, callback) {
      if (!origin) return callback(null, true);
      if (config.corsOrigins.includes(origin)) return callback(null, true);
      if (!config.isProduction && config.corsOrigins.length === 0) return callback(null, true);
      return callback(null, false);
    },
    credentials: false,
  })
);

if (!config.isTest) {
  app.use(morgan(config.isProduction ? "combined" : "dev"));
}

// Posts still accept photos as base64 text until Stage 2 moves them to
// Cloudinary, so only the posts routes get the large body limit.
app.use("/api/posts", express.json({ limit: "12mb" }));
app.use(express.json({ limit: "200kb" }));
app.use(sanitizeRequest);

app.get("/", (req, res) => {
  res.json({ success: true, message: "PlotPost Backend is running!" });
});

app.get("/api/health", (req, res) => {
  const isDatabaseConnected = mongoose.connection.readyState === 1;
  res.status(isDatabaseConnected ? 200 : 503).json({
    success: isDatabaseConnected,
    database: isDatabaseConnected ? "connected" : "disconnected",
  });
});

app.use("/api", apiLimiter);
app.use("/api/auth", require("./routes/authRoutes"));
app.use("/api/users", require("./routes/userRoutes"));
app.use("/api/posts", require("./routes/postRoutes"));
app.use("/api/upload", require("./routes/uploadRoutes"));
app.use("/api/enquiries", require("./routes/enquiryRoutes"));

app.use(notFound);
app.use(errorHandler);

module.exports = app;
