import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String title;
  final String location;
  final String purpose;
  final String priority; // high | medium | low
  final DateTime deadline;
  final String assignedTo; // field officer employeeId
  final String createdBy; // hod employeeId
  final String status; // assigned|accepted|inprogress|completed|approved|rejected|missed
  final String department;
  final String district;
  final int totalVisits;
  final DateTime? lastVisitAt;
  final bool isDemo;
  final DateTime timestamp;

  TaskModel({
    required this.id,
    required this.title,
    required this.location,
    required this.purpose,
    required this.priority,
    required this.deadline,
    required this.assignedTo,
    required this.createdBy,
    required this.status,
    required this.department,
    required this.district,
    this.totalVisits = 0,
    this.lastVisitAt,
    this.isDemo = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory TaskModel.fromMap(Map<String, dynamic> map, String docId) {
    return TaskModel(
      id: docId,
      title: map['title'] ?? '',
      location: map['location'] ?? '',
      purpose: map['purpose'] ?? '',
      priority: map['priority'] ?? 'medium',
      deadline: map['deadline'] is Timestamp
          ? (map['deadline'] as Timestamp).toDate()
          : DateTime.now(),
      assignedTo: map['assignedTo'] ?? '',
      createdBy: map['createdBy'] ?? '',
      status: map['status'] ?? 'assigned',
      department: map['department'] ?? '',
      district: map['district'] ?? '',
      totalVisits: (map['totalVisits'] ?? 0) as int,
      lastVisitAt: map['lastVisitAt'] is Timestamp
          ? (map['lastVisitAt'] as Timestamp).toDate()
          : null,
      isDemo: map['isDemo'] ?? false,
      timestamp: map['timestamp'] is Timestamp
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'location': location,
      'purpose': purpose,
      'priority': priority,
      'deadline': Timestamp.fromDate(deadline),
      'assignedTo': assignedTo,
      'createdBy': createdBy,
      'status': status,
      'department': department,
      'district': district,
      'totalVisits': totalVisits,
      'lastVisitAt': lastVisitAt != null ? Timestamp.fromDate(lastVisitAt!) : null,
      'isDemo': isDemo,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
