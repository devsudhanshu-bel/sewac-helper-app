const { prisma } =
  require("../config/db");





/*
|--------------------------------------------------------------------------
| Create Tracking Log Service
|--------------------------------------------------------------------------
*/
const createTrackingLogService =
  async ({

    workerId,

    slno,

    phoneNumber,

    citizenName,

    drySlno,

    wetSlno,

    address,

    buildingNo,

    floorNo,

    photoUrl,

    latitude,

    longitude,

    status,

    remarks,

  }) => {

    try {

      /*
      |--------------------------------------------------------------------------
      | BLOCK FAILED RECORDS
      |--------------------------------------------------------------------------
      */
      if (

        status === "FAILED" ||

        status === "ERROR" ||

        status === "DUPLICATE"

      ) {

        return {

          success: false,

          message:
            "Tracking log skipped because operation failed",

        };

      }




      /*
      |--------------------------------------------------------------------------
      | REQUIRED VALIDATION
      |--------------------------------------------------------------------------
      */
      if (

        !workerId ||

        !status

      ) {

        return {

          success: false,

          message:
            "Required tracking fields missing",

        };

      }




      /*
      |--------------------------------------------------------------------------
      | PHONE NUMBER REQUIRED ONLY FOR FOUND
      |--------------------------------------------------------------------------
      */
      if (

        status === "FOUND" &&

        !phoneNumber

      ) {

        return {

          success: false,

          message:
            "Phone number is required for FOUND status",

        };

      }




      /*
      |--------------------------------------------------------------------------
      | CREATE TRACKING LOG
      |--------------------------------------------------------------------------
      */
      const trackingLog =
        await prisma.trackingLog.create({

          data: {

            workerId,

            slno:
              slno || null,

            phoneNumber:
              phoneNumber || null,

            citizenName:
              citizenName || null,

            drySlno:
              drySlno || null,

            wetSlno:
              wetSlno || null,

            address:
              address || null,

            buildingNo:
              buildingNo || null,

            floorNo:
              floorNo || null,

            photoUrl:
              photoUrl || null,

            latitude:
              latitude !== undefined &&
              latitude !== null &&
              latitude !== ""
                ? parseFloat(latitude)
                : null,

            longitude:
              longitude !== undefined &&
              longitude !== null &&
              longitude !== ""
                ? parseFloat(longitude)
                : null,

            status,

            remarks:
              remarks || null,

          },

        });




      return {

        success: true,

        data:
          trackingLog,

      };

    } catch (error) {

      console.error(
        "CREATE TRACKING LOG SERVICE ERROR:",
        error
      );

      throw error;

    }

  };





/*
|--------------------------------------------------------------------------
| Get All Tracking Logs
|--------------------------------------------------------------------------
*/
const getAllTrackingLogsService =
  async () => {

    try {

      const logs =
        await prisma.trackingLog.findMany({

          orderBy: {

            createdAt:
              "desc",

          },

        });



      return logs;

    } catch (error) {

      console.error(
        "GET ALL TRACKING LOGS SERVICE ERROR:",
        error
      );

      throw error;

    }

  };





/*
|--------------------------------------------------------------------------
| Get Tracking Logs By Worker
|--------------------------------------------------------------------------
*/
const getTrackingLogsByWorkerService =
  async (workerId) => {

    try {

      const logs =
        await prisma.trackingLog.findMany({

          where: {

            workerId,

          },

          orderBy: {

            createdAt:
              "desc",

          },

        });



      return logs;

    } catch (error) {

      console.error(
        "GET TRACKING LOGS BY WORKER SERVICE ERROR:",
        error
      );

      throw error;

    }

  };





/*
|--------------------------------------------------------------------------
| Get Tracking Logs By Status
|--------------------------------------------------------------------------
*/
const getTrackingLogsByStatusService =
  async (status) => {

    try {

      const logs =
        await prisma.trackingLog.findMany({

          where: {

            status,

          },

          orderBy: {

            createdAt:
              "desc",

          },

        });



      return logs;

    } catch (error) {

      console.error(
        "GET TRACKING LOGS BY STATUS SERVICE ERROR:",
        error
      );

      throw error;

    }

  };





/*
|--------------------------------------------------------------------------
| Export Services
|--------------------------------------------------------------------------
*/
module.exports = {

  createTrackingLogService,

  getAllTrackingLogsService,

  getTrackingLogsByWorkerService,

  getTrackingLogsByStatusService,

};