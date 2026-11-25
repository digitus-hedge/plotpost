const express = require("express");
const router = express.Router();

const users = require("../controllers/userController");
const { protect } = require("../middleware/authMiddleware");
const upload = require("../middleware/uploadMiddleware");
const validate = require("../middleware/validate");
const v = require("../validators/userValidators");

// User Profile routes
router.get("/profile", protect, users.getUserProfile);
router.put("/profile", protect, validate({ body: v.updateProfileSchema }), users.updateUserProfile);
router.post("/profile/photo", protect, upload.single("image"), users.uploadProfilePhoto);
router.delete("/profile/photo", protect, users.deleteProfilePhoto);

// Account settings and deletion
router.patch("/settings", protect, validate({ body: v.settingsSchema }), users.updateSettings);
router.delete("/account", protect, validate({ body: v.deleteAccountSchema }), users.deleteAccount);

// Saved / Bookmarks routes
router.post("/saved/:postId", protect, users.toggleSavedPost);
router.get("/saved", protect, users.getSavedPosts);

// Public profile (keep last: "/:id" would otherwise match "/saved")
router.get("/:id", validate({ params: v.userIdParams }), users.getPublicProfile);

module.exports = router;
