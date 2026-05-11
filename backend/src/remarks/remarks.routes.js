const express = require("express");

const router = express.Router();

const {
  createRemark,
  getAllRemarks,
} = require("./remarks.controller");





/*
|--------------------------------------------------------------------------
| Create Remark
|--------------------------------------------------------------------------
| POST /api/v1/remarks/create
|--------------------------------------------------------------------------
*/
router.post("/create", createRemark);





/*
|--------------------------------------------------------------------------
| Get All Remarks
|--------------------------------------------------------------------------
| GET /api/v1/remarks
|--------------------------------------------------------------------------
*/
router.get("/", getAllRemarks);





module.exports = router;