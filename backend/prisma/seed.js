const { PrismaClient } = require("@prisma/client");
const bcrypt = require("bcryptjs");

const prisma = new PrismaClient();

const seedModerators = async () => {
  try {

    console.log("=================================");
    console.log(" Seeding Moderators...");
    console.log("=================================");

    const hashedPassword = await bcrypt.hash(
      "sewac@2026",
      10
    );



    const moderators = [];



    for (let i = 1; i <= 15; i++) {

      const username = `sewac${String(i).padStart(2, "0")}`;

      moderators.push({
        username,
        password: hashedPassword,
        role: "MODERATOR",
      });
    }



    for (const moderator of moderators) {

      const existingModerator =
        await prisma.moderator.findUnique({
          where: {
            username: moderator.username,
          },
        });



      if (!existingModerator) {

        await prisma.moderator.create({
          data: moderator,
        });

        console.log(
          `Created Moderator : ${moderator.username}`
        );

      } else {

        console.log(
          `Already Exists : ${moderator.username}`
        );
      }
    }



    console.log("=================================");
    console.log(" Moderator Seeding Completed");
    console.log("=================================");

  } catch (error) {

    console.error("SEED ERROR:", error);

  } finally {

    await prisma.$disconnect();
  }
};



seedModerators();