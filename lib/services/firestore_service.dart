import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/attendance.dart';
import '../models/company.dart';
import '../models/punch_capture.dart';
import '../models/company_asset.dart';
import '../models/expense_claim.dart';
import '../models/leave_request.dart';
import '../models/payslip.dart';
import '../models/performance_goal.dart';
import '../models/recruitment_candidate.dart';
import '../models/timesheet_entry.dart';
import '../models/user_profile.dart';
import '../models/shift_policy.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Creates a new Company and the associated Company Admin profile atomically using a batch write.
  /// Generates a unique company document ID if not explicitly provided.
  Future<String> createCompany({
    required String companyName,
    required String adminUid,
    required String adminName,
    required String adminEmail,
    String? adminPhone,
    String? address,
    String? industry,
    String? explicitCompanyId,
    String? createdByUid,
    String? designation,
    String timezone = 'Asia/Kolkata',
    List<int> workDays = const [1, 2, 3, 4, 5],
    double fullDayHours = 8,
    double halfDayHours = 4,
    ShiftTemplate? dayShift,
    ShiftTemplate? nightShift,
  }) async {
    final batch = _firestore.batch();

    final companyRef = explicitCompanyId != null && explicitCompanyId.isNotEmpty
        ? _firestore.collection('companies').doc(explicitCompanyId)
        : _firestore.collection('companies').doc();

    final companyId = companyRef.id;
    final userRef = _firestore.collection('users').doc(adminUid);

    final cleanCompanyName = companyName.trim();
    final cleanAdminName = adminName.trim();
    final cleanAdminEmail = adminEmail.trim();
    final cleanPhone = adminPhone?.trim() ?? '';
    final cleanAddress = address?.trim() ?? '';
    final cleanIndustry = industry?.trim().isNotEmpty == true
        ? industry!.trim()
        : 'General & Dental Healthcare';
    final creator = createdByUid != null && createdByUid.isNotEmpty
        ? createdByUid
        : adminUid;

    batch.set(companyRef, {
      'id': companyId,
      'name': cleanCompanyName,
      'createdBy': creator,
      'adminEmail': cleanAdminEmail,
      'adminName': cleanAdminName,
      'phone': cleanPhone,
      'address': cleanAddress,
      'industry': cleanIndustry,
      'status': 'ACTIVE',
      'timezone': timezone,
      'workDays': workDays,
      'fullDayHours': fullDayHours,
      'halfDayHours': halfDayHours,
      'dayShift': (dayShift ?? ShiftTemplate.dayDefault).toMap(),
      'nightShift': (nightShift ?? ShiftTemplate.nightDefault).toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.set(userRef, {
      'uid': adminUid,
      'companyId': companyId,
      'companyName': cleanCompanyName,
      'name': cleanAdminName,
      'email': cleanAdminEmail,
      'phone': cleanPhone,
      'employeeId': 'ADMIN-001',
      'role': 'COMPANY_ADMIN',
      'status': 'ACTIVE',
      'department': 'Executive Administration',
      'designation': designation?.trim().isNotEmpty == true
          ? designation!.trim()
          : 'Organization Administrator',
      'reportingManagerUid': '',
      'reportingManagerName': '',
      'monthlySalary': 0,
      'workMode': 'OFFICE',
      'shiftType': 'DAY',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    return companyId;
  }

  /// Streams all companies in real-time across the platform (for Platform Admin)
  Stream<List<Company>> streamAllCompanies() {
    return _firestore.collection('companies').snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => Company.fromMap(doc.data(), docId: doc.id))
          .toList();
      list.sort((a, b) {
        if (a.createdAt != null && b.createdAt != null) {
          return b.createdAt!.compareTo(a.createdAt!);
        }
        return a.name.compareTo(b.name);
      });
      return list;
    });
  }

  /// Streams all platform users in real-time (for Platform Admin platform-wide statistics)
  Stream<List<UserProfile>> streamAllPlatformUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => UserProfile.fromMap(doc.data(), docId: doc.id))
          .toList();
    });
  }

  /// Provisions a Platform Super Admin profile in Firestore
  Future<void> createPlatformAdminProfile({
    required String uid,
    required String email,
    String name = 'Platform Super Admin',
  }) async {
    final docRef = _firestore.collection('users').doc(uid);
    final snapshot = await docRef.get();
    if (!snapshot.exists) {
      await docRef.set({
        'uid': uid,
        'companyId': '',
        'companyName': '',
        'name': name,
        'email': email.trim(),
        'phone': '',
        'employeeId': 'SUPER-ADMIN',
        'department': 'Executive Administration',
        'designation': 'Platform Super Administrator',
        'role': 'PLATFORM_ADMIN',
        'status': 'ACTIVE',
        'avatarUrl': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await docRef.update({
        'role': 'PLATFORM_ADMIN',
        'status': 'ACTIVE',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Streams a single company document in real-time
  Stream<Company?> streamCompanyById(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return Company.fromMap(doc.data()!, docId: doc.id);
    });
  }

  /// Updates an existing company's metadata and settings
  Future<void> updateCompany(Company company) async {
    await _firestore.collection('companies').doc(company.id).update({
      'name': company.name.trim(),
      'adminName': company.adminName.trim(),
      'adminEmail': company.adminEmail.trim(),
      'phone': company.phone.trim(),
      'address': company.address.trim(),
      'industry': company.industry.trim(),
      'status': company.status,
      'timezone': company.timezone,
      'workDays': company.workDays,
      'fullDayHours': company.fullDayHours,
      'halfDayHours': company.halfDayHours,
      'dayShift': company.dayShift.toMap(),
      'nightShift': company.nightShift.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Streams all users belonging to a specific company ID
  Stream<List<UserProfile>> streamCompanyUsers(String companyId) {
    return _firestore
        .collection('users')
        .where('companyId', isEqualTo: companyId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => UserProfile.fromMap(doc.data(), docId: doc.id))
          .toList();
      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    });
  }

  /// Streams all today's attendance records across all companies for Platform-wide overview
  Stream<List<Attendance>> streamAllAttendanceForDate(String dateKey) {
    return _firestore
        .collection('attendance')
        .where('date', isEqualTo: dateKey)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Attendance.fromMap(doc.data(), docId: doc.id))
          .toList();
    });
  }

  /// Streams all leave requests across the platform
  Stream<List<LeaveRequest>> streamAllPlatformLeaveRequests() {
    return _firestore
        .collection('leave_requests')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => LeaveRequest.fromMap(doc.data(), docId: doc.id))
          .toList();
      list.sort((a, b) {
        if (a.createdAt != null && b.createdAt != null) {
          return b.createdAt!.compareTo(a.createdAt!);
        }
        return b.startDate.compareTo(a.startDate);
      });
      return list;
    });
  }

  /// Platform Admin can change user role, department, designation, and status
  Future<void> updateUserRoleAndStatus({
    required String uid,
    required String role,
    required String status,
    String? designation,
    String? department,
    String? reportingManagerUid,
    String? reportingManagerName,
  }) async {
    final Map<String, dynamic> updateData = {
      'role': role,
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (designation != null) {
      updateData['designation'] = designation.trim();
    }
    if (department != null) {
      updateData['department'] = department.trim();
    }
    if (reportingManagerUid != null) {
      updateData['reportingManagerUid'] = reportingManagerUid.trim();
    }
    if (reportingManagerName != null) {
      updateData['reportingManagerName'] = reportingManagerName.trim();
    }
    await _firestore.collection('users').doc(uid).update(updateData);
  }

  /// Toggles a company's operational status (ACTIVE or SUSPENDED)
  Future<void> toggleCompanyStatus({
    required String companyId,
    required String newStatus,
  }) async {
    await _firestore.collection('companies').doc(companyId).update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Deletes a company document from Firestore
  Future<void> deleteCompany(String companyId) async {
    await _firestore.collection('companies').doc(companyId).delete();
  }

  /// Fetches a UserProfile once by UID
  Future<UserProfile?> getUserProfile(String uid) async {
    final snapshot = await _firestore.collection('users').doc(uid).get();
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }
    return UserProfile.fromMap(snapshot.data()!, docId: snapshot.id);
  }

  /// Streams the real-time UserProfile document for AuthGate and Dashboard updates
  Stream<UserProfile?> streamUserProfile(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return UserProfile.fromMap(snapshot.data()!, docId: snapshot.id);
    });
  }

  /// Fetches Company details once
  Future<Company?> getCompany(String companyId) async {
    final snapshot =
        await _firestore.collection('companies').doc(companyId).get();
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }
    return Company.fromMap(snapshot.data()!, docId: snapshot.id);
  }

  /// Streams Company details in real time
  Stream<Company?> streamCompany(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return Company.fromMap(snapshot.data()!, docId: snapshot.id);
    });
  }

  /// Streams list of all users/employees belonging to a company
  Stream<List<UserProfile>> streamCompanyEmployees(String companyId) {
    return _firestore
        .collection('users')
        .where('companyId', isEqualTo: companyId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => UserProfile.fromMap(doc.data(), docId: doc.id))
          .toList();
    });
  }

  /// Counts total employees in a given company
  Future<int> getEmployeeCount(String companyId) async {
    final countSnapshot = await _firestore
        .collection('users')
        .where('companyId', isEqualTo: companyId)
        .count()
        .get();
    return countSnapshot.count ?? 0;
  }

  /// Adds a new employee profile under /users/{uid}
  Future<void> addEmployee(UserProfile employee) async {
    await _firestore
        .collection('users')
        .doc(employee.uid)
        .set(employee.toMap());
  }

  /// Updates an existing employee profile
  Future<void> updateEmployee(UserProfile employee) async {
    final Map<String, dynamic> updateData = {
      'name': employee.name.trim(),
      'phone': employee.phone.trim(),
      'employeeId': employee.employeeId.trim(),
      'department': employee.department.trim(),
      'designation': employee.designation.trim(),
      'role': employee.role,
      'status': employee.status,
      'avatarUrl': employee.avatarUrl.trim(),
      'reportingManagerUid': employee.reportingManagerUid.trim(),
      'reportingManagerName': employee.reportingManagerName.trim(),
      'monthlySalary': employee.monthlySalary,
      'workMode': employee.workMode,
      'shiftType': employee.shiftType,
      'onboardingDocsCollected': employee.onboardingDocsCollected,
      'onboardingAssetsAssigned': employee.onboardingAssetsAssigned,
      'onboardingAccessReady': employee.onboardingAccessReady,
      'joiningDate': employee.joiningDate != null
          ? Timestamp.fromDate(employee.joiningDate!)
          : null,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('users').doc(employee.uid).update(updateData);
  }

  /// Self-service profile update for currently logged-in user (name, phone, avatar)
  Future<void> updateUserProfile(UserProfile profile) async {
    final Map<String, dynamic> updateData = {
      'name': profile.name.trim(),
      'phone': profile.phone.trim(),
      'avatarUrl': profile.avatarUrl.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('users').doc(profile.uid).update(updateData);
  }

  /// Quick update for user's profile avatar URL
  Future<void> updateAvatarUrl({
    required String uid,
    required String avatarUrl,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'avatarUrl': avatarUrl.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Toggles an employee's status between ACTIVE, SUSPENDED, or INACTIVE
  Future<void> toggleEmployeeStatus({
    required String uid,
    required String newStatus,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Deletes an employee's profile document
  Future<void> deleteEmployee(String uid) async {
    await _firestore.collection('users').doc(uid).delete();
  }

  /// Generates a suggested Employee ID such as EMP-001 based on current count
  Future<String> generateNextEmployeeId(String companyId) async {
    final count = await getEmployeeCount(companyId);
    final number = (count + 1).toString().padLeft(3, '0');
    return 'EMP-$number';
  }

  // ==========================================
  // ATTENDANCE METHODS
  // ==========================================

  /// Stream today's attendance document for a specific user
  Stream<Attendance?> streamTodayAttendance({
    required String uid,
    required String date,
  }) {
    final docId = '${uid}_$date';
    return _firestore
        .collection('attendance')
        .doc(docId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return Attendance.fromMap(snapshot.data()!, docId: snapshot.id);
    });
  }

  /// Open punch for the employee's current shift date (handles night spanning midnight).
  Stream<Attendance?> streamCurrentShiftAttendance({
    required UserProfile user,
  }) {
    return streamCompany(user.companyId).asyncExpand((company) {
      final policy = company ??
          Company(
            id: user.companyId,
            name: user.companyName,
            createdBy: '',
          );
      final shift = HoursEngine.shiftFor(policy, user);
      final now = DateTime.now();
      final primary = HoursEngine.attendanceDateKey(now, shift);
      final previous = Attendance.formatDateKey(
        now.subtract(const Duration(days: 1)),
      );
      return _combineAttendanceDocs(user.uid, primary, previous);
    });
  }

  Stream<Attendance?> _combineAttendanceDocs(
    String uid,
    String primaryDate,
    String previousDate,
  ) {
    if (primaryDate == previousDate) {
      return streamTodayAttendance(uid: uid, date: primaryDate);
    }

    Attendance? parse(DocumentSnapshot<Map<String, dynamic>> snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return Attendance.fromMap(snapshot.data()!, docId: snapshot.id);
    }

    final primaryRef =
        _firestore.collection('attendance').doc('${uid}_$primaryDate');
    final previousRef =
        _firestore.collection('attendance').doc('${uid}_$previousDate');

    return Stream<Attendance?>.multi((controller) {
      Attendance? primary;
      Attendance? previous;
      var gotPrimary = false;
      var gotPrevious = false;

      void emit() {
        if (!gotPrimary || !gotPrevious) return;
        final open = [previous, primary]
            .whereType<Attendance>()
            .where((a) => a.isClockedIn)
            .toList();
        if (open.isNotEmpty) {
          controller.add(open.first);
          return;
        }
        controller.add(primary ?? previous);
      }

      final sub1 = primaryRef.snapshots().listen((s) {
        primary = parse(s);
        gotPrimary = true;
        emit();
      });
      final sub2 = previousRef.snapshots().listen((s) {
        previous = parse(s);
        gotPrevious = true;
        emit();
      });
      controller.onCancel = () async {
        await sub1.cancel();
        await sub2.cancel();
      };
    });
  }

  Future<Company> _companyPolicy(String companyId) async {
    return await getCompany(companyId) ??
        Company(id: companyId, name: '', createdBy: '');
  }

  /// Clock in employee with face, GPS, and network proof.
  Future<Attendance> clockIn({
    required UserProfile user,
    required PunchCapture capture,
    DateTime? time,
  }) async {
    if (!capture.isComplete) {
      throw Exception(
        'Clock-in needs a live face photo and GPS location.',
      );
    }
    final now = time ?? DateTime.now();
    final company = await _companyPolicy(user.companyId);
    final shift = HoursEngine.shiftFor(company, user);
    final dateKey = HoursEngine.attendanceDateKey(now, shift);
    final docId = '${user.uid}_$dateKey';
    final hours = HoursEngine.evaluate(
      company: company,
      user: user,
      clockIn: now,
      workedMinutes: 0,
    );

    final attendance = Attendance(
      id: docId,
      uid: user.uid,
      companyId: user.companyId,
      employeeId: user.employeeId,
      employeeName: user.name,
      department: user.department,
      reportingManagerUid: user.reportingManagerUid,
      date: dateKey,
      clockIn: now,
      clockOut: null,
      status: hours.status,
      workingMinutes: 0,
      clockInCapture: capture,
      expectedMinutes: hours.expectedMinutes,
      overtimeMinutes: 0,
      shortfallMinutes: 0,
      workMode: user.workMode,
      shiftType: user.shiftType,
      createdAt: now,
      updatedAt: now,
    );

    await _firestore
        .collection('attendance')
        .doc(docId)
        .set(attendance.toMap(), SetOptions(merge: true));

    return attendance;
  }

  Future<Attendance> _loadAttendance(String attendanceId) async {
    final snapshot =
        await _firestore.collection('attendance').doc(attendanceId).get();
    if (!snapshot.exists || snapshot.data() == null) {
      throw Exception('Attendance record not found');
    }
    return Attendance.fromMap(snapshot.data()!, docId: snapshot.id);
  }

  List<AttendanceBreak> _endedBreaks(Attendance attendance, DateTime now) {
    return [
      for (final item in attendance.breaks)
        item.isActive ? item.copyWith(end: now) : item,
    ];
  }

  /// Clock out employee with face, GPS, and network proof.
  Future<Attendance> clockOut({
    required String attendanceId,
    required DateTime clockInTime,
    required PunchCapture capture,
    DateTime? time,
  }) async {
    if (!capture.isComplete) {
      throw Exception(
        'Clock-out needs a live face photo and GPS location.',
      );
    }
    final now = time ?? DateTime.now();
    final docRef = _firestore.collection('attendance').doc(attendanceId);
    final current = await _loadAttendance(attendanceId);
    final closedBreaks = _endedBreaks(current, now);
    final settled = current.copyWith(
      clockIn: current.clockIn ?? clockInTime,
      clockOut: now,
      breaks: closedBreaks,
      clockOutCapture: capture,
    );
    final workingMinutes = settled.netWorkedDuration(now).inMinutes;
    final company = await _companyPolicy(current.companyId);
    final user = await getUserProfile(current.uid) ??
        UserProfile(
          uid: current.uid,
          companyId: current.companyId,
          name: current.employeeName,
          email: '',
          role: 'EMPLOYEE',
          workMode: current.workMode,
          shiftType: current.shiftType,
        );
    final hours = HoursEngine.evaluate(
      company: company,
      user: user,
      clockIn: current.clockIn ?? clockInTime,
      clockOut: now,
      workedMinutes: workingMinutes,
    );

    await docRef.update({
      'clockOut': Timestamp.fromDate(now),
      'workingMinutes': workingMinutes,
      'status': hours.status,
      'expectedMinutes': hours.expectedMinutes,
      'overtimeMinutes': hours.overtimeMinutes,
      'shortfallMinutes': hours.shortfallMinutes,
      'breaks': closedBreaks.map((b) => b.toMap()).toList(),
      'clockOutCapture': capture.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final updatedSnapshot = await docRef.get();
    return Attendance.fromMap(updatedSnapshot.data()!, docId: docRef.id);
  }

  Future<void> startBreak({
    required String attendanceId,
    required String type,
    DateTime? time,
  }) async {
    final now = time ?? DateTime.now();
    final current = await _loadAttendance(attendanceId);
    if (!current.isClockedIn) {
      throw Exception('Clock in before starting a break');
    }
    if (current.isOnBreak) {
      throw Exception('End the current break first');
    }

    final kind = type.toUpperCase() == 'LUNCH' ? 'LUNCH' : 'OTHER';
    final breaks = [
      ...current.breaks,
      AttendanceBreak(
        id: '${kind}_${now.millisecondsSinceEpoch}',
        type: kind,
        start: now,
      ),
    ];

    await _firestore.collection('attendance').doc(attendanceId).update({
      'breaks': breaks.map((b) => b.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> endBreak({
    required String attendanceId,
    DateTime? time,
  }) async {
    final now = time ?? DateTime.now();
    final current = await _loadAttendance(attendanceId);
    if (!current.isOnBreak) {
      throw Exception('No active break to end');
    }

    final breaks = _endedBreaks(current, now);
    await _firestore.collection('attendance').doc(attendanceId).update({
      'breaks': breaks.map((b) => b.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Streams attendance history for an employee
  Stream<List<Attendance>> streamEmployeeAttendanceHistory(String uid) {
    return _firestore
        .collection('attendance')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => Attendance.fromMap(doc.data(), docId: doc.id))
          .toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  /// Streams company attendance for a specific date
  Stream<List<Attendance>> streamCompanyAttendanceByDate({
    required String companyId,
    required String date,
  }) {
    return _firestore
        .collection('attendance')
        .where('companyId', isEqualTo: companyId)
        .where('date', isEqualTo: date)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => Attendance.fromMap(doc.data(), docId: doc.id))
          .toList();
      list.sort((a, b) => a.employeeName.compareTo(b.employeeName));
      return list;
    });
  }

  /// Streams all company attendance records (for week/month/all history reports)
  Stream<List<Attendance>> streamCompanyAllAttendance(String companyId) {
    return _firestore
        .collection('attendance')
        .where('companyId', isEqualTo: companyId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => Attendance.fromMap(doc.data(), docId: doc.id))
          .toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  // ==========================================
  // LEAVE MANAGEMENT METHODS
  // ==========================================

  /// Submit a new leave request
  Future<String> submitLeaveRequest(LeaveRequest request) async {
    final docRef = request.id.isNotEmpty
        ? _firestore.collection('leave_requests').doc(request.id)
        : _firestore.collection('leave_requests').doc();

    final reqWithId = request.copyWith(id: docRef.id);
    await docRef.set(reqWithId.toMap());
    return docRef.id;
  }

  /// Streams leave requests for a single employee
  Stream<List<LeaveRequest>> streamEmployeeLeaveRequests(String uid) {
    return _firestore
        .collection('leave_requests')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => LeaveRequest.fromMap(doc.data(), docId: doc.id))
          .toList();
      list.sort((a, b) {
        if (a.createdAt != null && b.createdAt != null) {
          return b.createdAt!.compareTo(a.createdAt!);
        }
        return b.startDate.compareTo(a.startDate);
      });
      return list;
    });
  }

  /// Streams all leave requests for a company
  Stream<List<LeaveRequest>> streamCompanyLeaveRequests(String companyId) {
    return _firestore
        .collection('leave_requests')
        .where('companyId', isEqualTo: companyId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => LeaveRequest.fromMap(doc.data(), docId: doc.id))
          .toList();
      list.sort((a, b) {
        if (a.createdAt != null && b.createdAt != null) {
          return b.createdAt!.compareTo(a.createdAt!);
        }
        return b.startDate.compareTo(a.startDate);
      });
      return list;
    });
  }

  /// Review leave request (Approve or Reject by Admin/HR)
  Future<void> reviewLeaveRequest({
    required String requestId,
    required String status, // APPROVED or REJECTED
    required String reviewedBy,
    required String reviewedByName,
    String? reviewComment,
  }) async {
    await _firestore.collection('leave_requests').doc(requestId).update({
      'status': status,
      'reviewedBy': reviewedBy,
      'reviewedByName': reviewedByName,
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewComment': reviewComment?.trim() ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Cancel a pending leave request by employee
  Future<void> cancelLeaveRequest(String requestId) async {
    await _firestore.collection('leave_requests').doc(requestId).update({
      'status': 'CANCELLED',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateOnboardingChecklist({
    required String uid,
    required bool docsCollected,
    required bool assetsAssigned,
    required bool accessReady,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'onboardingDocsCollected': docsCollected,
      'onboardingAssetsAssigned': assetsAssigned,
      'onboardingAccessReady': accessReady,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ==========================================
  // TIMESHEET
  // ==========================================

  Future<String> submitTimesheet(TimesheetEntry entry) async {
    final docRef = entry.id.isNotEmpty
        ? _firestore.collection('timesheets').doc(entry.id)
        : _firestore.collection('timesheets').doc();
    await docRef.set({
      ...entry.toMap(),
      'id': docRef.id,
    });
    return docRef.id;
  }

  Stream<List<TimesheetEntry>> streamEmployeeTimesheets(String uid) {
    return _firestore
        .collection('timesheets')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => TimesheetEntry.fromMap(doc.data(), docId: doc.id))
          .toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  Stream<List<TimesheetEntry>> streamCompanyTimesheets(String companyId) {
    return _firestore
        .collection('timesheets')
        .where('companyId', isEqualTo: companyId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => TimesheetEntry.fromMap(doc.data(), docId: doc.id))
          .toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  Future<void> reviewTimesheet({
    required String id,
    required String status,
    required String reviewedBy,
    required String reviewedByName,
  }) async {
    await _firestore.collection('timesheets').doc(id).update({
      'status': status,
      'reviewedBy': reviewedBy,
      'reviewedByName': reviewedByName,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ==========================================
  // EXPENSES
  // ==========================================

  Future<String> submitExpense(ExpenseClaim claim) async {
    final docRef = claim.id.isNotEmpty
        ? _firestore.collection('expenses').doc(claim.id)
        : _firestore.collection('expenses').doc();
    await docRef.set({
      ...claim.toMap(),
      'id': docRef.id,
    });
    return docRef.id;
  }

  Stream<List<ExpenseClaim>> streamEmployeeExpenses(String uid) {
    return _firestore
        .collection('expenses')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ExpenseClaim.fromMap(doc.data(), docId: doc.id))
          .toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  Stream<List<ExpenseClaim>> streamCompanyExpenses(String companyId) {
    return _firestore
        .collection('expenses')
        .where('companyId', isEqualTo: companyId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ExpenseClaim.fromMap(doc.data(), docId: doc.id))
          .toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  Future<void> reviewExpense({
    required String id,
    required String status,
    required String reviewedBy,
    required String reviewedByName,
  }) async {
    await _firestore.collection('expenses').doc(id).update({
      'status': status,
      'reviewedBy': reviewedBy,
      'reviewedByName': reviewedByName,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ==========================================
  // ASSETS
  // ==========================================

  Future<String> saveAsset(CompanyAsset asset) async {
    final docRef = asset.id.isNotEmpty
        ? _firestore.collection('assets').doc(asset.id)
        : _firestore.collection('assets').doc();
    await docRef.set({
      ...asset.toMap(),
      'id': docRef.id,
    });
    return docRef.id;
  }

  Stream<List<CompanyAsset>> streamCompanyAssets(String companyId) {
    return _firestore
        .collection('assets')
        .where('companyId', isEqualTo: companyId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => CompanyAsset.fromMap(doc.data(), docId: doc.id))
          .toList();
      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    });
  }

  Stream<List<CompanyAsset>> streamEmployeeAssets(String uid) {
    return _firestore
        .collection('assets')
        .where('assignedUid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CompanyAsset.fromMap(doc.data(), docId: doc.id))
          .toList();
    });
  }

  // ==========================================
  // PERFORMANCE
  // ==========================================

  Future<String> savePerformanceGoal(PerformanceGoal goal) async {
    final docRef = goal.id.isNotEmpty
        ? _firestore.collection('performance_goals').doc(goal.id)
        : _firestore.collection('performance_goals').doc();
    await docRef.set({
      ...goal.toMap(),
      'id': docRef.id,
    });
    return docRef.id;
  }

  Stream<List<PerformanceGoal>> streamCompanyGoals(String companyId) {
    return _firestore
        .collection('performance_goals')
        .where('companyId', isEqualTo: companyId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => PerformanceGoal.fromMap(doc.data(), docId: doc.id))
          .toList();
      list.sort((a, b) => a.employeeName.compareTo(b.employeeName));
      return list;
    });
  }

  Stream<List<PerformanceGoal>> streamEmployeeGoals(String uid) {
    return _firestore
        .collection('performance_goals')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PerformanceGoal.fromMap(doc.data(), docId: doc.id))
          .toList();
    });
  }

  // ==========================================
  // RECRUITMENT
  // ==========================================

  Future<String> saveCandidate(RecruitmentCandidate candidate) async {
    final docRef = candidate.id.isNotEmpty
        ? _firestore.collection('candidates').doc(candidate.id)
        : _firestore.collection('candidates').doc();
    await docRef.set({
      ...candidate.toMap(),
      'id': docRef.id,
    });
    return docRef.id;
  }

  Stream<List<RecruitmentCandidate>> streamCompanyCandidates(String companyId) {
    return _firestore
        .collection('candidates')
        .where('companyId', isEqualTo: companyId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RecruitmentCandidate.fromMap(doc.data(), docId: doc.id))
          .toList();
    });
  }

  // ==========================================
  // PAYSLIPS
  // ==========================================

  Future<String> issuePayslip(Payslip payslip) async {
    final docRef = _firestore.collection('payslips').doc(payslip.id);
    await docRef.set(payslip.toMap());
    return docRef.id;
  }

  Stream<List<Payslip>> streamEmployeePayslips(String uid) {
    return _firestore
        .collection('payslips')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => Payslip.fromMap(doc.data(), docId: doc.id))
          .toList();
      list.sort((a, b) => b.month.compareTo(a.month));
      return list;
    });
  }

  Stream<List<Payslip>> streamCompanyPayslips(String companyId) {
    return _firestore
        .collection('payslips')
        .where('companyId', isEqualTo: companyId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => Payslip.fromMap(doc.data(), docId: doc.id))
          .toList();
      list.sort((a, b) => b.month.compareTo(a.month));
      return list;
    });
  }
}
