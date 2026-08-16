const express = require("express");

const {
    searchTickets,
    getTicketById
} = require("../controllers/ticket.controller");

const router = express.Router();

router.get("/search", searchTickets);
router.get("/:id", getTicketById);

module.exports = router;