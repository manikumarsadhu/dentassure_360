import 'package:cloud_firestore/cloud_firestore.dart';

class RecruitmentCandidate {
  final String id;
  final String companyId;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String stage;
  final String notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  RecruitmentCandidate({
    required this.id,
    required this.companyId,
    required this.name,
    required this.email,
    this.phone = '',
    this.role = 'EMPLOYEE',
    this.stage = 'APPLIED',
    this.notes = '',
    this.createdAt,
    this.updatedAt,
  });

  bool get isHired => stage.toUpperCase() == 'HIRED';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'stage': stage,
      'notes': notes,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory RecruitmentCandidate.fromMap(Map<String, dynamic> map, {String? docId}) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return RecruitmentCandidate(
      id: docId ?? map['id'] ?? '',
      companyId: map['companyId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? 'EMPLOYEE',
      stage: map['stage'] ?? 'APPLIED',
      notes: map['notes'] ?? '',
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }
}
