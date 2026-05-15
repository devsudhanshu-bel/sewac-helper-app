const rateLimit =
  require("express-rate-limit");

const {
  RedisStore,
} = require("rate-limit-redis");

const {
  redisClient,
} = require("../config/redis");



// =====================================
// SAFE REDIS COMMAND WRAPPER
// =====================================

const safeSendCommand =
  async (...args) => {

    try {

      // CONNECT IF CLOSED
      if (
        !redisClient.isOpen
      ) {

        await redisClient.connect();

      }

      return await redisClient.sendCommand(
        args
      );

    } catch (error) {

      console.log(
        "Rate Limiter Redis Error:",
        error.message
      );

      throw error;

    }

  };



// =====================================
// CREATE REDIS STORE
// IMPORTANT:
// EACH LIMITER NEEDS ITS OWN STORE
// =====================================

const createRedisStore =
  (prefix) => {

    return new RedisStore({

      prefix,

      sendCommand:
        safeSendCommand,

    });

  };



// =====================================
// GLOBAL LIMITER
// =====================================

const globalLimiter =
  rateLimit({

    store:
      createRedisStore(
        "global:"
      ),

    windowMs:
      15 * 60 * 1000,

    max: 100,

    standardHeaders: true,

    legacyHeaders: false,

    message: {

      success: false,

      message:
        "Too many requests. Please try again later.",

    },

  });



// =====================================
// LOGIN LIMITER
// =====================================

const loginLimiter =
  rateLimit({

    store:
      createRedisStore(
        "login:"
      ),

    windowMs:
      10 * 60 * 1000,

    max: 5,

    standardHeaders: true,

    legacyHeaders: false,

    message: {

      success: false,

      message:
        "Too many login attempts. Try again later.",

    },

  });



// =====================================
// RFID LIMITER
// =====================================

const rfidLimiter =
  rateLimit({

    store:
      createRedisStore(
        "rfid:"
      ),

    windowMs:
      1 * 60 * 1000,

    max: 30,

    standardHeaders: true,

    legacyHeaders: false,

    message: {

      success: false,

      message:
        "RFID request limit exceeded.",

    },

  });



// =====================================
// EXPORTS
// =====================================

module.exports = {

  globalLimiter,

  loginLimiter,

  rfidLimiter,

};