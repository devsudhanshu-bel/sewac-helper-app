const express = require("express");

const router = express.Router();

const {
  mapPhoneNumber,
} = require("../controllers/phone.controller");



// Map Phone Number
router.patch("/phone/map", mapPhoneNumber);



module.exports = router;