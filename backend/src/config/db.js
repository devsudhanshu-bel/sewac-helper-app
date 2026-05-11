const { PrismaClient } = require("@prisma/client");

const prisma = new PrismaClient({
  log: ["query", "info", "warn", "error"],
});

const connectDB = async () => {
  try {
    await prisma.$connect();

    console.log("=================================");
    console.log(" PostgreSQL Connected Successfully");
    console.log("=================================");
  } catch (error) {
    console.error("=================================");
    console.error(" Database Connection Failed");
    console.error(error.message);
    console.error("=================================");

    process.exit(1);
  }
};

module.exports = {
  prisma,
  connectDB,
};