const { prisma } =
  require("../config/db");

const {
  syncMasterCitizenData,
} = require("../master/master.service");





/*
|--------------------------------------------------------------------------
| GENERATE NEXT SLNO
|--------------------------------------------------------------------------
*/
const generateNextSLNO =
  async () => {

    /*
    |--------------------------------------------------------------------------
    | GET HIGHEST SLNO
    |--------------------------------------------------------------------------
    */
    const lastRFID =
      await prisma.rFIDMapping.findFirst({

        orderBy: {
          slno: "desc",
        },

        select: {
          slno: true,
        },

      });




    /*
    |--------------------------------------------------------------------------
    | FIRST RFID
    |--------------------------------------------------------------------------
    */
    if (
      !lastRFID ||
      !lastRFID.slno
    ) {

      return "00000001";

    }




    /*
    |--------------------------------------------------------------------------
    | CONVERT TO NUMBER
    |--------------------------------------------------------------------------
    */
    const currentNumber =
      parseInt(
        lastRFID.slno,
        10
      );




    /*
    |--------------------------------------------------------------------------
    | NEXT NUMBER
    |--------------------------------------------------------------------------
    */
    const nextNumber =
      currentNumber + 1;




    /*
    |--------------------------------------------------------------------------
    | PAD ZEROES
    |--------------------------------------------------------------------------
    */
    return String(nextNumber)
      .padStart(8, "0");

  };





/*
|--------------------------------------------------------------------------
| Create RFID
|--------------------------------------------------------------------------
| Auto Continues Sequence
|--------------------------------------------------------------------------
*/
const createRFIDService =
  async (rfid) => {

    /*
    |--------------------------------------------------------------------------
    | VALIDATE RFID
    |--------------------------------------------------------------------------
    */
    if (
      !rfid ||
      rfid.trim() === ""
    ) {

      return {

        success: false,

        message:
          "RFID code is required",

      };

    }




    /*
    |--------------------------------------------------------------------------
    | CHECK RFID EXISTS
    |--------------------------------------------------------------------------
    */
    const existingRFID =
      await prisma.rFIDMapping.findUnique({

        where: {
          rfid,
        },

      });




    /*
    |--------------------------------------------------------------------------
    | RFID ALREADY EXISTS
    |--------------------------------------------------------------------------
    */
    if (existingRFID) {

      return {

        success: false,

        message:
          "RFID already exists",

        data: {

          slno:
            existingRFID.slno,

        },

      };

    }




    /*
    |--------------------------------------------------------------------------
    | GENERATE NEXT SLNO
    |--------------------------------------------------------------------------
    */
    const nextSLNO =
      await generateNextSLNO();




    /*
    |--------------------------------------------------------------------------
    | CREATE RFID
    |--------------------------------------------------------------------------
    */
    const newRFID =
      await prisma.rFIDMapping.create({

        data: {

          slno:
            nextSLNO,

          rfid,

          phoneNumber:
            null,

          wasteType:
            null,

        },

      });




    /*
    |--------------------------------------------------------------------------
    | SUCCESS RESPONSE
    |--------------------------------------------------------------------------
    */
    return {

      success: true,

      message:
        "RFID created successfully",

      data:
        newRFID,

    };

  };





/*
|--------------------------------------------------------------------------
| Get All RFID Mappings
|--------------------------------------------------------------------------
*/
const getAllRFIDMappingsService =
  async () => {

    return prisma.rFIDMapping.findMany({

      orderBy: {
        slno: "desc",
      },

    });

  };





/*
|--------------------------------------------------------------------------
| Get Unmapped RFIDs
|--------------------------------------------------------------------------
*/
const getUnmappedRFIDsService =
  async () => {

    return prisma.rFIDMapping.findMany({

      where: {
        phoneNumber: null,
      },

      select: {

        slno: true,

        rfid: true,

        wasteType: true,

        createdAt: true,

      },

      orderBy: {
        slno: "desc",
      },

    });

  };





