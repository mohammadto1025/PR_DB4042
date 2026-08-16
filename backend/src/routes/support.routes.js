const express = require("express");

const {
    getAllReports,
    updateReportStatus,
    getAllReservations,
    updateReservationStatus
} = require("../controllers/support.controller");

const { authenticate } = require("../middleware/auth");
const { authorizeRoles } = require("../middleware/role");

const router = express.Router();

router.get("/reports", authenticate, authorizeRoles("support"), getAllReports);
router.patch("/reports/:id", authenticate, authorizeRoles("support"), updateReportStatus);

router.get("/reservations", authenticate, authorizeRoles("support"), getAllReservations);
router.patch("/reservations/:id/status", authenticate, authorizeRoles("support"), updateReservationStatus);

module.exports = router;
