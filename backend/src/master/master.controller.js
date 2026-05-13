const {

  getAllMasterData,

  getMasterByPhone,

  getMasterBySLNO,

} = require("./master.service");





/*
|--------------------------------------------------------------------------
| Get All Master Data
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

    return res.status(500).json({

      success: false,

      message: error.message,

    });

  }

};





/*
|--------------------------------------------------------------------------
| Get Master By Phone
|--------------------------------------------------------------------------
*/
const getMasterDataByPhone = async (
  req,
  res
) => {

  try {

    const { phoneNumber } =
      req.params;

    const data =
      await getMasterByPhone(
        phoneNumber
      );

    if (!data) {

      return res.status(404).json({

        success: false,

        message:
          "Master data not found",

      });

    }

    return res.status(200).json({

      success: true,

      data,

    });

  } catch (error) {

    return res.status(500).json({

      success: false,

      message: error.message,

    });

  }

};





/*
|--------------------------------------------------------------------------
| Get Master By SLNO
|--------------------------------------------------------------------------
*/
const getMasterDataBySLNO = async (
  req,
  res
) => {

  try {

    const { slno } =
      req.params;

    const data =
      await getMasterBySLNO(
        slno
      );

    if (!data) {

      return res.status(404).json({

        success: false,

        message:
          "Master data not found",

      });

    }

    return res.status(200).json({

      success: true,

      data,

    });

  } catch (error) {

    return res.status(500).json({

      success: false,

      message: error.message,

    });

  }

};





module.exports = {

  getMasterData,

  getMasterDataByPhone,

  getMasterDataBySLNO,

};