import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController phoneController = TextEditingController();

  void goToOTP() {
    final phone = phoneController.text.trim();

    if (phone.isEmpty ||
        phone.length != 10 ||
        !RegExp(r'^\d{10}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid 10-digit phone number')),
      );
      return;
    }

    String otp = (Random().nextInt(900000) + 100000).toString();
    OTPScreen.otpMap[phone] = otp;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('OTP sent! (Use $otp)')));

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OTPScreen(phone: phone)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // Bigger Logo
                Image.asset(
                  'assets/images/logo1.png',
                  height: 130,
                  errorBuilder:
                      (context, error, stackTrace) =>
                          const SizedBox(height: 130),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Welcome to Cash In-Out',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                const Text(
                  'Enter your phone number to continue',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                    fontFamily: 'Inter',
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Phone Number Field
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: InputDecoration(
                    hintText: 'Phone Number',
                    prefixIcon: const Icon(Icons.phone),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const Spacer(), // Pushes button toward the bottom
                // Generate OTP Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: goToOTP,
                    icon: const Icon(Icons.login),
                    label: const Text(
                      'Generate OTP',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A73E8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Register Text
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don’t have an account yet? "),
                    GestureDetector(
                      onTap: () {},
                      child: const Text(
                        "Register",
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.w500,
                          decoration:
                              TextDecoration
                                  .underline, // optional, to show it's clickable
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
