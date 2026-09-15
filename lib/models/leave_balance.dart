import 'leave_request.dart';

class LeaveBalance {
  final int totalCasual;
  final int totalSick;
  final int totalAnnual;

  final int usedCasual;
  final int usedSick;
  final int usedAnnual;
  final int usedUnpaid;

  const LeaveBalance({
    this.totalCasual = 12,
    this.totalSick = 10,
    this.totalAnnual = 15,
    this.usedCasual = 0,
    this.usedSick = 0,
    this.usedAnnual = 0,
    this.usedUnpaid = 0,
  });

  int get availableCasual => (totalCasual - usedCasual).clamp(0, 999);
  int get availableSick => (totalSick - usedSick).clamp(0, 999);
  int get availableAnnual => (totalAnnual - usedAnnual).clamp(0, 999);

  /// Computes the balance from a list of approved leave requests
  factory LeaveBalance.fromApprovedRequests(List<LeaveRequest> requests) {
    int casual = 0;
    int sick = 0;
    int annual = 0;
    int unpaid = 0;

    for (final req in requests) {
      if (req.isApproved) {
        switch (req.leaveType.toUpperCase()) {
          case 'CASUAL':
            casual += req.totalDays;
            break;
          case 'SICK':
            sick += req.totalDays;
            break;
          case 'ANNUAL':
            annual += req.totalDays;
            break;
          case 'UNPAID':
            unpaid += req.totalDays;
            break;
        }
      }
    }

    return LeaveBalance(
      totalCasual: 12,
      totalSick: 10,
      totalAnnual: 15,
      usedCasual: casual,
      usedSick: sick,
      usedAnnual: annual,
      usedUnpaid: unpaid,
    );
  }
}
