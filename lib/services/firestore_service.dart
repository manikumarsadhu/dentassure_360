import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/attendance.dart';
import '../models/company.dart';
import '../models/leave_request.dart';
import '../models/user_profile.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Creates a new Company and the associated Company Admin profile atomically using a batch write.
  /// Generates a unique company document ID if not explicitly provided.
  Future<String> createCompany({
    required String companyName,
    required String adminUid,
    required String adminName,
    required String adminEmail,
    String? explicitCompanyId,
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

    batch.set(companyRef, {
      'id': companyId,
      'name': cleanCompanyName,
      'createdBy': adminUid,
      'adminEmail': cleanAdminEmail,
      'adminName': cleanAdminName,
      'status': 'ACTIVE',
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.set(userRef, {
      'uid': adminUid,
      'companyId': companyId,
      'companyName': cleanCompanyName,
      'name': cleanAdminName,
      'email': cleanAdminEmail,
      'role': 'COMPANY_ADMIN',
      'status': 'ACTIVE',
      'department': 'Executive Administration',
      'designation': 'Organization Administrator',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    return companyId;
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
      'joiningDate': employee.joiningDate != null
          ? Timestamp.fromDate(employee.joiningDate!)
          : null,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('users').doc(employee.uid).update(updateData);
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

  /// Clock in employee
  Future<Attendance> clockIn({
    required UserProfile user,
    DateTime? time,
  }) async {
    final now = time ?? DateTime.now();
    final dateKey = Attendance.formatDateKey(now);
    final docId = '${user.uid}_$dateKey';

    // Late threshold: after 09:30 AM
    final isLate = (now.hour > 9) || (now.hour == 9 && now.minute > 30);
    final status = isLate ? 'LATE' : 'PRESENT';

    final attendance = Attendance(
      id: docId,
      uid: user.uid,
      companyId: user.companyId,
      employeeId: user.employeeId,
      employeeName: user.name,
      department: user.department,
      date: dateKey,
      clockIn: now,
      clockOut: null,
      status: status,
      workingMinutes: 0,
      createdAt: now,
      updatedAt: now,
    );

    await _firestore
        .collection('attendance')
        .doc(docId)
        .set(attendance.toMap(), SetOptions(merge: true));

    return attendance;
  }

  /// Clock out employee
  Future<Attendance> clockOut({
    required String attendanceId,
    required DateTime clockInTime,
    DateTime? time,
  }) async {
    final now = time ?? DateTime.now();
    final workingMinutes = now.difference(clockInTime).inMinutes;

    final docRef = _firestore.collection('attendance').doc(attendanceId);
    final snapshot = await docRef.get();
    String newStatus = 'PRESENT';

    if (snapshot.exists && snapshot.data() != null) {
      final currentStatus = snapshot.data()?['status'] ?? 'PRESENT';
      if (currentStatus == 'LATE') {
        newStatus = 'LATE';
      } else if (workingMinutes < 240) {
        // Less than 4 hours is HALF_DAY
        newStatus = 'HALF_DAY';
      }
    }

    await docRef.update({
      'clockOut': Timestamp.fromDate(now),
      'workingMinutes': workingMinutes,
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final updatedSnapshot = await docRef.get();
    return Attendance.fromMap(updatedSnapshot.data()!, docId: docRef.id);
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
}
