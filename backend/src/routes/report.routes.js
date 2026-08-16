const express = require("express");

const {
    createReport,
    getMyReports
} = require("../controllers/report.controller");

const { authenticate } = require("../middleware/auth");

const router = express.Router();

router.post("/", authenticate, createReport);
router.get("/my", authenticate, getMyReports);

module.exports = router;