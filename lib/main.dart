import 'package:flutter/material.dart';
import 'splashscreen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cash In-Out',
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
