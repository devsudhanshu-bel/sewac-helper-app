const { prisma } =
  require("../config/db");

const bcrypt =
  require("bcryptjs");

const jwt =
  require("jsonwebtoken");

const {
  v4: uuidv4,
} = require("uuid");

const {
  redisClient,
} = require("../config/redis");



// =====================================
// LOGIN SERVICE
// =====================================

const loginService =
  async (
    username,
    password
  ) => {

    try {

      // =====================================
      // FIND MODERATOR
      // =====================================

      const moderator =
        await prisma.moderator.findUnique({

          where: {
            username,
          },

        });



      // =====================================
      // MODERATOR NOT FOUND
      // =====================================

      if (!moderator) {

        throw new Error(
          "Invalid username or password"
        );

      }



      // =====================================
      // VERIFY PASSWORD
      // =====================================

      const isPasswordValid =
        await bcrypt.compare(

          password,

          moderator.password
        );



      // =====================================
      // INVALID PASSWORD
      // =====================================

      if (!isPasswordValid) {

        throw new Error(
          "Invalid username or password"
        );

      }



      // =====================================
      // CHECK ACTIVE SESSION
      // =====================================

      const existingSession =
        await redisClient.get(

          `session:${moderator.id}`
        );



      // =====================================
      // BLOCK MULTIPLE LOGIN
      // =====================================

      if (existingSession) {

        throw new Error(
          "Account already active on another device"
        );

      }



      // =====================================
      // GENERATE SESSION ID
      // =====================================

      const sessionId =
        uuidv4();



      // =====================================
      // SAVE SESSION IN REDIS
      // =====================================

      await redisClient.set(

        `session:${moderator.id}`,

        sessionId,

        {

          EX:
            60 * 60 * 24 * 7,

        }

      );



      // =====================================
      // GENERATE JWT TOKEN
      // =====================================

      const token =
        jwt.sign(

          {

            id:
              moderator.id,

            username:
              moderator.username,

            role:
              moderator.role,

            sessionId,

          },

          process.env.JWT_SECRET,

          {

            expiresIn:
              "7d",

          }

        );



      // =====================================
      // RETURN RESPONSE
      // =====================================

      return {

        token,

        moderator: {

          id:
            moderator.id,

          username:
            moderator.username,

          role:
            moderator.role,

          sessionId,

        },

      };

    } catch (error) {

      console.log(
        "LOGIN SERVICE ERROR:",
        error.message
      );

      throw error;

    }

  };



// =====================================
// LOGOUT SERVICE
// =====================================

const logoutService =
  async (userId) => {

    try {

      // =====================================
      // REMOVE REDIS SESSION
      // =====================================

      await redisClient.del(

        `session:${userId}`
      );



      return {

        success: true,

        message:
          "Logout successful",

      };

    } catch (error) {

      console.log(
        "LOGOUT SERVICE ERROR:",
        error.message
      );

      throw error;

    }

  };



// =====================================
// EXPORT SERVICES
// =====================================

module.exports = {

  loginService,

  logoutService,

};