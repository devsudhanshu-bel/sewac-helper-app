const express =
  require("express");

const router =
  express.Router();

const verifyToken =
  require("../auth/auth.middleware");

const {

  getCitizenByPhone,

  searchCitizenByName,

  getAllCitizenPhoneNumbers,

  getAllCitizenNames,

  getUnmappedCitizens,

} = require("./citizen.controller");





/*
|--------------------------------------------------------------------------
| HEALTH CHECK
|--------------------------------------------------------------------------
| GET /api/v1/citizen/health
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
        "Citizen service is running",

      timestamp:
        new Date(),

    });

  }

);





/*
|--------------------------------------------------------------------------
| GET CITIZEN BY PHONE NUMBER
|--------------------------------------------------------------------------
| GET /api/v1/citizen/phone/:phoneNumber
|--------------------------------------------------------------------------
|
| RETURNS:
| - Full Citizen Details
| - Survey Data
|
|--------------------------------------------------------------------------
*/
router.get(

  "/phone/:phoneNumber",

  verifyToken,

  getCitizenByPhone

);





/*
|--------------------------------------------------------------------------
| GET ALL CITIZEN PHONE NUMBERS
|--------------------------------------------------------------------------
| GET /api/v1/citizen/phones
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

  "/phones",

  verifyToken,

  getAllCitizenPhoneNumbers

);





/*
|--------------------------------------------------------------------------
| GET ALL CITIZEN NAMES
|--------------------------------------------------------------------------
| GET /api/v1/citizen/names
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

  "/names",

  verifyToken,

  getAllCitizenNames

);





/*
|--------------------------------------------------------------------------
| GET UNMAPPED CITIZENS
|--------------------------------------------------------------------------
| GET /api/v1/citizen/unmapped
|--------------------------------------------------------------------------
|
| PARTIAL MAPPING ARCHITECTURE
|--------------------------------------------------------------------------
|
| SHOWS:
| - No RFID
| - Only DRY RFID
| - Only WET RFID
|
| HIDES:
| - Fully mapped citizens
|   (Both DRY + WET RFIDs)
|
|--------------------------------------------------------------------------
*/
router.get(

  "/unmapped",

  verifyToken,

  getUnmappedCitizens

);





/*
|--------------------------------------------------------------------------
| SEARCH CITIZEN BY NAME
|--------------------------------------------------------------------------
| GET /api/v1/citizen/name/:citizenName
|--------------------------------------------------------------------------
|
| EXAMPLE:
| /api/v1/citizen/name/Ramesh
|
|--------------------------------------------------------------------------
*/
router.get(

  "/name/:citizenName",

  verifyToken,

  searchCitizenByName

);





module.exports = router;