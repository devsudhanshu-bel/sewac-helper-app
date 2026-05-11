const { surveyPrisma } = require("../config/surveyDb");



// =====================================
// GET CITIZEN BY PHONE NUMBER
// =====================================

const getCitizenByPhoneService = async (
  phoneNumber
) => {
  try {

    const citizen = await surveyPrisma.$queryRawUnsafe(`
      SELECT
        "Name of the Person",
        "Contact no of the HHs"
      FROM "survery_attribute_specific"
      WHERE "Contact no of the HHs" = '${phoneNumber}'
      LIMIT 1
    `);



    if (!citizen || citizen.length === 0) {
      return null;
    }



    return {
      citizenName:
        citizen[0]["Name of the Person"],

      phoneNumber:
        citizen[0]["Contact no of the HHs"],
    };

  } catch (error) {

    console.error(
      "SURVEY DB PHONE SEARCH ERROR:",
      error
    );

    throw error;
  }
};





// =====================================
// SEARCH CITIZEN BY NAME
// =====================================

const searchCitizenByNameService = async (
  citizenName
) => {
  try {

    const citizens = await surveyPrisma.$queryRawUnsafe(`
      SELECT
        "Name of the Person",
        "Contact no of the HHs"
      FROM "survery_attribute_specific"
      WHERE LOWER("Name of the Person")
      LIKE LOWER('%${citizenName}%')
      LIMIT 20
    `);



    return citizens.map((citizen) => ({
      citizenName:
        citizen["Name of the Person"],

      phoneNumber:
        citizen["Contact no of the HHs"],
    }));

  } catch (error) {

    console.error(
      "SURVEY DB NAME SEARCH ERROR:",
      error
    );

    throw error;
  }
};





module.exports = {
  getCitizenByPhoneService,
  searchCitizenByNameService,
};