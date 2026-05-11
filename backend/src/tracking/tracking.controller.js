const {
  createTrackingLogService,
  getAllTrackingLogsService,
  getTrackingLogsByWorkerService,
  getTrackingLogsByStatusService,
} = require("./tracking.service");





const createTrackingLog = async (req, res) => {
  try {

    const {
      slno,
      phoneNumber,
      citizenName,
      status,
      remarks,
    } = req.body;



    // Worker from JWT
    const workerId = req.user.username;



    if (!slno || !status) {
      return res.status(400).json({
        success: false,
        message: "SLNO and status are required",
      });
    }



    const trackingLog =
      await createTrackingLogService({
        workerId,
        slno,
        phoneNumber,
        citizenName,
        status,
        remarks,
      });



    return res.status(201).json({
      success: true,
      message: "Tracking log created successfully",
      data: trackingLog,
    });

  } catch (error) {

    console.error("TRACKING ERROR:", error);

    return res.status(500).json({
      success: false,
      message: "Internal Server Error",
    });
  }
};





const getAllTrackingLogs = async (
  req,
  res
) => {
  try {

    const logs =
      await getAllTrackingLogsService();



    return res.status(200).json({
      success: true,
      count: logs.length,
      data: logs,
    });

  } catch (error) {

    return res.status(500).json({
      success: false,
      message: "Internal Server Error",
    });
  }
};





const getTrackingLogsByWorker = async (
  req,
  res
) => {
  try {

    const { workerId } = req.params;

    const logs =
      await getTrackingLogsByWorkerService(
        workerId
      );



    return res.status(200).json({
      success: true,
      count: logs.length,
      data: logs,
    });

  } catch (error) {

    return res.status(500).json({
      success: false,
      message: "Internal Server Error",
    });
  }
};





const getTrackingLogsByStatus = async (
  req,
  res
) => {
  try {

    const { status } = req.params;

    const logs =
      await getTrackingLogsByStatusService(
        status
      );



    return res.status(200).json({
      success: true,
      count: logs.length,
      data: logs,
    });

  } catch (error) {

    return res.status(500).json({
      success: false,
      message: "Internal Server Error",
    });
  }
};





module.exports = {
  createTrackingLog,
  getAllTrackingLogs,
  getTrackingLogsByWorker,
  getTrackingLogsByStatus,
};