const express = require("express");
const cors = require("cors");



// =============================
// ROUTE IMPORTS
// =============================

const rfidRoutes = require("./routes/rfid.routes");

const phoneRoutes = require("./routes/phone.routes");

const authRoutes = require("./auth/auth.routes");

const trackingRoutes = require("./tracking/tracking.routes");

const citizenRoutes = require("./citizen/citizen.routes");



// =============================
// MIDDLEWARE IMPORTS
// =============================

const loggerMiddleware = require("./middleware/logger.middleware");

const errorMiddleware = require("./middleware/error.middleware");



const app = express();



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
  });

});



// =============================
// API ROUTES
// =============================

// Authentication
app.use("/api", authRoutes);


// RFID Mapping
app.use("/api", rfidRoutes);


// Phone Mapping
app.use("/api", phoneRoutes);


// Tracking Logs
app.use("/api", trackingRoutes);


// Citizen External Lookup
app.use("/api", citizenRoutes);



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