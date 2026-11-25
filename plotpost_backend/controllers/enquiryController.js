const Enquiry = require("../models/Enquiry");

// CREATE ENQUIRY
const createEnquiry = async (req, res) => {
  try {
    const {
      postId,
      postTitle,
      seller,
      name,
      phone,
      email,
      message,
      contactMethod,
      wantsVisit,
    } = req.body;

    if (!postTitle || !name || !phone) {
      return res.status(400).json({
        success: false,
        message: "Please provide property title, your name, and phone number",
      });
    }

    const enquiry = await Enquiry.create({
      user: req.user ? req.user._id : null,
      post: postId || null,
      postTitle: postTitle.trim(),
      seller: seller ? seller.trim() : "",
      name: name.trim(),
      phone: phone.trim(),
      email: email ? email.trim() : "",
      message: message ? message.trim() : "",
      contactMethod: contactMethod || "Phone call",
      wantsVisit: Boolean(wantsVisit),
    });

    res.status(201).json({
      success: true,
      message: "Enquiry submitted successfully",
      enquiry,
    });
  } catch (error) {
    console.error("Create enquiry error:", error);
    res.status(500).json({
      success: false,
      message: error.message || "Failed to submit enquiry",
    });
  }
};

// GET USER ENQUIRIES
const getMyEnquiries = async (req, res) => {
  try {
    const enquiries = await Enquiry.find({ user: req.user._id })
      .populate("post")
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      count: enquiries.length,
      enquiries,
    });
  } catch (error) {
    console.error("Get enquiries error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch enquiries",
    });
  }
};

// DELETE ENQUIRY
const deleteEnquiry = async (req, res) => {
  try {
    const enquiry = await Enquiry.findById(req.params.id);
    if (!enquiry) {
      return res.status(404).json({ success: false, message: "Enquiry not found" });
    }

    if (
  !enquiry.user ||
  enquiry.user.toString() !== req.user._id.toString()
) {
  return res.status(403).json({
    success: false,
    message: "Not authorized to delete this enquiry"
  });
}

    await enquiry.deleteOne();

    res.status(200).json({
      success: true,
      message: "Enquiry deleted successfully",
    });
  } catch (error) {
    console.error("Delete enquiry error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to delete enquiry",
    });
  }
};

module.exports = {
  createEnquiry,
  getMyEnquiries,
  deleteEnquiry,
};
