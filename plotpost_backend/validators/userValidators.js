const { z } = require("zod");
const mongoose = require("mongoose");

const text = (max, label) =>
  z.string({ error: `${label} must be text.` }).trim().max(max, `${label} is too long.`);

const updateProfileSchema = z.object({
  name: text(80, "Name").min(2, "Please enter your full name.").optional(),
  phone: text(20, "Phone number")
    .regex(/^[0-9+()\-\s]*$/, "Please enter a valid phone number.")
    .optional(),
  bio: text(500, "Bio").optional(),
  agency: text(100, "Agency name").optional(),
  designation: text(100, "Role / designation").optional(),
  location: text(120, "Location").optional(),
  // Older app versions send an image URL here; only http(s) links are kept.
  profileImage: z
    .string()
    .trim()
    .max(1000)
    .refine((v) => v === "" || /^https?:\/\//.test(v), "Profile image must be a link.")
    .optional(),
});

const settingsSchema = z
  .object({
    pushNotifications: z.boolean().optional(),
    emailInquiries: z.boolean().optional(),
    showPhoneNumber: z.boolean().optional(),
  })
  .refine((v) => Object.keys(v).length > 0, "Nothing to update.");

const deleteAccountSchema = z.object({
  // Accounts with a password confirm with it; Google-only accounts type DELETE.
  password: z.string().max(200).optional(),
  confirm: z.string().trim().optional(),
});

const userIdParams = z.object({
  id: z.string().refine((v) => mongoose.Types.ObjectId.isValid(v), "Invalid user ID."),
});

module.exports = { updateProfileSchema, settingsSchema, deleteAccountSchema, userIdParams };
