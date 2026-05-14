const {
  createClient,
} = require("redis");



// =====================================
// CREATE REDIS CLIENT
// =====================================

const redisClient =
  createClient({

    username:
      process.env.REDIS_USERNAME,

    password:
      process.env.REDIS_PASSWORD,

    socket: {

      host:
        process.env.REDIS_HOST,

      port:
        Number(
          process.env.REDIS_PORT
        ),

      // =====================================
      // AUTO RECONNECT STRATEGY
      // =====================================

      reconnectStrategy:
        (retries) => {

          // STOP AFTER 10 RETRIES
          if (retries > 10) {

            return new Error(
              "Redis reconnect failed"
            );

          }



          // RECONNECT DELAY
          return Math.min(
            retries * 100,
            3000
          );

        },

    },

  });



// =====================================
// REDIS EVENTS
// =====================================

redisClient.on(
  "connect",
  () => {

    console.log(
      "================================="
    );

    console.log(
      " REDIS CONNECTED"
    );

    console.log(
      "================================="
    );

  }
);



redisClient.on(
  "ready",
  () => {

    console.log(
      "================================="
    );

    console.log(
      " REDIS READY"
    );

    console.log(
      "================================="
    );

  }
);



redisClient.on(
  "reconnecting",
  () => {

    console.log(
      "================================="
    );

    console.log(
      " REDIS RECONNECTING"
    );

    console.log(
      "================================="
    );

  }
);



redisClient.on(
  "error",
  (error) => {

    console.log(
      "================================="
    );

    console.log(
      " REDIS ERROR"
    );

    console.log(
      error.message
    );

    console.log(
      "================================="
    );

  }
);



redisClient.on(
  "end",
  () => {

    console.log(
      "================================="
    );

    console.log(
      " REDIS CONNECTION CLOSED"
    );

    console.log(
      "================================="
    );

  }
);



// =====================================
// CONNECT REDIS
// =====================================

const connectRedis =
  async () => {

    try {

      // AVOID MULTIPLE CONNECTIONS
      if (
        !redisClient.isOpen
      ) {

        await redisClient.connect();

      }

    } catch (error) {

      console.log(
        "================================="
      );

      console.log(
        " REDIS CONNECT FAILED"
      );

      console.log(
        error.message
      );

      console.log(
        "================================="
      );

    }

  };



// =====================================
// DISCONNECT REDIS
// =====================================

const disconnectRedis =
  async () => {

    try {

      if (
        redisClient.isOpen
      ) {

        await redisClient.quit();

      }

    } catch (error) {

      console.log(
        "================================="
      );

      console.log(
        " REDIS DISCONNECT FAILED"
      );

      console.log(
        error.message
      );

      console.log(
        "================================="
      );

    }

  };



// =====================================
// SET CACHE
// =====================================

const setCache =
  async (
    key,
    value,
    expiryInSeconds = 3600
  ) => {

    try {

      await redisClient.set(

        key,

        JSON.stringify(value),

        {

          EX:
            expiryInSeconds,

        }

      );

    } catch (error) {

      console.log(
        "SET CACHE ERROR:",
        error.message
      );

    }

  };



// =====================================
// GET CACHE
// =====================================

const getCache =
  async (key) => {

    try {

      const data =
        await redisClient.get(
          key
        );



      if (!data) {

        return null;

      }



      return JSON.parse(
        data
      );

    } catch (error) {

      console.log(
        "GET CACHE ERROR:",
        error.message
      );

      return null;

    }

  };



// =====================================
// DELETE CACHE
// =====================================

const deleteCache =
  async (key) => {

    try {

      await redisClient.del(
        key
      );

    } catch (error) {

      console.log(
        "DELETE CACHE ERROR:",
        error.message
      );

    }

  };



// =====================================
// CHECK CACHE EXISTS
// =====================================

const cacheExists =
  async (key) => {

    try {

      const exists =
        await redisClient.exists(
          key
        );



      return exists === 1;

    } catch (error) {

      console.log(
        "CACHE EXISTS ERROR:",
        error.message
      );

      return false;

    }

  };



// =====================================
// REDIS HEALTH TEST
// =====================================

const testRedis =
  async () => {

    try {

      const randomNumber =
        Math.floor(
          Math.random() * 100000
        );



      // SAVE TEST VALUE
      await redisClient.set(
        "sewac:test",
        randomNumber
      );



      // GET TEST VALUE
      const value =
        await redisClient.get(
          "sewac:test"
        );



      console.log(
        "================================="
      );

      console.log(
        " REDIS TEST SUCCESS"
      );

      console.log(
        ` Saved Value : ${randomNumber}`
      );

      console.log(
        ` Retrieved Value : ${value}`
      );

      console.log(
        "================================="
      );

    } catch (error) {

      console.log(
        "================================="
      );

      console.log(
        " REDIS TEST FAILED"
      );

      console.log(
        error.message
      );

      console.log(
        "================================="
      );

    }

  };



// =====================================
// EXPORTS
// =====================================

module.exports = {

  redisClient,

  connectRedis,

  disconnectRedis,

  setCache,

  getCache,

  deleteCache,

  cacheExists,

  testRedis,

};