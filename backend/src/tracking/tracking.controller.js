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

      phoneNumber,

      citizenName,

      drySlno,

      wetSlno,

      status,

      remarks,

    } = req.body;





    /*
    |--------------------------------------------------------------------------
    | WORKER FROM JWT
    |--------------------------------------------------------------------------
    */
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
      !allowedStatuses.includes(
        status
      )
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

        !phoneNumber ||

        !citizenName ||

        !drySlno ||

        !wetSlno

      ) {

        return res.status(400).json({

          success: false,

          message:
            "phoneNumber, citizenName, drySlno and wetSlno are required for FOUND status",

        });
      }
    }





    /*
    |--------------------------------------------------------------------------
    | NOT_FOUND VALIDATION
    |--------------------------------------------------------------------------
    */
    if (status === "NOT_FOUND") {

      if (

        !phoneNumber ||

        !citizenName ||

        !remarks

      ) {

        return res.status(400).json({

          success: false,

          message:
            "citizenName, phoneNumber and remarks are required for NOT_FOUND status",

        });
      }
    }





    /*
    |--------------------------------------------------------------------------
    | CREATE TRACKING LOG
    |--------------------------------------------------------------------------
    */
    const trackingLog =
      await createTrackingLogService({



        /*
        |--------------------------------------------------------------------------
        | WORKER
        |--------------------------------------------------------------------------
        */

        workerId,




        /*
        |--------------------------------------------------------------------------
        | CITIZEN
        |--------------------------------------------------------------------------
        */

        phoneNumber:
          phoneNumber || null,



        citizenName:
          citizenName || null,




        /*
        |--------------------------------------------------------------------------
        | RFID SNAPSHOT
        |--------------------------------------------------------------------------
        */

        drySlno:
          status === "FOUND"
            ? drySlno
            : null,



        wetSlno:
          status === "FOUND"
            ? wetSlno
            : null,




        /*
        |--------------------------------------------------------------------------
        | STATUS
        |--------------------------------------------------------------------------
        */

        status,




        /*
        |--------------------------------------------------------------------------
        | REMARKS
        |--------------------------------------------------------------------------
        */

        remarks:
          remarks || null,

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
        error.message ||
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

    console.error(
      "GET ALL TRACKING LOGS ERROR:",
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

    console.error(
      "GET TRACKING LOGS BY WORKER ERROR:",
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

    console.error(
      "GET TRACKING LOGS BY STATUS ERROR:",
      error
    );

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