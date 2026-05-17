const { prisma } = require("../config/db");





/*
|--------------------------------------------------------------------------
| Map Phone Number To RFID
|--------------------------------------------------------------------------
| PATCH /api/v1/phone/map
|--------------------------------------------------------------------------
*/
const mapPhoneNumber = async (
  req,
  res
) => {

  try {

    const {
      slno,
      phoneNumber,
    } = req.body;



    // =============================
    // VALIDATION
    // =============================

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



    // =============================
    // CHECK RFID EXISTS
    // =============================

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



    // =============================
    // CHECK RFID ALREADY MAPPED
    // =============================

    if (
      existingRecord.phoneNumber
    ) {

      return res.status(409).json({

        success: false,

        message:
          "This RFID is already mapped",

        data:
          existingRecord,

      });

    }



    // =============================
    // GET EXISTING PHONE MAPPINGS
    // =============================

    const existingMappings =
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



    existingMappings.forEach(
      (item) => {

        if (
          item.wasteType === "DRY"
        ) {
          hasDry = true;
        }



        if (
          item.wasteType === "WET"
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

      return res.status(409).json({

        success: false,

        message:
          "Phone number already mapped for both Dry and Wet waste",

      });

    }



    // =============================
    // BLOCK DUPLICATE DRY
    // =============================

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



    // =============================
    // BLOCK DUPLICATE WET
    // =============================

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



    // =============================
    // UPDATE RFID
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



    // =============================
    // SUCCESS RESPONSE
    // =============================

    return res.status(200).json({

      success: true,

      message:
        "Phone number mapped successfully",

      data:
        updatedRecord,

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
| Get Phone Mapping By SLNO
|--------------------------------------------------------------------------
| GET /api/v1/phone/:slno
|--------------------------------------------------------------------------
*/
const getPhoneMappingBySLNO =
  async (req, res) => {

    try {

      const { slno } =
        req.params;



      if (!slno) {

        return res.status(400).json({

          success: false,

          message:
            "SLNO is required",

        });

      }



      const record =
        await prisma.rFIDMapping.findUnique({

          where: {
            slno,
          },

        });



      if (!record) {

        return res.status(404).json({

          success: false,

          message:
            "Record not found",

        });

      }



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
| Get All Phone Mappings
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
| Get Unmapped Phone Numbers
|--------------------------------------------------------------------------
| GET /api/v1/phone/unmapped
|--------------------------------------------------------------------------
*/
const getUnmappedPhoneNumbers =
  async (req, res) => {

    try {

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
          item.wasteType ===
          "DRY"
        ) {

          tracker[
            item.phoneNumber
          ].dry = true;

        }



        // WET
        if (
          item.wasteType ===
          "WET"
        ) {

          tracker[
            item.phoneNumber
          ].wet = true;

        }

      });



      // =============================
      // GET SURVEY DATA
      // EXTERNAL TABLE USING RAW SQL
      // =============================

      const citizens =
        await prisma.$queryRaw`

          SELECT DISTINCT
            "personName",
            "contactNumber"
          FROM "survey_attribute_specific"
          WHERE "contactNumber" IS NOT NULL

        `;



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



      // =============================
      // SUCCESS RESPONSE
      // =============================

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