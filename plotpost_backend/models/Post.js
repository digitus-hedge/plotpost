
const mongoose = require("mongoose");

const commentSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    text: {
      type: String,
      required: true,
      trim: true,
    },
  },
  { timestamps: true }
);

const postSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },

    caption: {
      type: String,
      trim: true,
      default: "",
    },

    title: { type: String, trim: true, default: "" },
    type: { type: String, trim: true, default: "Plot" },
    deal: { type: String, trim: true, default: "For sale" },
    price: { type: String, trim: true, default: "" },
    location: { type: String, trim: true, default: "" },
    description: { type: String, trim: true, default: "" },
    socialUrl: { type: String, trim: true, default: "" },
    sellerPhone: { type: String, trim: true, default: "" },
    area: { type: String, trim: true, default: "" },
    bedrooms: { type: String, trim: true, default: "" },
    bathrooms: { type: String, trim: true, default: "" },
    platform: { type: String, trim: true, default: "PlotPost" },

    imageUrl: {
      type: String,
      default: "",
    },
    imageUrls: {
      type: [String],
      default: [],
    },

    likes: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
      },
    ],

    comments: [commentSchema],
  },
  { timestamps: true }
);

module.exports = mongoose.model("Post", postSchema);
