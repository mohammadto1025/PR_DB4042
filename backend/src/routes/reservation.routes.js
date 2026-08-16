const express = require("express");

const {
  createReservation,
  getActiveReservations,
  getReservationHistory,
  changeReservationTicket,
  getCancellationPenalty,
  cancelReservation
} = require("../controllers/reservation.controller");

const { authenticate } = require("../middleware/auth");

const router = express.Router();

router.post("/", authenticate, createReservation);
router.get("/active", authenticate, getActiveReservations);
router.get("/history", authenticate, getReservationHistory);
router.post("/:id/change-ticket", authenticate, changeReservationTicket);
router.get("/:id/cancellation-penalty", authenticate, getCancellationPenalty);
router.post("/:id/cancel", authenticate, cancelReservation);

module.exports = router;