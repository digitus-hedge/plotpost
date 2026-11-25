// Gives an existing user the admin role (or removes it).
//   node scripts/make-admin.js someone@example.com
//   node scripts/make-admin.js someone@example.com --remove
// Uses MONGODB_URI from .env. Changes only that one user's role.
const { config, validateConfig } = require("../config/env");
const { connectDB, disconnectDB } = require("../config/db");
const User = require("../models/User");

const run = async () => {
  const email = (process.argv[2] || "").trim().toLowerCase();
  const remove = process.argv.includes("--remove");
  if (!email) {
    console.error("Usage: node scripts/make-admin.js <email> [--remove]");
    process.exit(1);
  }
  validateConfig();
  await connectDB(config.mongoUri);
  const user = await User.findOneAndUpdate(
    { email },
    { $set: { role: remove ? "user" : "admin" } },
    { returnDocument: "after" }
  );
  if (!user) {
    console.error(`No user found with email ${email}`);
  } else {
    console.log(`${user.email} is now: ${user.role}`);
  }
  await disconnectDB();
};

run().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
