const { prisma } = require("../config/db");

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

    // Check if RFID already exists
    const existingRFID = await prisma.rFIDMapping.findUnique({
      where: {
        rfid: value,
      },
    });

    if (existingRFID) {
      return res.status(409).json({
        success: false,
        message: "RFID already mapped",
        data: existingRFID,
      });
    }

    // Get latest entry
    const latestRecord = await prisma.rFIDMapping.findFirst({
      orderBy: {
        id: "desc",
      },
    });

    let nextNumber = 1;

    if (latestRecord) {
      const currentNumber = parseInt(
        latestRecord.slno.replace("SEWAC", "")
      );

      nextNumber = currentNumber + 1;
    }

    // Generate SLNO
    const slno = String(nextNumber).padStart(8, "0");;

    // Create new RFID entry
    const newRFID = await prisma.rFIDMapping.create({
      data: {
        slno,
        rfid: value,
        phoneNumber: null,
      },
    });

    return res.status(201).json({
      success: true,
      message: "RFID mapped successfully",
      data: newRFID,
    });

  } catch (error) {
    console.error("RFID CREATE ERROR:", error);

    return res.status(500).json({
      success: false,
      message: "Internal Server Error",
      error: error.message,
    });
  }
};




const mapPhoneNumber = async (req, res) => {
  try {
    const { rfid, phoneNumber } = req.body;

    // Validate
    if (!rfid || !phoneNumber) {
      return res.status(400).json({
        success: false,
        message: "RFID and phone number are required",
      });
    }

    // Check RFID existence
    const existingRFID = await prisma.rFIDMapping.findUnique({
      where: {
        rfid,
      },
    });

    if (!existingRFID) {
      return res.status(404).json({
        success: false,
        message: "RFID not found",
      });
    }

    // Update phone number
    const updatedRFID = await prisma.rFIDMapping.update({
      where: {
        rfid,
      },
      data: {
        phoneNumber,
      },
    });

    return res.status(200).json({
      success: true,
      message: "Phone number mapped successfully",
      data: updatedRFID,
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




const getAllRFIDMappings = async (req, res) => {
  try {
    const allMappings = await prisma.rFIDMapping.findMany({
      orderBy: {
        createdAt: "desc",
      },
    });

    return res.status(200).json({
      success: true,
      count: allMappings.length,
      data: allMappings,
    });

  } catch (error) {
    console.error("GET RFID ERROR:", error);

    return res.status(500).json({
      success: false,
      message: "Internal Server Error",
      error: error.message,
    });
  }
};




module.exports = {
  createRFID,
  mapPhoneNumber,
  getAllRFIDMappings,
};