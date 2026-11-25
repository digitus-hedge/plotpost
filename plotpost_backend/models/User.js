const mongoose = require("mongoose");

// A one-time 6-digit code (email verification or password reset).
// Only a hash of the code is stored.
const oneTimeCodeSchema = new mongoose.Schema(
  {
    codeHash: { type: String, required: true },
    expiresAt: { type: Date, required: true },
    attempts: { type: Number, default: 0 },
    sentAt: { type: Date, default: Date.now },
  },
  { _id: false }
);

const userSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, "Name is required"],
      trim: true,
      maxlength: 80,
    },
    email: {
      type: String,
      required: [true, "Email is required"],
      unique: true,
      lowercase: true,
      trim: true,
    },
    // Not returned by queries unless asked for with .select("+password").
    // Google-only accounts have no password until they set one.
    password: {
      type: String,
      select: false,
      required: [
        function passwordRequired() {
          return !this.googleId;
        },
        "Password is required",
      ],
    },
    role: {
      type: String,
      enum: ["user", "admin"],
      default: "user",
    },
    // Never sent to the app (see utils/serializeUser.js).
    googleId: { type: String },
    isEmailVerified: { type: Boolean, default: false },
    emailVerifiedAt: { type: Date },
    // Access tokens issued before this moment are rejected.
    passwordChangedAt: { type: Date, select: false },
    lastLoginAt: { type: Date },

    phone: { type: String, default: "", trim: true, maxlength: 20 },
    profileImage: { type: String, default: "" },
    profileImagePublicId: { type: String, default: "", select: false },
    bio: { type: String, default: "", maxlength: 500 },
    agency: { type: String, default: "", trim: true, maxlength: 100 },
    designation: { type: String, default: "", trim: true, maxlength: 100 },
    location: { type: String, default: "", trim: true, maxlength: 120 },

    settings: {
      pushNotifications: { type: Boolean, default: true },
      emailInquiries: { type: Boolean, default: true },
      showPhoneNumber: { type: Boolean, default: true },
    },

    emailVerification: { type: oneTimeCodeSchema, select: false },
    passwordReset: { type: oneTimeCodeSchema, select: false },

    savedPosts: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: "Post",
      },
    ],
  },
  {
    timestamps: true,
  }
);

// Each Google account can link to only one PlotPost account.
userSchema.index({ googleId: 1 }, { unique: true, sparse: true });

module.exports = mongoose.model("User", userSchema);
