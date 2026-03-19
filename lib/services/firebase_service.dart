// Firebase initialization and common Firebase operations
// Member 1 (Leader) implements this
import 'package:flutter/material.dart';

class FirebaseService {
  // TODO: upload photo to Firebase Storage
  Future<String?> uploadPhoto(dynamic imageFile, String path) async => null;

  // TODO: upload signature to Firebase Storage
  Future<String?> uploadSignature(dynamic signatureBytes, String path) async => null;

  // TODO: send push notification
  Future<void> sendNotification(String userId, String title, String body) async {}
}
