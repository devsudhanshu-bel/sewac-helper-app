const surveyService =
  require("./survey.services");

const cloudinary =
  require("../config/cloudinary");

const streamifier =
  require("streamifier");



// ======================================
// CLOUDINARY STREAM UPLOAD
// ======================================

const uploadToCloudinary =
  (buffer) => {

    return new Promise(

      (resolve, reject) => {

        const stream =
          cloudinary.uploader.upload_stream(

            {
              folder:
                "sewac-surveys",

              resource_type:
                "image",

              quality:
                "auto:good",

              fetch_format:
                "auto",
            },

            (error, result) => {

              if (error) {

                return reject(error);

              }

              resolve(result);

            }
          );



        streamifier
          .createReadStream(buffer)
          .pipe(stream);

      }
    );

};



// ======================================
// CREATE SURVEY
// ======================================

const createSurvey =
  async (req, res, next) => {

    try {

      const {
        contactNumber,
      } = req.body;



      // ======================================
      // VALIDATE PHONE NUMBER
      // ======================================

      if (!contactNumber) {

        return res.status(400).json({

          success: false,

          message:
            "Contact number is required",

        });

      }



      // ======================================
      // CHECK DUPLICATE SURVEY
      // ======================================

      const existingSurvey =
        await surveyService.findByPhone(
          contactNumber
        );



      if (existingSurvey) {

        return res.status(409).json({

          success: false,

          message:
            "Survey already submitted with this phone number",

        });

      }



      // ======================================
      // IMAGE UPLOAD
      // ======================================

      let imageUrl = null;



      if (req.file) {

        const uploadedImage =
          await uploadToCloudinary(
            req.file.buffer
          );

        imageUrl =
          uploadedImage.secure_url;

      }



      // ======================================
      // PREPARE SURVEY DATA
      // ======================================

      const surveyData = {

        ...req.body,

        buildingPhoto:
          imageUrl,

      };



      // ======================================
      // SAVE TO DATABASE
      // ======================================

      await surveyService.createSurvey(
        surveyData
      );



      // ======================================
      // FAST RESPONSE
      // ======================================

      return res.status(201).json({

        success: true,

        message:
          "Survey submitted successfully",

      });

    } catch (error) {

      console.error(
        "CREATE SURVEY ERROR:",
        error
      );



      // ======================================
      // PRISMA UNIQUE ERROR
      // ======================================

      if (
        error.code === "P2002"
      ) {

        return res.status(409).json({

          success: false,

          message:
            "Phone number already exists",

        });

      }



      return res.status(500).json({

        success: false,

        message:
          "Internal server error",

      });

    }

};



// ======================================
// GET ALL SURVEYS
// ======================================

const getAllSurveys =
  async (req, res, next) => {

    try {

      const result =
        await surveyService.getAllSurveys();



      return res.status(200).json({

        success: true,

        total:
          result.length,

        data:
          result,

      });

    } catch (error) {

      console.error(
        "GET ALL SURVEYS ERROR:",
        error
      );



      return res.status(500).json({

        success: false,

        message:
          "Internal server error",

      });

    }

};



// ======================================
// GET SURVEY BY ID
// ======================================

const getSurveyById =
  async (req, res, next) => {

    try {

      const { id } =
        req.params;



      const result =
        await surveyService.getSurveyById(
          Number(id)
        );



      if (!result) {

        return res.status(404).json({

          success: false,

          message:
            "Survey not found",

        });

      }



      return res.status(200).json({

        success: true,

        data:
          result,

      });

    } catch (error) {

      console.error(
        "GET SURVEY BY ID ERROR:",
        error
      );



      return res.status(500).json({

        success: false,

        message:
          "Internal server error",

      });

    }

};



// ======================================
// DELETE SURVEY
// ======================================

const deleteSurvey =
  async (req, res, next) => {

    try {

      const { id } =
        req.params;



      await surveyService.deleteSurvey(
        Number(id)
      );



      return res.status(200).json({

        success: true,

        message:
          "Survey deleted successfully",

      });

    } catch (error) {

      console.error(
        "DELETE SURVEY ERROR:",
        error
      );



      return res.status(500).json({

        success: false,

        message:
          "Internal server error",

      });

    }

};



// ======================================
// GET TOTAL SURVEY COUNT
// ======================================

const getSurveyCount =
  async (req, res, next) => {

    try {

      const total =
        await surveyService.getSurveyCount();



      return res.status(200).json({

        success: true,

        total,

      });

    } catch (error) {

      console.error(
        "GET SURVEY COUNT ERROR:",
        error
      );



      return res.status(500).json({

        success: false,

        message:
          "Internal server error",

      });

    }

};





module.exports = {

  createSurvey,

  getAllSurveys,

  getSurveyById,

  deleteSurvey,

  getSurveyCount,

};