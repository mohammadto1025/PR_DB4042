const express = require("express");

const {
  createRefund
} = require("../controllers/refund.controller");

const { authenticate } = require("../middleware/auth");

const router = express.Router();

router.post("/", authenticate, createRefund);

module.exports = router;