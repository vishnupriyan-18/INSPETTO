// Handles OTP login and role detection
// Member 1 (Leader) implements this
import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  // TODO: implement OTP send
  Future<void> sendOTP(String phoneNumber) async {}

  // TODO: implement OTP verify
  Future<bool> verifyOTP(String otp) async => false;

  // TODO: get user role after login
  Future<String> getUserRole(String phone) async => '';

  // TODO: logout
  Future<void> logout(BuildContext context) async {}
}
