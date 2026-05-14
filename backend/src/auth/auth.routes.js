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
// CHECK AUTH / ACTIVE SESSION
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

          sessionId:
            req.user.sessionId,

        },

      });

    } catch (error) {

      return res.status(500).json({

        success: false,

        message:
          error.message,

      });

    }

  }
);



// =====================================
// CLEAR SINGLE SESSION (DEV ONLY)
// =====================================

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

      return res.status(500).json({

        success: false,

        message:
          error.message,

      });

    }

  }
);



// =====================================
// CLEAR ALL SESSIONS (DEV ONLY)
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

      return res.status(500).json({

        success: false,

        message:
          error.message,

      });

    }

  }
);



// =====================================
// HEALTH CHECK ROUTE
// =====================================

router.get(
  "/health",

  (req, res) => {

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