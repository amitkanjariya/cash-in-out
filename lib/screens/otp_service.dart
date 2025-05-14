import 'dart:math';

class OTPService {
  static final Map<String, String> _otpMap = {};

  static String generateOTP(String phoneNumber) {
    final otp = _randomOTP();
    _otpMap[phoneNumber] = otp;
    return otp;
  }

  static bool verifyOTP(String phoneNumber, String enteredOTP) {
    return _otpMap[phoneNumber] == enteredOTP;
  }

  static void removeOTP(String phoneNumber) {
    _otpMap.remove(phoneNumber);
  }

  static String _randomOTP() {
    final random = Random();
    return List.generate(6, (_) => random.nextInt(10)).join();
  }
}
