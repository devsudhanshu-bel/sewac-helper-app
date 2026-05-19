const express =
  require("express");

const router =
  express.Router();

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
| HEALTH CHECK
|--------------------------------------------------------------------------
| GET /api/v1/phone/health
|--------------------------------------------------------------------------
| Useful For:
| - Render
| - Railway
| - UptimeRobot
|--------------------------------------------------------------------------
*/
router.get(

  "/health",

  (req, res) => {

    return res.status(200).json({

      success: true,

      message:
        "Phone service is running",

      timestamp:
        new Date(),

    });

  }

);





/*
|--------------------------------------------------------------------------
| MAP PHONE NUMBER TO RFID
|--------------------------------------------------------------------------
| PATCH /api/v1/phone/map
|--------------------------------------------------------------------------
|
| SUPPORTS:
|
| CASE 1:
| ONLY DRY RFID
|
| CASE 2:
| ONLY WET RFID
|
| CASE 3:
| BOTH RFIDS
|
| CASE 4:
| LATER SECOND RFID
|
|--------------------------------------------------------------------------
|
| BODY:
|
| {
|   "slno": "00000001",
|   "phoneNumber": "9876543210"
| }
|
|--------------------------------------------------------------------------
*/
router.patch(

  "/map",

  verifyToken,

  mapPhoneNumber

);





/*
|--------------------------------------------------------------------------
| GET AVAILABLE / UNMAPPED PHONE NUMBERS
|--------------------------------------------------------------------------
| GET /api/v1/phone/unmapped
|--------------------------------------------------------------------------
|
| SHOWS:
| - Citizens with NO RFID
| - Citizens with ONLY DRY RFID
| - Citizens with ONLY WET RFID
|
| HIDES:
| - Citizens with BOTH DRY + WET RFIDs
|
|--------------------------------------------------------------------------
*/
router.get(

  "/unmapped",

  verifyToken,

  getUnmappedPhoneNumbers

);





/*
|--------------------------------------------------------------------------
| GET ALL PHONE MAPPINGS
|--------------------------------------------------------------------------
| GET /api/v1/phone/all
|--------------------------------------------------------------------------
|
| RETURNS:
| - All RFID mappings
| - Mapped + unmapped
|
|--------------------------------------------------------------------------
*/
router.get(

  "/all",

  verifyToken,

  getAllPhoneMappings

);





/*
|--------------------------------------------------------------------------
| GET PHONE MAPPING BY SLNO
|--------------------------------------------------------------------------
| GET /api/v1/phone/:slno
|--------------------------------------------------------------------------
|
| EXAMPLE:
| /api/v1/phone/00000001
|
|--------------------------------------------------------------------------
*/
router.get(

  "/:slno",

  verifyToken,

  getPhoneMappingBySLNO

);





module.exports = router;