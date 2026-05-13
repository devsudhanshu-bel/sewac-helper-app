const {

  createTrackingLogService,

  getAllTrackingLogsService,

  getTrackingLogsByWorkerService,

  getTrackingLogsByStatusService,

} = require("./tracking.service");





/*
|--------------------------------------------------------------------------
| Create Tracking Log
|--------------------------------------------------------------------------
*/
const createTrackingLog = async (
  req,
  res
) => {

  try {

    const {

      slno,

      phoneNumber,

      citizenName,

      status,

      remarks,

    } = req.body;



    // Worker from JWT
    const workerId =
      req.user.username;



    /*
    |--------------------------------------------------------------------------
    | REQUIRED VALIDATION
    |--------------------------------------------------------------------------
    */
    if (!slno || !status) {

      return res.status(400).json({

        success: false,

        message:
          "SLNO and status are required",

      });

    }



    /*
    |--------------------------------------------------------------------------
    | VALID STATUS CHECK
    |--------------------------------------------------------------------------
    */
    const allowedStatuses = [

      "FOUND",

      "NOT_FOUND",

    ];



    if (
      !allowedStatuses.includes(status)
    ) {

      return res.status(400).json({

        success: false,

        message:
          "Invalid status value",

      });

    }



    /*
    |--------------------------------------------------------------------------
    | REMARK REQUIRED FOR NOT_FOUND
    |--------------------------------------------------------------------------
    */
    if (
      status === "NOT_FOUND" &&
      !remarks
    ) {

      return res.status(400).json({

        success: false,

        message:
          "Remarks required for NOT_FOUND status",

      });

    }



    /*
    |--------------------------------------------------------------------------
    | CREATE TRACKING LOG
    |--------------------------------------------------------------------------
    */
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

      message:
        "Tracking log created successfully",

      data: trackingLog,

    });

  } catch (error) {

    console.error(
      "TRACKING ERROR:",
      error
    );

    return res.status(500).json({

      success: false,

      message:
        "Internal Server Error",

    });

  }

};





/*
|--------------------------------------------------------------------------
| Get All Tracking Logs
|--------------------------------------------------------------------------
*/
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

      message:
        "Internal Server Error",

    });

  }

};





/*
|--------------------------------------------------------------------------
| Get Tracking Logs By Worker
|--------------------------------------------------------------------------
*/
const getTrackingLogsByWorker = async (
  req,
  res
) => {

  try {

    const { workerId } =
      req.params;

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

      message:
        "Internal Server Error",

    });

  }

};





/*
|--------------------------------------------------------------------------
| Get Tracking Logs By Status
|--------------------------------------------------------------------------
*/
const getTrackingLogsByStatus = async (
  req,
  res
) => {

  try {

    const { status } =
      req.params;

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

      message:
        "Internal Server Error",

    });

  }

};





module.exports = {

  createTrackingLog,

  getAllTrackingLogs,

  getTrackingLogsByWorker,

  getTrackingLogsByStatus,

};