const { z } = require("zod");

const email = z
  .string({ error: "Please enter your email address." })
  .trim()
  .toLowerCase()
  .max(254)
  .email("Please enter a valid email address.");

// bcrypt only uses the first 72 bytes of a password, hence the cap.
const newPassword = z
  .string({ error: "Please enter a password." })
  .min(8, "Password must be at least 8 characters.")
  .max(72, "Password must be at most 72 characters.")
  .regex(/[A-Za-z]/, "Password must include at least one letter.")
  .regex(/[0-9]/, "Password must include at least one number.");

// Login accepts any existing password (older accounts allowed 6 characters).
const existingPassword = z
  .string({ error: "Please enter your password." })
  .min(1, "Please enter your password.")
  .max(200);

const code = z
  .string({ error: "Please enter the 6-digit code." })
  .trim()
  .regex(/^\d{6}$/, "Please enter the 6-digit code.");

const refreshToken = z.string({ error: "Refresh token is required." }).min(20).max(200);

const registerSchema = z.object({
  name: z
    .string({ error: "Please enter your full name." })
    .trim()
    .min(2, "Please enter your full name.")
    .max(80, "Name is too long."),
  email,
  password: newPassword,
});

const loginSchema = z.object({ email, password: existingPassword });

const googleSchema = z.object({
  idToken: z.string({ error: "Google token is required." }).min(20).max(5000),
});

const refreshSchema = z.object({ refreshToken });

const logoutSchema = z.object({ refreshToken: refreshToken.optional() });

const forgotPasswordSchema = z.object({ email });

const resetPasswordSchema = z.object({ email, code, newPassword });

const verifyEmailSchema = z.object({ code });

const changePasswordSchema = z.object({
  // Not needed for Google accounts that have never set a password.
  currentPassword: existingPassword.optional(),
  newPassword,
});

module.exports = {
  registerSchema,
  loginSchema,
  googleSchema,
  refreshSchema,
  logoutSchema,
  forgotPasswordSchema,
  resetPasswordSchema,
  verifyEmailSchema,
  changePasswordSchema,
};
