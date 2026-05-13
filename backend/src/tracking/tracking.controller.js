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
    | STATUS REQUIRED
    |--------------------------------------------------------------------------
    */
    if (!status) {

      return res.status(400).json({

        success: false,

        message:
          "Status is required",

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
    | FOUND VALIDATION
    |--------------------------------------------------------------------------
    */
    if (status === "FOUND") {

      if (
        !slno ||
        !phoneNumber ||
        !citizenName
      ) {

        return res.status(400).json({

          success: false,

          message:
            "SLNO, phoneNumber and citizenName are required for FOUND status",

        });

      }

    }



    /*
    |--------------------------------------------------------------------------
    | NOT_FOUND VALIDATION
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

        slno:
          status === "FOUND"
            ? slno
            : null,

        phoneNumber:
          status === "FOUND"
            ? phoneNumber
            : null,

        citizenName:
          status === "FOUND"
            ? citizenName
            : null,

        status,

        remarks:
          status === "NOT_FOUND"
            ? remarks
            : null,

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