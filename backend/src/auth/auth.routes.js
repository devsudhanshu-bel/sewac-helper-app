const express = require("express");

const router = express.Router();

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
  async (req, res) => {

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
// HEALTH CHECK
// =====================================

router.get(
  "/health",
  (req, res) => {

    return res.status(200).json({

      success: true,

      message:
        "Auth service running successfully",

      timestamp:
        new Date(),

    });

  }
);





// =====================================
// CLEAR SINGLE SESSION
// =====================================

router.get(
  "/clear-session/:id",
  async (req, res) => {

    try {

      const sessionId =
        req.params.id;





      /*
      |--------------------------------------------------------------------------
      | VALIDATION
      |--------------------------------------------------------------------------
      */
      if (!sessionId) {

        return res.status(400).json({

          success: false,

          message:
            "Session ID is required",

        });

      }





      /*
      |--------------------------------------------------------------------------
      | DELETE SESSION
      |--------------------------------------------------------------------------
      */
      await redisClient.del(
        `session:${sessionId}`
      );





      return res.status(200).json({

        success: true,

        message:
          "Session cleared successfully",

        sessionId,

      });

    } catch (error) {

      console.log(
        "CLEAR SESSION ERROR:",
        error.message
      );

      return res.status(500).json({

        success: false,

        message:
          error.message,

      });

    }

  }
);





// =====================================
// CLEAR ALL SESSIONS
// =====================================

router.get(
  "/clear-all-sessions",
  async (req, res) => {

    try {

      /*
      |--------------------------------------------------------------------------
      | CLEAR REDIS
      |--------------------------------------------------------------------------
      */
      await redisClient.flushAll();





      return res.status(200).json({

        success: true,

        message:
          "All Redis sessions cleared successfully",

        timestamp:
          new Date(),

      });

    } catch (error) {

      console.log(
        "CLEAR ALL SESSIONS ERROR:",
        error.message
      );

      return res.status(500).json({

        success: false,

        message:
          error.message,

      });

    }

  }
);





// =====================================
// EXPORT ROUTER
// =====================================

module.exports = router;