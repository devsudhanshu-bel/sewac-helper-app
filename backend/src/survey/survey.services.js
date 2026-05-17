const {
  PrismaClient,
} = require(
  "@prisma/client"
);

const prisma =
  new PrismaClient();





// ======================================
// CREATE SURVEY SERVICE
// ======================================

const createSurvey =
  async (data) => {

    try {

      const survey =
        await prisma.survey.create({

          data: {

            // ======================================
            // DEFAULT LOCATION
            // ======================================

            city:
              data.city ||
              "Bangalore",



            ward:
              data.ward ||
              "Ibbanuru-174",



            // ======================================
            // SURVEY DETAILS
            // ======================================

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



            // ======================================
            // CLOUDINARY IMAGE URL
            // ======================================

            buildingPhoto:
              data.buildingPhoto || null,

          },

        });



      return survey;

    } catch (error) {

      console.error(
        "CREATE SURVEY SERVICE ERROR:",
        error
      );

      throw error;

    }

  };





// ======================================
// GET ALL SURVEYS
// ======================================

const getAllSurveys =
  async () => {

    try {

      const surveys =
        await prisma.survey.findMany({

          orderBy: {

            id:
              "desc",

          },

        });



      return surveys;

    } catch (error) {

      console.error(
        "GET ALL SURVEYS SERVICE ERROR:",
        error
      );

      throw error;

    }

  };





// ======================================
// GET SURVEY BY ID
// ======================================

const getSurveyById =
  async (id) => {

    try {

      const survey =
        await prisma.survey.findUnique({

          where: {

            id,

          },

        });



      return survey;

    } catch (error) {

      console.error(
        "GET SURVEY BY ID SERVICE ERROR:",
        error
      );

      throw error;

    }

  };





// ======================================
// EXPORT SERVICES
// ======================================

module.exports = {

  createSurvey,

  getAllSurveys,

  getSurveyById,

};