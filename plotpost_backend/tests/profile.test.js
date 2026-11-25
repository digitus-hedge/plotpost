const request = require("supertest");
const app = require("../app");
const db = require("./helpers/db");
const { registerUser, bearer } = require("./helpers/auth");
const User = require("../models/User");
const Post = require("../models/Post");
const Enquiry = require("../models/Enquiry");
const RefreshToken = require("../models/RefreshToken");
const imageService = require("../services/imageService");
const googleAuthService = require("../services/googleAuthService");

beforeAll(() => db.connect("profile"));
afterEach(async () => {
  await db.clear();
  jest.restoreAllMocks();
});
afterAll(() => db.close());

// Smallest valid PNG (1x1 pixel).
const PNG = Buffer.from(
  "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==",
  "base64"
);

const mockCloudinary = () => {
  let n = 0;
  const upload = jest.spyOn(imageService, "uploadAvatar").mockImplementation(async () => {
    n += 1;
    return { secure_url: `https://res.cloudinary.com/test-cloud/image/upload/v1/plotpost/avatars/a${n}.jpg`, public_id: `plotpost/avatars/a${n}` };
  });
  const destroy = jest.spyOn(imageService, "destroyImage").mockResolvedValue();
  return { upload, destroy };
};

describe("view and update profile", () => {
  test("returns the profile fields the edit screen uses", async () => {
    const { accessToken } = await registerUser({ name: "Ravi Kumar" });
    const res = await request(app).get("/api/users/profile").set(bearer(accessToken));
    expect(res.status).toBe(200);
    expect(res.body.user).toMatchObject({ name: "Ravi Kumar", agency: "", designation: "", location: "", phone: "", bio: "" });
    expect(res.body.user.settings).toEqual({ pushNotifications: true, emailInquiries: true, showPhoneNumber: true });
    expect(res.body.user.password).toBeUndefined();
  });

  test("saves name, phone, bio, agency, designation and location", async () => {
    const { accessToken } = await registerUser();
    const update = {
      name: "Ravi K",
      phone: "+91 98950 00001",
      bio: "Plots in Kozhikode",
      agency: "Calicut Prime Properties",
      designation: "Real Estate Agent",
      location: "Kozhikode, Kerala",
    };
    const res = await request(app).put("/api/users/profile").set(bearer(accessToken)).send(update);
    expect(res.status).toBe(200);
    expect(res.body.user).toMatchObject(update);
    const again = await request(app).get("/api/users/profile").set(bearer(accessToken));
    expect(again.body.user).toMatchObject(update);
  });

  test("ignores attempts to change role, email or verification", async () => {
    const { accessToken, email } = await registerUser();
    const res = await request(app)
      .put("/api/users/profile")
      .set(bearer(accessToken))
      .send({ name: "Fine Name", role: "admin", email: "other@example.com", isEmailVerified: true });
    expect(res.status).toBe(200);
    expect(res.body.user).toMatchObject({ role: "user", email, isEmailVerified: false });
  });

  test("rejects an invalid phone number and non-link profile images", async () => {
    const { accessToken } = await registerUser();
    expect((await request(app).put("/api/users/profile").set(bearer(accessToken)).send({ phone: "call me maybe" })).status).toBe(400);
    expect((await request(app).put("/api/users/profile").set(bearer(accessToken)).send({ profileImage: "data:image/png;base64,AAAA" })).status).toBe(400);
  });
});

describe("account settings", () => {
  test("saves the toggles", async () => {
    const { accessToken } = await registerUser();
    const res = await request(app).patch("/api/users/settings").set(bearer(accessToken)).send({ showPhoneNumber: false, pushNotifications: false });
    expect(res.status).toBe(200);
    expect(res.body.user.settings).toEqual({ pushNotifications: false, emailInquiries: true, showPhoneNumber: false });
  });

  test("rejects empty or wrong-type updates", async () => {
    const { accessToken } = await registerUser();
    expect((await request(app).patch("/api/users/settings").set(bearer(accessToken)).send({})).status).toBe(400);
    expect((await request(app).patch("/api/users/settings").set(bearer(accessToken)).send({ showPhoneNumber: "no" })).status).toBe(400);
  });
});

