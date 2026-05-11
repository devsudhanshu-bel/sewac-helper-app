const express = require("express");

const router = express.Router();

const verifyToken = require("../auth/auth.middleware");

const {
  getCitizenByPhone,
  searchCitizenByName,
} = require("./citizen.controller");



// =====================================
// GET CITIZEN BY PHONE
// =====================================

router.get(
  "/citizen/phone/:phoneNumber",
  verifyToken,
  getCitizenByPhone
);



// =====================================
// SEARCH CITIZEN BY NAME
// =====================================

router.get(
  "/citizen/name/:citizenName",
  verifyToken,
  searchCitizenByName
);



module.exports = router;