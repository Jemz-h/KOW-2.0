import 'package:flutter/material.dart';

import 'screens/start_screen.dart';

void main() {
  runApp(const MyApp());
}

/// App root widget that wires theme and landing screen.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(useMaterial3: true);
    return MaterialApp(
      // Uncomment the comment below to remove the debug ribbon on the upper right
      // debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'SuperCartoon',
        useMaterial3: true,
        textTheme: baseTheme.textTheme.apply(fontFamily: 'SuperCartoon'),
        primaryTextTheme: baseTheme.textTheme.apply(fontFamily: 'SuperCartoon'),
      ),
      home: const StartScreen(),
    );
  }
}
