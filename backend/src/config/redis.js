const redis = require("redis");

let redisClient;



// =====================================
// CONNECT REDIS
// =====================================

const connectRedis = async () => {

  try {

    redisClient = redis.createClient({
      url: process.env.REDIS_URL,
    });

    redisClient.on("error", (err) => {

      console.error("=================================");
      console.error(" REDIS ERROR");
      console.error(err.message);
      console.error("=================================");

    });

    await redisClient.connect();

    console.log("=================================");
    console.log(" REDIS CONNECTED");
    console.log("=================================");

  } catch (error) {

    console.error("=================================");
    console.error(" REDIS CONNECTION FAILED");
    console.error(error.message);
    console.error("=================================");

  }

};



// =====================================
// GET REDIS CLIENT
// =====================================

const getRedis = () => {

  if (!redisClient) {

    throw new Error("Redis not initialized");

  }

  return redisClient;

};



module.exports = {
  connectRedis,
  getRedis,
};