const { PrismaClient } =
  require("@prisma/client");

const prisma =
  new PrismaClient();



// =====================================
// GET CITIZEN BY PHONE NUMBER
// =====================================

const getCitizenByPhoneService =
  async (phoneNumber) => {

    try {

      const citizen =
        await prisma.survey.findFirst({

          where: {
            contactNumber: phoneNumber,
          },

        });



      if (!citizen) {
        return null;
      }



      return {

        citizenName:
          citizen.personName,

        phoneNumber:
          citizen.contactNumber,

      };

    } catch (error) {

      console.error(
        "GET CITIZEN BY PHONE ERROR:",
        error
      );

      throw error;

    }

};



// =====================================
// SEARCH CITIZEN BY NAME
// =====================================

const searchCitizenByNameService =
  async (citizenName) => {

    try {

      const citizens =
        await prisma.survey.findMany({

          where: {

            personName: {

              contains: citizenName,

              mode: "insensitive",

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




module.exports = {

  getCitizenByPhoneService,

  searchCitizenByNameService,

};