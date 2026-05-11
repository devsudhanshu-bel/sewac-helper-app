const express = require("express");
const cors = require("cors");



// =============================
// APP INITIALIZATION
// =============================

const app = express();



// =============================
// ROUTE IMPORTS
// =============================

const authRoutes = require("./auth/auth.routes");

const rfidRoutes = require("./rfid/rfid.routes");

const phoneRoutes = require("./phone/phone.routes");

const trackingRoutes = require("./tracking/tracking.routes");

const citizenRoutes = require("./citizen/citizen.routes");

const remarksRoutes = require("./remarks/remarks.routes");



// =============================
// MIDDLEWARE IMPORTS
// =============================

const loggerMiddleware =
  require("./middleware/logger.middleware");

const errorMiddleware =
  require("./middleware/error.middleware");



// =============================
// GLOBAL MIDDLEWARES
// =============================

app.use(cors());

app.use(express.json());

app.use(express.urlencoded({ extended: true }));



// =============================
// LOGGER MIDDLEWARE
// =============================

app.use(loggerMiddleware);



// =============================
// HEALTH CHECK ROUTE
// =============================

app.get("/", (req, res) => {

  return res.status(200).json({
    success: true,
    message: "SEWAC Helper Backend Running Successfully",
    version: "1.0.0",
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



// =============================
// 404 ROUTE HANDLER
// =============================

app.use((req, res) => {

  return res.status(404).json({
    success: false,
    message: "Route Not Found",
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