const { PrismaClient } =
  require("@prisma/client");

const prisma =
  new PrismaClient();



// ======================================
// CREATE SURVEY
// ======================================
const createSurvey =
  async (data) => {

    const survey =
      await prisma.survey.create({

        data: {

          city: "Bangalore",

          ward: "Ibbanuru-174",

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

      });

    return survey;

};



// ======================================
// GET ALL SURVEYS
// ======================================
const getAllSurveys =
  async () => {

    const surveys =
      await prisma.survey.findMany({

        orderBy: {

          id: "desc",

        },

      });

    return surveys;

};



// ======================================
// GET SURVEY BY ID
// ======================================
const getSurveyById =
  async (id) => {

    const survey =
      await prisma.survey.findUnique({

        where: {

          id,

        },

      });

    return survey;

};



module.exports = {

  createSurvey,

  getAllSurveys,

  getSurveyById,

};