const express = require("express");

const {
    getCities,
    getVenues,
    getSports,
    getSeatCategories
} = require("../controllers/cityVenue.controller");

const router = express.Router();

router.get("/cities", getCities);
router.get("/venues", getVenues);
router.get("/sports", getSports);
router.get("/seat-categories", getSeatCategories);

module.exports = router;