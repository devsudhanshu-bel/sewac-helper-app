const { prisma } = require("../config/db");

const bcrypt = require("bcryptjs");

const jwt = require("jsonwebtoken");



const loginService = async (username, password) => {

  // Check moderator
  const moderator = await prisma.moderator.findUnique({
    where: {
      username,
    },
  });



  if (!moderator) {
    throw new Error("Invalid username or password");
  }



  // Compare password
  const isPasswordValid = await bcrypt.compare(
    password,
    moderator.password
  );



  if (!isPasswordValid) {
    throw new Error("Invalid username or password");
  }



  // Generate JWT
  const token = jwt.sign(
    {
      id: moderator.id,
      username: moderator.username,
      role: moderator.role,
    },
    process.env.JWT_SECRET,
    {
      expiresIn: "7d",
    }
  );



  return {
    token,
    moderator: {
      id: moderator.id,
      username: moderator.username,
      role: moderator.role,
    },
  };
};





module.exports = {
  loginService,
};