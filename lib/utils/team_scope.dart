import '../models/user_profile.dart';

class TeamScope {
  static List<UserProfile> directReports({
    required List<UserProfile> all,
    required String managerUid,
  }) {
    return all
        .where((u) => u.uid != managerUid && u.reportingManagerUid == managerUid)
        .toList();
  }

  /// Manager downline: direct reports plus people who report to those Team Leads.
  static List<UserProfile> skipLevelReports({
    required List<UserProfile> all,
    required String managerUid,
  }) {
    final direct = directReports(all: all, managerUid: managerUid);
    final leadIds = direct.where((u) => u.isTeamLead).map((u) => u.uid).toSet();
    final nested = all.where(
      (u) => u.uid != managerUid && leadIds.contains(u.reportingManagerUid),
    );
    final seen = <String>{};
    final result = <UserProfile>[];
    for (final member in [...direct, ...nested]) {
      if (seen.add(member.uid)) {
        result.add(member);
      }
    }
    return result;
  }

  static List<UserProfile> reportsFor(UserProfile viewer, List<UserProfile> all) {
    if (viewer.isPeopleOps) {
      return all.where((u) => u.uid != viewer.uid).toList();
    }
    if (viewer.isManager) {
      return skipLevelReports(all: all, managerUid: viewer.uid);
    }
    if (viewer.isTeamLead) {
      return directReports(all: all, managerUid: viewer.uid);
    }
    return const [];
  }

  static Set<String> reportUids(UserProfile viewer, List<UserProfile> all) {
    return reportsFor(viewer, all).map((u) => u.uid).toSet();
  }

  static bool canApprove(
    UserProfile viewer,
    UserProfile subject, {
    List<UserProfile> all = const [],
  }) {
    if (viewer.isPeopleOps) return subject.companyId == viewer.companyId;
    if (viewer.uid == subject.uid) return false;
    return reportUids(viewer, all).contains(subject.uid) ||
        subject.reportingManagerUid == viewer.uid;
  }
}
