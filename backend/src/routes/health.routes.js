const express = require("express");

const { testDatabaseConnection } = require("../config/db");
const { testRedisConnection } = require("../config/redis");

const router = express.Router();

router.get("/", (req, res) => {
    res.json({
        success: true,
        message: "Backend API is running",
        phase: "Phase 3 - Backend API"
    });
});

router.get("/db", async (req, res, next) => {
    try {
        const dbInfo = await testDatabaseConnection();

        res.json({
            success: true,
            message: "PostgreSQL connection successful",
            data: dbInfo
        });
    } catch (error) {
        next(error);
    }
});

router.get("/redis", async (req, res, next) => {
    try {
        const redisStatus = await testRedisConnection();

        res.json({
            success: true,
            message: "Redis connection successful",
            data: {
                status: redisStatus
            }
        });
    } catch (error) {
        next(error);
    }
});

module.exports = router;