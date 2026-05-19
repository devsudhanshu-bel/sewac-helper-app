const { prisma } =
  require("../config/db");





/*
|--------------------------------------------------------------------------
| MAP PHONE NUMBER TO RFID
|--------------------------------------------------------------------------
|
| SUPPORTS:
|
| CASE 1:
| ONLY DRY
|
| CASE 2:
| ONLY WET
|
| CASE 3:
| BOTH
|
| CASE 4:
| LATER SECOND RFID
|
|--------------------------------------------------------------------------
*/
const mapPhoneNumberService =
  async (

    slno,

    phoneNumber

  ) => {

    /*
    |--------------------------------------------------------------------------
    | CHECK SLNO EXISTS
    |--------------------------------------------------------------------------
    */
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




    /*
    |--------------------------------------------------------------------------
    | RFID ALREADY USED
    |--------------------------------------------------------------------------
    */
    if (

      existingRecord.phoneNumber &&

      existingRecord.phoneNumber !==
      phoneNumber

    ) {

      throw new Error(
        "This RFID is already mapped"
      );

    }




    /*
    |--------------------------------------------------------------------------
    | GET ALL EXISTING PHONE MAPPINGS
    |--------------------------------------------------------------------------
    */
    const existingPhoneMappings =
      await prisma.rFIDMapping.findMany({

        where: {
          phoneNumber,
        },

        select: {

          wasteType: true,

          slno: true,

        },

      });




    let hasDry = false;

    let hasWet = false;





    existingPhoneMappings.forEach(
      (item) => {

        /*
        |--------------------------------------------------------------------------
        | DRY
        |--------------------------------------------------------------------------
        */
        if (

          item.wasteType
            ?.toLowerCase() ===
          "dry"

        ) {

          hasDry = true;

        }




        /*
        |--------------------------------------------------------------------------
        | WET
        |--------------------------------------------------------------------------
        */
        if (

          item.wasteType
            ?.toLowerCase() ===
          "wet"

        ) {

          hasWet = true;

        }

      }
    );




    /*
    |--------------------------------------------------------------------------
    | BLOCK DUPLICATE DRY
    |--------------------------------------------------------------------------
    */
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




    /*
    |--------------------------------------------------------------------------
    | BLOCK DUPLICATE WET
    |--------------------------------------------------------------------------
    */
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




    /*
    |--------------------------------------------------------------------------
    | UPDATE PHONE NUMBER
    |--------------------------------------------------------------------------
    */
    const updatedRecord =
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
    | GET CURRENT STATUS
    |--------------------------------------------------------------------------
    */
    const updatedMappings =
      await prisma.rFIDMapping.findMany({

        where: {
          phoneNumber,
        },

      });




    let dryRFID = null;

    let wetRFID = null;





    updatedMappings.forEach(
      (item) => {

        /*
        |--------------------------------------------------------------------------
        | DRY
        |--------------------------------------------------------------------------
        */
        if (
          item.wasteType === "DRY"
        ) {

          dryRFID = {

            slno:
              item.slno,

            rfid:
              item.rfid,

          };

        }




        /*
        |--------------------------------------------------------------------------
        | WET
        |--------------------------------------------------------------------------
        */
        if (
          item.wasteType === "WET"
        ) {

          wetRFID = {

            slno:
              item.slno,

            rfid:
              item.rfid,

          };

        }

      }
    );




    /*
    |--------------------------------------------------------------------------
    | RESPONSE
    |--------------------------------------------------------------------------
    */
    return {

      success: true,

      message:
        "Phone number mapped successfully",

      data: {

        phoneNumber,

        dryRFID,

        wetRFID,

        isFullyMapped:
          !!dryRFID && !!wetRFID,

      },

    };

  };





/*
|--------------------------------------------------------------------------
| GET PHONE MAPPING BY SLNO
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
| GET ALL PHONE MAPPINGS
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
| GET ONLY MAPPED PHONE RECORDS
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
| GET AVAILABLE / UNMAPPED PHONE NUMBERS
|--------------------------------------------------------------------------
|
| SHOWS:
| - NO RFID
| - ONLY DRY
| - ONLY WET
|
| HIDES:
| - BOTH DRY + WET
|--------------------------------------------------------------------------
*/
const getUnmappedPhoneNumbersService =
  async () => {

    /*
    |--------------------------------------------------------------------------
    | GET ALL RFID MAPPINGS
    |--------------------------------------------------------------------------
    */
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




    /*
    |--------------------------------------------------------------------------
    | TRACK MAPPING STATUS
    |--------------------------------------------------------------------------
    */
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




      /*
      |--------------------------------------------------------------------------
      | DRY
      |--------------------------------------------------------------------------
      */
      if (

        item.wasteType
          ?.toLowerCase() ===
        "dry"

      ) {

        tracker[
          item.phoneNumber
        ].dry = true;

      }




      /*
      |--------------------------------------------------------------------------
      | WET
      |--------------------------------------------------------------------------
      */
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




    /*
    |--------------------------------------------------------------------------
    | GET ALL SURVEY CITIZENS
    |--------------------------------------------------------------------------
    */
    const citizens =
      await prisma.$queryRaw`

        SELECT DISTINCT
          "personName",
          "contactNumber"
        FROM "survey_attribute_specific"
        WHERE "contactNumber" IS NOT NULL

      `;




    /*
    |--------------------------------------------------------------------------
    | FILTER INCOMPLETE CITIZENS
    |--------------------------------------------------------------------------
    */
    const filteredCitizens =
      citizens.filter(
        (citizen) => {

          const status =
            tracker[
              citizen.contactNumber
            ];



          /*
          |--------------------------------------------------------------------------
          | NEVER MAPPED
          |--------------------------------------------------------------------------
          */
          if (!status) {

            return true;

          }




          /*
          |--------------------------------------------------------------------------
          | ONLY ONE RFID EXISTS
          |--------------------------------------------------------------------------
          */
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




          /*
          |--------------------------------------------------------------------------
          | BOTH EXIST
          |--------------------------------------------------------------------------
          */
          return false;

        }
      );




    /*
    |--------------------------------------------------------------------------
    | RESPONSE
    |--------------------------------------------------------------------------
    */
    return filteredCitizens.map(
      (citizen) => ({

        citizenName:
          citizen.personName,

        phoneNumber:
          citizen.contactNumber,

      })
    );

  };





module.exports = {

  mapPhoneNumberService,

  getPhoneMappingBySLNOService,

  getAllPhoneMappingsService,

  getMappedPhoneRecordsService,

  getUnmappedPhoneNumbersService,

};