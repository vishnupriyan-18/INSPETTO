import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityLogModel {
  final String id;
  final String action;
  final String userId;
  final String taskId;
  final String visitId;
  final String remarks;
  final DateTime timestamp;

  ActivityLogModel({
    this.id = '',
    required this.action,
    required this.userId,
    this.taskId = '',
    this.visitId = '',
    this.remarks = '',
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ActivityLogModel.fromMap(Map<String, dynamic> map, String docId) {
    return ActivityLogModel(
      id: docId,
      action: map['action'] ?? '',
      userId: map['userId'] ?? '',
      taskId: map['taskId'] ?? '',
      visitId: map['visitId'] ?? '',
      remarks: map['remarks'] ?? '',
      timestamp: map['timestamp'] is Timestamp
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'action': action,
      'userId': userId,
      'taskId': taskId,
      'visitId': visitId,
      'remarks': remarks,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
