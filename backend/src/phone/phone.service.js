const { prisma } = require("../config/db");





/*
|--------------------------------------------------------------------------
| Map Phone Number To RFID
|--------------------------------------------------------------------------
*/
const mapPhoneNumberService = async (
  slno,
  phoneNumber
) => {

  // =============================
  // CHECK IF SLNO EXISTS
  // =============================

  const existingRecord =
    await prisma.rFIDMapping.findUnique({

      where: {
        slno,
      },

    });



  if (!existingRecord) {

    throw new Error(
      "SLNO not found"
    );

  }



  // =============================
  // CHECK IF RFID ALREADY MAPPED
  // =============================

  if (
    existingRecord.phoneNumber
  ) {

    throw new Error(
      "This RFID is already mapped"
    );

  }



  // =============================
  // GET EXISTING PHONE MAPPINGS
  // =============================

  const existingPhoneMappings =
    await prisma.rFIDMapping.findMany({

      where: {
        phoneNumber,
      },

      select: {
        wasteType: true,
      },

    });



  let hasDry = false;

  let hasWet = false;



  existingPhoneMappings.forEach(
    (item) => {

      if (
        item.wasteType
          ?.toLowerCase() ===
        "dry"
      ) {

        hasDry = true;

      }



      if (
        item.wasteType
          ?.toLowerCase() ===
        "wet"
      ) {

        hasWet = true;

      }

    }
  );



  // =============================
  // BLOCK IF BOTH EXIST
  // =============================

  if (
    hasDry &&
    hasWet
  ) {

    throw new Error(
      "Phone number already mapped for both Dry and Wet waste"
    );

  }



  // =============================
  // BLOCK DUPLICATE DRY
  // =============================

  if (

    existingRecord.wasteType
      ?.toLowerCase() ===
      "dry" &&

    hasDry

  ) {

    throw new Error(
      "Phone number already mapped to a Dry RFID"
    );

  }



  // =============================
  // BLOCK DUPLICATE WET
  // =============================

  if (

    existingRecord.wasteType
      ?.toLowerCase() ===
      "wet" &&

    hasWet

  ) {

    throw new Error(
      "Phone number already mapped to a Wet RFID"
    );

  }



  // =============================
  // UPDATE PHONE NUMBER
  // =============================

  const updatedRecord =
    await prisma.rFIDMapping.update({

      where: {
        slno,
      },

      data: {
        phoneNumber,
      },

    });



  return updatedRecord;

};





/*
|--------------------------------------------------------------------------
| Get Phone Mapping By SLNO
|--------------------------------------------------------------------------
*/
const getPhoneMappingBySLNOService =
  async (slno) => {

    const record =
      await prisma.rFIDMapping.findUnique({

        where: {
          slno,
        },

      });



    if (!record) {

      throw new Error(
        "Record not found"
      );

    }



    return record;

  };





/*
|--------------------------------------------------------------------------
| Get All Phone Mappings
|--------------------------------------------------------------------------
*/
const getAllPhoneMappingsService =
  async () => {

    const records =
      await prisma.rFIDMapping.findMany({

        orderBy: {
          createdAt: "desc",
        },

      });



    return records;

  };





/*
|--------------------------------------------------------------------------
| Get Only Mapped Phone Records
|--------------------------------------------------------------------------
*/
const getMappedPhoneRecordsService =
  async () => {

    const records =
      await prisma.rFIDMapping.findMany({

        where: {

          NOT: {
            phoneNumber: null,
          },

        },

        orderBy: {
          createdAt: "desc",
        },

      });



    return records;

  };





/*
|--------------------------------------------------------------------------
| Get Available / Unmapped Phone Numbers
|--------------------------------------------------------------------------
*/
const getUnmappedPhoneNumbersService =
  async () => {

    // =============================
    // GET ALL RFID MAPPINGS
    // =============================

    const mappings =
      await prisma.rFIDMapping.findMany({

        where: {

          phoneNumber: {
            not: null,
          },

        },

        select: {

          phoneNumber: true,

          wasteType: true,

        },

      });



    // =============================
    // TRACK DRY/WET STATUS
    // =============================

    const tracker = {};



    mappings.forEach((item) => {

      if (
        !tracker[item.phoneNumber]
      ) {

        tracker[item.phoneNumber] = {

          dry: false,

          wet: false,

        };

      }



      // DRY
      if (
        item.wasteType
          ?.toLowerCase() ===
        "dry"
      ) {

        tracker[
          item.phoneNumber
        ].dry = true;

      }



      // WET
      if (
        item.wasteType
          ?.toLowerCase() ===
        "wet"
      ) {

        tracker[
          item.phoneNumber
        ].wet = true;

      }

    });



    // =============================
    // GET ALL SURVEY CITIZENS
    // =============================

    const citizens =
      await prisma.survey.findMany({

        where: {

          contactNumber: {
            not: null,
          },

        },

        select: {

          personName: true,

          contactNumber: true,

        },

        distinct: [
          "contactNumber",
        ],

        orderBy: {
          id: "desc",
        },

      });



    // =============================
    // FILTER CITIZENS
    // =============================

    const filteredCitizens =
      citizens.filter(
        (citizen) => {

          const status =
            tracker[
              citizen.contactNumber
            ];



          // NEVER MAPPED
          if (!status) {
            return true;
          }



          // ONLY ONE EXISTS
          if (

            (
              status.dry &&
              !status.wet
            ) ||

            (
              !status.dry &&
              status.wet
            )

          ) {

            return true;

          }



          // BOTH EXIST
          return false;

        }
      );



    // =============================
    // FORMAT RESPONSE
    // =============================

    const formattedData =
      filteredCitizens.map(
        (citizen) => ({

          citizenName:
            citizen.personName,

          phoneNumber:
            citizen.contactNumber,

        })
      );



    return formattedData;

  };




module.exports = {

  mapPhoneNumberService,

  getPhoneMappingBySLNOService,

  getAllPhoneMappingsService,

  getMappedPhoneRecordsService,

  getUnmappedPhoneNumbersService,

};