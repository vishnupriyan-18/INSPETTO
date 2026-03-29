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
      final String upperId = employeeId.toUpperCase();
      final String exactId = employeeId;

      Future<Map<String, dynamic>?> checkDb(String collectionName, String field, String defaultRole) async {
        QuerySnapshot q1 = await _firestore.collection(collectionName).where(field, isEqualTo: upperId).limit(1).get();
        Map<String, dynamic>? data;
        if (q1.docs.isNotEmpty) {
          data = q1.docs.first.data() as Map<String, dynamic>;
        } else {
          QuerySnapshot q2 = await _firestore.collection(collectionName).where(field, isEqualTo: exactId).limit(1).get();
          if (q2.docs.isNotEmpty) {
            data = q2.docs.first.data() as Map<String, dynamic>;
          }
        }
        
        if (data != null) {
          // Normalize data
          if (!data.containsKey('employeeId') && data.containsKey(field)) {
            data['employeeId'] = data[field];
          }
          if (!data.containsKey('role')) {
            data['role'] = defaultRole;
          }
          return data;
        }
        return null;
      }

      // Check employees
      Map<String, dynamic>? emp = await checkDb('employees', 'employeeId', 'field_officer');
      if (emp != null) return emp;

      // Check hods/hod
      Map<String, dynamic>? hod = await checkDb('hods', 'employeeId', 'hod');
      if (hod != null) return hod;
      hod = await checkDb('hod', 'employeeId', 'hod');
      if (hod != null) return hod;
      hod = await checkDb('hods', 'hodId', 'hod');
      if (hod != null) return hod;
      hod = await checkDb('hod', 'hodId', 'hod');
      if (hod != null) return hod;

      // Check collectors/collector
      Map<String, dynamic>? col = await checkDb('collectors', 'employeeId', 'collector');
      if (col != null) return col;
      col = await checkDb('collector', 'employeeId', 'collector');
      if (col != null) return col;
      col = await checkDb('collectors', 'collectorId', 'collector');
      if (col != null) return col;
      col = await checkDb('collector', 'collectorId', 'collector');
      if (col != null) return col;

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
