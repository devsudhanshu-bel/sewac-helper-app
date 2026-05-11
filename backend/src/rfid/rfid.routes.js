const express = require("express");

const router = express.Router();

const {
  createRFID,
  getAllRFIDMappings,
  getUnmappedRFIDs,
  mapRFIDToPhone,
  getRFIDByValue,
} = require("./rfid.controller");



/*
|--------------------------------------------------------------------------
| Create RFID
|--------------------------------------------------------------------------
| POST /api/v1/rfid/rfid/:value
*/
router.post("/rfid/:value", createRFID);




/*
|--------------------------------------------------------------------------
| Get All RFID Mappings
|--------------------------------------------------------------------------
| GET /api/v1/rfid/rfid
*/
router.get("/rfid", getAllRFIDMappings);




/*
|--------------------------------------------------------------------------
| Get Unmapped RFIDs
|--------------------------------------------------------------------------
| GET /api/v1/rfid/unmapped
*/
router.get("/unmapped", getUnmappedRFIDs);




/*
|--------------------------------------------------------------------------
| Map RFID To Phone Number
|--------------------------------------------------------------------------
| POST /api/v1/rfid/map
*/
router.post("/map", mapRFIDToPhone);




/*
|--------------------------------------------------------------------------
| Get RFID Details By RFID Value
|--------------------------------------------------------------------------
| GET /api/v1/rfid/:rfid
*/
router.get("/:rfid", getRFIDByValue);




module.exports = router;