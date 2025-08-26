import 'dart:async';
import 'dart:math';

import 'package:cashinout/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // ✅ Added import

import 'homepage.dart';

class OTPScreen extends StatefulWidget {
  final String phone;
  const OTPScreen({super.key, required this.phone});
  static final Map<String, String> otpMap = {};

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final List<TextEditingController> otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  late Timer _timer;
  int _secondsRemaining = 30;
  bool _expired = false;
  bool _obscureOtp = true;
  String fullOtp = "";

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _secondsRemaining = 30;
    _expired = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _expired = true;
          _timer.cancel();
        }
      });
    });
  }

  void _resendOTP() {
    setState(() {
      for (var controller in otpControllers) {
        controller.clear();
      }
      String newOtp = (Random().nextInt(900000) + 100000).toString();
      OTPScreen.otpMap[widget.phone] = newOtp;
      _startTimer();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('OTP resent! (Use ${OTPScreen.otpMap[widget.phone]})'),
      ),
    );
  }

  void verifyOTP() async {
    String enteredOtp = fullOtp;
    String? correctOtp = OTPScreen.otpMap[widget.phone];

    if (enteredOtp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a 6-digit OTP')),
      );
      return;
    }

    if (_expired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP expired. Please resend.')),
      );
      return;
    }

    if (enteredOtp == correctOtp) {
      OTPScreen.otpMap.remove(widget.phone);
      await savePhoneNumber(widget.phone);

      // ✅ Save login status and phone using SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('phone', widget.phone);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP. Please try again.')),
      );
    }
  }

  Future<void> savePhoneNumber(String phone) async {
    try {
      print('Posting to: ${Constants.baseUrl}/login');
      print('Sending phone: $phone');
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/login'),
        body: {'phone': phone},
      );
      if (response.statusCode == 200) {
        print('Phone number saved. ${response.body}');
      } else {
        print('Failed to save number. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    for (var c in otpControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Image.asset('assets/images/logo_cashinout1.png', height: 130),
                const SizedBox(height: 20),
                const Text(
                  'Verify OTP',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Enter the 6-digit OTP sent to your number',
                  style: TextStyle(fontSize: 15, color: Colors.black54),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F4F4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    obscureText: _obscureOtp,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      counterText: "",
                      hintText: "OTP",
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: Colors.grey,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureOtp
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureOtp = !_obscureOtp;
                          });
                        },
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 18),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                    ),
                    onChanged: (value) {
                      fullOtp = value;
                      if (value.length == 6) {
                        for (int i = 0; i < 6; i++) {
                          otpControllers[i].text = value[i];
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(height: 10),
                _expired
                    ? TextButton(
                      onPressed: _resendOTP,
                      child: const Text(
                        "Resend OTP?",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF468585),
                        ),
                      ),
                    )
                    : Text(
                      "Resend code in 00:${_secondsRemaining.toString().padLeft(2, '0')}",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: verifyOTP,
                    icon: const Icon(Icons.login_rounded),
                    label: const Text(
                      "Login",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      backgroundColor: const Color(0xFF468585),
                      foregroundColor: Colors.white,
                    ),
                  ),
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
