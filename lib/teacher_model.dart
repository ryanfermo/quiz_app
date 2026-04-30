import 'package:cloud_firestore/cloud_firestore.dart';

class Teacher {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String department;
  final String gender;
  final String address;
  final DateTime? lastLogin;
  final DateTime? createdAt;

  Teacher({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.department,
    required this.gender,
    required this.address,
    this.lastLogin,
    this.createdAt,
  });

  factory Teacher.fromMap(String id, Map<String, dynamic> data) {
    return Teacher(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      department: data['department'] ?? '',
      gender: data['gender'] ?? '',
      address: data['address'] ?? '',
      lastLogin:
          data['lastLogin'] != null
              ? (data['lastLogin'] as Timestamp).toDate()
              : null,
      createdAt:
          data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'department': department,
      'gender': gender,
      'address': address,
      'lastLogin': lastLogin,
      'createdAt': createdAt,
    };
  }
}
