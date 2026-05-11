const errorMiddleware = (err, req, res, next) => {
  console.error("=================================");
  console.error("ERROR OCCURRED");
  console.error("Message :", err.message);
  console.error("Stack   :", err.stack);
  console.error("=================================");

  return res.status(err.status || 500).json({
    success: false,
    message: err.message || "Internal Server Error",
  });
};

module.exports = errorMiddleware;