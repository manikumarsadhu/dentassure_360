import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../navigation/app_nav.dart';
import '../theme/app_motion.dart';
import 'app_logo.dart';
import 'user_avatar.dart';

class AppShell extends StatelessWidget {
  final UserProfile user;
  final String selectedId;
  final ValueChanged<String> onSelect;
  final Widget body;
  final VoidCallback onLogout;
  final VoidCallback? onOpenProfile;

  const AppShell({
    super.key,
    required this.user,
    required this.selectedId,
    required this.onSelect,
    required this.body,
    required this.onLogout,
    this.onOpenProfile,
  });

  @override
  Widget build(BuildContext context) {
    final groups = AppNav.groupsFor(user);
    final isWide = MediaQuery.sizeOf(context).width >= 980;

    final sidebar = _NavSidebar(
      user: user,
      groups: groups,
      selectedId: selectedId,
      onSelect: onSelect,
      onLogout: onLogout,
      onOpenProfile: onOpenProfile,
    );

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            sidebar,
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const AppHeaderLogo(height: 38, maxWidth: 230),
        actions: [
          IconButton(
            tooltip: 'Sign Out',
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      drawer: Drawer(child: sidebar),
      body: body,
    );
  }
}

class _NavSidebar extends StatelessWidget {
  final UserProfile user;
  final List<NavGroup> groups;
  final String selectedId;
  final ValueChanged<String> onSelect;
  final VoidCallback onLogout;
  final VoidCallback? onOpenProfile;

  const _NavSidebar({
    required this.user,
    required this.groups,
    required this.selectedId,
    required this.onSelect,
    required this.onLogout,
    this.onOpenProfile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      child: SizedBox(
        width: 268,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
          ),
          child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: AppHeaderLogo(height: 42, maxWidth: 260),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: InkWell(
                onTap: onOpenProfile,
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  children: [
                    UserAvatar(
                      key: ValueKey(user.avatarUrl),
                      avatarUrl: user.avatarUrl,
                      name: user.name,
                      radius: 22,
                      fontSize: 16,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            user.role.replaceAll('_', ' '),
                            style: TextStyle(
                              fontSize: 11,
                              color: scheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  for (final group in groups) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 12, 6),
                      child: Text(
                        group.title.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    for (final item in group.items)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 2,
                        ),
                        child: PressableScale(
                          child: ListTile(
                            selected: selectedId == item.id,
                            selectedTileColor: scheme.primaryContainer,
                            selectedColor: scheme.onPrimaryContainer,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            leading: Icon(
                              item.icon,
                              color: selectedId == item.id
                                  ? scheme.primary
                                  : scheme.onSurfaceVariant,
                            ),
                            title: Text(
                              item.label,
                              style: TextStyle(
                                fontWeight: selectedId == item.id
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontSize: 14,
                                color: selectedId == item.id
                                    ? scheme.primary
                                    : scheme.onSurface,
                              ),
                            ),
                            onTap: () {
                              onSelect(item.id);
                              if (Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                              }
                            },
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: const Text('Sign out'),
              onTap: onLogout,
            ),
          ],
        ),
          ),
        ),
      ),
    );
  }
}
