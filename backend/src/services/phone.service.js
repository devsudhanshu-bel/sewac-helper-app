const { prisma } = require("../config/db");



const mapPhoneNumberService = async (slno, phoneNumber) => {

  // Check if SLNO exists
  const existingRecord = await prisma.rFIDMapping.findUnique({
    where: {
      slno,
    },
  });



  if (!existingRecord) {
    throw new Error("SLNO not found");
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



  return updatedRecord;
};





module.exports = {
  mapPhoneNumberService,
};