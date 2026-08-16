const express = require("express");

const {
    sendOtp,
    verifyOtp,
    requestLoginOtpAfterPassword,
    verifyLoginOtpAfterPassword,
    signup,
    getMe
} = require("../controllers/auth.controller");

const { authenticate } = require("../middleware/auth");

const router = express.Router();

router.post("/send-otp", sendOtp);
router.post("/verify-otp", verifyOtp);

router.post("/login", requestLoginOtpAfterPassword);
router.post("/login/verify-otp", verifyLoginOtpAfterPassword);

router.post("/signup", signup);
router.get("/me", authenticate, getMe);

module.exports = router;