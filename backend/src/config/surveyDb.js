const { PrismaClient } = require("@prisma/client");



// =====================================
// SURVEY DATABASE CONNECTION
// =====================================

const surveyPrisma = new PrismaClient({
  datasources: {
    db: {
      url: process.env.SURVEY_DATABASE_URL,
    },
  },
});



// =====================================
// CONNECT SURVEY DATABASE
// =====================================

const connectSurveyDB = async () => {
  try {

    await surveyPrisma.$connect();

    console.log("=================================");
    console.log(" Survey Database Connected");
    console.log("=================================");

  } catch (error) {

    console.error("=================================");
    console.error(" SURVEY DATABASE CONNECTION FAILED");
    console.error(error.message);
    console.error("=================================");

    process.exit(1);
  }
};





module.exports = {
  surveyPrisma,
  connectSurveyDB,
};