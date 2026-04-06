import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String employeeId;
  final String name;
  final String phone;
  final String role; // it_admin | hod | field_officer | collector
  final String designation;
  final String department;
  final String district;
  final String hodId;
  final bool isActive;
  final bool createdByAdmin;
  final String fcmToken;
  final DateTime createdAt;

  UserModel({
    required this.employeeId,
    required this.name,
    required this.phone,
    required this.role,
    required this.designation,
    required this.department,
    required this.district,
    this.hodId = '',
    this.isActive = true,
    this.createdByAdmin = true,
    this.fcmToken = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory UserModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return UserModel(
      employeeId: map['employeeId'] ?? docId ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? 'field_officer',
      designation: map['designation'] ?? '',
      department: map['department'] ?? '',
      district: map['district'] ?? '',
      hodId: map['hodId'] ?? '',
      isActive: map['isActive'] ?? true,
      createdByAdmin: map['createdByAdmin'] ?? true,
      fcmToken: map['fcmToken'] ?? '',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'employeeId': employeeId,
      'name': name,
      'phone': phone,
      'role': role,
      'designation': designation,
      'department': department,
      'district': district,
      'hodId': hodId,
      'isActive': isActive,
      'createdByAdmin': createdByAdmin,
      'fcmToken': fcmToken,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? employeeId,
    String? name,
    String? phone,
    String? role,
    String? designation,
    String? department,
    String? district,
    String? hodId,
    bool? isActive,
    bool? createdByAdmin,
    String? fcmToken,
    DateTime? createdAt,
  }) {
    return UserModel(
      employeeId: employeeId ?? this.employeeId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      designation: designation ?? this.designation,
      department: department ?? this.department,
      district: district ?? this.district,
      hodId: hodId ?? this.hodId,
      isActive: isActive ?? this.isActive,
      createdByAdmin: createdByAdmin ?? this.createdByAdmin,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
