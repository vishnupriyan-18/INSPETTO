import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/firebase_service.dart';

class NotificationProvider extends ChangeNotifier {
  final FirestoreService _fs = FirestoreService();

  Stream<List<NotificationModel>> notificationsStream(String userId) =>
      _fs.getNotifications(userId);

  Stream<int> unreadCountStream(String userId) =>
      _fs.getUnreadNotificationCount(userId);

  Future<void> markRead(String notifId) async {
    await _fs.markNotificationRead(notifId);
  }
}
