import 'package:flutter/material.dart';

import '../models/user_profile.dart';

class NavItem {
  final String id;
  final String label;
  final IconData icon;

  const NavItem({
    required this.id,
    required this.label,
    required this.icon,
  });
}

class NavGroup {
  final String title;
  final List<NavItem> items;

  const NavGroup({
    required this.title,
    required this.items,
  });
}

class AppNav {
  static List<NavGroup> groupsFor(UserProfile user) {
    if (user.isPeopleOps) {
      return const [
        NavGroup(
          title: 'Overview',
          items: [
            NavItem(id: 'home', label: 'Home', icon: Icons.dashboard_outlined),
          ],
        ),
        NavGroup(
          title: 'Core HR',
          items: [
            NavItem(id: 'people', label: 'HR & People', icon: Icons.people_outline),
            NavItem(
                id: 'onboarding',
                label: 'Employee Onboarding',
                icon: Icons.person_add_alt_1_outlined),
            NavItem(
                id: 'letters',
                label: 'Letters & Documents',
                icon: Icons.mail_outline),
          ],
        ),
        NavGroup(
          title: 'Time & Attendance',
          items: [
            NavItem(
                id: 'attendance',
                label: 'Attendance',
                icon: Icons.schedule_outlined),
            NavItem(id: 'leave', label: 'Leave', icon: Icons.event_available_outlined),
            NavItem(
                id: 'timesheet',
                label: 'Timesheet',
                icon: Icons.timer_outlined),
          ],
        ),
        NavGroup(
          title: 'Payroll & Expenses',
          items: [
            NavItem(
                id: 'payslips',
                label: 'Payslips',
                icon: Icons.payments_outlined),
            NavItem(
                id: 'expenses',
                label: 'Expenses',
                icon: Icons.receipt_long_outlined),
            NavItem(
                id: 'assets', label: 'Assets', icon: Icons.devices_outlined),
          ],
        ),
        NavGroup(
          title: 'Talent',
          items: [
            NavItem(
                id: 'recruitment',
                label: 'Recruitment & ATS',
                icon: Icons.work_outline),
            NavItem(
                id: 'performance',
                label: 'Performance',
                icon: Icons.insights_outlined),
          ],
        ),
        NavGroup(
          title: 'My Workspace',
          items: [
            NavItem(
                id: 'myLeave',
                label: 'My Leave',
                icon: Icons.beach_access_outlined),
            NavItem(
                id: 'profile',
                label: 'My Profile',
                icon: Icons.account_circle_outlined),
          ],
        ),
      ];
    }

    if (user.isManager) {
      return const [
        NavGroup(
          title: 'Overview',
          items: [
            NavItem(id: 'home', label: 'Home', icon: Icons.dashboard_outlined),
            NavItem(id: 'team', label: 'My Team', icon: Icons.groups_outlined),
          ],
        ),
        NavGroup(
          title: 'Time & Attendance',
          items: [
            NavItem(
                id: 'attendance',
                label: 'Team Attendance',
                icon: Icons.schedule_outlined),
            NavItem(
                id: 'leave',
                label: 'Team Leave',
                icon: Icons.event_available_outlined),
            NavItem(
                id: 'timesheet',
                label: 'Team Timesheets',
                icon: Icons.timer_outlined),
          ],
        ),
        NavGroup(
          title: 'Payroll & Expenses',
          items: [
            NavItem(
                id: 'expenses',
                label: 'Team Expenses',
                icon: Icons.receipt_long_outlined),
          ],
        ),
        NavGroup(
          title: 'Talent',
          items: [
            NavItem(
                id: 'performance',
                label: 'Team Performance',
                icon: Icons.insights_outlined),
          ],
        ),
        NavGroup(
          title: 'My Workspace',
          items: [
            NavItem(
                id: 'myLeave',
                label: 'My Leave',
                icon: Icons.beach_access_outlined),
            NavItem(
                id: 'myTimesheet',
                label: 'My Timesheet',
                icon: Icons.timer_outlined),
            NavItem(
                id: 'myLetters',
                label: 'My Letters',
                icon: Icons.mail_outline),
            NavItem(
                id: 'profile',
                label: 'My Profile',
                icon: Icons.account_circle_outlined),
          ],
        ),
      ];
    }

    if (user.isTeamLead) {
      return const [
        NavGroup(
          title: 'Overview',
          items: [
            NavItem(id: 'home', label: 'Home', icon: Icons.dashboard_outlined),
            NavItem(id: 'team', label: 'My Team', icon: Icons.groups_outlined),
          ],
        ),
        NavGroup(
          title: 'Time & Attendance',
          items: [
            NavItem(
                id: 'attendance',
                label: 'Team Attendance',
                icon: Icons.schedule_outlined),
            NavItem(
                id: 'leave',
                label: 'Leave Approvals',
                icon: Icons.event_available_outlined),
            NavItem(
                id: 'timesheet',
                label: 'Team Timesheets',
                icon: Icons.timer_outlined),
          ],
        ),
        NavGroup(
          title: 'My Workspace',
          items: [
            NavItem(
                id: 'myLeave',
                label: 'My Leave',
                icon: Icons.beach_access_outlined),
            NavItem(
                id: 'myTimesheet',
                label: 'My Timesheet',
                icon: Icons.timer_outlined),
            NavItem(
                id: 'myLetters',
                label: 'My Letters',
                icon: Icons.mail_outline),
            NavItem(
                id: 'profile',
                label: 'My Profile',
                icon: Icons.account_circle_outlined),
          ],
        ),
      ];
    }

    return const [
      NavGroup(
        title: 'My Workspace',
        items: [
          NavItem(id: 'home', label: 'Home', icon: Icons.home_outlined),
          NavItem(
              id: 'myLeave',
              label: 'Leave',
              icon: Icons.event_available_outlined),
          NavItem(
              id: 'myTimesheet',
              label: 'Timesheet',
              icon: Icons.timer_outlined),
          NavItem(
              id: 'expenses',
              label: 'Expenses',
              icon: Icons.receipt_long_outlined),
          NavItem(id: 'assets', label: 'My Assets', icon: Icons.devices_outlined),
          NavItem(
              id: 'payslips',
              label: 'Payslips',
              icon: Icons.payments_outlined),
          NavItem(
              id: 'myLetters',
              label: 'My Letters',
              icon: Icons.mail_outline),
          NavItem(
              id: 'profile',
              label: 'My Profile',
              icon: Icons.account_circle_outlined),
        ],
      ),
    ];
  }

  static String portalTitle(UserProfile user) {
    if (user.isCompanyAdmin) return 'Company Admin Portal';
    if (user.isHR) return 'HR Portal';
    if (user.isManager) return 'Manager Portal';
    if (user.isTeamLead) return 'Team Lead Portal';
    return 'Employee Workspace';
  }
}
