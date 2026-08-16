const express = require("express");
const { createPayment } = require("../controllers/payment.controller");
const { authenticate } = require("../middleware/auth");

const router = express.Router();

router.post("/", authenticate, createPayment);

module.exports = router;