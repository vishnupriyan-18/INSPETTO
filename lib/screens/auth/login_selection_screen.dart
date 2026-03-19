import 'package:flutter/material.dart';
import 'package:inspetto/providers/auth_provider.dart';
import 'package:inspetto/screens/auth/otp_screen.dart';
import 'package:inspetto/themes/app_colors.dart';
import 'package:provider/provider.dart';

class LoginSelectionScreen extends StatefulWidget {
  const LoginSelectionScreen({super.key});

  @override
  State<LoginSelectionScreen> createState() => _LoginSelectionScreenState();
}

class _LoginSelectionScreenState extends State<LoginSelectionScreen> {
  final TextEditingController _empIdController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _empIdController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_empIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter Employee ID'),
          backgroundColor: Colors.black,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    print('Step 1 - Looking for employee: ${_empIdController.text.trim()}');

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final employeeData = await authProvider.getEmployeeDetails(
      _empIdController.text.trim(),
    );

    print('Step 2 - Employee data: $employeeData');

    if (employeeData == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Employee ID not found!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('Step 3 - Sending OTP to: ${employeeData['phone']}');

    final otpSent = await authProvider.sendOTP(employeeData['phone']);

    print('Step 4 - OTP sent: $otpSent');

    setState(() => _isLoading = false);

    if (otpSent) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpScreen(
            employeeData: employeeData,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send OTP. Try again!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo
              Center(
                child: Image.asset(
                  'assets/logo.png',
                  height: 80,
                ),
              ),
              const SizedBox(height: 30),

              // Title
              const Center(
                child: Text(
                  'INSPETTO',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    letterSpacing: 4,
                  ),
                ),
              ),
              const Center(
                child: Text(
                  'Field Visit Inspection System',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 60),

              // Employee ID label
              const Text(
                'Employee ID',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),

              // Employee ID field
              TextField(
                controller: _empIdController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'Enter your Employee ID',
                  hintStyle: const TextStyle(color: AppColors.textHint),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Colors.black, width: 2),
                  ),
                  prefixIcon:
                      const Icon(Icons.badge_outlined, color: Colors.black),
                ),
              ),
              const SizedBox(height: 24),

              // Login button
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
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Send OTP',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 30),

              // Footer
              const Center(
                child: Text(
                  'Government of Tamil Nadu',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
