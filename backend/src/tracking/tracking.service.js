const { prisma } = require("../config/db");



const createTrackingLogService = async ({
  workerId,
  slno,
  phoneNumber,
  citizenName,
  status,
  remarks,
}) => {

  const trackingLog = await prisma.trackingLog.create({
    data: {
      workerId,
      slno,
      phoneNumber,
      citizenName,
      status,
      remarks,
    },
  });

  return trackingLog;
};





const getAllTrackingLogsService = async () => {

  const logs = await prisma.trackingLog.findMany({
    orderBy: {
      createdAt: "desc",
    },
  });

  return logs;
};





const getTrackingLogsByWorkerService = async (
  workerId
) => {

  const logs = await prisma.trackingLog.findMany({
    where: {
      workerId,
    },

    orderBy: {
      createdAt: "desc",
    },
  });

  return logs;
};





const getTrackingLogsByStatusService = async (
  status
) => {

  const logs = await prisma.trackingLog.findMany({
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