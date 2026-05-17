const express =
  require("express");

const router =
  express.Router();

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
| Content-Type => multipart/form-data
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
| IMPORTANT:
| Flutter multipart field name MUST be:
|
| "photo"
|
|--------------------------------------------------------------------------
|
| Upload Flow:
|
| Flutter
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
|
| Example:
|
| /tracking/worker/sewac01
|
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
|
|--------------------------------------------------------------------------
*/
router.get(

  "/status/:status",

  verifyToken,

  getTrackingLogsByStatus

);





/*
|--------------------------------------------------------------------------
| Health Check
|--------------------------------------------------------------------------
| GET /api/v1/tracking/health
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
        "Tracking service running successfully",

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