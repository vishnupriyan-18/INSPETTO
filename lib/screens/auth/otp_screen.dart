// OTP verification screen
// Member 1 (Leader) implements this
import 'package:flutter/material.dart';

class OtpScreen extends StatelessWidget {
  final String phoneNumber;
  final String role;
  const OtpScreen({super.key, required this.phoneNumber, required this.role});

  @override
  Widget build(BuildContext context) {
    // TODO: implement OTP screen
    return const Scaffold(body: Center(child: Text('OTP Screen')));
  }
}
