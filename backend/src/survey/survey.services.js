const { PrismaClient } =
  require("@prisma/client");

const prisma =
  new PrismaClient();



// ======================================
// CREATE SURVEY
// ======================================

const createSurvey =
  async (data) => {

    return prisma.survey.create({

      data: {

        city:
          "Bangalore",

        ward:
          "Ibbanuru-174",

        area:
          data.area || null,

        wasteGeneratorTypes:
          data.wasteGeneratorTypes || null,

        houseNumber:
          data.houseNumber || null,

        floorNumber:
          data.floorNumber || null,

        householdType:
          data.householdType || null,

        personName:
          data.personName || null,

        contactNumber:
          data.contactNumber || null,

        numberOfPeople:
          data.numberOfPeople || null,

        buildingPhoto:
          data.buildingPhoto || null,

      },

      select: {

        id: true,

        personName: true,

        contactNumber: true,

        createdAt: true,

      },

    });

};



// ======================================
// FIND SURVEY BY PHONE NUMBER
// ======================================

const findByPhone =
  async (contactNumber) => {

    return prisma.survey.findFirst({

      where: {

        contactNumber,

      },

      select: {

        id: true,

      },

    });

};



// ======================================
// GET ALL SURVEYS
// ======================================

const getAllSurveys =
  async () => {

    return prisma.survey.findMany({

      orderBy: {

        createdAt: "desc",

      },

    });

};



// ======================================
// GET SURVEY BY ID
// ======================================

const getSurveyById =
  async (id) => {

    return prisma.survey.findUnique({

      where: {

        id,

      },

    });

};



// ======================================
// DELETE SURVEY
// ======================================

const deleteSurvey =
  async (id) => {

    return prisma.survey.delete({

      where: {

        id,

      },

    });

};



// ======================================
// TOTAL SURVEY COUNT
// ======================================

const getSurveyCount =
  async () => {

    return prisma.survey.count();

};





module.exports = {

  createSurvey,

  findByPhone,

  getAllSurveys,

  getSurveyById,

  deleteSurvey,

  getSurveyCount,

};