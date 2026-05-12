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
  async (req, res, next) => {

    try {

      let imageUrl = null;



      // ======================================
      // UPLOAD IMAGE TO CLOUDINARY
      // ======================================

      if (req.file) {

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



        const uploadedImage =
          await streamUpload();



        imageUrl =
          uploadedImage.secure_url;

      }



      // ======================================
      // CREATE SURVEY DATA
      // ======================================

      const surveyData = {

        ...req.body,

        buildingPhoto:
          imageUrl,

      };



      const result =
        await surveyService.createSurvey(
          surveyData
        );



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

      next(error);

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

        total: result.length,

        data: result,

      });

    } catch (error) {

      console.error(
        "GET ALL SURVEYS ERROR:",
        error
      );

      next(error);

    }

};



// ======================================
// GET SURVEY BY ID
// ======================================

const getSurveyById =
  async (req, res, next) => {

    try {

      const { id } = req.params;

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

        data: result,

      });

    } catch (error) {

      console.error(
        "GET SURVEY BY ID ERROR:",
        error
      );

      next(error);

    }

};





module.exports = {

  createSurvey,

  getAllSurveys,

  getSurveyById,

};