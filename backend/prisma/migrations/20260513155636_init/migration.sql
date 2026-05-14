-- CreateEnum
CREATE TYPE "WasteType" AS ENUM ('DRY', 'WET');

-- CreateTable
CREATE TABLE "RFIDMapping" (
    "id" SERIAL NOT NULL,
    "slno" TEXT NOT NULL,
    "phoneNumber" TEXT,
    "rfid" TEXT NOT NULL,
    "wasteType" "WasteType",
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "RFIDMapping_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Moderator" (
    "id" SERIAL NOT NULL,
    "username" TEXT NOT NULL,
    "password" TEXT NOT NULL,
    "role" TEXT NOT NULL DEFAULT 'MODERATOR',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Moderator_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "TrackingLog" (
    "id" SERIAL NOT NULL,
    "workerId" TEXT NOT NULL,
    "slno" TEXT,
    "citizenName" TEXT,
    "phoneNumber" TEXT,
    "rfid" TEXT,
    "wasteType" "WasteType",
    "status" TEXT NOT NULL DEFAULT 'FOUND',
    "remarks" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "TrackingLog_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Remark" (
    "id" SERIAL NOT NULL,
    "remark" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Remark_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "survey_attribute_specific" (
    "city" TEXT,
    "ward" TEXT,
    "area" TEXT,
    "wasteGeneratorTypes" TEXT,
    "houseNumber" TEXT,
    "floorNumber" TEXT,
    "householdType" TEXT,
    "personName" TEXT,
    "contactNumber" TEXT,
    "numberOfPeople" TEXT,
    "buildingPhoto" TEXT,
    "id" SERIAL NOT NULL,

    CONSTRAINT "survey_attribute_specific_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "master_citizen_data" (
    "id" SERIAL NOT NULL,
    "slno" TEXT NOT NULL,
    "phoneNumber" TEXT,
    "city" TEXT,
    "ward" TEXT,
    "area" TEXT,
    "wasteGeneratorTypes" TEXT,
    "houseNumber" TEXT,
    "floorNumber" TEXT,
    "householdType" TEXT,
    "personName" TEXT,
    "contactNumber" TEXT,
    "numberOfPeople" TEXT,
    "buildingPhoto" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "master_citizen_data_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "RFIDMapping_rfid_key" ON "RFIDMapping"("rfid");

-- CreateIndex
CREATE UNIQUE INDEX "RFIDMapping_slno_wasteType_key" ON "RFIDMapping"("slno", "wasteType");

-- CreateIndex
CREATE UNIQUE INDEX "Moderator_username_key" ON "Moderator"("username");

-- CreateIndex
CREATE UNIQUE INDEX "master_citizen_data_slno_key" ON "master_citizen_data"("slno");
