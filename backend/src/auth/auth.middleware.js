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
      // CHECK AUTH HEADER
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
      // VERIFY JWT
      // =====================================

      const decoded =
        jwt.verify(

          token,

          process.env.JWT_SECRET
        );



      // =====================================
      // CHECK REDIS ACTIVE SESSION
      // =====================================

      const activeSession =
        await redisClient.get(

          `session:${decoded.id}`
        );



      // =====================================
      // INVALID SESSION
      // =====================================

      if (

        !activeSession ||

        activeSession !==
          decoded.sessionId

      ) {

        return res.status(401).json({

          success: false,

          message:
            "Session expired. Please login again",

        });

      }



      // =====================================
      // SAVE USER DATA
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
      // NEXT MIDDLEWARE
      // =====================================

      next();

    } catch (error) {

      console.log(
        "VERIFY TOKEN ERROR:",
        error.message
      );



      return res.status(401).json({

        success: false,

        message:
          "Invalid or expired token",

      });

    }

  };



// =====================================
// EXPORT MIDDLEWARE
// =====================================

module.exports =
  verifyToken;