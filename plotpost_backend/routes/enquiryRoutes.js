const express = require("express");
const router = express.Router();

const {
  createEnquiry,
  getMyEnquiries,
  deleteEnquiry,
} = require("../controllers/enquiryController");

const { protect, optionalAuth } = require("../middleware/authMiddleware");

router.post("/", optionalAuth, createEnquiry);
router.get("/my", protect, getMyEnquiries);
router.delete("/:id", protect, deleteEnquiry);

module.exports = router;
