const { prisma } =
  require("../config/db");





/*
|--------------------------------------------------------------------------
| Create Tracking Log Service
|--------------------------------------------------------------------------
*/
const createTrackingLogService =
  async ({

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
    slno,

    phoneNumber,

    citizenName,



    /*
    |--------------------------------------------------------------------------
    | RFID SNAPSHOT
    |--------------------------------------------------------------------------
    */
    drySlno,

    wetSlno,



    /*
    |--------------------------------------------------------------------------
    | NOT FOUND DETAILS
    |--------------------------------------------------------------------------
    */
    address,

    buildingNo,

    floorNo,

    photoUrl,



    /*
    |--------------------------------------------------------------------------
    | GEO LOCATION
    |--------------------------------------------------------------------------
    */
    latitude,

    longitude,



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
    remarks,

  }) => {

    try {

      /*
      |--------------------------------------------------------------------------
      | CREATE TRACKING LOG
      |--------------------------------------------------------------------------
      */
      const trackingLog =
        await prisma.trackingLog.create({

          data: {

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
            slno:
              slno || null,



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
              drySlno || null,



            wetSlno:
              wetSlno || null,



            /*
            |--------------------------------------------------------------------------
            | NOT FOUND DETAILS
            |--------------------------------------------------------------------------
            */
            address:
              address || null,



            buildingNo:
              buildingNo || null,



            floorNo:
              floorNo || null,



            /*
            |--------------------------------------------------------------------------
            | CLOUDINARY IMAGE URL
            |--------------------------------------------------------------------------
            */
            photoUrl:
              photoUrl || null,



            /*
            |--------------------------------------------------------------------------
            | GEO LOCATION
            |--------------------------------------------------------------------------
            */
            latitude:
              latitude !== undefined
                ? parseFloat(latitude)
                : null,



            longitude:
              longitude !== undefined
                ? parseFloat(longitude)
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

          },

        });



      return trackingLog;

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