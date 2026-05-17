const multer =
  require("multer");



// =====================================
// MEMORY STORAGE
// =====================================

const storage =
  multer.memoryStorage();



// =====================================
// FILE FILTER
// =====================================

const fileFilter =
  (
    req,
    file,
    cb
  ) => {

    const allowedMimeTypes = [

      "image/jpeg",

      "image/jpg",

      "image/png",

      "image/webp",

    ];



    if (

      allowedMimeTypes.includes(
        file.mimetype
      )

    ) {

      cb(
        null,
        true
      );

    } else {

      cb(

        new Error(
          "Only jpg, jpeg, png and webp images are allowed"
        ),

        false

      );

    }

  };



// =====================================
// MULTER CONFIG
// =====================================

const upload =
  multer({

    storage,



    limits: {

      fileSize:
        10 * 1024 * 1024,

    },



    fileFilter,

  });



// =====================================
// EXPORT
// =====================================

module.exports =
  upload;