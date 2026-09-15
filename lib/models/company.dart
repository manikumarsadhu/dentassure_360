import 'package:cloud_firestore/cloud_firestore.dart';

class Company {
  final String id;
  final String name;
  final String createdBy;
  final String adminEmail;
  final String adminName;
  final String status;
  final DateTime? createdAt;

  Company({
    required this.id,
    required this.name,
    required this.createdBy,
    this.adminEmail = '',
    this.adminName = '',
    this.status = 'ACTIVE',
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdBy': createdBy,
      'adminEmail': adminEmail,
      'adminName': adminName,
      'status': status,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory Company.fromMap(Map<String, dynamic> map, {String? docId}) {
    DateTime? parsedCreatedAt;
    if (map['createdAt'] is Timestamp) {
      parsedCreatedAt = (map['createdAt'] as Timestamp).toDate();
    } else if (map['createdAt'] is String) {
      parsedCreatedAt = DateTime.tryParse(map['createdAt']);
    }

    return Company(
      id: docId ?? map['id'] ?? '',
      name: map['name'] ?? '',
      createdBy: map['createdBy'] ?? '',
      adminEmail: map['adminEmail'] ?? '',
      adminName: map['adminName'] ?? '',
      status: map['status'] ?? 'ACTIVE',
      createdAt: parsedCreatedAt,
    );
  }

  Company copyWith({
    String? id,
    String? name,
    String? createdBy,
    String? adminEmail,
    String? adminName,
    String? status,
    DateTime? createdAt,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      createdBy: createdBy ?? this.createdBy,
      adminEmail: adminEmail ?? this.adminEmail,
      adminName: adminName ?? this.adminName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
