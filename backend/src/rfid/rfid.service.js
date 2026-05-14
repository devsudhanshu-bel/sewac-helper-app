const { prisma } = require("../config/db");

const {
  syncMasterCitizenData,
} = require("../master/master.service");





/*
|--------------------------------------------------------------------------
| Create RFID
|--------------------------------------------------------------------------
| Auto Generates RFID Number (SLNO)
|--------------------------------------------------------------------------
*/
const createRFIDService = async (
  rfid
) => {

  /*
  |--------------------------------------------------------------------------
  | CHECK EXISTING RFID CODE
  |--------------------------------------------------------------------------
  */
  const existingRFID =
    await prisma.rFIDMapping.findUnique({

      where: {
        rfid,
      },

    });



  if (existingRFID) {

    throw new Error(
      "RFID already exists"
    );

  }




  /*
  |--------------------------------------------------------------------------
  | GET LAST RFID NUMBER
  |--------------------------------------------------------------------------
  */
  const lastRFID =
    await prisma.rFIDMapping.findFirst({

      orderBy: {
        createdAt: "desc",
      },

    });




  /*
  |--------------------------------------------------------------------------
  | GENERATE NEXT RFID NUMBER
  |--------------------------------------------------------------------------
  */
  let nextSLNO = "00000001";



  if (
    lastRFID &&
    lastRFID.slno
  ) {

    const currentNumber =
      parseInt(lastRFID.slno);

    const nextNumber =
      currentNumber + 1;

    nextSLNO =
      String(nextNumber).padStart(
        8,
        "0"
      );
  }




  /*
  |--------------------------------------------------------------------------
  | CREATE RFID
  |--------------------------------------------------------------------------
  */
  const newRFID =
    await prisma.rFIDMapping.create({

      data: {

        slno: nextSLNO,

        rfid,

        phoneNumber: null,

        wasteType: null,

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
const getUnmappedRFIDsService =
  async () => {

    return await prisma.rFIDMapping.findMany({

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
        createdAt: "desc",
      },

    });
  };





/*
|--------------------------------------------------------------------------
| Map RFID To Citizen
|--------------------------------------------------------------------------
| Mapping happens using RFID Number (SLNO)
|--------------------------------------------------------------------------
*/
const mapRFIDService = async (

  slno,

  phoneNumber,

  wasteType

) => {

  /*
  |--------------------------------------------------------------------------
  | VALIDATE RFID NUMBER EXISTS
  |--------------------------------------------------------------------------
  */
  const existingRFID =
    await prisma.rFIDMapping.findFirst({

      where: {
        slno,
        phoneNumber: null,
      },

    });



  if (!existingRFID) {

    throw new Error(
      "Available RFID not found for this SLNO"
    );

  }




  /*
  |--------------------------------------------------------------------------
  | CHECK IF CITIZEN ALREADY HAS THIS WASTE TYPE
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
      `${wasteType} RFID already assigned to this citizen`
    );

  }




  /*
  |--------------------------------------------------------------------------
  | MAP RFID
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
| Get RFID By RFID Number (SLNO)
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

      if (
        item.wasteType === "DRY"
      ) {

        dry = {

          slno: item.slno,

          rfid: item.rfid,

        };
      }



      if (
        item.wasteType === "WET"
      ) {

        wet = {

          slno: item.slno,

          rfid: item.rfid,

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