const { prisma } =
  require("../config/db");





/*
|--------------------------------------------------------------------------
| Create Tracking Log
|--------------------------------------------------------------------------
*/
const createTrackingLogService = async ({

  workerId,

  phoneNumber,

  citizenName,

  drySlno,

  wetSlno,

  status,

  remarks,

}) => {

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

      },

    });



  return trackingLog;
};





/*
|--------------------------------------------------------------------------
| Get All Tracking Logs
|--------------------------------------------------------------------------
*/
const getAllTrackingLogsService =
  async () => {

    const logs =
      await prisma.trackingLog.findMany({

        orderBy: {
          createdAt: "desc",
        },

      });



    return logs;
  };





/*
|--------------------------------------------------------------------------
| Get Tracking Logs By Worker
|--------------------------------------------------------------------------
*/
const getTrackingLogsByWorkerService =
  async (workerId) => {

    const logs =
      await prisma.trackingLog.findMany({

        where: {
          workerId,
        },

        orderBy: {
          createdAt: "desc",
        },

      });



    return logs;
  };





/*
|--------------------------------------------------------------------------
| Get Tracking Logs By Status
|--------------------------------------------------------------------------
*/
const getTrackingLogsByStatusService =
  async (status) => {

    const logs =
      await prisma.trackingLog.findMany({

        where: {
          status,
        },

        orderBy: {
          createdAt: "desc",
        },

      });



    return logs;
  };





module.exports = {

  createTrackingLogService,

  getAllTrackingLogsService,

  getTrackingLogsByWorkerService,

  getTrackingLogsByStatusService,

};