const express = require("express");

const router = express.Router();

const verifyToken =
  require("../auth/auth.middleware");

const {
  mapPhoneNumber,
  getPhoneMappingBySLNO,
  getAllPhoneMappings,
  getUnmappedPhoneNumbers,
} = require("./phone.controller");





/*
|--------------------------------------------------------------------------
| Map Phone Number To RFID
|--------------------------------------------------------------------------
| PATCH /api/v1/phone/map
|--------------------------------------------------------------------------
*/
router.patch(
  "/map",
  verifyToken,
  mapPhoneNumber
);





/*
|--------------------------------------------------------------------------
| Get Available / Unmapped Phone Numbers
|--------------------------------------------------------------------------
| GET /api/v1/phone/unmapped
|--------------------------------------------------------------------------
*/
router.get(
  "/unmapped",
  verifyToken,
  getUnmappedPhoneNumbers
);





/*
|--------------------------------------------------------------------------
| Get All Phone Mappings
|--------------------------------------------------------------------------
| GET /api/v1/phone/all
|--------------------------------------------------------------------------
*/
router.get(
  "/all",
  verifyToken,
  getAllPhoneMappings
);





/*
|--------------------------------------------------------------------------
| Get Phone Mapping By SLNO
|--------------------------------------------------------------------------
| GET /api/v1/phone/:slno
|--------------------------------------------------------------------------
*/
router.get(
  "/:slno",
  verifyToken,
  getPhoneMappingBySLNO
);





module.exports = router;