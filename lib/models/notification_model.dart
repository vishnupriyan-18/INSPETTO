import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String toUserId;
  final String taskId;
  final String title;
  final String message;
  final String type; // task_assigned | report_submitted | approved | rejected
  final bool isRead;
  final DateTime timestamp;

  NotificationModel({
    this.id = '',
    required this.toUserId,
    this.taskId = '',
    required this.title,
    required this.message,
    required this.type,
    this.isRead = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory NotificationModel.fromMap(Map<String, dynamic> map, String docId) {
    return NotificationModel(
      id: docId,
      toUserId: map['toUserId'] ?? '',
      taskId: map['taskId'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: map['type'] ?? '',
      isRead: map['isRead'] ?? false,
      timestamp: map['timestamp'] is Timestamp
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'toUserId': toUserId,
      'taskId': taskId,
      'title': title,
      'message': message,
      'type': type,
      'isRead': isRead,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
