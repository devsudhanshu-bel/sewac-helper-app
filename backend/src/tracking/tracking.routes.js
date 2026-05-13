const express = require("express");

const router = express.Router();

const verifyToken =
  require("../auth/auth.middleware");

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
| POST /api/v1/tracking/tracking/create
|--------------------------------------------------------------------------
*/
router.post(

  "/tracking/create",

  verifyToken,

  createTrackingLog

);





/*
|--------------------------------------------------------------------------
| Get All Tracking Logs
|--------------------------------------------------------------------------
| GET /api/v1/tracking/tracking
|--------------------------------------------------------------------------
*/
router.get(

  "/tracking",

  verifyToken,

  getAllTrackingLogs

);





/*
|--------------------------------------------------------------------------
| Get Tracking Logs By Worker
|--------------------------------------------------------------------------
| GET /api/v1/tracking/tracking/worker/:workerId
|--------------------------------------------------------------------------
*/
router.get(

  "/tracking/worker/:workerId",

  verifyToken,

  getTrackingLogsByWorker

);





/*
|--------------------------------------------------------------------------
| Get Tracking Logs By Status
|--------------------------------------------------------------------------
| GET /api/v1/tracking/tracking/status/:status
|--------------------------------------------------------------------------
*/
router.get(

  "/tracking/status/:status",

  verifyToken,

  getTrackingLogsByStatus

);





module.exports = router;