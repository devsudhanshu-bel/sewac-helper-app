const { prisma } = require("../config/db");





/*
|--------------------------------------------------------------------------
| Map Phone Number To RFID
|--------------------------------------------------------------------------
| POST /api/v1/phone/map
|--------------------------------------------------------------------------
*/
const mapPhoneNumber = async (req, res) => {
  try {

    const { slno, phoneNumber } = req.body;



    // =============================
    // VALIDATION
    // =============================

    if (!slno || !phoneNumber) {

      return res.status(400).json({
        success: false,
        message: "SLNO and phone number are required",
      });

    }



    // =============================
    // CHECK RFID RECORD EXISTS
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
        message: "SLNO not found",
      });

    }



    // =============================
    // CHECK IF ALREADY MAPPED
    // =============================

    if (existingRecord.phoneNumber) {

      return res.status(409).json({
        success: false,
        message: "Phone number already mapped to this RFID",
        data: existingRecord,
      });

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



    // =============================
    // SUCCESS RESPONSE
    // =============================

    return res.status(200).json({
      success: true,
      message: "Phone number mapped successfully",
      data: updatedRecord,
    });

  } catch (error) {

    console.error("PHONE MAP ERROR:", error);



    return res.status(500).json({
      success: false,
      message: "Internal Server Error",
      error: error.message,
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
const getPhoneMappingBySLNO = async (req, res) => {
  try {

    const { slno } = req.params;



    if (!slno) {

      return res.status(400).json({
        success: false,
        message: "SLNO is required",
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
        message: "Record not found",
      });

    }



    return res.status(200).json({
      success: true,
      data: record,
    });

  } catch (error) {

    console.error("GET PHONE MAPPING ERROR:", error);



    return res.status(500).json({
      success: false,
      message: "Internal Server Error",
      error: error.message,
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
const getAllPhoneMappings = async (req, res) => {
  try {

    const records =
      await prisma.rFIDMapping.findMany({
        orderBy: {
          createdAt: "desc",
        },
      });



    return res.status(200).json({
      success: true,
      count: records.length,
      data: records,
    });

  } catch (error) {

    console.error("GET ALL PHONE MAPPINGS ERROR:", error);



    return res.status(500).json({
      success: false,
      message: "Internal Server Error",
      error: error.message,
    });

  }
};





module.exports = {
  mapPhoneNumber,
  getPhoneMappingBySLNO,
  getAllPhoneMappings,
};