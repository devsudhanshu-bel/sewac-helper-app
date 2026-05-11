const express = require("express");

const router = express.Router();

const {
  mapPhoneNumber,
  getPhoneMappingBySLNO,
  getAllPhoneMappings,
} = require("./phone.controller");





/*
|--------------------------------------------------------------------------
| Map Phone Number To RFID
|--------------------------------------------------------------------------
| PATCH /api/v1/phone/map
|--------------------------------------------------------------------------
*/
router.patch("/map", mapPhoneNumber);





/*
|--------------------------------------------------------------------------
| Get Phone Mapping By SLNO
|--------------------------------------------------------------------------
| GET /api/v1/phone/:slno
|--------------------------------------------------------------------------
*/
router.get("/:slno", getPhoneMappingBySLNO);





/*
|--------------------------------------------------------------------------
| Get All Phone Mappings
|--------------------------------------------------------------------------
| GET /api/v1/phone/all
|--------------------------------------------------------------------------
*/
router.get("/all", getAllPhoneMappings);





module.exports = router;