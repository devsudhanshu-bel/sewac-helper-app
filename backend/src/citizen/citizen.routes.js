const express = require("express");

const router = express.Router();

const verifyToken =
  require("../auth/auth.middleware");

const {
  getCitizenByPhone,
  searchCitizenByName,
  getAllCitizenPhoneNumbers,
  getAllCitizenNames,
} = require("./citizen.controller");





/*
|--------------------------------------------------------------------------
| Get Citizen By Phone Number
|--------------------------------------------------------------------------
| GET /api/v1/citizen/phone/:phoneNumber
|--------------------------------------------------------------------------
*/
router.get(
  "/phone/:phoneNumber",
  verifyToken,
  getCitizenByPhone
);





/*
|--------------------------------------------------------------------------
| Get All Citizen Phone Numbers
|--------------------------------------------------------------------------
| GET /api/v1/citizen/phones
|--------------------------------------------------------------------------
*/
router.get(
  "/phones",
  verifyToken,
  getAllCitizenPhoneNumbers
);





/*
|--------------------------------------------------------------------------
| Search Citizen By Name
|--------------------------------------------------------------------------
| GET /api/v1/citizen/name/:citizenName
|--------------------------------------------------------------------------
*/
router.get(
  "/name/:citizenName",
  verifyToken,
  searchCitizenByName
);





/*
|--------------------------------------------------------------------------
| Get All Citizen Names
|--------------------------------------------------------------------------
| GET /api/v1/citizen/names
|--------------------------------------------------------------------------
*/
router.get(
  "/names",
  verifyToken,
  getAllCitizenNames
);





module.exports = router;