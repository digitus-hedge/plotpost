const Post = require("../models/Post");

const getPostFields = (body) => ({
  title: body.title,
  type: body.type,
  deal: body.deal,
  price: body.price,
  location: body.location,
  description: body.description,
  socialUrl: body.socialUrl,
  sellerPhone: body.sellerPhone,
  area: body.area,
  bedrooms: body.bedrooms,
  bathrooms: body.bathrooms,
  platform: body.platform,
});

const validatePost = (title, location, imageUrls) => {
  if (!title?.trim() || !location?.trim()) {
    return "Please provide a title and location.";
  }
  if (!Array.isArray(imageUrls) || imageUrls.length > 8) {
    return "Please choose up to 8 photos totaling no more than 8 MB.";
  }
  if (
    imageUrls.some(
      (url) =>
        typeof url !== "string" ||
        (!url.startsWith("http://") &&
          !url.startsWith("https://") &&
          !/^data:image\/[\w.+-]+;base64,[A-Za-z0-9+/]*={0,2}$/.test(url))
    )
  ) {
    return "One or more photos have an invalid format.";
  }
  const uploadedImages = imageUrls.filter((url) => url.startsWith("data:image/"));
  const uploadedImageBytes = uploadedImages.reduce((total, url) => {
    const encodedData = url.split(",")[1] || "";
    const padding = encodedData.endsWith("==") ? 2 : encodedData.endsWith("=") ? 1 : 0;
    return total + Math.floor((encodedData.length * 3) / 4) - padding;
  }, 0);
  if (
    Buffer.byteLength(JSON.stringify(imageUrls), "utf8") > 11 * 1024 * 1024 ||
    uploadedImageBytes > 8 * 1024 * 1024
  ) {
    return "Please choose up to 8 photos totaling no more than 8 MB.";
  }
  return null;
};

// CREATE POST
const createPost = async (req, res) => {
  try {
    const { title, location, description, imageUrls = [] } = req.body;
    const validationMessage = validatePost(title, location, imageUrls);
    if (validationMessage) {
      return res.status(400).json({
        success: false,
        message: validationMessage,
      });
    }

    const post = await Post.create({
      user: req.user._id,
      caption: description || title,
      ...getPostFields(req.body),
      imageUrls,
    });

    const populatedPost = await Post.findById(post._id)
      .populate("user", "name email profileImage");

    res.status(201).json({
      success: true,
      message: "Post created successfully",
      post: populatedPost,
    });

  } catch (error) {
    console.error("Create post error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to create post",
    });
  }
};

// UPDATE POST

const updatePost = async (req, res) => {
  try {
    const post = await Post.findById(req.params.id);

    if (!post) {
      return res.status(404).json({
        success: false,
        message: "Post not found.",
      });
    }

    if (post.user.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: "You cannot edit this post.",
      });
    }

const updates = Object.fromEntries(
  Object.entries(getPostFields(req.body)).filter(
    ([key, value]) => value !== undefined
  )
);
    // Validate the final post values, not just the submitted fields.
    const title = updates.title ?? post.title;
    const location = updates.location ?? post.location;
    const imageUrls = req.body.imageUrls ?? post.imageUrls;

    const validationMessage = validatePost(title, location, imageUrls);

    if (validationMessage) {
      return res.status(400).json({
        success: false,
        message: validationMessage,
      });
    }

    Object.assign(post, updates);

    // Update images only when imageUrls is explicitly provided.
    if (req.body.imageUrls !== undefined) {
      post.imageUrls = imageUrls;
    }

    // Keep caption synchronized when description is changed.
    if (req.body.description !== undefined) {
      post.caption = req.body.description;
    }

    await post.save();

    const populatedPost = await Post.findById(post._id)
      .populate("user", "name email profileImage");

    return res.status(200).json({
      success: true,
      message: "Post updated successfully.",
      post: populatedPost,
    });
  } catch (error) {
    console.error("Update post error:", error);

    return res.status(500).json({
      success: false,
      message: "Failed to update post.",
    });
  }
};



// GET ALL POSTS WITH PAGINATION
const getPosts = async (req, res) => {
  try {
    const page = Math.max(1, parseInt(req.query.page, 10) || 1);
    const limit = Math.min(50, Math.max(1, parseInt(req.query.limit, 10) || 10));
    const skip = (page - 1) * limit;

    const [posts, total] = await Promise.all([
      Post.find()
        .populate("user", "name profileImage")
        .populate("comments.user", "name profileImage")
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit),
      Post.countDocuments()
    ]);

    res.status(200).json({
      success: true,
      count: total,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
      posts
    });

  } catch (error) {
    console.error("Get posts error:", error);

    res.status(500).json({
      success: false,
      message: "Failed to fetch posts"
    });
  }
};


// GET MY POSTS
const getMyPosts = async (req, res) => {
  try {
    const posts = await Post.find({ user: req.user._id })
      .populate("user", "name email profileImage")
      .populate("comments.user", "name profileImage")
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      count: posts.length,
      posts,
    });
  } catch (error) {
    console.error("Get my posts error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch your posts",
    });
  }
};

// DELETE POST
const deletePost = async (req, res) => {
  try {
    const post = await Post.findById(req.params.id);
    if (!post) {
      return res.status(404).json({ success: false, message: "Post not found." });
    }
    if (post.user.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: "Not authorized to delete this post." });
    }

    await post.deleteOne();

    res.status(200).json({
      success: true,
      message: "Post deleted successfully",
    });
  } catch (error) {
    console.error("Delete post error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to delete post",
    });
  }
};

// TOGGLE LIKE POST
const likePost = async (req, res) => {
  try {
    const post = await Post.findById(req.params.id);
    if (!post) {
      return res.status(404).json({ success: false, message: "Post not found." });
    }

    const likeIndex = post.likes.indexOf(req.user._id);
    let isLiked = false;

    if (likeIndex > -1) {
      post.likes.splice(likeIndex, 1);
      isLiked = false;
    } else {
      post.likes.push(req.user._id);
      isLiked = true;
    }

    await post.save();

    res.status(200).json({
      success: true,
      isLiked,
      likesCount: post.likes.length,
      message: isLiked ? "Post liked" : "Post unliked",
    });
  } catch (error) {
    console.error("Like post error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to toggle like",
    });
  }
};

// ADD COMMENT TO POST
const addComment = async (req, res) => {
  try {
    const { text } = req.body;
    if (!text || !text.trim()) {
      return res.status(400).json({ success: false, message: "Comment text is required." });
    }

    const post = await Post.findById(req.params.id);
    if (!post) {
      return res.status(404).json({ success: false, message: "Post not found." });
    }

    post.comments.push({
      user: req.user._id,
      text: text.trim(),
    });

    await post.save();

    const updatedPost = await Post.findById(post._id)
      .populate("comments.user", "name profileImage");

    res.status(201).json({
      success: true,
      message: "Comment added successfully",
      comments: updatedPost.comments,
    });
  } catch (error) {
    console.error("Add comment error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to add comment",
    });
  }
};

module.exports = {
  createPost,
  updatePost,
  getPosts,
  getMyPosts,
  deletePost,
  likePost,
  addComment,
};
