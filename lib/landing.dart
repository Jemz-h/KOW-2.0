import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Uncomment the comment below to remove the debug ribbon on the upper right
      // debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;

            return Stack(
              children: [
                // Background
                Positioned.fill(
                  child: Image.asset(
                    "assets/images/bg_spc.png",
                    fit: BoxFit.cover,
                  ),
                ),

                // Logos
                Positioned(
                  top: h * 0.04,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset("assets/images/lg_sauyo.png", height: h * 0.1),
                      SizedBox(width: w * 0.03),
                      Image.asset("assets/images/lg_qcu.png", height: h * 0.1),
                      SizedBox(width: w * 0.03),
                      Image.asset("assets/images/lg_bctpoc.png", height: h * 0.1),
                    ],
                  ),
                ),

                // Title
                Positioned(
                  top: h * 0.17,
                  left: 20,
                  right: 20,
                  child: Text(
                    "KARUNUNGAN ON\nWHEELS",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "supercartoon",
                      fontSize: w * 0.11,
                      letterSpacing: 1,
                      color: Colors.white,
                      shadows: const [
                        Shadow(
                          blurRadius: 6,
                          color: Colors.black,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                ),

                // Subtitle
                Positioned(
                  top: h * 0.35,
                  left: 20,
                  right: 20,
                  child: Text(
                    "“ENHANCING FUNCTIONAL LITERACY THROUGH\nLOCALLY DEVELOPED INSTRUCTIONAL MATERIALS”",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "supercartoon",
                      fontSize: w * 0.035,
                      color: Colors.yellow,
                      letterSpacing: 1,
                      shadows: const [
                        Shadow(
                          blurRadius: 4,
                          color: Colors.black,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ),

                // Characters
                Positioned(
                  bottom: h * 0.10,
                  left: w * -0.1,
                  child: Image.asset(
                    "assets/images/oyo.png",
                    height: h * 0.5,
                  ),
                ),

                Positioned(
                  bottom: h * 0.12,
                  right: w * 0.03,
                  child: Image.asset(
                    "assets/images/sisa.png",
                    height: h * 0.35,
                  ),
                ),

                // Tap to start text
                Positioned(
                  bottom: h * 0.03,
                  left: 0,
                  right: 0,
                  child: Text(
                    "Tap anywhere to start",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "supercartoon",
                      fontSize: w * 0.045,
                      color: Colors.white,
                      shadows: const [
                        Shadow(
                          blurRadius: 4,
                          color: Colors.black,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
