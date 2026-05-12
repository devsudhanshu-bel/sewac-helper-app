const surveyService =
  require("./survey.services");



// ======================================
// CREATE SURVEY
// ======================================
const createSurvey =
  async (req, res, next) => {

    try {

      const surveyData = req.body;

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