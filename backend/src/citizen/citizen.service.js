const { PrismaClient } =
  require("@prisma/client");

const prisma =
  new PrismaClient();





/*
|--------------------------------------------------------------------------
| Get Citizen By Phone Number
|--------------------------------------------------------------------------
*/
const getCitizenByPhoneService =
  async (phoneNumber) => {

    try {

      const citizen =
        await prisma.survey.findFirst({

          where: {
            contactNumber:
              phoneNumber,
          },

        });



      // =============================
      // NOT FOUND
      // =============================

      if (!citizen) {
        return null;
      }



      // =============================
      // RESPONSE
      // =============================

      return {

        citizenName:
          citizen.personName,

        phoneNumber:
          citizen.contactNumber,

        city:
          citizen.city,

        ward:
          citizen.ward,

        area:
          citizen.area,

        wasteGeneratorTypes:
          citizen.wasteGeneratorTypes,

        houseNumber:
          citizen.houseNumber,

        floorNumber:
          citizen.floorNumber,

        householdType:
          citizen.householdType,

        numberOfPeople:
          citizen.numberOfPeople,

        buildingPhoto:
          citizen.buildingPhoto,

      };

    } catch (error) {

      console.error(
        "GET CITIZEN BY PHONE ERROR:",
        error
      );



      throw error;

    }

  };





/*
|--------------------------------------------------------------------------
| Search Citizen By Name
|--------------------------------------------------------------------------
*/
const searchCitizenByNameService =
  async (citizenName) => {

    try {

      const citizens =
        await prisma.survey.findMany({

          where: {

            personName: {

              contains:
                citizenName,

              mode:
                "insensitive",

            },

          },

          take: 20,

        });



      return citizens.map(
        (citizen) => ({

          citizenName:
            citizen.personName,

          phoneNumber:
            citizen.contactNumber,

          city:
            citizen.city,

          ward:
            citizen.ward,

          area:
            citizen.area,

        })
      );

    } catch (error) {

      console.error(
        "SEARCH CITIZEN BY NAME ERROR:",
        error
      );



      throw error;

    }

  };





/*
|--------------------------------------------------------------------------
| Get All Citizen Phone Numbers
|--------------------------------------------------------------------------
*/
const getAllCitizenPhoneNumbersService =
  async () => {

    try {

      const citizens =
        await prisma.survey.findMany({

          where: {

            contactNumber: {

              not: null,

            },

          },

          select: {

            contactNumber: true,

            personName: true,

          },

          distinct: [
            "contactNumber",
          ],

          take: 1000,

        });



      return citizens.map(
        (citizen) => ({

          citizenName:
            citizen.personName,

          phoneNumber:
            citizen.contactNumber,

        })
      );

    } catch (error) {

      console.error(
        "GET ALL PHONE NUMBERS ERROR:",
        error
      );



      throw error;

    }

  };





/*
|--------------------------------------------------------------------------
| Get All Citizen Names
|--------------------------------------------------------------------------
*/
const getAllCitizenNamesService =
  async () => {

    try {

      const citizens =
        await prisma.survey.findMany({

          where: {

            personName: {

              not: null,

            },

          },

          select: {

            personName: true,

          },

          distinct: [
            "personName",
          ],

          take: 1000,

        });



      return citizens.map(
        (citizen) => ({

          citizenName:
            citizen.personName,

        })
      );

    } catch (error) {

      console.error(
        "GET ALL CITIZEN NAMES ERROR:",
        error
      );



      throw error;

    }

  };





module.exports = {

  getCitizenByPhoneService,

  searchCitizenByNameService,

  getAllCitizenPhoneNumbersService,

  getAllCitizenNamesService,

};