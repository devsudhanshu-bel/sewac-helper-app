const { prisma } = require("../config/db");

const {
  syncMasterCitizenData,
} = require("../master/master.service");





/*
|--------------------------------------------------------------------------
| Create RFID
|--------------------------------------------------------------------------
*/
const createRFIDService = async (slno, rfid) => {

  // CHECK EXISTING SLNO
  const existingSLNO =
    await prisma.rFIDMapping.findUnique({
      where: {
        slno,
      },
    });

  if (existingSLNO) {
    throw new Error("SLNO already exists");
  }

  // CHECK EXISTING RFID
  const existingRFID =
    await prisma.rFIDMapping.findUnique({
      where: {
        rfid,
      },
    });

  if (existingRFID) {
    throw new Error("RFID already exists");
  }

  // CREATE RFID
  const newRFID =
    await prisma.rFIDMapping.create({
      data: {
        slno,
        rfid,
        phoneNumber: null,
      },
    });

  return newRFID;
};





/*
|--------------------------------------------------------------------------
| Get All RFID Mappings
|--------------------------------------------------------------------------
*/
const getAllRFIDMappingsService = async () => {

  return await prisma.rFIDMapping.findMany({

    orderBy: {
      createdAt: "desc",
    },

  });
};





/*
|--------------------------------------------------------------------------
| Get Unmapped RFIDs
|--------------------------------------------------------------------------
*/
const getUnmappedRFIDsService = async () => {

  return await prisma.rFIDMapping.findMany({

    where: {
      phoneNumber: null,
    },

    select: {

      slno: true,

      rfid: true,

      createdAt: true,

    },

    orderBy: {
      createdAt: "desc",
    },

  });
};





/*
|--------------------------------------------------------------------------
| Map RFID To Phone Number
|--------------------------------------------------------------------------
*/
const mapRFIDToPhoneService = async (
  slno,
  phoneNumber
) => {

  // CHECK RFID EXISTS
  const existingRFID =
    await prisma.rFIDMapping.findUnique({

      where: {
        slno,
      },

    });

  if (!existingRFID) {

    throw new Error(
      "RFID not found"
    );

  }

  // CHECK IF RFID ALREADY MAPPED
  if (existingRFID.phoneNumber) {

    throw new Error(
      "RFID already mapped"
    );

  }

  // UPDATE RFID MAPPING
  const updatedRFID =
    await prisma.rFIDMapping.update({

      where: {
        slno,
      },

      data: {
        phoneNumber,
      },

    });

  /*
  |--------------------------------------------------------------------------
  | AUTO SYNC MASTER DATABASE
  |--------------------------------------------------------------------------
  */
  await syncMasterCitizenData(
    phoneNumber
  );

  return updatedRFID;
};





/*
|--------------------------------------------------------------------------
| Get RFID By Value
|--------------------------------------------------------------------------
*/
const getRFIDByValueService = async (
  rfid
) => {

  const data =
    await prisma.rFIDMapping.findUnique({

      where: {
        rfid,
      },

    });

  if (!data) {

    throw new Error(
      "RFID not found"
    );

  }

  return data;
};





/*
|--------------------------------------------------------------------------
| Get RFID By SLNO
|--------------------------------------------------------------------------
*/
const getRFIDBySLNOService = async (
  slno
) => {

  const data =
    await prisma.rFIDMapping.findUnique({

      where: {
        slno,
      },

    });

  if (!data) {

    throw new Error(
      "RFID not found"
    );

  }

  return data;
};





module.exports = {

  createRFIDService,

  getAllRFIDMappingsService,

  getUnmappedRFIDsService,

  mapRFIDToPhoneService,

  getRFIDByValueService,

  getRFIDBySLNOService,

};