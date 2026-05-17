const { prisma } =
  require("../config/db");





/*
|--------------------------------------------------------------------------
| Sync Master Citizen Data
|--------------------------------------------------------------------------
*/
const syncMasterCitizenData =
  async (phoneNumber) => {

    // =============================
    // GET RFID DATA
    // =============================

    const rfidMappings =
      await prisma.rFIDMapping.findMany({

        where: {
          phoneNumber,
        },

      });



    if (
      !rfidMappings ||
      rfidMappings.length === 0
    ) {

      return null;

    }



    // =============================
    // GET SURVEY DATA
    // EXTERNAL TABLE
    // =============================

    const surveyRows =
      await prisma.$queryRaw`

        SELECT *
        FROM "survey_attribute_specific"
        WHERE "contactNumber" = ${phoneNumber}
        LIMIT 1

      `;



    const surveyData =
      surveyRows[0];



    if (!surveyData) {

      return null;

    }



    // =============================
    // EXTRACT DRY/WET RFID
    // =============================

    let dryRFID = null;
    let wetRFID = null;

    let drySlno = null;
    let wetSlno = null;



    rfidMappings.forEach((item) => {

      // DRY
      if (
        item.wasteType ===
        "DRY"
      ) {

        dryRFID =
          item.rfid;

        drySlno =
          item.slno;

      }



      // WET
      if (
        item.wasteType ===
        "WET"
      ) {

        wetRFID =
          item.rfid;

        wetSlno =
          item.slno;

      }

    });



    // =============================
    // UPSERT MASTER DATA
    // =============================

    const master =
      await prisma.masterCitizenData.upsert({

        where: {
          phoneNumber,
        },

        update: {

          dryRFID,
          wetRFID,

          drySlno,
          wetSlno,

          city:
            surveyData.city,

          ward:
            surveyData.ward,

          area:
            surveyData.area,

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

          phoneNumber,

          dryRFID,
          wetRFID,

          drySlno,
          wetSlno,

          city:
            surveyData.city,

          ward:
            surveyData.ward,

          area:
            surveyData.area,

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
const getAllMasterData =
  async () => {

    return await prisma.masterCitizenData.findMany({

      orderBy: {
        createdAt: "desc",
      },

    });

  };





/*
|--------------------------------------------------------------------------
| Get Master By Phone
|--------------------------------------------------------------------------
*/
const getMasterByPhone =
  async (phoneNumber) => {

    return await prisma.masterCitizenData.findUnique({

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
const getMasterBySLNO =
  async (slno) => {

    return await prisma.masterCitizenData.findFirst({

      where: {

        OR: [

          {
            drySlno: slno,
          },

          {
            wetSlno: slno,
          },

        ],

      },

    });

  };





module.exports = {

  syncMasterCitizenData,

  getAllMasterData,

  getMasterByPhone,

  getMasterBySLNO,

};