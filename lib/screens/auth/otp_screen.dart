import 'package:flutter/material.dart';
import 'package:inspetto/providers/auth_provider.dart';
import 'package:inspetto/screens/collector/collector_main_screen.dart';
import 'package:inspetto/screens/field_officer/officer_main_screen.dart';
import 'package:inspetto/screens/hod/hod_main_screen.dart';
import 'package:inspetto/themes/app_colors.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';

class OtpScreen extends StatefulWidget {
  final Map<String, dynamic> employeeData;
  const OtpScreen({super.key, required this.employeeData});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  String _otp = '';
  bool _isLoading = false;

  void _verifyOTP() async {
    if (_otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter 6 digit OTP')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final verified = await authProvider.verifyOTP(_otp);

    if (verified) {
      await authProvider.saveSession(
        employeeId: widget.employeeData['employeeId'],
        name: widget.employeeData['name'],
        role: widget.employeeData['role'],
        district: widget.employeeData['district'],
        department: widget.employeeData['department'] ?? '',
      );

      final role = widget.employeeData['role'];
      if (!mounted) return;

      Widget screen;
      if (role == 'field_officer') {
        screen = OfficerMainScreen(
          officerId: widget.employeeData['employeeId'],
          officerName: widget.employeeData['name'],
        );
      } else if (role == 'hod') {
        screen = HodMainScreen(
          hodId: widget.employeeData['employeeId'],
          hodName: widget.employeeData['name'],
        );
      } else {
        screen = CollectorMainScreen(
          collectorId: widget.employeeData['employeeId'],
          collectorName: widget.employeeData['name'],
        );
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => screen),
        (route) => false,
      );
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid OTP! Try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Verify OTP'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sms_outlined, size: 60, color: Colors.black),
            const SizedBox(height: 20),
            const Text(
              'OTP Sent!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter the OTP sent to your registered phone number',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 40),
            PinCodeTextField(
              appContext: context,
              length: 6,
              onChanged: (value) => _otp = value,
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(8),
                fieldHeight: 50,
                fieldWidth: 45,
                activeFillColor: Colors.white,
                inactiveFillColor: Colors.white,
                selectedFillColor: Colors.white,
                activeColor: Colors.black,
                inactiveColor: Colors.grey,
                selectedColor: Colors.black,
              ),
              enableActiveFill: true,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isLoading ? null : _verifyOTP,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Verify OTP',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
