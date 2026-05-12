require("dotenv").config();

const http = require("http");

const { Server } = require("socket.io");

const app = require("./app");

const { connectDB } =
  require("./config/db");

const {
  connectRedis,
} = require("./config/redis");



// =====================================
// PORT
// =====================================

const PORT =
  process.env.PORT || 5000;



// =====================================
// CREATE HTTP SERVER
// =====================================

const server =
  http.createServer(app);



// =====================================
// INITIALIZE SOCKET.IO
// =====================================

const io =
  new Server(server, {

    cors: {

      origin: "*",

      methods: [
        "GET",
        "POST",
        "PUT",
        "DELETE",
      ],

    },

});



// =====================================
// SOCKET CONNECTION
// =====================================

io.on(
  "connection",
  (socket) => {

    console.log(
      "================================="
    );

    console.log(
      " SOCKET CONNECTED"
    );

    console.log(
      ` Socket ID : ${socket.id}`
    );

    console.log(
      "================================="
    );



    // =====================================
    // TEST EVENT
    // =====================================

    socket.on(
      "ping-server",
      (data) => {

        console.log(
          " Ping Received :",
          data
        );

        socket.emit(
          "pong-server",
          {

            success: true,

            message:
              "Server received ping",

          }
        );

      }
    );



    // =====================================
    // JOIN ADMIN ROOM
    // =====================================

    socket.on(
      "join-admin-room",
      () => {

        socket.join("admins");

        console.log(
          `${socket.id} joined admins room`
        );

      }
    );



    // =====================================
    // JOIN DEVICE ROOM
    // =====================================

    socket.on(
      "join-device-room",
      () => {

        socket.join("devices");

        console.log(
          `${socket.id} joined devices room`
        );

      }
    );



    // =====================================
    // DISCONNECT EVENT
    // =====================================

    socket.on(
      "disconnect",
      () => {

        console.log(
          "================================="
        );

        console.log(
          " SOCKET DISCONNECTED"
        );

        console.log(
          ` Socket ID : ${socket.id}`
        );

        console.log(
          "================================="
        );

      }
    );

});



// =====================================
// MAKE SOCKET AVAILABLE GLOBALLY
// =====================================

global.io = io;



// =====================================
// START SERVER
// =====================================

const startServer =
  async () => {

    try {

      console.log(
        "================================="
      );

      console.log(
        " STARTING SEWAC SERVER"
      );

      console.log(
        "================================="
      );



      // =====================================
      // CONNECT MAIN DATABASE
      // =====================================

      await connectDB();



      // =====================================
      // CONNECT REDIS (OPTIONAL)
      // =====================================

      if (
        process.env.REDIS_URL_ENABLED
        === "true"
      ) {

        await connectRedis();

      }



      // =====================================
      // START EXPRESS + SOCKET SERVER
      // =====================================

      server.listen(
        PORT,
        () => {

          console.log(
            "================================="
          );

          console.log(
            " SEWAC Helper Backend Running"
          );

          console.log(
            ` Server Port : ${PORT}`
          );

          console.log(
            " Socket.IO Enabled"
          );

          console.log(
            "================================="
          );

        }
      );

    } catch (error) {

      console.error(
        "================================="
      );

      console.error(
        " SERVER START FAILED"
      );

      console.error(
        error.message
      );

      console.error(
        "================================="
      );

      process.exit(1);

    }

};



// =====================================
// HANDLE UNCAUGHT ERRORS
// =====================================

process.on(
  "uncaughtException",
  (error) => {

    console.error(
      "================================="
    );

    console.error(
      " UNCAUGHT EXCEPTION"
    );

    console.error(
      error.message
    );

    console.error(
      "================================="
    );

});



process.on(
  "unhandledRejection",
  (error) => {

    console.error(
      "================================="
    );

    console.error(
      " UNHANDLED PROMISE REJECTION"
    );

    console.error(
      error.message
    );

    console.error(
      "================================="
    );

});



// =====================================
// START APPLICATION
// =====================================

startServer();