import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
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

  void verifyOTP() {
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
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // Logo
              Image.asset(
                'assets/images/logo1.png',
                height: 130,
                errorBuilder:
                    (context, error, stackTrace) => const SizedBox(height: 130),
              ),

              const SizedBox(height: 20),

              const Text(
                'Verify OTP',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              const Text(
                'Enter the 6-digit OTP sent to your number',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                  fontFamily: 'Inter',
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // OTP Input Field with Toggle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F4),
                  borderRadius: BorderRadius.circular(14),
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
                    border: InputBorder.none,
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
                        color: Colors.blue,
                      ),
                    ),
                  )
                  : Text(
                    "Resend code in 00:${_secondsRemaining.toString().padLeft(2, '0')}",
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),

              const SizedBox(height: 32),

              // Login Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: verifyOTP,
                  icon: const Icon(Icons.login_rounded),
                  label: const Text(
                    "Login",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Register Text
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don’t have an account yet? ",
                    style: TextStyle(color: Colors.black),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "Register",
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
