const nodemailer = require("nodemailer");
const { config } = require("../config/env");
const { CODE_TTL_MINUTES } = require("./codeService");

// In tests, emails are collected here instead of being sent.
const outbox = [];

let transporter;
const getTransporter = () => {
  if (!transporter) {
    transporter = nodemailer.createTransport({
      host: config.smtp.host,
      port: config.smtp.port,
      secure: config.smtp.port === 465,
      auth: { user: config.smtp.user, pass: config.smtp.pass },
    });
  }
  return transporter;
};

// True when a code email can actually reach someone.
const canSend = () => config.isTest || config.smtp.configured || config.emailDevLogCodes;

const send = async ({ to, subject, text, html, meta }) => {
  if (config.isTest) {
    outbox.push({ to, subject, text, meta });
    return;
  }
  if (!config.smtp.configured) {
    if (config.emailDevLogCodes) {
      console.log(`[email not sent, SMTP not set up] to=${to} subject="${subject}" code=${meta?.code}`);
      return;
    }
    throw new Error("SMTP is not configured.");
  }
  await getTransporter().sendMail({ from: config.smtp.from, to, subject, text, html });
};

const escapeHtml = (value) =>
  String(value).replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]);

const codeEmail = (title, intro, code) => ({
  text: `${intro}\n\nYour code: ${code}\n\nIt expires in ${CODE_TTL_MINUTES} minutes. If you didn't ask for this, you can ignore this email.\n\nPlotPost`,
  html: `<div style="font-family:Arial,sans-serif;max-width:480px">
  <h2 style="margin:0 0 12px">${title}</h2>
  <p>${escapeHtml(intro)}</p>
  <p style="font-size:28px;font-weight:bold;letter-spacing:6px;margin:20px 0">${code}</p>
  <p style="color:#666">It expires in ${CODE_TTL_MINUTES} minutes. If you didn't ask for this, you can ignore this email.</p>
  <p>PlotPost</p></div>`,
});

const sendVerificationCode = (user, code) =>
  send({
    to: user.email,
    subject: "Your PlotPost verification code",
    ...codeEmail("Verify your email", `Hi ${user.name}, use this code to verify your PlotPost email address.`, code),
    meta: { type: "verify", code },
  });

const sendPasswordResetCode = (user, code) =>
  send({
    to: user.email,
    subject: "Your PlotPost password reset code",
    ...codeEmail("Reset your password", `Hi ${user.name}, use this code to reset your PlotPost password.`, code),
    meta: { type: "reset", code },
  });

module.exports = { canSend, sendVerificationCode, sendPasswordResetCode, outbox };
