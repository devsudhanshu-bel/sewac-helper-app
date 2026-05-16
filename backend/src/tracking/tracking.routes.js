const express = require("express");

const router = express.Router();

const verifyToken =
  require("../auth/auth.middleware");

const upload =
  require("../middleware/upload.middleware");

const {

  createTrackingLog,

  getAllTrackingLogs,

  getTrackingLogsByWorker,

  getTrackingLogsByStatus,

} = require("./tracking.controller");





/*
|--------------------------------------------------------------------------
| Create Tracking Log
|--------------------------------------------------------------------------
| POST /api/v1/tracking/create
|--------------------------------------------------------------------------
|
| IMPORTANT:
| Use multipart/form-data
|
|--------------------------------------------------------------------------
|
| FOUND BODY:
|
| slno          -> text
| phoneNumber   -> text
| citizenName   -> text
| drySlno       -> text
| wetSlno       -> text
| status        -> FOUND
|
|--------------------------------------------------------------------------
|
| NOT_FOUND BODY:
|
| status        -> NOT_FOUND
| address       -> text
| buildingNo    -> text
| floorNo       -> text
| remarks       -> text
| latitude      -> text
| longitude     -> text
| photo         -> file
|
|--------------------------------------------------------------------------
|
| Cloudinary automatically uploads:
|
| req.file.path
|
| and stores URL inside:
|
| photoUrl
|
|--------------------------------------------------------------------------
*/
router.post(

  "/create",

  verifyToken,

  upload.single("photo"),

  createTrackingLog

);





/*
|--------------------------------------------------------------------------
| Get All Tracking Logs
|--------------------------------------------------------------------------
| GET /api/v1/tracking/all
|--------------------------------------------------------------------------
*/
router.get(

  "/all",

  verifyToken,

  getAllTrackingLogs

);





/*
|--------------------------------------------------------------------------
| Get Tracking Logs By Worker
|--------------------------------------------------------------------------
| GET /api/v1/tracking/worker/:workerId
|--------------------------------------------------------------------------
*/
router.get(

  "/worker/:workerId",

  verifyToken,

  getTrackingLogsByWorker

);





/*
|--------------------------------------------------------------------------
| Get Tracking Logs By Status
|--------------------------------------------------------------------------
| GET /api/v1/tracking/status/:status
|--------------------------------------------------------------------------
|
| Example:
|
| /tracking/status/FOUND
|
| /tracking/status/NOT_FOUND
|--------------------------------------------------------------------------
*/
router.get(

  "/status/:status",

  verifyToken,

  getTrackingLogsByStatus

);





module.exports = router;