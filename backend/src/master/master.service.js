const { prisma } = require("../config/db");





/*
|--------------------------------------------------------------------------
| Sync Master Citizen Data
|--------------------------------------------------------------------------
*/
const syncMasterCitizenData = async (phoneNumber) => {

  // RFID DATA
  const rfidData =
    await prisma.rFIDMapping.findFirst({
      where: {
        phoneNumber,
      },
    });

  if (!rfidData) {
    return null;
  }

  // SURVEY DATA
  const surveyData =
    await prisma.survey.findFirst({
      where: {
        contactNumber: phoneNumber,
      },
    });

  if (!surveyData) {
    return null;
  }

  // UPSERT MASTER TABLE
  const master =
    await prisma.masterCitizenData.upsert({

      where: {
        slno: rfidData.slno,
      },

      update: {

        rfid: rfidData.rfid,

        phoneNumber:
          rfidData.phoneNumber,

        city: surveyData.city,
        ward: surveyData.ward,
        area: surveyData.area,

        wasteGeneratorTypes:
          surveyData.wasteGeneratorTypes,

        houseNumber:
          surveyData.houseNumber,

        floorNumber:
          surveyData.floorNumber,

        householdType:
          surveyData.householdType,

        personName:
          surveyData.personName,

        contactNumber:
          surveyData.contactNumber,

        numberOfPeople:
          surveyData.numberOfPeople,

        buildingPhoto:
          surveyData.buildingPhoto,
      },

      create: {

        slno: rfidData.slno,

        rfid: rfidData.rfid,

        phoneNumber:
          rfidData.phoneNumber,

        city: surveyData.city,
        ward: surveyData.ward,
        area: surveyData.area,

        wasteGeneratorTypes:
          surveyData.wasteGeneratorTypes,

        houseNumber:
          surveyData.houseNumber,

        floorNumber:
          surveyData.floorNumber,

        householdType:
          surveyData.householdType,

        personName:
          surveyData.personName,

        contactNumber:
          surveyData.contactNumber,

        numberOfPeople:
          surveyData.numberOfPeople,

        buildingPhoto:
          surveyData.buildingPhoto,
      },
    });

  return master;
};





/*
|--------------------------------------------------------------------------
| Get All Master Data
|--------------------------------------------------------------------------
*/
const getAllMasterData = async () => {

  return await prisma.masterCitizenData.findMany({
    orderBy: {
      createdAt: "desc",
    },
  });
};





/*
|--------------------------------------------------------------------------
| Get Master By Phone Number
|--------------------------------------------------------------------------
*/
const getMasterByPhone = async (phoneNumber) => {

  return await prisma.masterCitizenData.findFirst({
    where: {
      phoneNumber,
    },
  });
};





/*
|--------------------------------------------------------------------------
| Get Master By SLNO
|--------------------------------------------------------------------------
*/
const getMasterBySLNO = async (slno) => {

  return await prisma.masterCitizenData.findFirst({
    where: {
      slno,
    },
  });
};





module.exports = {
  syncMasterCitizenData,
  getAllMasterData,
  getMasterByPhone,
  getMasterBySLNO,
};