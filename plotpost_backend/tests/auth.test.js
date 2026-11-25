const request = require("supertest");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const app = require("../app");
const db = require("./helpers/db");
const { registerUser, bearer } = require("./helpers/auth");
const User = require("../models/User");
const RefreshToken = require("../models/RefreshToken");
const { outbox } = require("../services/emailService");
const googleAuthService = require("../services/googleAuthService");

beforeAll(() => db.connect("auth"));
afterEach(async () => {
  await db.clear();
  outbox.length = 0;
  jest.restoreAllMocks();
});
afterAll(() => db.close());

const lastCodeFor = (email, type) => {
  const mail = [...outbox].reverse().find((m) => m.to === email && m.meta.type === type);
  return mail?.meta.code;
};

// Lets a test ask for another code without waiting out the 60-second cooldown.
const skipCooldown = (email, field) =>
  User.updateOne({ email }, { $set: { [`${field}.sentAt`]: new Date(Date.now() - 120000) } });

const oldAccessToken = (userId) =>
  jwt.sign({ id: userId, type: "access", iat: Math.floor(Date.now() / 1000) - 60 }, process.env.JWT_SECRET);

describe("register", () => {
  test("creates an account, returns both tokens and emails a code", async () => {
    const res = await request(app)
      .post("/api/auth/register")
      .send({ name: "  Asha Menon ", email: "  Asha@Example.COM ", password: "Password123" });

    expect(res.status).toBe(201);
    expect(res.body.token).toBe(res.body.accessToken);
    expect(res.body.refreshToken).toEqual(expect.any(String));
    expect(res.body.expiresIn).toBe(900);
    expect(res.body.user).toMatchObject({ name: "Asha Menon", email: "asha@example.com", role: "user", isEmailVerified: false });
    expect(res.body.user.password).toBeUndefined();
    expect(res.body.verificationEmailSent).toBe(true);
    expect(lastCodeFor("asha@example.com", "verify")).toMatch(/^\d{6}$/);

    const stored = await User.findOne({ email: "asha@example.com" }).select("+password");
    expect(stored.password).not.toBe("Password123");
    expect(await bcrypt.compare("Password123", stored.password)).toBe(true);
  });

  test("refuses a duplicate email (any letter case)", async () => {
    await registerUser({ email: "dup@example.com" });
    const res = await request(app).post("/api/auth/register").send({ name: "Other", email: "DUP@example.com", password: "Password123" });
    expect(res.status).toBe(409);
    expect(res.body.message).toMatch(/already exists/);
  });

  test.each([
    [{ name: "A B", email: "x@example.com", password: "short1" }, /at least 8/],
    [{ name: "A B", email: "x@example.com", password: "onlyletters" }, /number/],
    [{ name: "A B", email: "not-an-email", password: "Password123" }, /valid email/],
    [{ email: "x@example.com", password: "Password123" }, /name/],
  ])("rejects invalid input %#", async (body, message) => {
    const res = await request(app).post("/api/auth/register").send(body);
    expect(res.status).toBe(400);
    expect(res.body.message).toMatch(message);
  });

  test("cannot make itself an admin", async () => {
    const res = await request(app)
      .post("/api/auth/register")
      .send({ name: "Sneaky", email: "sneaky@example.com", password: "Password123", role: "admin" });
    expect(res.status).toBe(201);
    expect(res.body.user.role).toBe("user");
  });
});

describe("login", () => {
  test("works with the right password, in any email case", async () => {
    const { email, password } = await registerUser();
    const res = await request(app).post("/api/auth/login").send({ email: email.toUpperCase(), password });
    expect(res.status).toBe(200);
    expect(res.body.accessToken).toBeDefined();
    expect(res.body.refreshToken).toBeDefined();
    expect(res.body.user.password).toBeUndefined();
  });

  test("gives the same answer for a wrong password and an unknown email", async () => {
    const { email } = await registerUser();
    const wrong = await request(app).post("/api/auth/login").send({ email, password: "Wrong12345" });
    const unknown = await request(app).post("/api/auth/login").send({ email: "nobody@example.com", password: "Wrong12345" });
    expect(wrong.status).toBe(401);
    expect(unknown.status).toBe(401);
    expect(wrong.body.message).toBe(unknown.body.message);
  });

  test("existing accounts with old 6-character passwords can still log in", async () => {
    await User.create({ name: "Old User", email: "old@example.com", password: await bcrypt.hash("abc123", 10) });
    const res = await request(app).post("/api/auth/login").send({ email: "old@example.com", password: "abc123" });
    expect(res.status).toBe(200);
  });
});

