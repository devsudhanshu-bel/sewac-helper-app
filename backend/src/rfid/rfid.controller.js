const {
  createRFIDService,
  getAllRFIDMappingsService,
  getUnmappedRFIDsService,
  mapRFIDService,
  getRFIDByValueService,
  getCitizenRFIDsService,
} = require("./rfid.service");





/*
|--------------------------------------------------------------------------
| Create RFID
|--------------------------------------------------------------------------
| POST /api/v1/rfid/create/:rfid
| GET  /api/v1/rfid/create/:rfid
|--------------------------------------------------------------------------
*/
const createRFID = async (
  req,
  res
) => {
  try {

    const { rfid } =
      req.params;



    /*
    |--------------------------------------------------------------------------
    | VALIDATION
    |--------------------------------------------------------------------------
    */
    if (
      !rfid ||
      rfid.trim() === ""
    ) {

      return res.status(400).json({

        success: false,

        message:
          "RFID code is required",

      });
    }



    /*
    |--------------------------------------------------------------------------
    | CREATE RFID
    |--------------------------------------------------------------------------
    */
    const newRFID =
      await createRFIDService(
        rfid
      );



    return res.status(201).json({

      success: true,

      message:
        "RFID created successfully",

      data: newRFID,

    });

  } catch (error) {

    console.error(
      "RFID CREATE ERROR:",
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
| Map RFID To Citizen
|--------------------------------------------------------------------------
| PATCH /api/v1/rfid/map
|--------------------------------------------------------------------------
*/
const mapRFID = async (
  req,
  res
) => {
  try {

    const {

      slno,

      phoneNumber,

      wasteType,

    } = req.body;



    /*
    |--------------------------------------------------------------------------
    | VALIDATION
    |--------------------------------------------------------------------------
    */
    if (

      !slno ||

      !phoneNumber ||

      !wasteType

    ) {

      return res.status(400).json({

        success: false,

        message:
          "SLNO, phone number, and wasteType are required",

      });
    }



    /*
    |--------------------------------------------------------------------------
    | VALIDATE WASTE TYPE
    |--------------------------------------------------------------------------
    */
    const allowedWasteTypes = [
      "DRY",
      "WET",
    ];



    if (
      !allowedWasteTypes.includes(
        wasteType
      )
    ) {

      return res.status(400).json({

        success: false,

        message:
          "Invalid waste type. Use DRY or WET",

      });
    }



    /*
    |--------------------------------------------------------------------------
    | MAP RFID
    |--------------------------------------------------------------------------
    */
    const mappedRFID =
      await mapRFIDService(

        slno,

        phoneNumber,

        wasteType

      );



    return res.status(200).json({

      success: true,

      message:
        "RFID mapped successfully",

      data: mappedRFID,

    });

  } catch (error) {

    console.error(
      "RFID MAP ERROR:",
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
| Get All RFID Mappings
|--------------------------------------------------------------------------
| GET /api/v1/rfid/all
|--------------------------------------------------------------------------
*/
const getAllRFIDMappings = async (
  req,
  res
) => {
  try {

    const allMappings =
      await getAllRFIDMappingsService();



    return res.status(200).json({

      success: true,

      count: allMappings.length,

      data: allMappings,

    });

  } catch (error) {

    console.error(
      "GET RFID MAPPINGS ERROR:",
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
| Get Unmapped RFIDs
|--------------------------------------------------------------------------
| GET /api/v1/rfid/unmapped
|--------------------------------------------------------------------------
*/
const getUnmappedRFIDs = async (
  req,
  res
) => {
  try {

    const unmappedRFIDs =
      await getUnmappedRFIDsService();



    return res.status(200).json({

      success: true,

      count:
        unmappedRFIDs.length,

      data: unmappedRFIDs,

    });

  } catch (error) {

    console.error(
      "GET UNMAPPED RFID ERROR:",
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
| Get RFID Details By RFID Number
|--------------------------------------------------------------------------
| GET /api/v1/rfid/rfid/:slno
|--------------------------------------------------------------------------
*/
const getRFIDByValue = async (
  req,
  res
) => {
  try {

    const { rfid } =
      req.params;



    /*
    |--------------------------------------------------------------------------
    | VALIDATION
    |--------------------------------------------------------------------------
    */
    if (!rfid) {

      return res.status(400).json({

        success: false,

        message:
          "RFID number is required",

      });
    }



    /*
    |--------------------------------------------------------------------------
    | GET RFID
    |--------------------------------------------------------------------------
    */
    const rfidData =
      await getRFIDByValueService(
        rfid
      );



    return res.status(200).json({

      success: true,

      data: rfidData,

    });

  } catch (error) {

    console.error(
      "GET RFID BY VALUE ERROR:",
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
| Get Citizen RFIDs
|--------------------------------------------------------------------------
| GET /api/v1/rfid/citizen/:phoneNumber
|--------------------------------------------------------------------------
*/
const getCitizenRFIDs = async (
  req,
  res
) => {
  try {

    const { phoneNumber } =
      req.params;



    /*
    |--------------------------------------------------------------------------
    | VALIDATION
    |--------------------------------------------------------------------------
    */
    if (!phoneNumber) {

      return res.status(400).json({

        success: false,

        message:
          "Phone number is required",

      });
    }



    /*
    |--------------------------------------------------------------------------
    | GET RFIDS
    |--------------------------------------------------------------------------
    */
    const rfids =
      await getCitizenRFIDsService(
        phoneNumber
      );



    return res.status(200).json({

      success: true,

      data: rfids,

    });

  } catch (error) {

    console.error(
      "GET CITIZEN RFIDS ERROR:",
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

  createRFID,

  mapRFID,

  getAllRFIDMappings,

  getUnmappedRFIDs,

  getRFIDByValue,

  getCitizenRFIDs,

};