const express =
  require("express");

const router =
  express.Router();

const surveyController =
  require("./survey.controller");

const upload =
  require("../middleware/upload.middleware");





/*
|--------------------------------------------------------------------------
| Create Survey
|--------------------------------------------------------------------------
| POST /api/v1/survey/create
|--------------------------------------------------------------------------
|
| IMPORTANT:
| Content-Type => multipart/form-data
|
|--------------------------------------------------------------------------
|
| BODY:
|
| city                  -> text
| ward                  -> text
| area                  -> text
| wasteGeneratorTypes   -> text
| houseNumber           -> text
| floorNumber           -> text
| householdType         -> text
| personName            -> text
| contactNumber         -> text
| numberOfPeople        -> text
| buildingPhoto         -> file
|
|--------------------------------------------------------------------------
|
| IMPORTANT:
| Flutter multipart field name MUST be:
|
| "buildingPhoto"
|
|--------------------------------------------------------------------------
|
| Upload Flow:
|
| Flutter
| ↓
| Multipart Request
| ↓
| multer.memoryStorage()
| ↓
| req.file.buffer
| ↓
| streamifier
| ↓
| Cloudinary
| ↓
| secure_url
| ↓
| Prisma DB
|
|--------------------------------------------------------------------------
*/
router.post(

  "/create",

  upload.single(
    "buildingPhoto"
  ),

  surveyController.createSurvey

);





/*
|--------------------------------------------------------------------------
| Get All Surveys
|--------------------------------------------------------------------------
| GET /api/v1/survey/all
|--------------------------------------------------------------------------
*/
router.get(

  "/all",

  surveyController.getAllSurveys

);





/*
|--------------------------------------------------------------------------
| Get Survey By ID
|--------------------------------------------------------------------------
| GET /api/v1/survey/:id
|--------------------------------------------------------------------------
|
| Example:
|
| /survey/1
|
|--------------------------------------------------------------------------
*/
router.get(

  "/:id",

  surveyController.getSurveyById

);





/*
|--------------------------------------------------------------------------
| Survey Health Check
|--------------------------------------------------------------------------
| GET /api/v1/survey/health
|--------------------------------------------------------------------------
*/
router.get(

  "/health",

  (
    req,
    res
  ) => {

    return res.status(200).json({

      success: true,

      message:
        "Survey service running successfully",

    });

  }

);





/*
|--------------------------------------------------------------------------
| Export Router
|--------------------------------------------------------------------------
*/
module.exports =
  router;