describe("profile photo", () => {
  test("upload stores the Cloudinary link; replacing deletes the old photo", async () => {
    const { upload, destroy } = mockCloudinary();
    const { accessToken } = await registerUser();

    const first = await request(app).post("/api/users/profile/photo").set(bearer(accessToken)).attach("image", PNG, { filename: "me.png", contentType: "image/png" });
    expect(first.status).toBe(200);
    expect(first.body.user.profileImage).toMatch(/a1\.jpg$/);

    const second = await request(app).post("/api/users/profile/photo").set(bearer(accessToken)).attach("image", PNG, { filename: "me2.png", contentType: "image/png" });
    expect(second.status).toBe(200);
    expect(upload).toHaveBeenCalledTimes(2);
    expect(destroy).toHaveBeenCalledWith("plotpost/avatars/a1");
  });

  test("rejects non-images and missing files", async () => {
    mockCloudinary();
    const { accessToken } = await registerUser();
    const pdf = await request(app).post("/api/users/profile/photo").set(bearer(accessToken)).attach("image", Buffer.from("%PDF-1.4"), { filename: "x.pdf", contentType: "application/pdf" });
    expect(pdf.status).toBe(400);
    expect(pdf.body.message).toMatch(/JPG, PNG and WEBP/);
    expect((await request(app).post("/api/users/profile/photo").set(bearer(accessToken))).status).toBe(400);
  });

  test("delete clears the photo and removes it from Cloudinary", async () => {
    const { destroy } = mockCloudinary();
    const { accessToken } = await registerUser();
    await request(app).post("/api/users/profile/photo").set(bearer(accessToken)).attach("image", PNG, { filename: "me.png", contentType: "image/png" });
    const res = await request(app).delete("/api/users/profile/photo").set(bearer(accessToken));
    expect(res.status).toBe(200);
    expect(res.body.user.profileImage).toBe("");
    expect(destroy).toHaveBeenCalledWith("plotpost/avatars/a1");
  });
});

describe("public profile", () => {
  test("shows public details only, and hides the phone when the owner says so", async () => {
    const { user, accessToken } = await registerUser({ name: "Seller One" });
    await request(app).put("/api/users/profile").set(bearer(accessToken)).send({ phone: "9895000001", agency: "Prime Plots" });

    const res = await request(app).get(`/api/users/${user.id}`);
    expect(res.status).toBe(200);
    expect(res.body.user).toMatchObject({ name: "Seller One", agency: "Prime Plots", phone: "9895000001", postsCount: 0 });
    expect(res.body.user.email).toBeUndefined();
    expect(res.body.user.settings).toBeUndefined();

    await request(app).patch("/api/users/settings").set(bearer(accessToken)).send({ showPhoneNumber: false });
    const hidden = await request(app).get(`/api/users/${user.id}`);
    expect(hidden.body.user.phone).toBe("");
  });

  test("bad and unknown IDs", async () => {
    expect((await request(app).get("/api/users/not-an-id")).status).toBe(400);
    expect((await request(app).get("/api/users/64b7f0f0f0f0f0f0f0f0f0f0")).status).toBe(404);
  });

  test("/api/users/saved still reaches the saved-posts route", async () => {
    const { accessToken } = await registerUser();
    const res = await request(app).get("/api/users/saved").set(bearer(accessToken));
    expect(res.status).toBe(200);
    expect(res.body.savedPosts).toEqual([]);
  });
});

