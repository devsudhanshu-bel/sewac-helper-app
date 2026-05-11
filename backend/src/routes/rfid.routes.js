const express = require("express");

const router = express.Router();

const {
  createRFID,
  getAllRFIDMappings,
} = require("../controllers/rfid.controller");



// Create RFID Mapping
router.post("/rfid/:value", createRFID);



// Get All RFID Mappings
router.get("/rfid", getAllRFIDMappings);



module.exports = router;