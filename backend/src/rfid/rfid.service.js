const { prisma } =
  require("../config/db");





/*
|--------------------------------------------------------------------------
| Create New RFID
|--------------------------------------------------------------------------
*/
const createRFIDService =
  async (rfidValue) => {

    // =============================
    // CHECK IF RFID ALREADY EXISTS
    // =============================

    const existingRFID =
      await prisma.rFIDMapping.findUnique({

        where: {
          rfid: rfidValue,
        },

      });



    if (existingRFID) {

      throw new Error(
        "RFID already exists"
      );

    }



    // =============================
    // GET LATEST RECORD
    // =============================

    const latestRecord =
      await prisma.rFIDMapping.findFirst({

        orderBy: {
          createdAt: "desc",
        },

      });



    // =============================
    // GENERATE NEXT SLNO
    // =============================

    let nextNumber = 1;



    if (
      latestRecord &&
      latestRecord.slno
    ) {

      const numericPart =
        latestRecord.slno.replace(
          /\D/g,
          ""
        );

      nextNumber =
        parseInt(
          numericPart || "0"
        ) + 1;

    }



    // Example:
    // 00000001
    // 00000002

    const slno =
      String(nextNumber)
        .padStart(8, "0");



    // =============================
    // CREATE RFID RECORD
    // =============================

    const newRFID =
      await prisma.rFIDMapping.create({

        data: {

          slno,

          rfid: rfidValue,

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
const getAllRFIDMappingsService =
  async () => {

    const allMappings =
      await prisma.rFIDMapping.findMany({

        orderBy: {
          createdAt: "desc",
        },

      });



    return allMappings;

};






/*
|--------------------------------------------------------------------------
| Get Only Unmapped RFIDs
|--------------------------------------------------------------------------
*/
const getUnmappedRFIDsService =
  async () => {

    const unmappedRFIDs =
      await prisma.rFIDMapping.findMany({

        where: {
          phoneNumber: null,
        },

        select: {

          id: true,

          slno: true,

          rfid: true,

          createdAt: true,

        },

        orderBy: {
          createdAt: "desc",
        },

      });



    return unmappedRFIDs;

};






/*
|--------------------------------------------------------------------------
| Map RFID To Phone Number
|--------------------------------------------------------------------------
*/
const mapRFIDToPhoneService =
  async (
    rfid,
    phoneNumber
  ) => {

    // =============================
    // CHECK IF RFID EXISTS
    // =============================

    const existingRFID =
      await prisma.rFIDMapping.findUnique({

        where: {
          slno: rfid,
        },

      });



    if (!existingRFID) {

      throw new Error(
        "RFID not found"
      );

    }



    // =============================
    // CHECK IF RFID ALREADY MAPPED
    // =============================

    if (
      existingRFID.phoneNumber
    ) {

      throw new Error(
        "RFID already mapped"
      );

    }



    // =============================
    // UPDATE RFID RECORD
    // =============================

    const updatedRFID =
      await prisma.rFIDMapping.update({

        where: {
          slno: rfid,
        },

        data: {
          phoneNumber,
        },

      });



    return updatedRFID;

};






/*
|--------------------------------------------------------------------------
| Get RFID By RFID Value
|--------------------------------------------------------------------------
*/
const getRFIDByValueService =
  async (rfid) => {

    const rfidData =
      await prisma.rFIDMapping.findUnique({

        where: {
          rfid,
        },

      });



    return rfidData;

};






/*
|--------------------------------------------------------------------------
| Get RFID By SLNO
|--------------------------------------------------------------------------
*/
const getRFIDBySLNOService =
  async (slno) => {

    const rfidData =
      await prisma.rFIDMapping.findUnique({

        where: {
          slno,
        },

      });



    return rfidData;

};






module.exports = {

  createRFIDService,

  getAllRFIDMappingsService,

  getUnmappedRFIDsService,

  mapRFIDToPhoneService,

  getRFIDByValueService,

  getRFIDBySLNOService,

};