const {

  loginService,

  logoutService,

} = require("./auth.service");



// =====================================
// LOGIN CONTROLLER
// =====================================

const login =
  async (req, res) => {

    try {

      // =====================================
      // EXTRACT BODY
      // =====================================

      const {

        username,

        password,

      } = req.body;



      // =====================================
      // VALIDATION
      // =====================================

      if (
        !username ||
        !password
      ) {

        return res.status(400).json({

          success: false,

          message:
            "Username and password are required",

        });

      }



      // =====================================
      // LOGIN SERVICE
      // =====================================

      const result =
        await loginService(

          username,

          password
        );



      // =====================================
      // SUCCESS RESPONSE
      // =====================================

      return res.status(200).json({

        success: true,

        message:
          "Login successful",

        data: {

          token:
            result.token,

          moderator:
            result.moderator,

        },

      });

    } catch (error) {

      console.log(
        "LOGIN CONTROLLER ERROR:",
        error.message
      );



      return res.status(401).json({

        success: false,

        message:
          error.message,

      });

    }

  };



// =====================================
// LOGOUT CONTROLLER
// =====================================

const logout =
  async (req, res) => {

    try {

      // =====================================
      // CHECK AUTH USER
      // =====================================

      if (!req.user) {

        return res.status(401).json({

          success: false,

          message:
            "Unauthorized access",

        });

      }



      // =====================================
      // LOGOUT SERVICE
      // =====================================

      const result =
        await logoutService(

          req.user.id
        );



      // =====================================
      // SUCCESS RESPONSE
      // =====================================

      return res.status(200).json({

        success: true,

        message:
          result.message,

      });

    } catch (error) {

      console.log(
        "LOGOUT CONTROLLER ERROR:",
        error.message
      );



      return res.status(500).json({

        success: false,

        message:
          error.message,

      });

    }

  };



// =====================================
// EXPORTS
// =====================================

module.exports = {

  login,

  logout,

};