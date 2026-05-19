const { PrismaClient } =
  require("@prisma/client");

const prisma =
  new PrismaClient();





/*
|--------------------------------------------------------------------------
| GET CITIZEN BY PHONE NUMBER
|--------------------------------------------------------------------------
*/
const getCitizenByPhoneService =
  async (phoneNumber) => {

    try {

      const citizens =
        await prisma.$queryRaw`

          SELECT *
          FROM "survey_attribute_specific"
          WHERE "contactNumber" = ${phoneNumber}
          LIMIT 1

        `;




      const citizen =
        citizens[0];




      /*
      |--------------------------------------------------------------------------
      | NOT FOUND
      |--------------------------------------------------------------------------
      */
      if (!citizen) {

        return null;

      }




      /*
      |--------------------------------------------------------------------------
      | RESPONSE
      |--------------------------------------------------------------------------
      */
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
| SEARCH CITIZEN BY NAME
|--------------------------------------------------------------------------
*/
const searchCitizenByNameService =
  async (citizenName) => {

    try {

      const citizens =
        await prisma.$queryRaw`

          SELECT
            "personName",
            "contactNumber",
            "city",
            "ward",
            "area"
          FROM "survey_attribute_specific"
          WHERE LOWER("personName")
          LIKE LOWER(${`%${citizenName}%`})
          LIMIT 20

        `;




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
| GET ALL CITIZEN PHONE NUMBERS
|--------------------------------------------------------------------------
|
| SHOWS:
| - Citizens with NO RFID
| - Citizens with ONLY DRY
| - Citizens with ONLY WET
|
| HIDES:
| - Citizens with BOTH DRY + WET
|--------------------------------------------------------------------------
*/
const getAllCitizenPhoneNumbersService =
  async () => {

    try {

      /*
      |--------------------------------------------------------------------------
      | GET ALL RFID MAPPINGS
      |--------------------------------------------------------------------------
      */
      const allMappings =
        await prisma.rFIDMapping.findMany({

          where: {

            phoneNumber: {
              not: null,
            },

          },

          select: {

            phoneNumber: true,

            wasteType: true,

          },

        });




      /*
      |--------------------------------------------------------------------------
      | GROUP MAPPING STATUS
      |--------------------------------------------------------------------------
      */
      const mappingStatus = {};




      allMappings.forEach((item) => {

        if (!mappingStatus[item.phoneNumber]) {

          mappingStatus[item.phoneNumber] = {

            hasDry: false,

            hasWet: false,

          };

        }




        if (
          item.wasteType === "DRY"
        ) {

          mappingStatus[
            item.phoneNumber
          ].hasDry = true;

        }




        if (
          item.wasteType === "WET"
        ) {

          mappingStatus[
            item.phoneNumber
          ].hasWet = true;

        }

      });




      /*
      |--------------------------------------------------------------------------
      | FULLY MAPPED PHONES
      |--------------------------------------------------------------------------
      */
      const fullyMappedPhones =
        Object.keys(mappingStatus)
          .filter((phone) => {

            return (

              mappingStatus[phone]
                .hasDry &&

              mappingStatus[phone]
                .hasWet

            );

          });




      /*
      |--------------------------------------------------------------------------
      | GET ALL CITIZENS
      |--------------------------------------------------------------------------
      */
      const citizens =
        await prisma.$queryRaw`

          SELECT DISTINCT
            "personName",
            "contactNumber"
          FROM "survey_attribute_specific"
          WHERE "contactNumber" IS NOT NULL
          LIMIT 1000

        `;




      /*
      |--------------------------------------------------------------------------
      | FILTER INCOMPLETE CITIZENS
      |--------------------------------------------------------------------------
      */
      const filteredCitizens =
        citizens.filter(
          (citizen) =>

            !fullyMappedPhones.includes(
              citizen.contactNumber
            )
        );




      /*
      |--------------------------------------------------------------------------
      | RESPONSE
      |--------------------------------------------------------------------------
      */
      return filteredCitizens.map(
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
| GET ALL CITIZEN NAMES
|--------------------------------------------------------------------------
|
| SHOWS:
| - Citizens with NO RFID
| - Citizens with ONLY DRY
| - Citizens with ONLY WET
|
| HIDES:
| - Citizens with BOTH DRY + WET
|--------------------------------------------------------------------------
*/
const getAllCitizenNamesService =
  async () => {

    try {

      /*
      |--------------------------------------------------------------------------
      | GET ALL RFID MAPPINGS
      |--------------------------------------------------------------------------
      */
      const allMappings =
        await prisma.rFIDMapping.findMany({

          where: {

            phoneNumber: {
              not: null,
            },

          },

          select: {

            phoneNumber: true,

            wasteType: true,

          },

        });




      /*
      |--------------------------------------------------------------------------
      | GROUP MAPPING STATUS
      |--------------------------------------------------------------------------
      */
      const mappingStatus = {};




      allMappings.forEach((item) => {

        if (!mappingStatus[item.phoneNumber]) {

          mappingStatus[item.phoneNumber] = {

            hasDry: false,

            hasWet: false,

          };

        }




        if (
          item.wasteType === "DRY"
        ) {

          mappingStatus[
            item.phoneNumber
          ].hasDry = true;

        }




        if (
          item.wasteType === "WET"
        ) {

          mappingStatus[
            item.phoneNumber
          ].hasWet = true;

        }

      });




      /*
      |--------------------------------------------------------------------------
      | FULLY MAPPED PHONES
      |--------------------------------------------------------------------------
      */
      const fullyMappedPhones =
        Object.keys(mappingStatus)
          .filter((phone) => {

            return (

              mappingStatus[phone]
                .hasDry &&

              mappingStatus[phone]
                .hasWet

            );

          });




      /*
      |--------------------------------------------------------------------------
      | GET ALL CITIZENS
      |--------------------------------------------------------------------------
      */
      const citizens =
        await prisma.$queryRaw`

          SELECT DISTINCT
            "personName",
            "contactNumber"
          FROM "survey_attribute_specific"
          WHERE "personName" IS NOT NULL
          LIMIT 1000

        `;




      /*
      |--------------------------------------------------------------------------
      | FILTER INCOMPLETE CITIZENS
      |--------------------------------------------------------------------------
      */
      const filteredCitizens =
        citizens.filter(
          (citizen) =>

            !fullyMappedPhones.includes(
              citizen.contactNumber
            )
        );




      /*
      |--------------------------------------------------------------------------
      | RESPONSE
      |--------------------------------------------------------------------------
      */
      return filteredCitizens.map(
        (citizen) => ({

          citizenName:
            citizen.personName,

          phoneNumber:
            citizen.contactNumber,

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





/*
|--------------------------------------------------------------------------
| GET UNMAPPED CITIZENS
|--------------------------------------------------------------------------
|
| SHOWS:
| - No RFID
| - Only DRY
| - Only WET
|
| HIDES:
| - BOTH DRY + WET
|--------------------------------------------------------------------------
*/
const getUnmappedCitizensService =
  async () => {

    try {

      /*
      |--------------------------------------------------------------------------
      | GET ALL RFID MAPPINGS
      |--------------------------------------------------------------------------
      */
      const allMappings =
        await prisma.rFIDMapping.findMany({

          where: {

            phoneNumber: {
              not: null,
            },

          },

          select: {

            phoneNumber: true,

            wasteType: true,

          },

        });




      /*
      |--------------------------------------------------------------------------
      | GROUP MAPPING STATUS
      |--------------------------------------------------------------------------
      */
      const mappingStatus = {};




      allMappings.forEach((item) => {

        if (!mappingStatus[item.phoneNumber]) {

          mappingStatus[item.phoneNumber] = {

            hasDry: false,

            hasWet: false,

          };

        }




        if (
          item.wasteType === "DRY"
        ) {

          mappingStatus[
            item.phoneNumber
          ].hasDry = true;

        }




        if (
          item.wasteType === "WET"
        ) {

          mappingStatus[
            item.phoneNumber
          ].hasWet = true;

        }

      });




      /*
      |--------------------------------------------------------------------------
      | FULLY MAPPED PHONES
      |--------------------------------------------------------------------------
      */
      const fullyMappedPhones =
        Object.keys(mappingStatus)
          .filter((phone) => {

            return (

              mappingStatus[phone]
                .hasDry &&

              mappingStatus[phone]
                .hasWet

            );

          });




      /*
      |--------------------------------------------------------------------------
      | GET ALL CITIZENS
      |--------------------------------------------------------------------------
      */
      const citizens =
        await prisma.$queryRaw`

          SELECT DISTINCT
            "personName",
            "contactNumber"
          FROM "survey_attribute_specific"
          WHERE "contactNumber" IS NOT NULL

        `;




      /*
      |--------------------------------------------------------------------------
      | FILTER INCOMPLETE CITIZENS
      |--------------------------------------------------------------------------
      */
      const unmappedCitizens =
        citizens.filter(
          (citizen) =>

            !fullyMappedPhones.includes(
              citizen.contactNumber
            )
        );




      /*
      |--------------------------------------------------------------------------
      | RESPONSE
      |--------------------------------------------------------------------------
      */
      return unmappedCitizens.map(
        (citizen) => ({

          citizenName:
            citizen.personName,

          phoneNumber:
            citizen.contactNumber,

        })
      );

    } catch (error) {

      console.error(
        "GET UNMAPPED CITIZENS ERROR:",
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

  getUnmappedCitizensService,

};