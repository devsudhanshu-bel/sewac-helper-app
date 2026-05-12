const express = require("express");

const router =
  express.Router();

const surveyController =
  require("./survey.controller");

const upload =
  require("../middleware/upload.middleware");



// ======================================
// CREATE SURVEY
// ======================================

router.post(
  "/create",

  upload.single(
    "buildingPhoto"
  ),

  surveyController.createSurvey
);



// ======================================
// GET ALL SURVEYS
// ======================================

router.get(
  "/all",
  surveyController.getAllSurveys
);



// ======================================
// GET SURVEY BY ID
// ======================================

router.get(
  "/:id",
  surveyController.getSurveyById
);



module.exports = router;