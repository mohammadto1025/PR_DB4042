const express = require("express");

const {
    indexTickets,
    searchTicketsElastic
} = require("../controllers/search.controller");

const router = express.Router();

router.post("/index-tickets", indexTickets);
router.get("/tickets", searchTicketsElastic);

module.exports = router;