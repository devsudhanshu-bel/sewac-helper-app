const { loginService } = require("./auth.service");



const login = async (req, res) => {
  try {

    const { username, password } = req.body;



    if (!username || !password) {
      return res.status(400).json({
        success: false,
        message: "Username and password are required",
      });
    }



    const result = await loginService(
      username,
      password
    );



    return res.status(200).json({
      success: true,
      message: "Login successful",
      data: result,
    });

  } catch (error) {

    return res.status(401).json({
      success: false,
      message: error.message,
    });
  }
};





module.exports = {
  login,
};