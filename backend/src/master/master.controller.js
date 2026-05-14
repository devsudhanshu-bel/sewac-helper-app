const {

  getAllMasterData,

  getMasterByPhone,

  getMasterBySLNO,

} = require("./master.service");





/*
|--------------------------------------------------------------------------
| Get All Master Data
|--------------------------------------------------------------------------
| GET /api/v1/master/all
|--------------------------------------------------------------------------
*/
const getMasterData = async (
  req,
  res
) => {

  try {

    const data =
      await getAllMasterData();



    return res.status(200).json({

      success: true,

      count: data.length,

      data,

    });

  } catch (error) {

    console.error(
      "GET MASTER DATA ERROR:",
      error
    );



    return res.status(500).json({

      success: false,

      message:
        error.message ||
        "Internal Server Error",

    });

  }

};





/*
|--------------------------------------------------------------------------
| Get Master By Phone Number
|--------------------------------------------------------------------------
| GET /api/v1/master/phone/:phoneNumber
|--------------------------------------------------------------------------
*/
const getMasterDataByPhone = async (
  req,
  res
) => {

  try {

    const { phoneNumber } =
      req.params;



    // =============================
    // VALIDATION
    // =============================

    if (!phoneNumber) {

      return res.status(400).json({

        success: false,

        message:
          "Phone number is required",

      });

    }



    // =============================
    // FETCH DATA
    // =============================

    const data =
      await getMasterByPhone(
        phoneNumber
      );



    // =============================
    // NOT FOUND
    // =============================

    if (!data) {

      return res.status(404).json({

        success: false,

        message:
          "Master data not found",

      });

    }



    // =============================
    // SUCCESS
    // =============================

    return res.status(200).json({

      success: true,

      data,

    });

  } catch (error) {

    console.error(
      "GET MASTER BY PHONE ERROR:",
      error
    );



    return res.status(500).json({

      success: false,

      message:
        error.message ||
        "Internal Server Error",

    });

  }

};





/*
|--------------------------------------------------------------------------
| Get Master By SLNO
|--------------------------------------------------------------------------
| GET /api/v1/master/slno/:slno
|--------------------------------------------------------------------------
*/
const getMasterDataBySLNO = async (
  req,
  res
) => {

  try {

    const { slno } =
      req.params;



    // =============================
    // VALIDATION
    // =============================

    if (!slno) {

      return res.status(400).json({

        success: false,

        message:
          "SLNO is required",

      });

    }



    // =============================
    // FETCH DATA
    // =============================

    const data =
      await getMasterBySLNO(
        slno
      );



    // =============================
    // NOT FOUND
    // =============================

    if (!data) {

      return res.status(404).json({

        success: false,

        message:
          "Master data not found",

      });

    }



    // =============================
    // SUCCESS
    // =============================

    return res.status(200).json({

      success: true,

      data,

    });

  } catch (error) {

    console.error(
      "GET MASTER BY SLNO ERROR:",
      error
    );



    return res.status(500).json({

      success: false,

      message:
        error.message ||
        "Internal Server Error",

    });

  }

};





module.exports = {

  getMasterData,

  getMasterDataByPhone,

  getMasterDataBySLNO,

};