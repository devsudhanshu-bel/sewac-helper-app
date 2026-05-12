const express = require("express");

const router = express.Router();

const surveyController = require("./survey.controller");



// ======================================
// CREATE SURVEY
// ======================================
router.post(
  "/create",
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