const mongoose = require("mongoose");

const enquirySchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
    },
    post: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Post",
    },
    postTitle: {
      type: String,
      required: true,
      trim: true,
    },
    seller: {
      type: String,
      default: "",
      trim: true,
    },
    name: {
      type: String,
      required: true,
      trim: true,
    },
    phone: {
      type: String,
      required: true,
      trim: true,
    },
    email: {
      type: String,
      default: "",
      trim: true,
    },
    message: {
      type: String,
      default: "",
    },
    contactMethod: {
      type: String,
      enum: ["Phone call", "WhatsApp", "Email"],
      default: "Phone call",
    },
    wantsVisit: {
      type: Boolean,
      default: false,
    },
    status: {
      type: String,
      enum: ["Pending", "Contacted", "Closed"],
      default: "Pending",
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model("Enquiry", enquirySchema);