describe("protected routes", () => {
  test("need a valid token", async () => {
    const { accessToken } = await registerUser();
    expect((await request(app).get("/api/users/profile")).status).toBe(401);
    expect((await request(app).get("/api/users/profile").set(bearer("garbage"))).status).toBe(401);
    expect((await request(app).get("/api/users/profile").set(bearer(accessToken))).status).toBe(200);
  });

  test("reject expired tokens and tokens signed with another secret", async () => {
    const { user } = await registerUser();
    const expired = jwt.sign({ id: user.id, type: "access" }, process.env.JWT_SECRET, { expiresIn: -10 });
    const forged = jwt.sign({ id: user.id, type: "access" }, "some-other-secret");
    expect((await request(app).get("/api/users/profile").set(bearer(expired))).status).toBe(401);
    expect((await request(app).get("/api/users/profile").set(bearer(forged))).status).toBe(401);
  });

  test("still accept tokens issued by the old backend (no type claim)", async () => {
    const { user } = await registerUser();
    const legacy = jwt.sign({ id: user.id }, process.env.JWT_SECRET, { expiresIn: "30d" });
    expect((await request(app).get("/api/users/profile").set(bearer(legacy))).status).toBe(200);
  });
});

describe("refresh tokens", () => {
  test("exchange for a new pair, and each refresh token works only once", async () => {
    const { refreshToken } = await registerUser();
    const first = await request(app).post("/api/auth/refresh").send({ refreshToken });
    expect(first.status).toBe(200);
    expect(first.body.refreshToken).not.toBe(refreshToken);
    expect((await request(app).get("/api/users/profile").set(bearer(first.body.accessToken))).status).toBe(200);

    const again = await request(app).post("/api/auth/refresh").send({ refreshToken });
    expect(again.status).toBe(401);
  });

  test("reusing an old refresh token ends every session (theft protection)", async () => {
    const { refreshToken } = await registerUser();
    const rotated = await request(app).post("/api/auth/refresh").send({ refreshToken });
    // Pretend the first token was used a minute ago, outside the grace window.
    await RefreshToken.updateMany({ replacedByHash: { $ne: null } }, { $set: { revokedAt: new Date(Date.now() - 60000) } });

    expect((await request(app).post("/api/auth/refresh").send({ refreshToken })).status).toBe(401);
    // The newest token was revoked as well.
    expect((await request(app).post("/api/auth/refresh").send({ refreshToken: rotated.body.refreshToken })).status).toBe(401);
  });

  test("garbage and missing tokens are refused", async () => {
    expect((await request(app).post("/api/auth/refresh").send({ refreshToken: "x".repeat(40) })).status).toBe(401);
    expect((await request(app).post("/api/auth/refresh").send({})).status).toBe(400);
  });

  test("are stored only as hashes", async () => {
    const { refreshToken } = await registerUser();
    const rows = await RefreshToken.find().lean();
    expect(rows).toHaveLength(1);
    expect(JSON.stringify(rows)).not.toContain(refreshToken);
  });
});

describe("logout", () => {
  test("ends this device's session", async () => {
    const { refreshToken } = await registerUser();
    expect((await request(app).post("/api/auth/logout").send({ refreshToken })).status).toBe(200);
    expect((await request(app).post("/api/auth/refresh").send({ refreshToken })).status).toBe(401);
  });

  test("succeeds even without a token", async () => {
    expect((await request(app).post("/api/auth/logout").send({})).status).toBe(200);
  });

  test("logout-all ends every device", async () => {
    const { email, password, accessToken, refreshToken } = await registerUser();
    const second = await request(app).post("/api/auth/login").send({ email, password });
    expect((await request(app).post("/api/auth/logout-all").set(bearer(accessToken))).status).toBe(200);
    expect((await request(app).post("/api/auth/refresh").send({ refreshToken })).status).toBe(401);
    expect((await request(app).post("/api/auth/refresh").send({ refreshToken: second.body.refreshToken })).status).toBe(401);
  });
});

