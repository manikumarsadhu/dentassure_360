import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyAsset {
  final String id;
  final String companyId;
  final String name;
  final String type;
  final String serial;
  final String assignedUid;
  final String assignedName;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CompanyAsset({
    required this.id,
    required this.companyId,
    required this.name,
    this.type = 'LAPTOP',
    this.serial = '',
    this.assignedUid = '',
    this.assignedName = '',
    this.status = 'AVAILABLE',
    this.createdAt,
    this.updatedAt,
  });

  bool get isAssigned => status.toUpperCase() == 'ASSIGNED';
  bool get isAvailable => status.toUpperCase() == 'AVAILABLE';
  bool get isRecovered => status.toUpperCase() == 'RECOVERED';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'name': name,
      'type': type,
      'serial': serial,
      'assignedUid': assignedUid,
      'assignedName': assignedName,
      'status': status,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory CompanyAsset.fromMap(Map<String, dynamic> map, {String? docId}) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return CompanyAsset(
      id: docId ?? map['id'] ?? '',
      companyId: map['companyId'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] ?? 'LAPTOP',
      serial: map['serial'] ?? '',
      assignedUid: map['assignedUid'] ?? '',
      assignedName: map['assignedName'] ?? '',
      status: map['status'] ?? 'AVAILABLE',
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }
}
