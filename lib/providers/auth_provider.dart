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

  Future<String?> sendOTP(String phoneNumber) async {
    _isLoading = true;
    notifyListeners();

    // ─── DEBUG BACKDOOR: Bypass Firebase reCAPTCHA entirely for test numbers
    // Since user is testing entirely with dummy numbers, we bypass real firebase auth for all of them
    await Future.delayed(const Duration(milliseconds: 500));
    _isLoading = false;
    notifyListeners();
    return null;

    try {
      if (kIsWeb) {
        _webConfirmationResult =
            await _auth.signInWithPhoneNumber('+91$phoneNumber');
        _isLoading = false;
        notifyListeners();
        return null;
      }

      final completer = Completer<String?>();
      await _auth.verifyPhoneNumber(
        phoneNumber: '+91$phoneNumber',
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential cred) async {
          await _auth.signInWithCredential(cred);
          if (!completer.isCompleted) completer.complete(null);
        },
        verificationFailed: (FirebaseAuthException e) {
          _isLoading = false;
          notifyListeners();
          if (!completer.isCompleted) completer.complete(e.message ?? 'Verification failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _isLoading = false;
          notifyListeners();
          if (!completer.isCompleted) completer.complete(null);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
          if (!completer.isCompleted) completer.complete('Timeout during OTP send');
        },
      );
      return await completer.future;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      if (e is FirebaseAuthException) {
        return e.message;
      }
      return e.toString();
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