describe("email verification", () => {
  test("the emailed code verifies the account", async () => {
    const { email, accessToken } = await registerUser();
    const res = await request(app).post("/api/auth/verify-email").set(bearer(accessToken)).send({ code: lastCodeFor(email, "verify") });
    expect(res.status).toBe(200);
    expect(res.body.user.isEmailVerified).toBe(true);
  });

  test("a wrong code fails, and 5 wrong tries lock the code", async () => {
    const { email, accessToken } = await registerUser();
    const code = lastCodeFor(email, "verify");
    const wrong = code === "000000" ? "111111" : "000000";
    for (let i = 0; i < 5; i += 1) {
      const res = await request(app).post("/api/auth/verify-email").set(bearer(accessToken)).send({ code: wrong });
      expect(res.status).toBe(400);
    }
    const correctButLocked = await request(app).post("/api/auth/verify-email").set(bearer(accessToken)).send({ code });
    expect(correctButLocked.status).toBe(400);
  });

  test("resend has a 60-second cooldown and then sends a new code", async () => {
    const { email, accessToken } = await registerUser();
    expect((await request(app).post("/api/auth/resend-verification").set(bearer(accessToken))).status).toBe(429);
    await skipCooldown(email, "emailVerification");
    const res = await request(app).post("/api/auth/resend-verification").set(bearer(accessToken));
    expect(res.status).toBe(200);
    expect(outbox.filter((m) => m.to === email && m.meta.type === "verify")).toHaveLength(2);
  });
});

describe("forgot and reset password", () => {
  test("unknown and known emails get the same answer; only real accounts get mail", async () => {
    const { email } = await registerUser();
    const unknown = await request(app).post("/api/auth/forgot-password").send({ email: "nobody@example.com" });
    const known = await request(app).post("/api/auth/forgot-password").send({ email });
    expect(unknown.status).toBe(200);
    expect(known.status).toBe(200);
    expect(unknown.body.message).toBe(known.body.message);
    expect(outbox.some((m) => m.to === "nobody@example.com")).toBe(false);
    expect(lastCodeFor(email, "reset")).toMatch(/^\d{6}$/);
  });

  test("reset with the code changes the password and ends old sessions", async () => {
    const { email, password, user, refreshToken } = await registerUser();
    await request(app).post("/api/auth/forgot-password").send({ email });
    const code = lastCodeFor(email, "reset");

    const bad = await request(app).post("/api/auth/reset-password").send({ email, code: code === "000000" ? "111111" : "000000", newPassword: "NewPass456" });
    expect(bad.status).toBe(400);

    const res = await request(app).post("/api/auth/reset-password").send({ email, code, newPassword: "NewPass456" });
    expect(res.status).toBe(200);
    expect(res.body.accessToken).toBeDefined();
    expect(res.body.user.isEmailVerified).toBe(true);

    expect((await request(app).post("/api/auth/login").send({ email, password })).status).toBe(401);
    expect((await request(app).post("/api/auth/login").send({ email, password: "NewPass456" })).status).toBe(200);
    expect((await request(app).post("/api/auth/refresh").send({ refreshToken })).status).toBe(401);
    expect((await request(app).get("/api/users/profile").set(bearer(oldAccessToken(user.id)))).status).toBe(401);

    // The code can't be used twice.
    const reuse = await request(app).post("/api/auth/reset-password").send({ email, code, newPassword: "Another789" });
    expect(reuse.status).toBe(400);
  });
});

