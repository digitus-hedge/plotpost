
const express = require("express");
const router = express.Router();

const { protect } = require("../middleware/authMiddleware");
const upload = require("../middleware/uploadMiddleware");
const { uploadImage } = require("../controllers/uploadController");

router.post(
  "/",
  protect,
  (req, res, next) => {
    upload.single("image")(req, res, (error) => {
      if (error) {
        return res.status(400).json({
          success: false,
          message: error.message,
        });
      }

      next();
    });
  },
  uploadImage
);

module.exports = router;
