/*
  Warnings:

  - You are about to drop the column `rfid` on the `TrackingLog` table. All the data in the column will be lost.
  - You are about to drop the column `wasteType` on the `TrackingLog` table. All the data in the column will be lost.
  - The `status` column on the `TrackingLog` table would be dropped and recreated. This will lead to data loss if there is data in the column.
  - You are about to drop the column `slno` on the `master_citizen_data` table. All the data in the column will be lost.
  - You are about to drop the `Remark` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `survey_attribute_specific` table. If the table is not empty, all the data it contains will be lost.
  - A unique constraint covering the columns `[phoneNumber]` on the table `master_citizen_data` will be added. If there are existing duplicate values, this will fail.
  - Added the required column `updatedAt` to the `TrackingLog` table without a default value. This is not possible if the table is not empty.
  - Made the column `phoneNumber` on table `master_citizen_data` required. This step will fail if there are existing NULL values in that column.

*/
-- CreateEnum
CREATE TYPE "TrackingStatus" AS ENUM ('FOUND', 'NOT_FOUND');

-- DropIndex
DROP INDEX "master_citizen_data_slno_key";

-- AlterTable
ALTER TABLE "TrackingLog" DROP COLUMN "rfid",
DROP COLUMN "wasteType",
ADD COLUMN     "address" TEXT,
ADD COLUMN     "buildingNo" TEXT,
ADD COLUMN     "drySlno" TEXT,
ADD COLUMN     "floorNo" TEXT,
ADD COLUMN     "latitude" DOUBLE PRECISION,
ADD COLUMN     "longitude" DOUBLE PRECISION,
ADD COLUMN     "photoUrl" TEXT,
ADD COLUMN     "updatedAt" TIMESTAMP(3) NOT NULL,
ADD COLUMN     "wetSlno" TEXT,
DROP COLUMN "status",
ADD COLUMN     "status" "TrackingStatus" NOT NULL DEFAULT 'FOUND';

-- AlterTable
ALTER TABLE "master_citizen_data" DROP COLUMN "slno",
ADD COLUMN     "dryRFID" TEXT,
ADD COLUMN     "drySlno" TEXT,
ADD COLUMN     "wetRFID" TEXT,
ADD COLUMN     "wetSlno" TEXT,
ALTER COLUMN "phoneNumber" SET NOT NULL;

-- DropTable
DROP TABLE "Remark";

-- DropTable
DROP TABLE "survey_attribute_specific";

-- CreateIndex
CREATE UNIQUE INDEX "master_citizen_data_phoneNumber_key" ON "master_citizen_data"("phoneNumber");
