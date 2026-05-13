const { prisma } = require("../config/db");

const {
  createRFIDService,
  getAllRFIDMappingsService,
  getUnmappedRFIDsService,
  mapRFIDToPhoneService,
  getRFIDByValueService,
} = require("./rfid.service");





/*
|--------------------------------------------------------------------------
| Create RFID
|--------------------------------------------------------------------------
| POST /api/v1/rfid/rfid/:value
|--------------------------------------------------------------------------
*/
const createRFID = async (req, res) => {
  try {

    const { value } = req.params;

    // VALIDATE RFID
    if (!value || value.trim() === "") {
      return res.status(400).json({
        success: false,
        message: "RFID value is required",
      });
    }

    /*
    |--------------------------------------------------------------------------
    | GET LAST SLNO
    |--------------------------------------------------------------------------
    */
    const lastRFID =
      await prisma.rFIDMapping.findFirst({

        orderBy: {
          slno: "desc",
        },

      });




    /*
    |--------------------------------------------------------------------------
    | GENERATE NEXT SLNO
    |--------------------------------------------------------------------------
    */
    let nextSLNO = "00000001";

    if (lastRFID && lastRFID.slno) {

      const currentNumber =
        parseInt(lastRFID.slno);

      const nextNumber =
        currentNumber + 1;

      nextSLNO =
        String(nextNumber).padStart(8, "0");
    }




    /*
    |--------------------------------------------------------------------------
    | CREATE RFID
    |--------------------------------------------------------------------------
    */
    const newRFID =
      await createRFIDService(
        nextSLNO,
        value
      );



    return res.status(201).json({
      success: true,
      message: "RFID created successfully",
      data: newRFID,
    });

  } catch (error) {

    console.error(
      "RFID CREATE ERROR:",
      error
    );

    return res.status(500).json({
      success: false,
      message:
        error.message ||
        "Internal Server Error",
    });
  }
};



/*
|--------------------------------------------------------------------------
| Map RFID SLNO To Phone Number
|--------------------------------------------------------------------------
| POST /api/v1/rfid/map
|--------------------------------------------------------------------------
*/
const mapRFIDToPhone = async (req, res) => {
  try {

    const {
      slno,
      phoneNumber,
    } = req.body;

    // VALIDATE
    if (!slno || !phoneNumber) {
      return res.status(400).json({
        success: false,
        message:
          "SLNO and phone number are required",
      });
    }



    const updatedRFID =
      await mapRFIDToPhoneService(
        slno,
        phoneNumber
      );



    return res.status(200).json({
      success: true,
      message:
        "RFID mapped successfully",
      data: updatedRFID,
    });

  } catch (error) {

    console.error(
      "RFID MAP ERROR:",
      error
    );

    return res.status(500).json({
      success: false,
      message:
        error.message ||
        "Internal Server Error",
    });
  }
};





/*
|--------------------------------------------------------------------------
| Get All RFID Mappings
|--------------------------------------------------------------------------
| GET /api/v1/rfid/rfid
|--------------------------------------------------------------------------
*/
const getAllRFIDMappings = async (
  req,
  res
) => {
  try {

    const allMappings =
      await getAllRFIDMappingsService();



    return res.status(200).json({
      success: true,
      count: allMappings.length,
      data: allMappings,
    });

  } catch (error) {

    console.error(
      "GET RFID ERROR:",
      error
    );

    return res.status(500).json({
      success: false,
      message:
        error.message ||
        "Internal Server Error",
    });
  }
};





/*
|--------------------------------------------------------------------------
| Get Only Unmapped RFIDs
|--------------------------------------------------------------------------
| GET /api/v1/rfid/unmapped
|--------------------------------------------------------------------------
*/
const getUnmappedRFIDs = async (
  req,
  res
) => {
  try {

    const unmappedRFIDs =
      await getUnmappedRFIDsService();



    return res.status(200).json({
      success: true,
      count:
        unmappedRFIDs.length,
      data: unmappedRFIDs,
    });

  } catch (error) {

    console.error(
      "GET UNMAPPED RFID ERROR:",
      error
    );

    return res.status(500).json({
      success: false,
      message:
        error.message ||
        "Internal Server Error",
    });
  }
};





/*
|--------------------------------------------------------------------------
| Get RFID Details By RFID Value
|--------------------------------------------------------------------------
| GET /api/v1/rfid/:rfid
|--------------------------------------------------------------------------
*/
const getRFIDByValue = async (
  req,
  res
) => {
  try {

    const { rfid } =
      req.params;

    if (!rfid) {
      return res.status(400).json({
        success: false,
        message:
          "RFID is required",
      });
    }



    const rfidData =
      await getRFIDByValueService(
        rfid
      );



    return res.status(200).json({
      success: true,
      data: rfidData,
    });

  } catch (error) {

    console.error(
      "GET RFID BY VALUE ERROR:",
      error
    );

    return res.status(500).json({
      success: false,
      message:
        error.message ||
        "Internal Server Error",
    });
  }
};





module.exports = {
  createRFID,
  mapRFIDToPhone,
  getAllRFIDMappings,
  getUnmappedRFIDs,
  getRFIDByValue,
};