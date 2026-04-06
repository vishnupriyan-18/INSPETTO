import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/user_model.dart';
import '../services/firebase_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _fs = FirestoreService();

  String _verificationId = '';
  ConfirmationResult? _webConfirmationResult;
  bool _isLoading = false;
  UserModel? _currentUser;

  bool get isLoading => _isLoading;
  UserModel? get currentUser => _currentUser;
  bool get isAdmin => _currentUser?.role == 'it_admin';
  bool get isHod => _currentUser?.role == 'hod';
  bool get isFo => _currentUser?.role == 'field_officer';
  bool get isCollector => _currentUser?.role == 'collector';

  // ── Fetch employee from Firestore (only employees collection) ──
  Future<UserModel?> getEmployeeDetails(String employeeId) async {
    return await _fs.getEmployeeById(employeeId);
  }

  Future<bool> sendOTP(String phoneNumber) async {
    _isLoading = true;
    notifyListeners();

    // ─── DEBUG BACKDOOR: Bypass Firebase reCAPTCHA entirely for test numbers
    if (phoneNumber.contains('8667337744') || 
        phoneNumber.contains('0000000000') ||
        phoneNumber.contains('9999999999') ||
        phoneNumber.contains('8888888888')) {
      await Future.delayed(const Duration(milliseconds: 800)); // Simulate delay
      _isLoading = false;
      notifyListeners();
      return true;
    }

    try {
      if (kIsWeb) {
        _webConfirmationResult =
            await _auth.signInWithPhoneNumber('+91$phoneNumber');
        _isLoading = false;
        notifyListeners();
        return true;
      }

      final completer = Completer<bool>();
      await _auth.verifyPhoneNumber(
        phoneNumber: '+91$phoneNumber',
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential cred) async {
          await _auth.signInWithCredential(cred);
          if (!completer.isCompleted) completer.complete(true);
        },
        verificationFailed: (FirebaseAuthException e) {
          _isLoading = false;
          notifyListeners();
          if (!completer.isCompleted) completer.complete(false);
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _isLoading = false;
          notifyListeners();
          if (!completer.isCompleted) completer.complete(true);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
          if (!completer.isCompleted) completer.complete(false);
        },
      );
      return await completer.future;
    } catch (_) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOTP(String otp) async {
    // ─── DEBUG BACKDOOR: Auto-accept dummy OTP for development
    if (otp == '123456' || otp == '111111' || otp == '000000') {
      await Future.delayed(const Duration(milliseconds: 800)); // Simulate delay
      return true;
    }

    try {
      if (kIsWeb) {
        if (_webConfirmationResult == null) return false;
        await _webConfirmationResult!.confirm(otp);
        return true;
      }

      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: otp,
      );
      await _auth.signInWithCredential(credential);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Save session ──
  Future<void> saveSession(UserModel user) async {
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('employeeId', user.employeeId);
    await prefs.setString('name', user.name);
    await prefs.setString('role', user.role);
    await prefs.setString('designation', user.designation);
    await prefs.setString('district', user.district);
    await prefs.setString('department', user.department);
    await prefs.setString('hodId', user.hodId);
    await prefs.setBool('isLoggedIn', true);
    notifyListeners();
  }

  // ── Restore session on launch ──
  Future<UserModel?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (!isLoggedIn) return null;
    final employeeId = prefs.getString('employeeId') ?? '';
    if (employeeId.isEmpty) return null;
    final user = UserModel(
      employeeId: employeeId,
      name: prefs.getString('name') ?? '',
      phone: '',
      role: prefs.getString('role') ?? '',
      designation: prefs.getString('designation') ?? '',
      department: prefs.getString('department') ?? '',
      district: prefs.getString('district') ?? '',
      hodId: prefs.getString('hodId') ?? '',
    );
    _currentUser = user;
    notifyListeners();
    return user;
  }

  // ── Logout ──
  Future<void> logout(BuildContext context) async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await _auth.signOut();
    notifyListeners();
  }
}
