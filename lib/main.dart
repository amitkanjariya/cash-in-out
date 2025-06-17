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
      theme: ThemeData(
        primarySwatch: MaterialColor(0xFF468585, {
          50: Color(0xFFE1EBEB),
          100: Color(0xFFB3CCCC),
          200: Color(0xFF80AAAA),
          300: Color(0xFF4D8888),
          400: Color(0xFF266F6F),
          500: Color(0xFF468585),
          600: Color(0xFF3F7D7D),
          700: Color(0xFF367272),
          800: Color(0xFF2E6868),
          900: Color(0xFF1F5555),
        }),
        inputDecorationTheme: InputDecorationTheme(
          border: const OutlineInputBorder(),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF468585), width: 1.5),
          ),
          floatingLabelStyle: MaterialStateTextStyle.resolveWith((states) {
            if (states.contains(MaterialState.focused)) {
              return const TextStyle(color: Color(0xFF468585));
            }
            return const TextStyle(color: Colors.grey);
          }),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
