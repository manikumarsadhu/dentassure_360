import 'package:cloud_firestore/cloud_firestore.dart';

import 'shift_policy.dart';

class Company {
  final String id;
  final String name;
  final String createdBy;
  final String adminEmail;
  final String adminName;
  final String phone;
  final String address;
  final String industry;
  final String status;
  final String timezone;
  final List<int> workDays;
  final double fullDayHours;
  final double halfDayHours;
  final ShiftTemplate dayShift;
  final ShiftTemplate nightShift;
  final bool pfRestrictToStatutoryCeiling;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Company({
    required this.id,
    required this.name,
    required this.createdBy,
    this.adminEmail = '',
    this.adminName = '',
    this.phone = '',
    this.address = '',
    this.industry = 'General & Dental Healthcare',
    this.status = 'ACTIVE',
    this.timezone = 'Asia/Kolkata',
    this.workDays = const [1, 2, 3, 4, 5],
    this.fullDayHours = 8,
    this.halfDayHours = 4,
    this.dayShift = ShiftTemplate.dayDefault,
    this.nightShift = ShiftTemplate.nightDefault,
    this.pfRestrictToStatutoryCeiling = true,
    this.createdAt,
    this.updatedAt,
  });

  bool get isActive => status.toUpperCase() == 'ACTIVE';
  bool get isSuspended => status.toUpperCase() == 'SUSPENDED';
  int get fullDayMinutes => (fullDayHours * 60).round();
  int get halfDayMinutes => (halfDayHours * 60).round();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdBy': createdBy,
      'adminEmail': adminEmail,
      'adminName': adminName,
      'phone': phone,
      'address': address,
      'industry': industry,
      'status': status,
      'timezone': timezone,
      'workDays': workDays,
      'fullDayHours': fullDayHours,
      'halfDayHours': halfDayHours,
      'dayShift': dayShift.toMap(),
      'nightShift': nightShift.toMap(),
      'pfRestrictToStatutoryCeiling': pfRestrictToStatutoryCeiling,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory Company.fromMap(Map<String, dynamic> map, {String? docId}) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    final rawDays = map['workDays'];
    final days = <int>[];
    if (rawDays is List) {
      for (final item in rawDays) {
        if (item is num) days.add(item.toInt());
      }
    }

    return Company(
      id: docId ?? map['id'] ?? '',
      name: map['name'] ?? '',
      createdBy: map['createdBy'] ?? '',
      adminEmail: map['adminEmail'] ?? '',
      adminName: map['adminName'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      industry: map['industry'] ?? 'General & Dental Healthcare',
      status: map['status'] ?? 'ACTIVE',
      timezone: (map['timezone'] ?? 'Asia/Kolkata').toString(),
      workDays: days.isEmpty ? const [1, 2, 3, 4, 5] : days,
      fullDayHours: (map['fullDayHours'] as num?)?.toDouble() ?? 8,
      halfDayHours: (map['halfDayHours'] as num?)?.toDouble() ?? 4,
      dayShift: ShiftTemplate.fromMap(map['dayShift'], ShiftTemplate.dayDefault),
      nightShift:
          ShiftTemplate.fromMap(map['nightShift'], ShiftTemplate.nightDefault),
      pfRestrictToStatutoryCeiling: map['pfRestrictToStatutoryCeiling'] != false,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  Company copyWith({
    String? id,
    String? name,
    String? createdBy,
    String? adminEmail,
    String? adminName,
    String? phone,
    String? address,
    String? industry,
    String? status,
    String? timezone,
    List<int>? workDays,
    double? fullDayHours,
    double? halfDayHours,
    ShiftTemplate? dayShift,
    ShiftTemplate? nightShift,
    bool? pfRestrictToStatutoryCeiling,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      createdBy: createdBy ?? this.createdBy,
      adminEmail: adminEmail ?? this.adminEmail,
      adminName: adminName ?? this.adminName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      industry: industry ?? this.industry,
      status: status ?? this.status,
      timezone: timezone ?? this.timezone,
      workDays: workDays ?? this.workDays,
      fullDayHours: fullDayHours ?? this.fullDayHours,
      halfDayHours: halfDayHours ?? this.halfDayHours,
      dayShift: dayShift ?? this.dayShift,
      nightShift: nightShift ?? this.nightShift,
      pfRestrictToStatutoryCeiling:
          pfRestrictToStatutoryCeiling ?? this.pfRestrictToStatutoryCeiling,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
