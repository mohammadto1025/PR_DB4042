const express = require("express");

const {
  getMyProfile,
  updateMyProfile
} = require("../controllers/user.controller");

const { authenticate } = require("../middleware/auth");

const router = express.Router();

router.get("/me", authenticate, getMyProfile);
router.patch("/me", authenticate, updateMyProfile);

module.exports = router;