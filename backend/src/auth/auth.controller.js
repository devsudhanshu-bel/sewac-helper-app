const {

  loginService,

  logoutService,

} = require("./auth.service");



// =====================================
// LOGIN
// =====================================

const login =
  async (req, res) => {

    try {

      const {
        username,
        password,
      } = req.body;



      // VALIDATION
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



      // LOGIN SERVICE
      const result =
        await loginService(

          username,

          password
        );



      return res.status(200).json({

        success: true,

        message:
          "Login successful",

        data:
          result,

      });

    } catch (error) {

      return res.status(401).json({

        success: false,

        message:
          error.message,

      });

    }

  };



// =====================================
// LOGOUT
// =====================================

const logout =
  async (req, res) => {

    try {

      const result =
        await logoutService(
          req.user.id
        );



      return res.status(200).json({

        success: true,

        message:
          result.message,

      });

    } catch (error) {

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