const express = require("express");

const router = express.Router();

const {

  getMasterData,

  getMasterDataByPhone,

  getMasterDataBySLNO,

} = require("./master.controller");





/*
|--------------------------------------------------------------------------
| DEBUG LOG
|--------------------------------------------------------------------------
*/
console.log({

  getMasterData,

  getMasterDataByPhone,

  getMasterDataBySLNO,

});





/*
|--------------------------------------------------------------------------
| Get All Master Data
|--------------------------------------------------------------------------
| GET /api/v1/master
|--------------------------------------------------------------------------
*/
router.get(
  "/",
  getMasterData
);





/*
|--------------------------------------------------------------------------
| Get Master Data By Phone Number
|--------------------------------------------------------------------------
| GET /api/v1/master/phone/:phoneNumber
|--------------------------------------------------------------------------
*/
router.get(
  "/phone/:phoneNumber",
  getMasterDataByPhone
);





/*
|--------------------------------------------------------------------------
| Get Master Data By SLNO
|--------------------------------------------------------------------------
| GET /api/v1/master/slno/:slno
|--------------------------------------------------------------------------
*/
router.get(
  "/slno/:slno",
  getMasterDataBySLNO
);





module.exports = router;