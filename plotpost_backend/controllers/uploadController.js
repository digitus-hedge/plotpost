
const cloudinary = require("../config/cloudinary");

const uploadImage = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: "Please select an image.",
      });
    }

    const result = await new Promise((resolve, reject) => {
      const stream = cloudinary.uploader.upload_stream(
        {
          folder: "plotpost",
          resource_type: "image",
        },
        (error, result) => {
          if (error) return reject(error);
          resolve(result);
        }
      );

      stream.end(req.file.buffer);
    });

    return res.status(200).json({
      success: true,
      message: "Image uploaded successfully.",
      imageUrl: result.secure_url,
      publicId: result.public_id,
    });

  } catch (error) {
    console.error("Image upload error:", error);

    return res.status(500).json({
      success: false,
      message: "Image upload failed.",
    });
  }
};

module.exports = { uploadImage };
