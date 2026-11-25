
const multer = require("multer");
const AppError = require("../utils/AppError");

const storage = multer.memoryStorage();

const fileFilter = (req, file, callback) => {
  const allowedTypes = [
    "image/jpeg",
    "image/png",
    "image/webp",
  ];

  if (!allowedTypes.includes(file.mimetype)) {
    return callback(
      AppError.badRequest("Only JPG, PNG and WEBP images are allowed.")
    );
  }

  callback(null, true);
};

const upload = multer({
  storage,
  limits: {
    fileSize: 8 * 1024 * 1024,
  },
  fileFilter,
});

module.exports = upload;
