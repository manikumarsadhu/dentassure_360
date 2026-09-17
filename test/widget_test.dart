import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dentassure_360/models/attendance.dart';
import 'package:dentassure_360/models/company.dart';
import 'package:dentassure_360/models/leave_balance.dart';
import 'package:dentassure_360/models/leave_request.dart';
import 'package:dentassure_360/models/payslip.dart';
import 'package:dentassure_360/models/punch_capture.dart';
import 'package:dentassure_360/models/shift_policy.dart';
import 'package:dentassure_360/models/timesheet_entry.dart';
import 'package:dentassure_360/models/user_profile.dart';
import 'package:dentassure_360/utils/auth_error_handler.dart';
import 'package:dentassure_360/utils/team_scope.dart';
import 'package:dentassure_360/widgets/user_avatar.dart';

void main() {
  group('UserProfile Model', () {
    test('UserProfile full serialization and deserialization', () {
      final joining = DateTime(2025, 1, 15);
      final created = DateTime(2025, 1, 10);
      final user = UserProfile(
        uid: 'user_123',
        companyId: 'company_abc',
        companyName: 'Dentassure Technologies',
        name: 'Aman Sharma',
        email: 'aman@dentassuretech.com',
        phone: '+91 9876543210',
        employeeId: 'EMP-001',
        department: 'Software Engineering',
        designation: 'Senior Flutter Developer',
        role: 'EMPLOYEE',
        status: 'ACTIVE',
        avatarUrl: 'https://images.example.com/avatar123.jpg',
        joiningDate: joining,
        createdAt: created,
        updatedAt: created,
      );

      final map = user.toMap();
      expect(map['uid'], 'user_123');
      expect(map['companyId'], 'company_abc');
      expect(map['companyName'], 'Dentassure Technologies');
      expect(map['name'], 'Aman Sharma');
      expect(map['email'], 'aman@dentassuretech.com');
      expect(map['phone'], '+91 9876543210');
      expect(map['employeeId'], 'EMP-001');
      expect(map['department'], 'Software Engineering');
      expect(map['designation'], 'Senior Flutter Developer');
      expect(map['role'], 'EMPLOYEE');
      expect(map['status'], 'ACTIVE');
      expect(map['avatarUrl'], 'https://images.example.com/avatar123.jpg');
      expect(map['joiningDate'], isA<Timestamp>());

      final fromMap = UserProfile.fromMap(map, docId: 'user_123');
      expect(fromMap.uid, 'user_123');
      expect(fromMap.companyId, 'company_abc');
      expect(fromMap.companyName, 'Dentassure Technologies');
      expect(fromMap.name, 'Aman Sharma');
      expect(fromMap.email, 'aman@dentassuretech.com');
      expect(fromMap.phone, '+91 9876543210');
      expect(fromMap.employeeId, 'EMP-001');
      expect(fromMap.department, 'Software Engineering');
      expect(fromMap.designation, 'Senior Flutter Developer');
      expect(fromMap.role, 'EMPLOYEE');
      expect(fromMap.status, 'ACTIVE');
      expect(fromMap.avatarUrl, 'https://images.example.com/avatar123.jpg');
      expect(fromMap.reportingManagerUid, '');
      expect(fromMap.isCompanyAdmin, isFalse);
      expect(fromMap.isEmployee, isTrue);
      expect(fromMap.isActive, isTrue);
      expect(fromMap.isSuspended, isFalse);
      expect(fromMap.workMode, 'OFFICE');
      expect(fromMap.shiftType, 'DAY');
      expect(fromMap.joiningDate?.year, 2025);
    });

    test('UserProfile copyWith and status transitions', () {
      final user = UserProfile(
        uid: 'user_456',
        companyId: 'company_abc',
        name: 'Alex Turner',
        email: 'alex@dentassuretech.com',
        role: 'EMPLOYEE',
        status: 'ACTIVE',
      );

      final updated = user.copyWith(
        status: 'SUSPENDED',
        avatarUrl: 'https://images.example.com/alex.png',
      );
      expect(updated.isActive, isFalse);
      expect(updated.isSuspended, isTrue);
      expect(updated.name, 'Alex Turner');
      expect(updated.avatarUrl, 'https://images.example.com/alex.png');
    });

    test('UserProfile role helper getters', () {
      final platformAdmin = UserProfile(
        uid: '0',
        companyId: '',
        name: 'Platform Super Admin',
        email: 'root@platform.io',
        role: 'PLATFORM_ADMIN',
      );
      expect(platformAdmin.isPlatformAdmin, isTrue);
      expect(platformAdmin.isSuperAdmin, isTrue);
      expect(platformAdmin.isCompanyAdmin, isFalse);
      expect(platformAdmin.isEmployee, isFalse);

      final superAdmin = UserProfile(
        uid: '00',
        companyId: '',
        name: 'Super Admin',
        email: 'super@platform.io',
        role: 'SUPER_ADMIN',
      );
      expect(superAdmin.isPlatformAdmin, isTrue);
      expect(superAdmin.isSuperAdmin, isTrue);
      expect(superAdmin.isCompanyAdmin, isFalse);

      final admin = UserProfile(
        uid: '1',
        companyId: 'c1',
        name: 'Tech Admin',
        email: 'admin@c1.com',
        role: 'COMPANY_ADMIN',
      );
      expect(admin.isCompanyAdmin, isTrue);
      expect(admin.isPlatformAdmin, isFalse);
      expect(admin.isEmployee, isFalse);

      final employee = UserProfile(
        uid: '2',
        companyId: 'c1',
        name: 'Software Engineer',
        email: 'dev@c1.com',
        role: 'EMPLOYEE',
      );
      expect(employee.isCompanyAdmin, isFalse);
      expect(employee.isPlatformAdmin, isFalse);
      expect(employee.isEmployee, isTrue);

      final manager = UserProfile(
        uid: '3',
        companyId: 'c1',
        name: 'Engineering Manager',
        email: 'manager@c1.com',
        role: 'MANAGER',
      );
      expect(manager.isManager, isTrue);

      final teamLead = UserProfile(
        uid: '4',
        companyId: 'c1',
        name: 'Squad Lead',
        email: 'lead@c1.com',
        role: 'TEAM_LEAD',
        reportingManagerUid: '3',
        reportingManagerName: 'Engineering Manager',
      );
      expect(teamLead.isTeamLead, isTrue);
      expect(teamLead.isEmployee, isFalse);
      expect(teamLead.isManager, isFalse);
      expect(teamLead.reportingManagerUid, '3');

      final hr = UserProfile(
        uid: '5',
        companyId: 'c1',
        name: 'People Partner',
        email: 'hr@c1.com',
        role: 'HR',
      );
      expect(hr.isHR, isTrue);
      expect(hr.isPeopleOps, isTrue);
    });

    test('UserProfile reporting line serializes', () {
      final user = UserProfile(
        uid: 'u1',
        companyId: 'c1',
        name: 'Dev',
        email: 'dev@c1.com',
        role: 'EMPLOYEE',
        reportingManagerUid: 'lead1',
        reportingManagerName: 'Team Lead',
        monthlySalary: 80000,
      );
      final map = user.toMap();
      expect(map['reportingManagerUid'], 'lead1');
      expect(map['monthlySalary'], 80000);
      final fromMap = UserProfile.fromMap(map, docId: 'u1');
      expect(fromMap.reportingManagerUid, 'lead1');
      expect(fromMap.reportingManagerName, 'Team Lead');
      expect(fromMap.monthlySalary, 80000);
      expect(fromMap.isOnboardingComplete, isFalse);
    });
  });

  group('UserAvatar', () {
    test('reuses the same ImageProvider for the same data URL', () {
      const url =
          'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';
      final first = getUserAvatarImageProvider(url);
      final second = getUserAvatarImageProvider(url);
      expect(first, isNotNull);
      expect(identical(first, second), isTrue);
    });
  });

  group('LeaveRequest Model', () {
    test('LeaveRequest serialization and deserialization', () {
      final leave = LeaveRequest(
        id: 'req_123',
        companyId: 'comp_1',
        uid: 'user_1',
        employeeId: 'EMP-001',
        employeeName: 'Aman Sharma',
        department: 'Software Engineering',
        leaveType: 'CASUAL',
        startDate: '2026-09-18',
        endDate: '2026-09-19',
        totalDays: 2,
        reason: 'Tech conference & hackathon',
        status: 'PENDING',
      );

      final map = leave.toMap();
      expect(map['id'], 'req_123');
      expect(map['companyId'], 'comp_1');
      expect(map['uid'], 'user_1');
      expect(map['employeeId'], 'EMP-001');
      expect(map['employeeName'], 'Aman Sharma');
      expect(map['leaveType'], 'CASUAL');
      expect(map['startDate'], '2026-09-18');
      expect(map['endDate'], '2026-09-19');
      expect(map['totalDays'], 2);
      expect(map['reason'], 'Tech conference & hackathon');
      expect(map['status'], 'PENDING');

      final fromMap = LeaveRequest.fromMap(map, docId: 'req_123');
      expect(fromMap.id, 'req_123');
      expect(fromMap.displayLeaveType, 'Casual Leave');
      expect(fromMap.totalDays, 2);
      expect(fromMap.isPending, isTrue);
      expect(fromMap.isApproved, isFalse);
      expect(fromMap.formattedDateRange, contains('Sep 18 – Sep 19'));
    });

    test('LeaveRequest coversDate helper for attendance integration', () {
      final approvedLeave = LeaveRequest(
        id: 'req_456',
        companyId: 'comp_1',
        uid: 'user_1',
        employeeId: 'EMP-001',
        employeeName: 'Aman Sharma',
        leaveType: 'SICK',
        startDate: '2026-09-15',
        endDate: '2026-09-17',
        totalDays: 3,
        reason: 'Flu recovery',
        status: 'APPROVED',
      );

      expect(approvedLeave.coversDate('2026-09-15'), isTrue);
      expect(approvedLeave.coversDate('2026-09-16'), isTrue);
      expect(approvedLeave.coversDate('2026-09-17'), isTrue);
      expect(approvedLeave.coversDate('2026-09-14'), isFalse);
      expect(approvedLeave.coversDate('2026-09-18'), isFalse);

      final pendingLeave = approvedLeave.copyWith(status: 'PENDING');
      expect(pendingLeave.coversDate('2026-09-15'), isFalse);
    });
  });

  group('LeaveBalance Model', () {
    test('Calculates available leave balance from approved requests', () {
      final requests = [
        LeaveRequest(
          id: '1',
          companyId: 'c',
          uid: 'u',
          employeeId: 'E1',
          employeeName: 'A',
          leaveType: 'CASUAL',
          startDate: '2026-01-01',
          endDate: '2026-01-02',
          totalDays: 2,
          reason: 'Test',
          status: 'APPROVED',
        ),
        LeaveRequest(
          id: '2',
          companyId: 'c',
          uid: 'u',
          employeeId: 'E1',
          employeeName: 'A',
          leaveType: 'CASUAL',
          startDate: '2026-02-01',
          endDate: '2026-02-04',
          totalDays: 4,
          reason: 'Test',
          status: 'PENDING',
        ),
        LeaveRequest(
          id: '3',
          companyId: 'c',
          uid: 'u',
          employeeId: 'E1',
          employeeName: 'A',
          leaveType: 'SICK',
          startDate: '2026-03-01',
          endDate: '2026-03-03',
          totalDays: 3,
          reason: 'Fever',
          status: 'APPROVED',
        ),
      ];

      final balance = LeaveBalance.fromApprovedRequests(requests);
      expect(balance.totalCasual, 12);
      expect(balance.usedCasual, 2);
      expect(balance.availableCasual, 10);

      expect(balance.totalSick, 10);
      expect(balance.usedSick, 3);
      expect(balance.availableSick, 7);

      expect(balance.totalAnnual, 15);
      expect(balance.usedAnnual, 0);
      expect(balance.availableAnnual, 15);
    });
  });

  group('Attendance Model', () {
    test('Attendance serialization and deserialization', () {
      final clockInTime = DateTime(2026, 9, 15, 9, 2);
      final clockOutTime = DateTime(2026, 9, 15, 17, 5);

      final att = Attendance(
        id: 'user1_2026-09-15',
        uid: 'user1',
        companyId: 'comp1',
        employeeId: 'EMP-001',
        employeeName: 'Aman Sharma',
        department: 'Software Engineering',
        date: '2026-09-15',
        clockIn: clockInTime,
        clockOut: clockOutTime,
        status: 'PRESENT',
        workingMinutes: 483,
      );

      final map = att.toMap();
      expect(map['id'], 'user1_2026-09-15');
      expect(map['uid'], 'user1');
      expect(map['companyId'], 'comp1');
      expect(map['employeeId'], 'EMP-001');
      expect(map['employeeName'], 'Aman Sharma');
      expect(map['department'], 'Software Engineering');
      expect(map['date'], '2026-09-15');
      expect(map['status'], 'PRESENT');
      expect(map['workingMinutes'], 483);
      expect(map['clockIn'], isA<Timestamp>());
      expect(map['clockOut'], isA<Timestamp>());

      final fromMap = Attendance.fromMap(map, docId: 'user1_2026-09-15');
      expect(fromMap.id, 'user1_2026-09-15');
      expect(fromMap.employeeName, 'Aman Sharma');
      expect(fromMap.status, 'PRESENT');
      expect(fromMap.isPresent, isTrue);
      expect(fromMap.isLate, isFalse);
      expect(fromMap.isCompleted, isTrue);
      expect(fromMap.isClockedIn, isFalse);
      expect(fromMap.formattedClockIn, '09:02 AM');
      expect(fromMap.formattedClockOut, '05:05 PM');
      expect(fromMap.formattedWorkingDuration, '8h 03m');
      expect(fromMap.formattedClockInWithSeconds, '09:02:00 AM');
      expect(fromMap.breaks, isEmpty);
    });

    test('PunchCapture serializes face, GPS and Wi-Fi proof', () {
      final capture = PunchCapture(
        facePhotoUrl: 'data:image/jpeg;base64,abc',
        latitude: 17.385044,
        longitude: 78.486671,
        accuracyMeters: 12.4,
        wifiSsid: 'Dentassure-Office',
        wifiBssid: 'aa:bb:cc:dd:ee:ff',
        ipAddress: '49.37.1.10',
        localIp: '192.168.1.24',
        platform: 'android',
        capturedAt: DateTime(2026, 9, 17, 9, 12),
      );

      final att = Attendance(
        id: 'u1_2026-09-17',
        uid: 'u1',
        companyId: 'c1',
        employeeId: 'EMP-001',
        employeeName: 'Tarun',
        date: '2026-09-17',
        clockIn: DateTime(2026, 9, 17, 9, 12),
        status: 'PRESENT',
        clockInCapture: capture,
      );

      final map = att.toMap();
      expect(map['clockInCapture'], isA<Map>());
      final roundTrip = Attendance.fromMap(map, docId: att.id);
      expect(roundTrip.clockInCapture?.hasFace, isTrue);
      expect(roundTrip.clockInCapture?.hasGps, isTrue);
      expect(roundTrip.clockInCapture?.wifiSsid, 'Dentassure-Office');
      expect(roundTrip.clockInCapture?.wifiBssid, 'aa:bb:cc:dd:ee:ff');
      expect(roundTrip.clockInCapture?.ipAddress, '49.37.1.10');
      expect(roundTrip.clockInCapture?.isComplete, isTrue);
      expect(roundTrip.clockOutCapture, isNull);
    });

    test('Attendance state and working duration formatting', () {
      final clockInTime = DateTime(2026, 9, 15, 9, 45);
      final attLate = Attendance(
        id: 'user2_2026-09-15',
        uid: 'user2',
        companyId: 'comp1',
        employeeId: 'EMP-002',
        employeeName: 'Alex Turner',
        date: '2026-09-15',
        clockIn: clockInTime,
        clockOut: null,
        status: 'LATE',
        workingMinutes: 0,
      );

      expect(attLate.isClockedIn, isTrue);
      expect(attLate.isCompleted, isFalse);
      expect(attLate.isLate, isTrue);
      expect(attLate.formattedClockIn, '09:45 AM');
      expect(attLate.formattedClockOut, '—');
    });

    test('Breaks pause net working time and format seconds', () {
      final clockInTime = DateTime(2026, 9, 16, 9, 0, 0);
      final lunchStart = DateTime(2026, 9, 16, 13, 0, 0);
      final lunchEnd = DateTime(2026, 9, 16, 13, 45, 12);
      final now = DateTime(2026, 9, 16, 14, 0, 5);

      final att = Attendance(
        id: 'user3_2026-09-16',
        uid: 'user3',
        companyId: 'comp1',
        employeeId: 'EMP-003',
        employeeName: 'Abhishikth',
        date: '2026-09-16',
        clockIn: clockInTime,
        clockOut: null,
        status: 'PRESENT',
        breaks: [
          AttendanceBreak(
            id: 'LUNCH_1',
            type: 'LUNCH',
            start: lunchStart,
            end: lunchEnd,
          ),
        ],
      );

      expect(att.isOnBreak, isFalse);
      expect(att.liveWorkedLabel(now), '4h 14m 53s');
      expect(att.liveBreakLabel(now), '45m 12s');

      final onLunch = att.copyWith(
        breaks: [
          AttendanceBreak(
            id: 'LUNCH_2',
            type: 'LUNCH',
            start: lunchStart,
          ),
        ],
      );
      expect(onLunch.isOnBreak, isTrue);
      expect(onLunch.activeBreak?.label, 'Lunch');
      expect(onLunch.liveWorkedLabel(now), '4h 00m 00s');
      expect(onLunch.liveBreakLabel(now), '1h 00m 05s');

      final map = att.toMap();
      final fromMap = Attendance.fromMap(map, docId: att.id);
      expect(fromMap.breaks, hasLength(1));
      expect(fromMap.breaks.first.type, 'LUNCH');
      expect(fromMap.breaks.first.end, isNotNull);
    });

    test('Date key formatter utility', () {
      final date = DateTime(2026, 9, 15);
      expect(Attendance.formatDateKey(date), '2026-09-15');
    });
  });

  group('Company Model', () {
    test('Company serialization and deserialization', () {
      final now = DateTime.now();
      final company = Company(
        id: 'comp_999',
        name: 'Dentassure Technologies',
        createdBy: 'user_123',
        adminEmail: 'admin@dentassuretech.com',
        adminName: 'Vikram Malhotra',
        phone: '+91 9876543210',
        address: '101 Cyber City, Hyderabad',
        industry: 'Dental & Healthcare Services',
        status: 'ACTIVE',
        createdAt: now,
      );

      final map = company.toMap();
      expect(map['id'], 'comp_999');
      expect(map['name'], 'Dentassure Technologies');
      expect(map['createdBy'], 'user_123');
      expect(map['adminEmail'], 'admin@dentassuretech.com');
      expect(map['adminName'], 'Vikram Malhotra');
      expect(map['phone'], '+91 9876543210');
      expect(map['address'], '101 Cyber City, Hyderabad');
      expect(map['industry'], 'Dental & Healthcare Services');
      expect(map['status'], 'ACTIVE');
      expect(map['createdAt'], isA<Timestamp>());

      final fromMap = Company.fromMap(map, docId: 'comp_999');
      expect(fromMap.id, 'comp_999');
      expect(fromMap.name, 'Dentassure Technologies');
      expect(fromMap.createdBy, 'user_123');
      expect(fromMap.adminEmail, 'admin@dentassuretech.com');
      expect(fromMap.adminName, 'Vikram Malhotra');
      expect(fromMap.phone, '+91 9876543210');
      expect(fromMap.address, '101 Cyber City, Hyderabad');
      expect(fromMap.industry, 'Dental & Healthcare Services');
      expect(fromMap.status, 'ACTIVE');
      expect(fromMap.isActive, isTrue);
      expect(fromMap.isSuspended, isFalse);
      expect(fromMap.timezone, 'Asia/Kolkata');
      expect(fromMap.dayShift.startHm, '09:30');
      expect(fromMap.dayShift.endHm, '18:30');
      expect(fromMap.nightShift.crossesMidnight, isTrue);
      expect(fromMap.fullDayHours, 8);
      expect(fromMap.halfDayHours, 4);

      final suspended = fromMap.copyWith(status: 'SUSPENDED');
      expect(suspended.isActive, isFalse);
      expect(suspended.isSuspended, isTrue);
    });

    test('Missing policy fields fall back to 09:30 day shift', () {
      final fromMap = Company.fromMap({
        'name': 'Legacy Clinic',
        'createdBy': 'u0',
      }, docId: 'legacy');
      expect(fromMap.timezone, 'Asia/Kolkata');
      expect(fromMap.workDays, [1, 2, 3, 4, 5]);
      expect(fromMap.dayShift.startHm, '09:30');
      expect(fromMap.dayShift.endHm, '18:30');
      expect(fromMap.fullDayHours, 8);
      expect(fromMap.halfDayHours, 4);
      expect(fromMap.nightShift.crossesMidnight, isTrue);
    });
  });

  group('HoursEngine', () {
    final company = Company(
      id: 'c1',
      name: 'Acme',
      createdBy: 'u0',
    );
    final officeDay = UserProfile(
      uid: 'e1',
      companyId: 'c1',
      name: 'Dev',
      email: 'd@c1.com',
      role: 'EMPLOYEE',
    );
    final nightWorker = officeDay.copyWith(shiftType: 'NIGHT');
    final freelancer = officeDay.copyWith(workMode: 'FREELANCE');

    test('Day shift late after start plus grace', () {
      expect(
        HoursEngine.isLateAt(DateTime(2026, 9, 17, 9, 30), company.dayShift),
        isFalse,
      );
      expect(
        HoursEngine.isLateAt(DateTime(2026, 9, 17, 9, 31), company.dayShift),
        isTrue,
      );
    });

    test('Half-day and overtime from expected hours', () {
      final short = HoursEngine.evaluate(
        company: company,
        user: officeDay,
        clockIn: DateTime(2026, 9, 17, 9, 15),
        clockOut: DateTime(2026, 9, 17, 12, 15),
        workedMinutes: 180,
      );
      expect(short.status, 'HALF_DAY');
      expect(short.expectedMinutes, 480);
      expect(short.shortfallMinutes, 300);

      final ot = HoursEngine.evaluate(
        company: company,
        user: officeDay,
        clockIn: DateTime(2026, 9, 17, 9, 15),
        clockOut: DateTime(2026, 9, 17, 19, 15),
        workedMinutes: 540,
      );
      expect(ot.status, 'PRESENT');
      expect(ot.overtimeMinutes, 60);
    });

    test('Freelance skips late and half-day', () {
      final result = HoursEngine.evaluate(
        company: company,
        user: freelancer,
        clockIn: DateTime(2026, 9, 17, 11, 0),
        clockOut: DateTime(2026, 9, 17, 13, 0),
        workedMinutes: 120,
      );
      expect(result.status, 'PRESENT');
      expect(result.late, isFalse);
      expect(result.halfDay, isFalse);
    });

    test('Night shift date stays on the start calendar day', () {
      final shift = company.nightShift;
      expect(
        HoursEngine.attendanceDateKey(DateTime(2026, 9, 17, 21, 10), shift),
        '2026-09-17',
      );
      expect(
        HoursEngine.attendanceDateKey(DateTime(2026, 9, 18, 0, 30), shift),
        '2026-09-17',
      );
      expect(
        HoursEngine.isLateAt(DateTime(2026, 9, 17, 21, 0), shift),
        isFalse,
      );
      expect(
        HoursEngine.isLateAt(DateTime(2026, 9, 18, 0, 30), shift),
        isTrue,
      );
      expect(
        HoursEngine.isLateAt(DateTime(2026, 9, 17, 20, 50), shift),
        isFalse,
      );
      expect(HoursEngine.shiftFor(company, nightWorker).crossesMidnight, isTrue);
      expect(HoursEngine.expectedMinutes(company, shift), 540);
    });
  });

  group('AuthErrorHandler', () {
    test('Returns friendly message for FirebaseAuthException codes', () {
      final emailInUse = FirebaseAuthException(
        code: 'email-already-in-use',
        message: 'The email address is already in use by another account.',
      );
      expect(
        AuthErrorHandler.getErrorMessage(emailInUse),
        contains('already registered'),
      );

      final invalidCred = FirebaseAuthException(
        code: 'invalid-credential',
      );
      expect(
        AuthErrorHandler.getErrorMessage(invalidCred),
        contains('Incorrect email or password'),
      );

      final networkErr = FirebaseAuthException(
        code: 'network-request-failed',
      );
      expect(
        AuthErrorHandler.getErrorMessage(networkErr),
        contains('internet connection'),
      );
    });

    test('Handles generic String and Exception', () {
      expect(
        AuthErrorHandler.getErrorMessage('Custom error message'),
        'Custom error message',
      );
    });
  });

  group('TeamScope', () {
    test('Direct and skip-level reports', () {
      final manager = UserProfile(
        uid: 'm1',
        companyId: 'c1',
        name: 'Manager',
        email: 'm@c1.com',
        role: 'MANAGER',
      );
      final lead = UserProfile(
        uid: 'l1',
        companyId: 'c1',
        name: 'Lead',
        email: 'l@c1.com',
        role: 'TEAM_LEAD',
        reportingManagerUid: 'm1',
      );
      final emp = UserProfile(
        uid: 'e1',
        companyId: 'c1',
        name: 'Engineer',
        email: 'e@c1.com',
        role: 'EMPLOYEE',
        reportingManagerUid: 'l1',
      );
      final outsider = UserProfile(
        uid: 'e2',
        companyId: 'c1',
        name: 'Other',
        email: 'o@c1.com',
        role: 'EMPLOYEE',
        reportingManagerUid: 'someone-else',
      );
      final all = [manager, lead, emp, outsider];

      final leadTeam = TeamScope.reportsFor(lead, all);
      expect(leadTeam.map((u) => u.uid), ['e1']);

      final managerTeam = TeamScope.reportsFor(manager, all);
      expect(managerTeam.map((u) => u.uid).toSet(), {'l1', 'e1'});
      expect(managerTeam.map((u) => u.uid), isNot(contains('e2')));
    });
  });

  group('Timesheet and Payslip models', () {
    test('TimesheetEntry serialization', () {
      final entry = TimesheetEntry(
        id: 'ts1',
        companyId: 'c1',
        uid: 'u1',
        employeeName: 'Dev',
        reportingManagerUid: 'lead1',
        date: '2026-09-16',
        project: 'Dentassure',
        task: 'Role dashboards',
        hours: 6.5,
        billable: true,
      );
      final map = entry.toMap();
      expect(map['project'], 'Dentassure');
      expect(map['hours'], 6.5);
      final fromMap = TimesheetEntry.fromMap(map, docId: 'ts1');
      expect(fromMap.isPending, isTrue);
      expect(fromMap.hours, 6.5);
      expect(fromMap.reportingManagerUid, 'lead1');
    });

    test('Payslip.fromSalary breakdown', () {
      final slip = Payslip.fromSalary(
        id: 'u1_2026-09',
        companyId: 'c1',
        uid: 'u1',
        employeeName: 'Dev',
        month: '2026-09',
        monthlySalary: 100000,
      );
      expect(slip.basic, 50000);
      expect(slip.hra, 20000);
      expect(slip.allowances, 30000);
      expect(slip.deductions, 6000);
      expect(slip.netPay, 94000);
    });
  });
}
