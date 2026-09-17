import 'attendance.dart';
import 'company.dart';
import 'user_profile.dart';

class ShiftTemplate {
  final String name;
  final String startHm;
  final String endHm;
  final int graceMinutes;
  final bool crossesMidnight;
  final bool enabled;

  const ShiftTemplate({
    required this.name,
    required this.startHm,
    required this.endHm,
    this.graceMinutes = 0,
    this.crossesMidnight = false,
    this.enabled = true,
  });

  static const dayDefault = ShiftTemplate(
    name: 'General Day',
    startHm: '09:30',
    endHm: '18:30',
  );

  static const nightDefault = ShiftTemplate(
    name: 'Night',
    startHm: '21:00',
    endHm: '06:00',
    crossesMidnight: true,
  );

  int get startMinutes => parseHm(startHm);
  int get endMinutes => parseHm(endHm);

  /// Wall-clock length of the shift, including overnight spans.
  int get durationMinutes {
    if (crossesMidnight || endMinutes <= startMinutes) {
      return (24 * 60 - startMinutes) + endMinutes;
    }
    return endMinutes - startMinutes;
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'startHm': startHm,
      'endHm': endHm,
      'graceMinutes': graceMinutes,
      'crossesMidnight': crossesMidnight,
      'enabled': enabled,
    };
  }

  factory ShiftTemplate.fromMap(dynamic value, ShiftTemplate fallback) {
    if (value is! Map) return fallback;
    final map = Map<String, dynamic>.from(value);
    return ShiftTemplate(
      name: (map['name'] ?? fallback.name).toString(),
      startHm: cleanHm(map['startHm'] ?? fallback.startHm),
      endHm: cleanHm(map['endHm'] ?? fallback.endHm),
      graceMinutes:
          (map['graceMinutes'] as num?)?.toInt() ?? fallback.graceMinutes,
      crossesMidnight:
          map['crossesMidnight'] == true || fallback.crossesMidnight,
      enabled: map['enabled'] != false,
    );
  }

  ShiftTemplate copyWith({
    String? name,
    String? startHm,
    String? endHm,
    int? graceMinutes,
    bool? crossesMidnight,
    bool? enabled,
  }) {
    return ShiftTemplate(
      name: name ?? this.name,
      startHm: startHm ?? this.startHm,
      endHm: endHm ?? this.endHm,
      graceMinutes: graceMinutes ?? this.graceMinutes,
      crossesMidnight: crossesMidnight ?? this.crossesMidnight,
      enabled: enabled ?? this.enabled,
    );
  }

  static int parseHm(String hm) {
    final parts = hm.split(':');
    final hour = int.tryParse(parts.first) ?? 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return hour * 60 + minute;
  }

  static String formatHm(int minutes) {
    var m = minutes % (24 * 60);
    if (m < 0) m += 24 * 60;
    final h = m ~/ 60;
    final min = m % 60;
    return '${h.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
  }

  static String cleanHm(dynamic value) {
    final raw = value.toString().trim();
    if (RegExp(r'^\d{1,2}:\d{2}$').hasMatch(raw)) {
      final parts = raw.split(':');
      return '${parts[0].padLeft(2, '0')}:${parts[1]}';
    }
    return '09:30';
  }
}

class AttendanceHoursResult {
  final String status;
  final int expectedMinutes;
  final int workedMinutes;
  final int overtimeMinutes;
  final int shortfallMinutes;
  final bool late;
  final bool halfDay;

  const AttendanceHoursResult({
    required this.status,
    required this.expectedMinutes,
    required this.workedMinutes,
    required this.overtimeMinutes,
    required this.shortfallMinutes,
    required this.late,
    required this.halfDay,
  });
}

/// Company policy + employee shift/work-mode hour engine.
class HoursEngine {
  static ShiftTemplate shiftFor(Company company, UserProfile user) {
    if (user.isNightShift && company.nightShift.enabled) {
      return company.nightShift;
    }
    return company.dayShift;
  }

  static String attendanceDateKey(DateTime now, ShiftTemplate shift) {
    if (!shift.crossesMidnight) {
      return Attendance.formatDateKey(now);
    }
    final nowMin = now.hour * 60 + now.minute;
    if (nowMin < shift.endMinutes) {
      return Attendance.formatDateKey(now.subtract(const Duration(days: 1)));
    }
    return Attendance.formatDateKey(now);
  }

  static int expectedMinutes(Company company, ShiftTemplate shift) {
    if (shift.crossesMidnight) return shift.durationMinutes;
    return company.fullDayMinutes;
  }

  static bool isLateAt(DateTime clockIn, ShiftTemplate shift) {
    final startWithGrace = shift.startMinutes + shift.graceMinutes;
    final clock = clockIn.hour * 60 + clockIn.minute;
    if (!shift.crossesMidnight) {
      return clock > startWithGrace;
    }
    // Evening portion of a night shift (e.g. 21:00–23:59).
    if (clock >= shift.startMinutes) {
      return clock > startWithGrace;
    }
    // After midnight until official end (e.g. 00:00–06:00) is past start.
    if (clock < shift.endMinutes) {
      return true;
    }
    // Before tonight's start (e.g. 06:01–20:59) is early, not late.
    return false;
  }

  static AttendanceHoursResult evaluate({
    required Company company,
    required UserProfile user,
    required DateTime clockIn,
    DateTime? clockOut,
    required int workedMinutes,
  }) {
    final shift = shiftFor(company, user);
    final expected = expectedMinutes(company, shift);
    final worked = workedMinutes < 0 ? 0 : workedMinutes;
    final skipPolicy = user.isFreelance;
    final late = skipPolicy ? false : isLateAt(clockIn, shift);
    final halfDay = !skipPolicy &&
        !late &&
        clockOut != null &&
        worked < company.halfDayMinutes;
    final overtime =
        clockOut == null ? 0 : (worked > expected ? worked - expected : 0);
    final shortfall =
        clockOut == null ? 0 : (worked < expected ? expected - worked : 0);

    String status = 'PRESENT';
    if (late) {
      status = 'LATE';
    } else if (halfDay) {
      status = 'HALF_DAY';
    }

    return AttendanceHoursResult(
      status: status,
      expectedMinutes: expected,
      workedMinutes: worked,
      overtimeMinutes: overtime,
      shortfallMinutes: shortfall,
      late: late,
      halfDay: halfDay,
    );
  }
}
