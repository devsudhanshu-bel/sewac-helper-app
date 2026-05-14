const express =
  require("express");

const router =
  express.Router();

const {
  redisClient,
} = require("../config/redis");



// =====================================
// REDIS TEST
// =====================================

router.get(
  "/redis-test",
  async (req, res) => {

    try {

      // SAVE TEST VALUE
      await redisClient.set(
        "sewac:test",
        "Redis Working"
      );



      // GET TEST VALUE
      const value =
        await redisClient.get(
          "sewac:test"
        );



      return res.status(200).json({

        success: true,

        message:
          "Redis Connected Successfully",

        data: value,

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



module.exports = router;