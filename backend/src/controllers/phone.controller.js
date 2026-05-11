const { prisma } = require("../config/db");

const mapPhoneNumber = async (req, res) => {
  try {

    const { slno, phoneNumber } = req.body;

    // Validation
    if (!slno || !phoneNumber) {
      return res.status(400).json({
        success: false,
        message: "SLNO and phone number are required",
      });
    }

    // Check if SLNO exists
    const existingRecord = await prisma.rFIDMapping.findUnique({
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

    // Update phone number
    const updatedRecord = await prisma.rFIDMapping.update({
      where: {
        slno,
      },
      data: {
        phoneNumber,
      },
    });

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
    });
  }
};

module.exports = {
  mapPhoneNumber,
};