const express = require("express");

const cors = require("cors");

const compression = require("compression");

const helmet = require("helmet");



// =============================
// APP INITIALIZATION
// =============================

const app = express();



// =============================
// ROUTE IMPORTS
// =============================

const upload =
  require("../middlewares/cloudinary.middleware");

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


// =============================
// REDIS IMPORTS
// =============================

const {
  connectRedis,
} = require("./config/redis");

const redisTestRoute =
  require("./test/redis.test.route");

// =============================
// REDIS CONNECTION
// =============================

connectRedis().catch(console.error);

// =============================
// MIDDLEWARE IMPORTS
// =============================

const loggerMiddleware =
  require("./middleware/logger.middleware");

const errorMiddleware =
  require("./middleware/error.middleware");



// =============================
// SECURITY MIDDLEWARES
// =============================

app.use(helmet());



// =============================
// CORS CONFIGURATION
// =============================

app.use(cors({

  origin: "*",

  methods: [
    "GET",
    "POST",
    "PUT",
    "DELETE",
    "PATCH",
  ],

  credentials: true,

}));



// =============================
// COMPRESSION MIDDLEWARE
// =============================

app.use(compression({

  level: 6,

  threshold: 1024,

}));



// =============================
// BODY PARSER MIDDLEWARES
// =============================

app.use(express.json({

  limit: "10mb",

}));



app.use(express.urlencoded({

  extended: true,

  limit: "10mb",

}));



// =============================
// LOGGER MIDDLEWARE
// =============================

app.use(loggerMiddleware);



// =============================
// REQUEST TIME LOGGER
// =============================

app.use((req, res, next) => {

  req.requestTime =
    new Date().toISOString();

  next();

});



// =============================
// HEALTH CHECK ROUTE
// =============================

app.get("/", (req, res) => {

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

});



// =============================
// API VERSION PREFIX
// =============================

const API_PREFIX = "/api/v1";



// =============================
// API ROUTES
// =============================


/*
|--------------------------------------------------------------------------
| Redis Test Routes
|--------------------------------------------------------------------------
*/
app.use(
  "/api/v1/test",
  redisTestRoute
);



/*
|--------------------------------------------------------------------------
| Authentication Routes
|--------------------------------------------------------------------------
*/
app.use(
  `${API_PREFIX}/auth`,
  authRoutes
);




/*
|--------------------------------------------------------------------------
| RFID Routes
|--------------------------------------------------------------------------
*/
app.use(
  `${API_PREFIX}/rfid`,
  rfidRoutes
);




/*
|--------------------------------------------------------------------------
| Phone Routes
|--------------------------------------------------------------------------
*/
app.use(
  `${API_PREFIX}/phone`,
  phoneRoutes
);




/*
|--------------------------------------------------------------------------
| Tracking Routes
|--------------------------------------------------------------------------
*/
app.use(
  `${API_PREFIX}/tracking`,
  trackingRoutes
);




/*
|--------------------------------------------------------------------------
| Citizen Routes
|--------------------------------------------------------------------------
*/
app.use(
  `${API_PREFIX}/citizen`,
  citizenRoutes
);




/*
|--------------------------------------------------------------------------
| Remarks Routes
|--------------------------------------------------------------------------
*/
app.use(
  `${API_PREFIX}/remarks`,
  remarksRoutes
);




/*
|--------------------------------------------------------------------------
| Survey Routes
|--------------------------------------------------------------------------
*/
app.use(
  `${API_PREFIX}/survey`,
  surveyRoutes
);

app.use(
  `${API_PREFIX}/master`,
  masterRoutes
);

// =============================
// 404 ROUTE HANDLER
// =============================

app.use((req, res) => {

  return res.status(404).json({

    success: false,

    message: "Route Not Found",

    path: req.originalUrl,

    method: req.method,

    timestamp:
      new Date().toISOString(),

  });

});



// =============================
// GLOBAL ERROR HANDLER
// =============================

app.use(errorMiddleware);



// =============================
// EXPORT APP
// =============================

module.exports = app;