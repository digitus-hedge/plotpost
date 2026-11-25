const bcrypt = require("bcryptjs");
const mongoose = require("mongoose");
const User = require("../models/User");
const Post = require("../models/Post");
const Enquiry = require("../models/Enquiry");
const RefreshToken = require("../models/RefreshToken");
const AppError = require("../utils/AppError");
const { serializeUser, serializePublicUser } = require("../utils/serializeUser");
const imageService = require("../services/imageService");

// GET USER PROFILE
const getUserProfile = async (req, res) => {
  res.status(200).json({
    success: true,
    user: serializeUser(req.user),
  });
};

// UPDATE USER PROFILE
const updateUserProfile = async (req, res) => {
  const user = await User.findById(req.user._id);
  const fields = ["name", "phone", "bio", "agency", "designation", "location"];
  for (const field of fields) {
    if (req.body[field] !== undefined) user[field] = req.body[field];
  }
  // Older app versions may send a link here; new uploads use POST /profile/photo.
  if (req.body.profileImage !== undefined && req.body.profileImage !== user.profileImage) {
    user.profileImage = req.body.profileImage;
  }
  await user.save();

  res.status(200).json({
    success: true,
    message: "Profile updated successfully",
    user: serializeUser(user),
  });
};

// UPDATE ACCOUNT SETTINGS (push, email inquiries, show phone number)
const updateSettings = async (req, res) => {
  const user = await User.findById(req.user._id);
  for (const [key, value] of Object.entries(req.body)) {
    user.settings[key] = value;
  }
  await user.save();
  res.status(200).json({
    success: true,
    message: "Settings saved",
    user: serializeUser(user),
  });
};

// UPLOAD PROFILE PHOTO (multipart field "image")
const uploadProfilePhoto = async (req, res) => {
  if (!req.file) throw AppError.badRequest("Please select an image.");

  const user = await User.findById(req.user._id).select("+profileImagePublicId");
  const previousPublicId = user.profileImagePublicId;

  const result = await imageService.uploadAvatar(req.file.buffer, user._id);
  user.profileImage = result.secure_url;
  user.profileImagePublicId = result.public_id;
  await user.save();
  await imageService.destroyImage(previousPublicId);

  res.status(200).json({
    success: true,
    message: "Profile photo updated",
    imageUrl: result.secure_url,
    user: serializeUser(user),
  });
};

// DELETE PROFILE PHOTO
const deleteProfilePhoto = async (req, res) => {
  const user = await User.findById(req.user._id).select("+profileImagePublicId");
  const publicId = user.profileImagePublicId;
  user.profileImage = "";
  user.profileImagePublicId = "";
  await user.save();
  await imageService.destroyImage(publicId);

  res.status(200).json({
    success: true,
    message: "Profile photo removed",
    user: serializeUser(user),
  });
};

// PUBLIC PROFILE OF ANY USER
const getPublicProfile = async (req, res) => {
  const user = await User.findById(req.params.id);
  if (!user) throw AppError.notFound("User not found.");
  const postsCount = await Post.countDocuments({ user: user._id });
  res.status(200).json({
    success: true,
    user: { ...serializePublicUser(user), postsCount },
  });
};

// Removes one user's comments from other people's posts. (Written as a
// filter-and-save rather than a conditional $pull so it behaves the same on
// every MongoDB-compatible database; Stage 4 moves comments to their own collection.)
const removeCommentsBy = async (userId) => {
  const posts = await Post.find({ "comments.user": userId }).select("comments");
  await Promise.all(
    posts.map((post) =>
      Post.updateOne(
        { _id: post._id },
        { $set: { comments: post.comments.filter((c) => String(c.user) !== String(userId)) } }
      )
    )
  );
};

// DELETE ACCOUNT
// Permanently removes the user, their posts (and photos), enquiries, likes,
// comments and sessions. The user confirms with their password, or by
// typing DELETE if their account has no password (Google-only).
const deleteAccount = async (req, res) => {
  const user = await User.findById(req.user._id).select("+password +profileImagePublicId");

  if (user.password) {
    const ok = req.body.password && (await bcrypt.compare(req.body.password, user.password));
    if (!ok) throw AppError.badRequest("Your password is incorrect.");
  } else if (req.body.confirm !== "DELETE") {
    throw AppError.badRequest('Type DELETE to confirm.');
  }

  const posts = await Post.find({ user: user._id }).select("_id imageUrl imageUrls").lean();
  const postIds = posts.map((p) => p._id);
  const photoIds = posts
    .flatMap((p) => [p.imageUrl, ...(p.imageUrls || [])])
    .map((url) => imageService.publicIdFromUrl(url))
    .filter(Boolean);

  // One step at a time: several steps can touch the same post document.
  await Enquiry.deleteMany({ $or: [{ user: user._id }, { post: { $in: postIds } }] });
  await Post.updateMany({ likes: user._id }, { $pull: { likes: user._id } });
  await removeCommentsBy(user._id);
  await User.updateMany({ savedPosts: { $in: postIds } }, { $pullAll: { savedPosts: postIds } });
  await RefreshToken.deleteMany({ user: user._id });
  await Post.deleteMany({ user: user._id });
  await User.deleteOne({ _id: user._id });

  // Photo cleanup happens last: it can't undo the deletion if Cloudinary fails.
  await Promise.all(
    [...photoIds, user.profileImagePublicId].filter(Boolean).map((id) => imageService.destroyImage(id))
  );

  res.status(200).json({ success: true, message: "Your account has been deleted." });
};

// TOGGLE SAVED POST

const toggleSavedPost = async (req, res) => {
  try {
    const { postId } = req.params;

    if (!mongoose.Types.ObjectId.isValid(postId)) {
      return res.status(400).json({
        success: false,
        message: "Invalid post ID",
      });
    }

    const [user, post] = await Promise.all([
      User.findById(req.user._id),
      Post.findById(postId),
    ]);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    if (!post) {
      return res.status(404).json({
        success: false,
        message: "Post not found",
      });
    }

    const postIndex = user.savedPosts.findIndex(
      (id) => id.toString() === postId
    );

    let isSaved;

    if (postIndex > -1) {
      user.savedPosts.splice(postIndex, 1);
      isSaved = false;
    } else {
      user.savedPosts.push(post._id);
      isSaved = true;
    }

    await user.save();

    return res.status(200).json({
      success: true,
      isSaved,
      message: isSaved
        ? "Post saved to bookmarks"
        : "Post removed from bookmarks",
      savedPosts: user.savedPosts,
    });
  } catch (error) {
    console.error("Toggle saved post error:", error);

    return res.status(500).json({
      success: false,
      message: "Failed to toggle saved post",
    });
  }
};


// GET SAVED POSTS
const getSavedPosts = async (req, res) => {
  try {
    const user = await User.findById(req.user._id).populate({
      path: "savedPosts",
      populate: { path: "user", select: "name email profileImage" },
    });

    if (!user) {
      return res.status(404).json({ success: false, message: "User not found" });
    }

    res.status(200).json({
      success: true,
      count: user.savedPosts.length,
      savedPosts: user.savedPosts,
    });
  } catch (error) {
    console.error("Get saved posts error:", error);
    res.status(500).json({ success: false, message: "Failed to fetch saved posts" });
  }
};

module.exports = {
  getUserProfile,
  updateUserProfile,
  updateSettings,
  uploadProfilePhoto,
  deleteProfilePhoto,
  getPublicProfile,
  deleteAccount,
  toggleSavedPost,
  getSavedPosts,
};
