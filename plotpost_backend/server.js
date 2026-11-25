const { config, validateConfig } = require("./config/env");
const { connectDB, disconnectDB } = require("./config/db");

const start = async () => {
  try {
    validateConfig();
  } catch (error) {
    console.error(error.message);
    process.exit(1);
  }

  try {
    await connectDB();
  } catch (error) {
    // Exiting lets Railway restart the service and try again.
    console.error("MongoDB connection error:", error.message);
    process.exit(1);
  }

  const app = require("./app");
  const server = app.listen(config.port, "0.0.0.0", () => {
    console.log(`Server running on port ${config.port} (${config.nodeEnv})`);
  });

  // Railway sends SIGTERM when it redeploys; finish open requests first.
  const shutdown = (signal) => {
    console.log(`${signal} received, shutting down.`);
    server.close(async () => {
      await disconnectDB().catch(() => {});
      process.exit(0);
    });
    setTimeout(() => process.exit(1), 10000).unref();
  };
  process.on("SIGTERM", () => shutdown("SIGTERM"));
  process.on("SIGINT", () => shutdown("SIGINT"));
};

start();
