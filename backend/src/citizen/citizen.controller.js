const {
  getCitizenByPhoneService,
  searchCitizenByNameService,
} = require("./citizen.service");





// =====================================
// GET CITIZEN BY PHONE
// =====================================

const getCitizenByPhone = async (
  req,
  res
) => {
  try {

    const { phoneNumber } = req.params;



    const citizen =
      await getCitizenByPhoneService(
        phoneNumber
      );



    if (!citizen) {
      return res.status(404).json({
        success: false,
        message: "Citizen not found",
      });
    }



    return res.status(200).json({
      success: true,
      data: citizen,
    });

  } catch (error) {

    console.error("PHONE SEARCH ERROR:", error);

    return res.status(500).json({
      success: false,
      message: "Internal Server Error",
    });
  }
};





// =====================================
// SEARCH CITIZEN BY NAME
// =====================================

const searchCitizenByName = async (
  req,
  res
) => {
  try {

    const { citizenName } = req.params;



    const citizens =
      await searchCitizenByNameService(
        citizenName
      );



    if (!citizens || citizens.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Citizen not found",
      });
    }



    return res.status(200).json({
      success: true,
      count: citizens.length,
      data: citizens,
    });

  } catch (error) {

    console.error("NAME SEARCH ERROR:", error);

    return res.status(500).json({
      success: false,
      message: "Internal Server Error",
    });
  }
};





module.exports = {
  getCitizenByPhone,
  searchCitizenByName,
};