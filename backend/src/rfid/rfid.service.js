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

    const lastRFID =
      await prisma.rFIDMapping.findFirst({

        orderBy: {
          slno: "desc",
        },

        select: {
          slno: true,
        },

      });




    if (
      !lastRFID ||
      !lastRFID.slno
    ) {

      return "00000001";

    }




    const currentNumber =
      parseInt(
        lastRFID.slno,
        10
      );




    const nextNumber =
      currentNumber + 1;




    return String(nextNumber)
      .padStart(8, "0");

  };





/*
|--------------------------------------------------------------------------
| CREATE RFID
|--------------------------------------------------------------------------
*/
const createRFIDService =
  async (rfid) => {

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
    | RFID LENGTH VALIDATION
    |--------------------------------------------------------------------------
    */
    if (
      rfid.length !== 24
    ) {

      return {

        success: false,

        message:
          "RFID must be exactly 24 characters",

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




    const nextSLNO =
      await generateNextSLNO();




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
| GET ALL RFID MAPPINGS
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
| GET UNMAPPED RFIDS
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
| MAP RFID TO CITIZEN
|--------------------------------------------------------------------------
|
| CASE 1:
| WET ONLY
|
| CASE 2:
| DRY ONLY
|
| CASE 3:
| BOTH
|
| CASE 4:
| LATER UPDATE
|
*/
const mapRFIDService =
  async (

    slno,

    phoneNumber,

    wasteType

  ) => {

    /*
    |--------------------------------------------------------------------------
    | VALIDATE WASTE TYPE
    |--------------------------------------------------------------------------
    */
    if (
      wasteType !== "DRY" &&
      wasteType !== "WET"
    ) {

      throw new Error(
        "Waste type must be DRY or WET"
      );

    }




    /*
    |--------------------------------------------------------------------------
    | FIND RFID
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
    | RFID ALREADY USED BY ANOTHER CITIZEN
    |--------------------------------------------------------------------------
    */
    if (
      existingRFID.phoneNumber &&
      existingRFID.phoneNumber !==
      phoneNumber
    ) {

      throw new Error(

        `RFID already assigned to ${existingRFID.phoneNumber}`

      );

    }




    /*
    |--------------------------------------------------------------------------
    | CHECK IF SAME WASTE TYPE EXISTS
    |--------------------------------------------------------------------------
    |
    | EXAMPLE:
    | Citizen already has DRY
    | Cannot assign another DRY
    |
    */
    const existingWasteType =
      await prisma.rFIDMapping.findFirst({

        where: {

          phoneNumber,

          wasteType,

          NOT: {
            slno,
          },

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
    | AUTO MASTER DB SYNC
    |--------------------------------------------------------------------------
    |
    | EVEN IF ONLY ONE RFID EXISTS
    |
    */
    await syncMasterCitizenData(
      phoneNumber
    );




    /*
    |--------------------------------------------------------------------------
    | GET CURRENT CITIZEN RFIDS
    |--------------------------------------------------------------------------
    */
    const citizenRFIDs =
      await prisma.rFIDMapping.findMany({

        where: {
          phoneNumber,
        },

      });




    const dryRFID =
      citizenRFIDs.find(
        (item) =>
          item.wasteType === "DRY"
      );




    const wetRFID =
      citizenRFIDs.find(
        (item) =>
          item.wasteType === "WET"
      );




    return {

      success: true,

      message:
        "RFID mapped successfully",

      data: {

        citizenPhone:
          phoneNumber,

        dryRFID:
          dryRFID || null,

        wetRFID:
          wetRFID || null,

      },

    };

  };





/*
|--------------------------------------------------------------------------
| GET RFID BY SLNO
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
| GET CITIZEN RFIDS
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

      isFullyMapped:
        !!dry && !!wet,

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