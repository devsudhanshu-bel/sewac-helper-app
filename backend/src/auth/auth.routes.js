const express =
  require("express");

const router =
  express.Router();

const {

  login,

  logout,

} = require("./auth.controller");

const verifyToken =
  require("./auth.middleware");

const {
  redisClient,
} = require("../config/redis");



// =====================================
// LOGIN ROUTE
// =====================================

router.post(

  "/login",

  login

);



// =====================================
// LOGOUT ROUTE
// =====================================

router.post(

  "/logout",

  verifyToken,

  logout

);



// =====================================
// GET CURRENT USER
// =====================================

router.get(

  "/me",

  verifyToken,

  async (
    req,
    res
  ) => {

    try {

      return res.status(200).json({

        success: true,

        message:
          "User authenticated successfully",

        data: {

          id:
            req.user.id,

          username:
            req.user.username,

          role:
            req.user.role,

        },

      });

    } catch (error) {

      console.log(
        "ME ROUTE ERROR:",
        error.message
      );



      return res.status(500).json({

        success: false,

        message:
          "Failed to fetch user details",

      });

    }

  }

);



// =====================================
// DEV ONLY - CLEAR SINGLE SESSION
// =====================================

if (
  process.env.NODE_ENV !==
  "production"
) {

  router.get(

    "/clear-session/:id",

    async (
      req,
      res
    ) => {

      try {

        await redisClient.del(

          `session:${req.params.id}`
        );



        return res.status(200).json({

          success: true,

          message:
            "Session cleared successfully",

        });

      } catch (error) {

        console.log(
          "CLEAR SESSION ERROR:",
          error.message
        );



        return res.status(500).json({

          success: false,

          message:
            "Failed to clear session",

        });

      }

    }

  );



  // =====================================
  // DEV ONLY - CLEAR ALL SESSIONS
  // =====================================

  router.get(

    "/clear-all-sessions",

    async (
      req,
      res
    ) => {

      try {

        await redisClient.flushAll();



        return res.status(200).json({

          success: true,

          message:
            "All Redis sessions cleared",

        });

      } catch (error) {

        console.log(
          "CLEAR ALL SESSIONS ERROR:",
          error.message
        );



        return res.status(500).json({

          success: false,

          message:
            "Failed to clear Redis sessions",

        });

      }

    }

  );

}



// =====================================
// HEALTH CHECK
// =====================================

router.get(

  "/health",

  (
    req,
    res
  ) => {

    return res.status(200).json({

      success: true,

      message:
        "Auth service running successfully",

    });

  }

);



// =====================================
// EXPORT ROUTER
// =====================================

module.exports =
  router;