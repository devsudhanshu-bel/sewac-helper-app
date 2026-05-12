import 'package:flutter/material.dart';
import 'login_screen.dart';

class ReaderScreen
    extends StatefulWidget {

  const ReaderScreen({
    super.key,
  });

  @override
  State<ReaderScreen>
  createState() =>
      _ReaderScreenState();
}

class _ReaderScreenState
    extends State<
        ReaderScreen> {

  @override
  Widget build(
      BuildContext context) {

    return Scaffold(

      backgroundColor:
      const Color(
          0xFFF8F9FA),

      appBar:
      AppBar(

        backgroundColor:
        Colors.white,

        elevation: 0,

        centerTitle:
        true,

        leading:
        Padding(

          padding:
          const EdgeInsets.only(
              left: 16),

          child:
          Image.asset(

            "assets/images/logo.png",

            errorBuilder:
                (
                context,
                error,
                stackTrace,
                ) {

              return const Icon(

                Icons.recycling,

                color:
                Color(
                    0xFF4CAF50),
              );
            },
          ),
        ),

        title:
        const Text(

          "SEWAC Helper",

          style:
          TextStyle(

            color:
            Color(
                0xFF1A237E),

            fontWeight:
            FontWeight.w900,

            fontSize: 20,
          ),
        ),

        actions: [

          IconButton(

            icon:
            const Icon(

              Icons
                  .logout_rounded,

              color:
              Color(
                  0xFF1A237E),
            ),

            onPressed: () {

              Navigator.pushReplacement(

                context,

                MaterialPageRoute(

                  builder:
                      (_) =>
                  const LoginScreen(),
                ),
              );
            },
          ),
        ],
      ),

      body:
      Padding(

        padding:
        const EdgeInsets.all(
            24),

        child:
        Column(

          crossAxisAlignment:
          CrossAxisAlignment
              .start,

          children: [

            const Text(

              "Reader",

              style:
              TextStyle(

                fontSize:
                28,

                fontWeight:
                FontWeight.bold,

                color:
                Color(
                    0xFF2C3E50),
              ),
            ),

            const SizedBox(
              height: 32,
            ),

            Container(

              width:
              double.infinity,

              padding:
              const EdgeInsets.all(
                  24),

              decoration:
              BoxDecoration(

                color:
                Colors.white,

                borderRadius:
                BorderRadius.circular(
                    28),
              ),

              child:
              Column(

                children: [

                  const Icon(

                    Icons
                        .nfc_rounded,

                    size:
                    64,

                    color:
                    Color(
                        0xFF4CAF50),
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  const Text(

                    "Tap RFID Card",

                    style:
                    TextStyle(

                      fontSize:
                      18,

                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  TextFormField(

                    autofocus:
                    true,

                    showCursor:
                    true,

                    decoration:
                    InputDecoration(

                      hintText:
                      "Tap RFID card to scan...",

                      hintStyle:
                      const TextStyle(

                        color:
                        Colors.grey,
                      ),

                      filled:
                      true,

                      fillColor:
                      Colors.white,

                      contentPadding:
                      const EdgeInsets.symmetric(

                        horizontal:
                        16,

                        vertical:
                        16,
                      ),

                      border:
                      OutlineInputBorder(

                        borderRadius:
                        BorderRadius.circular(
                            16),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  SizedBox(

                    width:
                    double.infinity,

                    child:
                    Container(

                      decoration:
                      BoxDecoration(

                        borderRadius:
                        BorderRadius.circular(
                            16),

                        gradient:
                        const LinearGradient(

                          colors: [

                            Color(
                                0xFFFFA000),

                            Color(
                                0xFF4CAF50),
                          ],
                        ),

                        boxShadow: [

                          BoxShadow(

                            color:
                            Colors.green
                                .withOpacity(
                                0.18),

                            blurRadius:
                            16,

                            offset:
                            const Offset(
                                0, 6),
                          ),
                        ],
                      ),

                      child:
                      ElevatedButton(

                        onPressed:
                            () {

                          ScaffoldMessenger.of(
                              context)
                              .showSnackBar(

                            const SnackBar(

                              backgroundColor:
                              Color(
                                  0xFF4CAF50),

                              content:
                              Text(
                                  "RFID saved successfully"),
                            ),
                          );
                        },

                        style:
                        ElevatedButton.styleFrom(

                          backgroundColor:
                          Colors.transparent,

                          shadowColor:
                          Colors.transparent,

                          padding:
                          const EdgeInsets.symmetric(
                              vertical:
                              16),

                          shape:
                          RoundedRectangleBorder(

                            borderRadius:
                            BorderRadius.circular(
                                16),
                          ),
                        ),

                        child:
                        const Text(

                          "SAVE",

                          style:
                          TextStyle(

                            color:
                            Colors.white,

                            fontSize:
                            15,

                            fontWeight:
                            FontWeight.bold,

                            letterSpacing:
                            0.8,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}