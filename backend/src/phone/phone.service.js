const { prisma } = require("../config/db");





/*
|--------------------------------------------------------------------------
| Map Phone Number To RFID
|--------------------------------------------------------------------------
*/
const mapPhoneNumberService = async (slno, phoneNumber) => {

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
    throw new Error("SLNO not found");
  }



  // =============================
  // CHECK IF ALREADY MAPPED
  // =============================

  if (existingRecord.phoneNumber) {
    throw new Error(
      "Phone number already mapped to this RFID"
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
const getPhoneMappingBySLNOService = async (slno) => {

  const record =
    await prisma.rFIDMapping.findUnique({
      where: {
        slno,
      },
    });



  if (!record) {
    throw new Error("Record not found");
  }



  return record;
};





/*
|--------------------------------------------------------------------------
| Get All Phone Mappings
|--------------------------------------------------------------------------
*/
const getAllPhoneMappingsService = async () => {

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
const getMappedPhoneRecordsService = async () => {

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





module.exports = {
  mapPhoneNumberService,
  getPhoneMappingBySLNOService,
  getAllPhoneMappingsService,
  getMappedPhoneRecordsService,
};