describe("delete account", () => {
  test("needs the right password", async () => {
    const { accessToken } = await registerUser();
    const res = await request(app).delete("/api/users/account").set(bearer(accessToken)).send({ password: "Wrong1234" });
    expect(res.status).toBe(400);
    expect(await User.countDocuments()).toBe(1);
  });

  test("removes the user and everything that belongs to them, and nothing else", async () => {
    const { destroy } = mockCloudinary();
    const owner = await registerUser({ name: "Leaving User" });
    const other = await registerUser({ name: "Staying User" });

    const ownPost = await Post.create({
      user: owner.user.id,
      title: "Plot",
      location: "Kozhikode",
      imageUrls: ["https://res.cloudinary.com/test-cloud/image/upload/v1/plotpost/p1.jpg"],
    });
    const otherPost = await Post.create({
      user: other.user.id,
      title: "Villa",
      location: "Kochi",
      likes: [owner.user.id, other.user.id],
      comments: [{ user: owner.user.id, text: "Nice" }, { user: other.user.id, text: "Thanks" }],
    });
    await User.updateOne({ _id: other.user.id }, { $set: { savedPosts: [ownPost._id, otherPost._id] } });
    await Enquiry.create({ user: owner.user.id, post: otherPost._id, postTitle: "Villa", name: "L", phone: "1" });
    await Enquiry.create({ user: other.user.id, post: ownPost._id, postTitle: "Plot", name: "S", phone: "2" });
    await Enquiry.create({ user: other.user.id, post: otherPost._id, postTitle: "Villa", name: "S", phone: "3" });

    const res = await request(app).delete("/api/users/account").set(bearer(owner.accessToken)).send({ password: owner.password });
    expect(res.status).toBe(200);

    expect(await User.findById(owner.user.id)).toBeNull();
    expect(await Post.findById(ownPost._id)).toBeNull();
    expect(await RefreshToken.countDocuments({ user: owner.user.id })).toBe(0);

    const kept = await Post.findById(otherPost._id);
    expect(kept.likes.map(String)).toEqual([other.user.id]);
    expect(kept.comments.map((c) => c.text)).toEqual(["Thanks"]);

    const otherUser = await User.findById(other.user.id);
    expect(otherUser.savedPosts.map(String)).toEqual([String(otherPost._id)]);
    expect(await Enquiry.countDocuments()).toBe(1);

    expect(destroy).toHaveBeenCalledWith("plotpost/p1");
    expect((await request(app).post("/api/auth/login").send({ email: owner.email, password: owner.password })).status).toBe(401);
    expect((await request(app).get("/api/users/profile").set(bearer(owner.accessToken))).status).toBe(401);
  });

  test("Google-only accounts confirm by typing DELETE", async () => {
    jest.spyOn(googleAuthService, "verifyGoogleIdToken").mockResolvedValue({
      googleId: "g-1", email: "g@example.com", emailVerified: true, name: "G", picture: "",
    });
    const google = await request(app).post("/api/auth/google").send({ idToken: "a".repeat(50) });
    const token = google.body.accessToken;

    expect((await request(app).delete("/api/users/account").set(bearer(token)).send({ confirm: "delete" })).status).toBe(400);
    expect((await request(app).delete("/api/users/account").set(bearer(token)).send({ confirm: "DELETE" })).status).toBe(200);
    expect(await User.countDocuments()).toBe(0);
  });
});

describe("Cloudinary link parsing", () => {
  test("finds our public IDs and ignores everything else", () => {
    expect(imageService.publicIdFromUrl("https://res.cloudinary.com/test-cloud/image/upload/v1712/plotpost/abc.jpg")).toBe("plotpost/abc");
    expect(imageService.publicIdFromUrl("https://res.cloudinary.com/test-cloud/image/upload/plotpost/avatars/x.webp")).toBe("plotpost/avatars/x");
    expect(imageService.publicIdFromUrl("https://res.cloudinary.com/someone-else/image/upload/v1/plotpost/abc.jpg")).toBeNull();
    expect(imageService.publicIdFromUrl("data:image/png;base64,AAAA")).toBeNull();
    expect(imageService.publicIdFromUrl("https://example.com/plotpost/abc.jpg")).toBeNull();
  });
});
