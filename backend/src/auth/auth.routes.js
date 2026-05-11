const express = require("express");

const router = express.Router();

const { login } = require("./auth.controller");



// Login Route
router.post("/auth/login", login);



module.exports = router;