/*
|--------------------------------------------------------------------------
| Map RFID To Citizen
|--------------------------------------------------------------------------
*/
const mapRFIDService =
  async (

    slno,

    phoneNumber,

    wasteType

  ) => {

    /*
    |--------------------------------------------------------------------------
    | VALIDATE RFID EXISTS
    |--------------------------------------------------------------------------
    */
    const existingRFID =
      await prisma.rFIDMapping.findFirst({

        where: {
          slno,
        },

      });




    if (!existingRFID) {

      throw new Error(
        "RFID not found"
      );

    }




    /*
    |--------------------------------------------------------------------------
    | RFID ALREADY MAPPED
    |--------------------------------------------------------------------------
    */
    if (
      existingRFID.phoneNumber
    ) {

      /*
      |--------------------------------------------------------------------------
      | SAME CITIZEN
      |--------------------------------------------------------------------------
      */
      if (
        existingRFID.phoneNumber ===
        phoneNumber
      ) {

        throw new Error(
          `${wasteType} RFID already assigned to this citizen`
        );

      }




      /*
      |--------------------------------------------------------------------------
      | DIFFERENT CITIZEN
      |--------------------------------------------------------------------------
      */
      throw new Error(

        `RFID already assigned to ${existingRFID.phoneNumber}`

      );

    }




    /*
    |--------------------------------------------------------------------------
    | CHECK WASTE TYPE
    |--------------------------------------------------------------------------
    */
    const existingWasteType =
      await prisma.rFIDMapping.findFirst({

        where: {

          phoneNumber,

          wasteType,

        },

      });




    if (existingWasteType) {

      throw new Error(
        `Citizen already has a ${wasteType} RFID`
      );

    }




    /*
    |--------------------------------------------------------------------------
    | UPDATE RFID
    |--------------------------------------------------------------------------
    */
    const updatedRFID =
      await prisma.rFIDMapping.update({

        where: {
          id: existingRFID.id,
        },

        data: {

          phoneNumber,

          wasteType,

        },

      });




    /*
    |--------------------------------------------------------------------------
    | AUTO SYNC MASTER DB
    |--------------------------------------------------------------------------
    */
    await syncMasterCitizenData(
      phoneNumber
    );




    return updatedRFID;

  };





/*
|--------------------------------------------------------------------------
| Get RFID By SLNO
|--------------------------------------------------------------------------
*/
const getRFIDByValueService =
  async (slno) => {

    const data =
      await prisma.rFIDMapping.findFirst({

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





/*
|--------------------------------------------------------------------------
| Get Citizen RFIDs
|--------------------------------------------------------------------------
*/
const getCitizenRFIDsService =
  async (phoneNumber) => {

    const rfids =
      await prisma.rFIDMapping.findMany({

        where: {
          phoneNumber,
        },

      });




    if (
      !rfids ||
      rfids.length === 0
    ) {

      throw new Error(
        "No RFIDs found for citizen"
      );

    }




    let dry = null;

    let wet = null;





    rfids.forEach((item) => {

      /*
      |--------------------------------------------------------------------------
      | DRY RFID
      |--------------------------------------------------------------------------
      */
      if (
        item.wasteType === "DRY"
      ) {

        dry = {

          slno:
            item.slno,

          rfid:
            item.rfid,

        };

      }




      /*
      |--------------------------------------------------------------------------
      | WET RFID
      |--------------------------------------------------------------------------
      */
      if (
        item.wasteType === "WET"
      ) {

        wet = {

          slno:
            item.slno,

          rfid:
            item.rfid,

        };

      }

    });




    return {

      phoneNumber,

      dry,

      wet,

    };

  };





module.exports = {

  createRFIDService,

  getAllRFIDMappingsService,

  getUnmappedRFIDsService,

  mapRFIDService,

  getRFIDByValueService,

  getCitizenRFIDsService,

};