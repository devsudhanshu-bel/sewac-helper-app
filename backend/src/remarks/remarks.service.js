const { prisma } = require("../config/db");





/*
|--------------------------------------------------------------------------
| Create Remark
|--------------------------------------------------------------------------
*/
const createRemarkService = async (remark) => {

  const newRemark =
    await prisma.remark.create({
      data: {
        remark,
      },
    });



  return newRemark;
};





/*
|--------------------------------------------------------------------------
| Get All Remarks
|--------------------------------------------------------------------------
*/
const getAllRemarksService = async () => {

  const remarks =
    await prisma.remark.findMany({
      orderBy: {
        createdAt: "desc",
      },
    });



  return remarks;
};





module.exports = {
  createRemarkService,
  getAllRemarksService,
};