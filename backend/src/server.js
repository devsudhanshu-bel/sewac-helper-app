require("dotenv").config();

const app = require("./app");

const { connectDB } = require("./config/db");



const PORT = process.env.PORT || 5000;



// =============================
// START SERVER
// =============================

const startServer = async () => {
  try {

    // Connect Database
    await connectDB();



    // Start Express Server
    app.listen(PORT, () => {
      console.log("=================================");
      console.log(` SEWAC Helper Backend Running`);
      console.log(` Server Port : ${PORT}`);
      console.log("=================================");
    });

  } catch (error) {

    console.error("=================================");
    console.error(" SERVER START FAILED");
    console.error(error.message);
    console.error("=================================");

    process.exit(1);
  }
};



startServer();