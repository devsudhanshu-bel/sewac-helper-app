const express = require("express");

const router = express.Router();

const verifyToken = require("../auth/auth.middleware");

const {
  createTrackingLog,
  getAllTrackingLogs,
  getTrackingLogsByWorker,
  getTrackingLogsByStatus,
} = require("./tracking.controller");



// Create Tracking Log
router.post(
  "/tracking/create",
  verifyToken,
  createTrackingLog
);



// Get All Logs
router.get(
  "/tracking",
  verifyToken,
  getAllTrackingLogs
);



// Get Logs By Worker
router.get(
  "/tracking/worker/:workerId",
  verifyToken,
  getTrackingLogsByWorker
);



// Get Logs By Status
router.get(
  "/tracking/status/:status",
  verifyToken,
  getTrackingLogsByStatus
);



module.exports = router;