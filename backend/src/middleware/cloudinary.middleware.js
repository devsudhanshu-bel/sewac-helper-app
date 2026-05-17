const multer =
  require("multer");

const {
  CloudinaryStorage,
} = require(
  "multer-storage-cloudinary"
);

const cloudinary =
  require("../config/cloudinary.config");



// =====================================
// CLOUDINARY STORAGE
// =====================================

const storage =
  new CloudinaryStorage({

    cloudinary,

    params: async (
      req,
      file
    ) => {

      return {

        folder:
          "sewac_logs",

        resource_type:
          "image",

        allowed_formats: [

          "jpg",

          "jpeg",

          "png",

          "webp",

        ],

      };

    },

  });



// =====================================
// MULTER UPLOAD
// =====================================

const upload =
  multer({

    storage,

    limits: {

      fileSize:
        10 * 1024 * 1024,

    },

  });



// =====================================
// EXPORT
// =====================================

module.exports =
  upload;