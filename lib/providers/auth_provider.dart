import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _verificationId = '';
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ── Save login to phone locally ──
  Future<void> saveSession({
    required String employeeId,
    required String name,
    required String role,
    required String district,
    String? department,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('employeeId', employeeId);
    await prefs.setString('name', name);
    await prefs.setString('role', role);
    await prefs.setString('district', district);
    await prefs.setString('department', department ?? '');
    await prefs.setBool('isLoggedIn', true);
  }

  // ── Check if already logged in ──
  Future<Map<String, String>?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (!isLoggedIn) return null;
    return {
      'employeeId': prefs.getString('employeeId') ?? '',
      'name': prefs.getString('name') ?? '',
      'role': prefs.getString('role') ?? '',
      'district': prefs.getString('district') ?? '',
      'department': prefs.getString('department') ?? '',
    };
  }

  // ── Clear session on logout ──
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await _auth.signOut();
    notifyListeners();
  }

  // ── Fetch employee details from Firestore ──
  Future<Map<String, dynamic>?> getEmployeeDetails(String employeeId) async {
    try {
      // Check employees collection
      QuerySnapshot empQuery = await _firestore
          .collection('employees')
          .where('employeeId', isEqualTo: employeeId.toUpperCase())
          .limit(1)
          .get();

      if (empQuery.docs.isNotEmpty) {
        return empQuery.docs.first.data() as Map<String, dynamic>;
      }

      // Check hods collection
      QuerySnapshot hodQuery = await _firestore
          .collection('hods')
          .where('employeeId', isEqualTo: employeeId.toUpperCase())
          .limit(1)
          .get();

      if (hodQuery.docs.isNotEmpty) {
        return hodQuery.docs.first.data() as Map<String, dynamic>;
      }

      // Check collectors collection
      QuerySnapshot colQuery = await _firestore
          .collection('collectors')
          .where('employeeId', isEqualTo: employeeId.toUpperCase())
          .limit(1)
          .get();

      if (colQuery.docs.isNotEmpty) {
        return colQuery.docs.first.data() as Map<String, dynamic>;
      }

      return null;
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }

  // ── Send OTP ──
  Future<bool> sendOTP(String phoneNumber) async {
    try {
      _isLoading = true;
      notifyListeners();

      Completer<bool> completer = Completer<bool>();

      await _auth.verifyPhoneNumber(
        phoneNumber: '+91$phoneNumber',
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          if (!completer.isCompleted) completer.complete(true);
        },
        verificationFailed: (FirebaseAuthException e) {
          print('OTP Failed: ${e.code} - ${e.message}');
          _isLoading = false;
          notifyListeners();
          if (!completer.isCompleted) completer.complete(false);
        },
        codeSent: (String verificationId, int? resendToken) {
          print('OTP Sent Successfully!');
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
    } catch (e) {
      print('Send OTP Error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  // ── Verify OTP ──
  Future<bool> verifyOTP(String otp) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: otp,
      );
      await _auth.signInWithCredential(credential);
      return true;
    } catch (e) {
      print('OTP Verify Error: $e');
      return false;
    }
  }

  // ── Logout ──
  Future<void> logout(BuildContext context) async {
    await clearSession();
    notifyListeners();
  }
}
