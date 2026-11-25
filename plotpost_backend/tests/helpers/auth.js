const request = require("supertest");
const app = require("../../app");

let counter = 0;

// Registers a fresh user and returns { user, accessToken, refreshToken, email, password }.
const registerUser = async (overrides = {}) => {
  counter += 1;
  const body = {
    name: "Test User",
    email: `user${counter}-${Date.now()}@example.com`,
    password: "Password123",
    ...overrides,
  };
  const res = await request(app).post("/api/auth/register").send(body);
  if (res.status !== 201) {
    throw new Error(`register failed: ${res.status} ${JSON.stringify(res.body)}`);
  }
  return {
    user: res.body.user,
    accessToken: res.body.accessToken,
    refreshToken: res.body.refreshToken,
    email: body.email,
    password: body.password,
  };
};

const bearer = (token) => ({ Authorization: `Bearer ${token}` });

module.exports = { registerUser, bearer };
