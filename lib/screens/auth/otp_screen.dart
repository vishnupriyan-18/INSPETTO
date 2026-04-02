import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../services/notification_service.dart';
import '../../services/firebase_service.dart';
import '../admin/admin_main_screen.dart';
import '../hod/hod_main_screen.dart';
import '../field_officer/officer_main_screen.dart';
import '../collector/collector_main_screen.dart';

class OtpScreen extends StatefulWidget {
  final UserModel employeeData;
  const OtpScreen({super.key, required this.employeeData});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.length != 6) {
      _snack('Enter 6-digit OTP', Colors.red);
      return;
    }
    setState(() => _isLoading = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final verified = await auth.verifyOTP(_otpController.text.trim());

    if (!mounted) return;

    if (!verified) {
      setState(() => _isLoading = false);
      _snack('Invalid OTP. Try again.', Colors.red);
      return;
    }

    // Build UserModel from Firestore data
    final user = widget.employeeData;

    // Save FCM token
    try {
      final token = await NotificationService().getFcmToken();
      if (token != null) {
        await FirestoreService().updateFcmToken(user.employeeId, token);
      }
    } catch (e) {
      print('FCM Token fetch failed (safe to ignore on web): $e');
    }

    await auth.saveSession(user);

    setState(() => _isLoading = false);
    if (!mounted) return;

    _navigateByRole(user.role);
  }

  void _navigateByRole(String role) {
    Widget screen;
    switch (role) {
      case 'it_admin':
        screen = const AdminMainScreen();
        break;
      case 'hod':
        screen = const HodMainScreen();
        break;
      case 'field_officer':
        screen = const OfficerMainScreen();
        break;
      case 'collector':
        screen = const CollectorMainScreen();
        break;
      default:
        _snack('Unknown role: $role', Colors.red);
        return;
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => screen),
      (route) => false,
    );
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    final phone = widget.employeeData.phone;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('OTP Verification',
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 8),
              Text('Enter the 6-digit code sent to +91 $phone',
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 40),
              PinCodeTextField(
                appContext: context,
                length: 6,
                controller: _otpController,
                keyboardType: TextInputType.number,
                animationType: AnimationType.fade,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(10),
                  fieldHeight: 56,
                  fieldWidth: 46,
                  activeFillColor: Colors.white,
                  activeColor: Colors.black,
                  selectedColor: Colors.black,
                  inactiveColor: Colors.grey.shade300,
                ),
                onChanged: (_) {},
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _verifyOTP,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Verify & Login',
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
