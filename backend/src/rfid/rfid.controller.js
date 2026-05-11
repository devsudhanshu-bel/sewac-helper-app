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
*/
const createRFID = async (req, res) => {
  try {

    const { value } = req.params;

    // Validate RFID
    if (!value || value.trim() === "") {
      return res.status(400).json({
        success: false,
        message: "RFID value is required",
      });
    }



    const newRFID = await createRFIDService(value);



    return res.status(201).json({
      success: true,
      message: "RFID created successfully",
      data: newRFID,
    });

  } catch (error) {

    console.error("RFID CREATE ERROR:", error);

    return res.status(500).json({
      success: false,
      message: error.message || "Internal Server Error",
    });
  }
};





/*
|--------------------------------------------------------------------------
| Map RFID To Phone Number
|--------------------------------------------------------------------------
*/
const mapRFIDToPhone = async (req, res) => {
  try {

    const { rfid, phoneNumber } = req.body;

    // Validate
    if (!rfid || !phoneNumber) {
      return res.status(400).json({
        success: false,
        message: "RFID and phone number are required",
      });
    }



    const updatedRFID = await mapRFIDToPhoneService(
      rfid,
      phoneNumber
    );



    return res.status(200).json({
      success: true,
      message: "RFID mapped successfully",
      data: updatedRFID,
    });

  } catch (error) {

    console.error("RFID MAP ERROR:", error);

    return res.status(500).json({
      success: false,
      message: error.message || "Internal Server Error",
    });
  }
};





/*
|--------------------------------------------------------------------------
| Get All RFID Mappings
|--------------------------------------------------------------------------
*/
const getAllRFIDMappings = async (req, res) => {
  try {

    const allMappings =
      await getAllRFIDMappingsService();



    return res.status(200).json({
      success: true,
      count: allMappings.length,
      data: allMappings,
    });

  } catch (error) {

    console.error("GET RFID ERROR:", error);

    return res.status(500).json({
      success: false,
      message: error.message || "Internal Server Error",
    });
  }
};





/*
|--------------------------------------------------------------------------
| Get Only Unmapped RFIDs
|--------------------------------------------------------------------------
*/
const getUnmappedRFIDs = async (req, res) => {
  try {

    const unmappedRFIDs =
      await getUnmappedRFIDsService();



    return res.status(200).json({
      success: true,
      count: unmappedRFIDs.length,
      data: unmappedRFIDs,
    });

  } catch (error) {

    console.error("GET UNMAPPED RFID ERROR:", error);

    return res.status(500).json({
      success: false,
      message: error.message || "Internal Server Error",
    });
  }
};





/*
|--------------------------------------------------------------------------
| Get RFID By RFID Value
|--------------------------------------------------------------------------
*/
const getRFIDByValue = async (req, res) => {
  try {

    const { rfid } = req.params;

    if (!rfid) {
      return res.status(400).json({
        success: false,
        message: "RFID is required",
      });
    }



    const rfidData =
      await getRFIDByValueService(rfid);



    if (!rfidData) {
      return res.status(404).json({
        success: false,
        message: "RFID not found",
      });
    }



    return res.status(200).json({
      success: true,
      data: rfidData,
    });

  } catch (error) {

    console.error("GET RFID BY VALUE ERROR:", error);

    return res.status(500).json({
      success: false,
      message: error.message || "Internal Server Error",
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