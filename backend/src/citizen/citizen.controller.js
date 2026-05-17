const {
  getCitizenByPhoneService,
  searchCitizenByNameService,
  getAllCitizenPhoneNumbersService,
  getAllCitizenNamesService,
  getUnmappedCitizensService,
} = require("./citizen.service");





/*
|--------------------------------------------------------------------------
| Get Citizen By Phone Number
|--------------------------------------------------------------------------
| GET /api/v1/citizen/phone/:phoneNumber
|--------------------------------------------------------------------------
*/
const getCitizenByPhone = async (
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
    // FETCH CITIZEN
    // =============================

    const citizen =
      await getCitizenByPhoneService(
        phoneNumber
      );



    // =============================
    // NOT FOUND
    // =============================

    if (!citizen) {

      return res.status(404).json({

        success: false,

        message:
          "Citizen not found",

      });

    }



    // =============================
    // SUCCESS
    // =============================

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

      message:
        error.message ||
        "Internal Server Error",

    });

  }

};





/*
|--------------------------------------------------------------------------
| Search Citizen By Name
|--------------------------------------------------------------------------
| GET /api/v1/citizen/name/:citizenName
|--------------------------------------------------------------------------
*/
const searchCitizenByName = async (
  req,
  res
) => {

  try {

    const { citizenName } =
      req.params;



    // =============================
    // VALIDATION
    // =============================

    if (!citizenName) {

      return res.status(400).json({

        success: false,

        message:
          "Citizen name is required",

      });

    }



    // =============================
    // SEARCH
    // =============================

    const citizens =
      await searchCitizenByNameService(
        citizenName
      );



    // =============================
    // NOT FOUND
    // =============================

    if (
      !citizens ||
      citizens.length === 0
    ) {

      return res.status(404).json({

        success: false,

        message:
          "Citizen not found",

      });

    }



    // =============================
    // SUCCESS
    // =============================

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

      message:
        error.message ||
        "Internal Server Error",

    });

  }

};





/*
|--------------------------------------------------------------------------
| Get All Citizen Phone Numbers
|--------------------------------------------------------------------------
| GET /api/v1/citizen/phones
|--------------------------------------------------------------------------
*/
const getAllCitizenPhoneNumbers =
  async (req, res) => {

    try {

      const phoneNumbers =
        await getAllCitizenPhoneNumbersService();



      return res.status(200).json({

        success: true,

        count:
          phoneNumbers.length,

        data:
          phoneNumbers,

      });

    } catch (error) {

      console.error(
        "GET ALL PHONE NUMBERS ERROR:",
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
| Get All Citizen Names
|--------------------------------------------------------------------------
| GET /api/v1/citizen/names
|--------------------------------------------------------------------------
*/
const getAllCitizenNames =
  async (req, res) => {

    try {

      const citizenNames =
        await getAllCitizenNamesService();



      return res.status(200).json({

        success: true,

        count:
          citizenNames.length,

        data:
          citizenNames,

      });

    } catch (error) {

      console.error(
        "GET ALL CITIZEN NAMES ERROR:",
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
| Get Unmapped Citizens
|--------------------------------------------------------------------------
| GET /api/v1/citizen/unmapped
|--------------------------------------------------------------------------
*/
const getUnmappedCitizens =
  async (req, res) => {

    try {

      const citizens =
        await getUnmappedCitizensService();



      return res.status(200).json({

        success: true,

        count:
          citizens.length,

        data:
          citizens,

      });

    } catch (error) {

      console.error(
        "GET UNMAPPED CITIZENS ERROR:",
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

  getCitizenByPhone,

  searchCitizenByName,

  getAllCitizenPhoneNumbers,

  getAllCitizenNames,

  getUnmappedCitizens,

};