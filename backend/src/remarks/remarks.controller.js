const {
  createRemarkService,
  getAllRemarksService,
} = require("./remarks.service");





/*
|--------------------------------------------------------------------------
| Create Remark
|--------------------------------------------------------------------------
*/
const createRemark = async (req, res) => {
  try {

    const { remark } = req.body;



    // Validation
    if (!remark || remark.trim() === "") {

      return res.status(400).json({
        success: false,
        message: "Remark is required",
      });

    }



    const newRemark =
      await createRemarkService(remark);



    return res.status(201).json({
      success: true,
      message: "Remark created successfully",
      data: newRemark,
    });

  } catch (error) {

    console.error("CREATE REMARK ERROR:", error);



    return res.status(500).json({
      success: false,
      message: "Internal Server Error",
      error: error.message,
    });

  }
};





/*
|--------------------------------------------------------------------------
| Get All Remarks
|--------------------------------------------------------------------------
*/
const getAllRemarks = async (req, res) => {
  try {

    const remarks =
      await getAllRemarksService();



    return res.status(200).json({
      success: true,
      count: remarks.length,
      data: remarks,
    });

  } catch (error) {

    console.error("GET REMARKS ERROR:", error);



    return res.status(500).json({
      success: false,
      message: "Internal Server Error",
      error: error.message,
    });

  }
};





module.exports = {
  createRemark,
  getAllRemarks,
};