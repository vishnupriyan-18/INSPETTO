// User model for all 3 roles: collector, hod, field_officer
class UserModel {
  final String id;
  final String name;
  final String phone;
  final String role; // 'collector' | 'hod' | 'field_officer'
  final String district;
  final String department;

  UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.district,
    required this.department,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    // TODO: implement
    throw UnimplementedError();
  }

  Map<String, dynamic> toMap() {
    // TODO: implement
    throw UnimplementedError();
  }
}
