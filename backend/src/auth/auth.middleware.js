const jwt =
  require("jsonwebtoken");

const {
  redisClient,
} = require("../config/redis");



// =====================================
// VERIFY TOKEN MIDDLEWARE
// =====================================

const verifyToken =
  async (
    req,
    res,
    next
  ) => {

    try {

      // =====================================
      // GET AUTH HEADER
      // =====================================

      const authHeader =
        req.headers.authorization;



      // =====================================
      // VALIDATE AUTH HEADER
      // =====================================

      if (

        !authHeader ||

        !authHeader.startsWith(
          "Bearer "
        )

      ) {

        return res.status(401).json({

          success: false,

          message:
            "Access denied. No token provided",

        });

      }



      // =====================================
      // EXTRACT TOKEN
      // =====================================

      const token =
        authHeader.split(" ")[1];



      // =====================================
      // VERIFY JWT TOKEN
      // =====================================

      const decoded =
        jwt.verify(

          token,

          process.env.JWT_SECRET
        );



      // =====================================
      // GET ACTIVE SESSION FROM REDIS
      // =====================================

      const activeSession =
        await redisClient.get(

          `session:${decoded.id}`
        );



      // =====================================
      // SESSION NOT FOUND
      // =====================================

      if (!activeSession) {

        return res.status(401).json({

          success: false,

          message:
            "Session expired. Please login again",

        });

      }



      // =====================================
      // SESSION MISMATCH
      // =====================================

      if (

        activeSession !==
        decoded.sessionId

      ) {

        return res.status(401).json({

          success: false,

          message:
            "Another login detected. Please login again",

        });

      }



      // =====================================
      // ATTACH USER DATA
      // =====================================

      req.user = {

        id:
          decoded.id,

        username:
          decoded.username,

        role:
          decoded.role,

        sessionId:
          decoded.sessionId,

      };



      // =====================================
      // NEXT
      // =====================================

      next();

    } catch (error) {

      console.log(
        "VERIFY TOKEN ERROR:",
        error.message
      );



      // =====================================
      // JWT ERROR HANDLING
      // =====================================

      if (
        error.name ===
        "TokenExpiredError"
      ) {

        return res.status(401).json({

          success: false,

          message:
            "Token expired. Please login again",

        });

      }



      if (
        error.name ===
        "JsonWebTokenError"
      ) {

        return res.status(401).json({

          success: false,

          message:
            "Invalid token",

        });

      }



      // =====================================
      // DEFAULT ERROR
      // =====================================

      return res.status(500).json({

        success: false,

        message:
          "Authentication failed",

      });

    }

  };



// =====================================
// EXPORT MIDDLEWARE
// =====================================

module.exports =
  verifyToken;