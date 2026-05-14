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
| POST /api/v1/tracking/create
|--------------------------------------------------------------------------
|
| FOUND BODY:
| {
|   "slno": "00000001",
|   "phoneNumber": "9876543210",
|   "citizenName": "Ravi Kumar",
|   "wasteType": "DRY",
|   "status": "FOUND"
| }
|
| NOT_FOUND BODY:
| {
|   "status": "NOT_FOUND",
|   "remarks": "Citizen shifted"
| }
|--------------------------------------------------------------------------
*/
router.post(

  "/create",

  verifyToken,

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
| /tracking/status/FOUND
| /tracking/status/NOT_FOUND
|--------------------------------------------------------------------------
*/
router.get(

  "/status/:status",

  verifyToken,

  getTrackingLogsByStatus

);





module.exports = router;