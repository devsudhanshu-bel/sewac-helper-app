const { prisma } = require("../config/db");



const createRFIDService = async (rfidValue) => {

  // Check existing RFID
  const existingRFID = await prisma.rFIDMapping.findUnique({
    where: {
      rfid: rfidValue,
    },
  });

  if (existingRFID) {
    throw new Error("RFID already mapped");
  }



  // Get latest record
  const latestRecord = await prisma.rFIDMapping.findFirst({
    orderBy: {
      id: "desc",
    },
  });



  let nextNumber = 1;

  if (latestRecord) {
    const currentNumber = parseInt(
      latestRecord.slno.replace("SEWAC", "")
    );

    nextNumber = currentNumber + 1;
  }



  // Generate SLNO
  const slno = String(nextNumber).padStart(8, "0");



  // Create RFID record
  const newRFID = await prisma.rFIDMapping.create({
    data: {
      slno,
      rfid: rfidValue,
      phoneNumber: null,
    },
  });



  return newRFID;
};





const getAllRFIDMappingsService = async () => {

  const allMappings = await prisma.rFIDMapping.findMany({
    orderBy: {
      createdAt: "desc",
    },
  });

  return allMappings;
};





module.exports = {
  createRFIDService,
  getAllRFIDMappingsService,
};