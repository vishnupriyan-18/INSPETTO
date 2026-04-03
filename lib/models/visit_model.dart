import 'package:cloud_firestore/cloud_firestore.dart';

class VisitModel {
  final String id;
  final String taskId;
  final String officerId;
  final String photoUrl;
  final List<String> additionalPhotos;
  final double latitude;
  final double longitude;
  final String address;
  final double gpsAccuracy;
  final DateTime? photoDateTime;
  final int progress; // 0–100
  final String remarks;
  final String signatureUrl;
  final bool isFinalVisit;
  final String status; // pending | approved | rejected
  final String rejectionReason;
  final bool isSuspicious;
  final String department;
  final String district;
  final DateTime timestamp;

  VisitModel({
    required this.id,
    required this.taskId,
    required this.officerId,
    required this.photoUrl,
    this.additionalPhotos = const [],
    required this.latitude,
    required this.longitude,
    this.address = '',
    this.gpsAccuracy = 0.0,
    this.photoDateTime,
    required this.progress,
    required this.remarks,
    this.signatureUrl = '',
    this.isFinalVisit = false,
    this.status = 'pending',
    this.rejectionReason = '',
    this.isSuspicious = false,
    required this.department,
    required this.district,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory VisitModel.fromMap(Map<String, dynamic> map, String docId) {
    return VisitModel(
      id: docId,
      taskId: map['taskId'] ?? '',
      officerId: map['officerId'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      additionalPhotos: List<String>.from(map['additionalPhotos'] ?? []),
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      address: map['address'] ?? '',
      gpsAccuracy: (map['gpsAccuracy'] ?? 0.0).toDouble(),
      photoDateTime: map['photoDateTime'] is Timestamp
          ? (map['photoDateTime'] as Timestamp).toDate()
          : null,
      progress: (map['progress'] ?? 0) as int,
      remarks: map['remarks'] ?? '',
      signatureUrl: map['signatureUrl'] ?? '',
      isFinalVisit: map['isFinalVisit'] ?? false,
      status: map['status'] ?? 'pending',
      rejectionReason: map['rejectionReason'] ?? '',
      isSuspicious: map['isSuspicious'] ?? false,
      department: map['department'] ?? '',
      district: map['district'] ?? '',
      timestamp: map['timestamp'] is Timestamp
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'officerId': officerId,
      'photoUrl': photoUrl,
      'additionalPhotos': additionalPhotos,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'gpsAccuracy': gpsAccuracy,
      'photoDateTime': photoDateTime != null ? Timestamp.fromDate(photoDateTime!) : null,
      'progress': progress,
      'remarks': remarks,
      'signatureUrl': signatureUrl,
      'isFinalVisit': isFinalVisit,
      'status': status,
      'rejectionReason': rejectionReason,
      'isSuspicious': isSuspicious,
      'department': department,
      'district': district,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  VisitModel copyWith({
    String? id,
    String? taskId,
    String? officerId,
    String? photoUrl,
    List<String>? additionalPhotos,
    double? latitude,
    double? longitude,
    String? address,
    double? gpsAccuracy,
    DateTime? photoDateTime,
    int? progress,
    String? remarks,
    String? signatureUrl,
    bool? isFinalVisit,
    String? status,
    String? rejectionReason,
    bool? isSuspicious,
    String? department,
    String? district,
    DateTime? timestamp,
  }) {
    return VisitModel(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      officerId: officerId ?? this.officerId,
      photoUrl: photoUrl ?? this.photoUrl,
      additionalPhotos: additionalPhotos ?? this.additionalPhotos,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      gpsAccuracy: gpsAccuracy ?? this.gpsAccuracy,
      photoDateTime: photoDateTime ?? this.photoDateTime,
      progress: progress ?? this.progress,
      remarks: remarks ?? this.remarks,
      signatureUrl: signatureUrl ?? this.signatureUrl,
      isFinalVisit: isFinalVisit ?? this.isFinalVisit,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      isSuspicious: isSuspicious ?? this.isSuspicious,
      department: department ?? this.department,
      district: district ?? this.district,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
