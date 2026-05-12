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



// =====================================
// GET CITIZEN BY PHONE NUMBER
// =====================================

router.get(
  "/phone/:phoneNumber",
  verifyToken,
  getCitizenByPhone
);



// =====================================
// GET ALL CITIZEN PHONE NUMBERS
// =====================================

router.get(
  "/phones",
  verifyToken,
  getAllCitizenPhoneNumbers
);



// ====================================
// SEARCH CITIZEN BY NAME
// =====================================

router.get(
  "/name/:citizenName",
  verifyToken,
  searchCitizenByName
);



// ====================================
// GET ALL CITIZEN NAMES
// =====================================

router.get(
  "/names",
  verifyToken,
  getAllCitizenNames
);



module.exports = router;