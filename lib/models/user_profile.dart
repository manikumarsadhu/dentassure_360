import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String companyId;
  final String companyName;
  final String name;
  final String email;
  final String phone;
  final String employeeId;
  final String department;
  final String designation;
  final String role;
  final String status;
  final DateTime? joiningDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserProfile({
    required this.uid,
    required this.companyId,
    this.companyName = '',
    required this.name,
    required this.email,
    this.phone = '',
    this.employeeId = '',
    this.department = 'General',
    this.designation = 'Staff',
    required this.role,
    this.status = 'ACTIVE',
    this.joiningDate,
    this.createdAt,
    this.updatedAt,
  });

  bool get isCompanyAdmin => role == 'COMPANY_ADMIN';
  bool get isEmployee => role == 'EMPLOYEE';
  bool get isSuperAdmin => role == 'SUPER_ADMIN';
  bool get isManager => role == 'MANAGER';
  bool get isHR => role == 'HR';

  bool get isActive => status.toUpperCase() == 'ACTIVE';
  bool get isSuspended => status.toUpperCase() == 'SUSPENDED';

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'companyId': companyId,
      'companyName': companyName,
      'name': name,
      'email': email,
      'phone': phone,
      'employeeId': employeeId,
      'department': department,
      'designation': designation,
      'role': role,
      'status': status,
      'joiningDate': joiningDate != null
          ? Timestamp.fromDate(joiningDate!)
          : null,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map, {String? docId}) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return UserProfile(
      uid: docId ?? map['uid'] ?? '',
      companyId: map['companyId'] ?? '',
      companyName: map['companyName'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      employeeId: map['employeeId'] ?? '',
      department: map['department'] ?? 'General',
      designation: map['designation'] ?? 'Staff',
      role: map['role'] ?? 'EMPLOYEE',
      status: map['status'] ?? 'ACTIVE',
      joiningDate: parseDate(map['joiningDate']),
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  UserProfile copyWith({
    String? uid,
    String? companyId,
    String? companyName,
    String? name,
    String? email,
    String? phone,
    String? employeeId,
    String? department,
    String? designation,
    String? role,
    String? status,
    DateTime? joiningDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      employeeId: employeeId ?? this.employeeId,
      department: department ?? this.department,
      designation: designation ?? this.designation,
      role: role ?? this.role,
      status: status ?? this.status,
      joiningDate: joiningDate ?? this.joiningDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
