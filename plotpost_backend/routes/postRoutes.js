const express = require("express");
const router = express.Router();

const {
  createPost,
  getPosts,
  getMyPosts,
  updatePost,
  deletePost,
  likePost,
  addComment,
} = require("../controllers/postController");

const { protect } = require("../middleware/authMiddleware");

// Public routes
router.get("/", getPosts);

// Protected routes
router.get("/my", protect, getMyPosts);
router.post("/", protect, createPost);
router.put("/:id", protect, updatePost);
router.delete("/:id", protect, deletePost);
router.post("/:id/like", protect, likePost);
router.post("/:id/comment", protect, addComment);

module.exports = router;
