const express =
  require("express");

const cors =
  require("cors");

const compression =
  require("compression");

const helmet =
  require("helmet");



// =====================================
// RATE LIMITER IMPORTS
// =====================================

const {
  globalLimiter,
} = require(
  "./middleware/rateLimiter"
);



// =====================================
// APP INITIALIZATION
// =====================================

const app = express();



// =====================================
// TRUST PROXY
// IMPORTANT FOR:
// RENDER / RAILWAY / AWS / NGINX
// =====================================

app.set(
  "trust proxy",
  1
);



// =====================================
// ROUTE IMPORTS
// =====================================

const authRoutes =
  require("./auth/auth.routes");

const rfidRoutes =
  require("./rfid/rfid.routes");

const phoneRoutes =
  require("./phone/phone.routes");

const trackingRoutes =
  require("./tracking/tracking.routes");

const citizenRoutes =
  require("./citizen/citizen.routes");

const remarksRoutes =
  require("./remarks/remarks.routes");

const surveyRoutes =
  require("./survey/survey.routes");

const masterRoutes =
  require("./master/master.routes");



// =====================================
// REDIS IMPORTS
// =====================================

const {
  connectRedis,
} = require("./config/redis");

const redisTestRoute =
  require("./test/redis.test.route");



// =====================================
// MIDDLEWARE IMPORTS
// =====================================

const loggerMiddleware =
  require(
    "./middleware/logger.middleware"
  );

const errorMiddleware =
  require(
    "./middleware/error.middleware"
  );



// =====================================
// CONNECT REDIS
// =====================================

connectRedis().catch(
  console.error
);



// =====================================
// SECURITY MIDDLEWARE
// =====================================

app.use(
  helmet()
);



// =====================================
// GLOBAL RATE LIMITER
// =====================================

app.use(
  globalLimiter
);



// =====================================
// COMPRESSION MIDDLEWARE
// =====================================

app.use(
  compression({

    level: 6,

    threshold: 1024,

  })
);



// =====================================
// CORS CONFIGURATION
// =====================================

app.use(
  cors({

    origin: "*",

    methods: [
      "GET",
      "POST",
      "PUT",
      "DELETE",
      "PATCH",
    ],

    credentials: true,

  })
);



// =====================================
// BODY PARSER MIDDLEWARES
// =====================================

app.use(
  express.json({

    limit: "10mb",

  })
);



app.use(
  express.urlencoded({

    extended: true,

    limit: "10mb",

  })
);



// =====================================
// LOGGER MIDDLEWARE
// =====================================

app.use(
  loggerMiddleware
);



// =====================================
// REQUEST TIME LOGGER
// =====================================

app.use(
  (req, res, next) => {

    req.requestTime =
      new Date().toISOString();

    next();

  }
);



// =====================================
// HEALTH CHECK ROUTE
// =====================================

app.get(
  "/",
  (req, res) => {

    return res.status(200).json({

      success: true,

      message:
        "SEWAC Helper Backend Running Successfully",

      version: "1.0.0",

      timestamp:
        new Date().toISOString(),

      services: {

        api: true,

        socket: true,

        redis: true,

        database: true,

      },

    });

  }
);



// =====================================
// API VERSION PREFIX
// =====================================

const API_PREFIX =
  "/api/v1";



// =====================================
// REDIS TEST ROUTES
// =====================================

app.use(
  `${API_PREFIX}/test`,
  redisTestRoute
);



// =====================================
// AUTH ROUTES
// =====================================

app.use(
  `${API_PREFIX}/auth`,
  authRoutes
);



// =====================================
// RFID ROUTES
// =====================================

app.use(
  `${API_PREFIX}/rfid`,
  rfidRoutes
);



// =====================================
// PHONE ROUTES
// =====================================

app.use(
  `${API_PREFIX}/phone`,
  phoneRoutes
);



// =====================================
// TRACKING ROUTES
// =====================================

app.use(
  `${API_PREFIX}/tracking`,
  trackingRoutes
);



// =====================================
// CITIZEN ROUTES
// =====================================

app.use(
  `${API_PREFIX}/citizen`,
  citizenRoutes
);



// =====================================
// REMARKS ROUTES
// =====================================

app.use(
  `${API_PREFIX}/remarks`,
  remarksRoutes
);



// =====================================
// SURVEY ROUTES
// =====================================

app.use(
  `${API_PREFIX}/survey`,
  surveyRoutes
);



// =====================================
// MASTER ROUTES
// =====================================

app.use(
  `${API_PREFIX}/master`,
  masterRoutes
);



// =====================================
// 404 ROUTE HANDLER
// =====================================

app.use(
  (req, res) => {

    return res.status(404).json({

      success: false,

      message:
        "Route Not Found",

      path:
        req.originalUrl,

      method:
        req.method,

      timestamp:
        new Date().toISOString(),

    });

  }
);



// =====================================
// GLOBAL ERROR HANDLER
// =====================================

app.use(
  errorMiddleware
);



// =====================================
// EXPORT APP
// =====================================

module.exports =
  app;