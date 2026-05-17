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
      // INVALID USER
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



      if (!isPasswordValid) {

        throw new Error(
          "Invalid username or password"
        );

      }



      // =====================================
      // CHECK EXISTING SESSION
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
          "Account already logged in on another device"
        );

      }



      // =====================================
      // GENERATE SESSION ID
      // =====================================

      const sessionId =
        uuidv4();



      // =====================================
      // STORE SESSION
      // =====================================

      await redisClient.set(

        `session:${moderator.id}`,

        sessionId

      );



      // =====================================
      // GENERATE JWT
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
              "30d",

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
      // DELETE SESSION
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
// EXPORTS
// =====================================

module.exports = {

  loginService,

  logoutService,

};