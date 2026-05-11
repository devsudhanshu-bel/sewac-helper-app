const loggerMiddleware = (req, res, next) => {
  const currentTime = new Date().toISOString();

  console.log("===================================");
  console.log("Incoming Request");
  console.log("===================================");
  console.log("Time       :", currentTime);
  console.log("Method     :", req.method);
  console.log("URL        :", req.originalUrl);
  console.log("IP Address :", req.ip);
  console.log("Body       :", req.body);
  console.log("Params     :", req.params);
  console.log("===================================");

  next();
};

module.exports = loggerMiddleware;