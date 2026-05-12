const express = require("express");

const router = express.Router();

const verifyToken =
  require("../auth/auth.middleware");

const {
  getCitizenByPhone,
  searchCitizenByName,
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
// SEARCH CITIZEN BY NAME
// =====================================

router.get(
  "/name/:citizenName",
  verifyToken,
  searchCitizenByName
);



module.exports = router;