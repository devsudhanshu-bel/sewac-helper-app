const { prisma } =
  require("../config/db");

const {
  syncMasterCitizenData,
} = require("../master/master.service");





/*
|--------------------------------------------------------------------------
| MAP PHONE NUMBER TO RFID
|--------------------------------------------------------------------------
| PATCH /api/v1/phone/map
|--------------------------------------------------------------------------
|
| SUPPORTS:
|
| CASE 1:
| ONLY DRY RFID
|
| CASE 2:
| ONLY WET RFID
|
| CASE 3:
| BOTH RFIDS
|
| CASE 4:
| LATER SECOND RFID
|
|--------------------------------------------------------------------------
*/
const mapPhoneNumber =
  async (req, res) => {

    try {

      const {

        slno,

        phoneNumber,

      } = req.body;




      /*
      |--------------------------------------------------------------------------
      | VALIDATION
      |--------------------------------------------------------------------------
      */
      if (

        !slno ||

        !phoneNumber

      ) {

        return res.status(400).json({

          success: false,

          message:
            "SLNO and phone number are required",

        });

      }




      /*
      |--------------------------------------------------------------------------
      | CHECK RFID EXISTS
      |--------------------------------------------------------------------------
      */
      const existingRecord =
        await prisma.rFIDMapping.findUnique({

          where: {
            slno,
          },

        });




      if (!existingRecord) {

        return res.status(404).json({

          success: false,

          message:
            "SLNO not found",

        });

      }




      /*
      |--------------------------------------------------------------------------
      | RFID ALREADY USED BY ANOTHER PHONE
      |--------------------------------------------------------------------------
      */
      if (

        existingRecord.phoneNumber &&

        existingRecord.phoneNumber !==
        phoneNumber

      ) {

        return res.status(409).json({

          success: false,

          message:
            "This RFID is already mapped",

          data:
            existingRecord,

        });

      }




      /*
      |--------------------------------------------------------------------------
      | GET EXISTING PHONE MAPPINGS
      |--------------------------------------------------------------------------
      */
      const existingMappings =
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





      existingMappings.forEach(
        (item) => {

          /*
          |--------------------------------------------------------------------------
          | DRY
          |--------------------------------------------------------------------------
          */
          if (
            item.wasteType ===
            "DRY"
          ) {

            hasDry = true;

          }




          /*
          |--------------------------------------------------------------------------
          | WET
          |--------------------------------------------------------------------------
          */
          if (
            item.wasteType ===
            "WET"
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

        existingRecord.wasteType ===
          "DRY" &&

        hasDry

      ) {

        return res.status(409).json({

          success: false,

          message:
            "Phone number already mapped to a Dry RFID",

        });

      }




      /*
      |--------------------------------------------------------------------------
      | BLOCK DUPLICATE WET
      |--------------------------------------------------------------------------
      */
      if (

        existingRecord.wasteType ===
          "WET" &&

        hasWet

      ) {

        return res.status(409).json({

          success: false,

          message:
            "Phone number already mapped to a Wet RFID",

        });

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
      | AUTO MASTER TABLE SYNC
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
      | GET CURRENT RFID STATUS
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
          | DRY RFID
          |--------------------------------------------------------------------------
          */
          if (
            item.wasteType ===
            "DRY"
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
          | WET RFID
          |--------------------------------------------------------------------------
          */
          if (
            item.wasteType ===
            "WET"
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
      | SUCCESS RESPONSE
      |--------------------------------------------------------------------------
      */
      return res.status(200).json({

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

      });

    } catch (error) {

      console.error(
        "PHONE MAP ERROR:",
        error
      );




      return res.status(500).json({

        success: false,

        message:
          "Internal Server Error",

        error:
          error.message,

      });

    }

  };





/*
|--------------------------------------------------------------------------
| GET PHONE MAPPING BY SLNO
|--------------------------------------------------------------------------
| GET /api/v1/phone/:slno
|--------------------------------------------------------------------------
*/
const getPhoneMappingBySLNO =
  async (req, res) => {

    try {

      const { slno } =
        req.params;




      /*
      |--------------------------------------------------------------------------
      | VALIDATION
      |--------------------------------------------------------------------------
      */
      if (!slno) {

        return res.status(400).json({

          success: false,

          message:
            "SLNO is required",

        });

      }




      /*
      |--------------------------------------------------------------------------
      | GET RECORD
      |--------------------------------------------------------------------------
      */
      const record =
        await prisma.rFIDMapping.findUnique({

          where: {
            slno,
          },

        });




      /*
      |--------------------------------------------------------------------------
      | NOT FOUND
      |--------------------------------------------------------------------------
      */
      if (!record) {

        return res.status(404).json({

          success: false,

          message:
            "Record not found",

        });

      }




      /*
      |--------------------------------------------------------------------------
      | SUCCESS
      |--------------------------------------------------------------------------
      */
      return res.status(200).json({

        success: true,

        data:
          record,

      });

    } catch (error) {

      console.error(
        "GET PHONE MAPPING ERROR:",
        error
      );




      return res.status(500).json({

        success: false,

        message:
          "Internal Server Error",

        error:
          error.message,

      });

    }

  };





/*
|--------------------------------------------------------------------------
| GET ALL PHONE MAPPINGS
|--------------------------------------------------------------------------
| GET /api/v1/phone/all
|--------------------------------------------------------------------------
*/
const getAllPhoneMappings =
  async (req, res) => {

    try {

      const records =
        await prisma.rFIDMapping.findMany({

          orderBy: {
            createdAt: "desc",
          },

        });




      return res.status(200).json({

        success: true,

        count:
          records.length,

        data:
          records,

      });

    } catch (error) {

      console.error(
        "GET ALL PHONE MAPPINGS ERROR:",
        error
      );




      return res.status(500).json({

        success: false,

        message:
          "Internal Server Error",

        error:
          error.message,

      });

    }

  };





/*
|--------------------------------------------------------------------------
| GET UNMAPPED PHONE NUMBERS
|--------------------------------------------------------------------------
| GET /api/v1/phone/unmapped
|--------------------------------------------------------------------------
|
| SHOWS:
| - NO RFID
| - ONLY DRY RFID
| - ONLY WET RFID
|
| HIDES:
| - BOTH DRY + WET RFIDs
|--------------------------------------------------------------------------
*/
const getUnmappedPhoneNumbers =
  async (req, res) => {

    try {

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
          item.wasteType ===
          "DRY"
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
          item.wasteType ===
          "WET"
        ) {

          tracker[
            item.phoneNumber
          ].wet = true;

        }

      });




      /*
      |--------------------------------------------------------------------------
      | GET SURVEY DATA
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
      | FILTER CITIZENS
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
      | FORMAT RESPONSE
      |--------------------------------------------------------------------------
      */
      const formattedData =
        filteredCitizens.map(
          (citizen) => ({

            citizenName:
              citizen.personName,

            phoneNumber:
              citizen.contactNumber,

          })
        );




      /*
      |--------------------------------------------------------------------------
      | SUCCESS RESPONSE
      |--------------------------------------------------------------------------
      */
      return res.status(200).json({

        success: true,

        count:
          formattedData.length,

        data:
          formattedData,

      });

    } catch (error) {

      console.error(
        "GET UNMAPPED PHONE NUMBERS ERROR:",
        error
      );




      return res.status(500).json({

        success: false,

        message:
          "Internal Server Error",

        error:
          error.message,

      });

    }

  };





module.exports = {

  mapPhoneNumber,

  getPhoneMappingBySLNO,

  getAllPhoneMappings,

  getUnmappedPhoneNumbers,

};