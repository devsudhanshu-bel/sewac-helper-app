const {
  getCitizenByPhoneService,
  searchCitizenByNameService,
  getAllCitizenPhoneNumbersService,
  getAllCitizenNamesService,
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



    if (!phoneNumber) {

      return res.status(400).json({
        success: false,
        message: "Phone number is required",
      });
    }



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

    console.error(
      "GET CITIZEN BY PHONE ERROR:",
      error
    );

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



    if (!citizenName) {

      return res.status(400).json({
        success: false,
        message: "Citizen name is required",
      });
    }



    const citizens =
      await searchCitizenByNameService(
        citizenName
      );



    if (
      !citizens ||
      citizens.length === 0
    ) {

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

    console.error(
      "SEARCH CITIZEN BY NAME ERROR:",
      error
    );

    return res.status(500).json({
      success: false,
      message: "Internal Server Error",
    });
  }
};





// =====================================
// GET ALL CITIZEN PHONE NUMBERS
// =====================================

const getAllCitizenPhoneNumbers =
  async (req, res) => {
    try {

      const phoneNumbers =
        await getAllCitizenPhoneNumbersService();



      return res.status(200).json({
        success: true,
        count: phoneNumbers.length,
        data: phoneNumbers,
      });

    } catch (error) {

      console.error(
        "GET ALL PHONE NUMBERS ERROR:",
        error
      );

      return res.status(500).json({
        success: false,
        message: "Internal Server Error",
      });
    }
  };





// =====================================
// GET ALL CITIZEN NAMES
// =====================================

const getAllCitizenNames =
  async (req, res) => {
    try {

      const citizenNames =
        await getAllCitizenNamesService();



      return res.status(200).json({
        success: true,
        count: citizenNames.length,
        data: citizenNames,
      });

    } catch (error) {

      console.error(
        "GET ALL CITIZEN NAMES ERROR:",
        error
      );

      return res.status(500).json({
        success: false,
        message: "Internal Server Error",
      });
    }
  };





module.exports = {
  getCitizenByPhone,
  searchCitizenByName,
  getAllCitizenPhoneNumbers,
  getAllCitizenNames,
};