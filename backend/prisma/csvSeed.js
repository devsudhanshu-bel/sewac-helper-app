const fs = require("fs");
const csv = require("csv-parser");

const { PrismaClient } = require("@prisma/client");

const prisma = new PrismaClient();

function parseCSV(path) {
  return new Promise((resolve, reject) => {
    const results = [];

    fs.createReadStream(path)
      .pipe(csv())
      .on("data", (data) => results.push(data))
      .on("end", () => resolve(results))
      .on("error", reject);
  });
}

async function importRFIDMappings() {
  const data = await parseCSV("./RFIDMapping.csv");

  console.log("Importing RFID mappings...");

  for (const row of data) {
    try {
      await prisma.rFIDMapping.create({
        data: {
          slno: row.slno,
          phoneNumber: row.phoneNumber || null,
          rfid: row.rfid,
          wasteType:
            row.wasteType?.toUpperCase() === "DRY"
              ? "DRY"
              : "WET",
        },
      });

      console.log("RFID:", row.rfid);

    } catch (err) {

      console.log(
        "Skipping RFID:",
        row.rfid
      );
    }
  }
}

async function importCitizens() {
  const data = await parseCSV(
    "./survey_attribute_specific.csv"
  );

  console.log("Importing citizens...");

  for (const row of data) {
    try {
      await prisma.masterCitizenData.create({
        data: {
          phoneNumber:
            row.contactNumber ||
            `TEMP_${Math.random()}`,

          city: row.city,
          ward: row.ward,
          area: row.area,

          wasteGeneratorTypes:
            row.wasteGeneratorTypes,

          houseNumber: row.houseNumber,

          floorNumber: row.floorNumber,

          householdType:
            row.householdType,

          personName: row.personName,

          contactNumber:
            row.contactNumber,

          numberOfPeople:
            row.numberOfPeople,

          buildingPhoto:
            row.buildingPhoto,
        },
      });

      console.log(
        "Citizen:",
        row.contactNumber
      );

    } catch (err) {

      console.log(
        "Skipping citizen:",
        row.contactNumber
      );
    }
  }
}

async function main() {
  await importRFIDMappings();

  await importCitizens();

  console.log("CSV Import Completed");
}

main()
  .catch(console.error)
  .finally(async () => {
    await prisma.$disconnect();
  });