describe("change password", () => {
  test("needs the current password and a different new one", async () => {
    const { accessToken, password } = await registerUser();
    const wrong = await request(app).post("/api/auth/change-password").set(bearer(accessToken)).send({ currentPassword: "Wrong1234", newPassword: "NewPass456" });
    expect(wrong.status).toBe(400);
    const same = await request(app).post("/api/auth/change-password").set(bearer(accessToken)).send({ currentPassword: password, newPassword: password });
    expect(same.status).toBe(400);
  });

  test("logs out other devices and keeps this one logged in", async () => {
    const { email, password, accessToken, refreshToken } = await registerUser();
    const res = await request(app).post("/api/auth/change-password").set(bearer(accessToken)).send({ currentPassword: password, newPassword: "NewPass456" });
    expect(res.status).toBe(200);
    expect((await request(app).get("/api/users/profile").set(bearer(res.body.accessToken))).status).toBe(200);
    expect((await request(app).post("/api/auth/refresh").send({ refreshToken })).status).toBe(401);
    expect((await request(app).post("/api/auth/login").send({ email, password: "NewPass456" })).status).toBe(200);
  });
});

describe("Google sign-in", () => {
  const googleProfile = (overrides = {}) => ({
    googleId: "google-sub-123",
    email: "gina@example.com",
    emailVerified: true,
    name: "Gina George",
    picture: "https://lh3.googleusercontent.com/photo.jpg",
    ...overrides,
  });

  test("creates a verified account without a password", async () => {
    jest.spyOn(googleAuthService, "verifyGoogleIdToken").mockResolvedValue(googleProfile());
    const res = await request(app).post("/api/auth/google").send({ idToken: "a".repeat(50) });
    expect(res.status).toBe(201);
    expect(res.body.isNewUser).toBe(true);
    expect(res.body.user).toMatchObject({ email: "gina@example.com", isEmailVerified: true, googleLinked: true });
    expect(res.body.refreshToken).toBeDefined();

    const again = await request(app).post("/api/auth/google").send({ idToken: "a".repeat(50) });
    expect(again.status).toBe(200);
    expect(again.body.isNewUser).toBe(false);
    expect(await User.countDocuments()).toBe(1);
  });

  test("links to an existing account with the same verified email", async () => {
    const { email } = await registerUser({ email: "gina@example.com" });
    jest.spyOn(googleAuthService, "verifyGoogleIdToken").mockResolvedValue(googleProfile({ email }));
    const res = await request(app).post("/api/auth/google").send({ idToken: "a".repeat(50) });
    expect(res.status).toBe(200);
    expect(res.body.user.googleLinked).toBe(true);
    expect(await User.countDocuments()).toBe(1);
  });

  test("won't link when Google hasn't verified the email", async () => {
    const { email } = await registerUser({ email: "gina@example.com" });
    jest.spyOn(googleAuthService, "verifyGoogleIdToken").mockResolvedValue(googleProfile({ email, emailVerified: false }));
    const res = await request(app).post("/api/auth/google").send({ idToken: "a".repeat(50) });
    expect(res.status).toBe(409);
  });

  test("a Google-only account can't log in with a password until it sets one", async () => {
    jest.spyOn(googleAuthService, "verifyGoogleIdToken").mockResolvedValue(googleProfile());
    const google = await request(app).post("/api/auth/google").send({ idToken: "a".repeat(50) });

    expect((await request(app).post("/api/auth/login").send({ email: "gina@example.com", password: "Anything1" })).status).toBe(401);

    const set = await request(app).post("/api/auth/change-password").set(bearer(google.body.accessToken)).send({ newPassword: "MyNewPass1" });
    expect(set.status).toBe(200);
    expect((await request(app).post("/api/auth/login").send({ email: "gina@example.com", password: "MyNewPass1" })).status).toBe(200);
  });

  test("a rejected Google token returns 401", async () => {
    const AppError = require("../utils/AppError");
    jest.spyOn(googleAuthService, "verifyGoogleIdToken").mockRejectedValue(AppError.unauthorized("Google sign-in failed. Please try again."));
    const res = await request(app).post("/api/auth/google").send({ idToken: "a".repeat(50) });
    expect(res.status).toBe(401);
  });

  test("a missing Google token returns 400", async () => {
    expect((await request(app).post("/api/auth/google").send({})).status).toBe(400);
  });
});
