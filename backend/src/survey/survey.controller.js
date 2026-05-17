const surveyService =
  require("./survey.services");

const cloudinary =
  require("../config/cloudinary");

const streamifier =
  require("streamifier");





// ======================================
// CREATE SURVEY
// ======================================

const createSurvey =
  async (
    req,
    res,
    next
  ) => {

    try {

      let imageUrl = null;



      // ======================================
      // CHECK IF IMAGE EXISTS
      // ======================================

      if (req.file) {

        console.log(
          "SURVEY IMAGE RECEIVED"
        );



        // ======================================
        // CLOUDINARY STREAM UPLOAD
        // ======================================

        const streamUpload =
          () => {

            return new Promise(

              (
                resolve,
                reject
              ) => {

                const stream =
                  cloudinary.uploader.upload_stream(

                    {

                      folder:
                        "sewac-surveys",

                    },

                    (
                      error,
                      result
                    ) => {

                      if (result) {

                        resolve(result);

                      } else {

                        reject(error);

                      }

                    }

                  );



                streamifier

                  .createReadStream(
                    req.file.buffer
                  )

                  .pipe(stream);

              }

            );

          };



        // ======================================
        // UPLOAD TO CLOUDINARY
        // ======================================

        const uploadedImage =
          await streamUpload();



        // ======================================
        // SAVE CLOUDINARY URL
        // ======================================

        imageUrl =
          uploadedImage.secure_url;



        console.log(
          "SURVEY CLOUDINARY URL =>",
          imageUrl
        );

      } else {

        console.log(
          "NO SURVEY IMAGE RECEIVED"
        );

      }





      // ======================================
      // CREATE SURVEY PAYLOAD
      // ======================================

      const surveyData = {

        city:
          req.body.city ||
          "Bangalore",

        ward:
          req.body.ward ||
          "Ibbanuru-174",

        area:
          req.body.area || null,

        wasteGeneratorTypes:
          req.body.wasteGeneratorTypes || null,

        houseNumber:
          req.body.houseNumber || null,

        floorNumber:
          req.body.floorNumber || null,

        householdType:
          req.body.householdType || null,

        personName:
          req.body.personName || null,

        contactNumber:
          req.body.contactNumber || null,

        numberOfPeople:
          req.body.numberOfPeople || null,

        buildingPhoto:
          imageUrl,

      };



      console.log(
        "FINAL SURVEY DATA =>",
        surveyData
      );



      // ======================================
      // CREATE SURVEY
      // ======================================

      const result =
        await surveyService.createSurvey(
          surveyData
        );



      // ======================================
      // SUCCESS RESPONSE
      // ======================================

      return res.status(201).json({

        success: true,

        message:
          "Survey created successfully",

        data: result,

      });

    } catch (error) {

      console.error(
        "CREATE SURVEY ERROR:",
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





// ======================================
// GET ALL SURVEYS
// ======================================

const getAllSurveys =
  async (
    req,
    res,
    next
  ) => {

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
          error.message ||
          "Internal Server Error",

      });

    }

  };





// ======================================
// GET SURVEY BY ID
// ======================================

const getSurveyById =
  async (
    req,
    res,
    next
  ) => {

    try {

      const { id } =
        req.params;



      const result =
        await surveyService.getSurveyById(
          Number(id)
        );



      // ======================================
      // NOT FOUND
      // ======================================

      if (!result) {

        return res.status(404).json({

          success: false,

          message:
            "Survey not found",

        });

      }



      // ======================================
      // SUCCESS RESPONSE
      // ======================================

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
          error.message ||
          "Internal Server Error",

      });

    }

  };





// ======================================
// EXPORT CONTROLLERS
// ======================================

module.exports = {

  createSurvey,

  getAllSurveys,

  getSurveyById,

};