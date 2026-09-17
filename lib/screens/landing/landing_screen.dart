import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/app_motion.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/platform_suite_art.dart';
import '../auth/login_screen.dart';

/// Unsigned entry: landing first, then login on a nested stack so a successful
/// sign-in can replace this entire shell without leftover routes.
class PublicShell extends StatelessWidget {
  const PublicShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      initialRoute: '/',
      onGenerateRoute: (settings) {
        final page = settings.name == '/login'
            ? const LoginScreen()
            : const LandingScreen();
        return MaterialPageRoute(settings: settings, builder: (_) => page);
      },
    );
  }
}

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final _scroll = ScrollController();
  final _productKey = GlobalKey();
  final _rolesKey = GlobalKey();
  final _platformKey = GlobalKey();
  bool _elevatedNav = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final next = _scroll.offset > 12;
      if (next != _elevatedNav) setState(() => _elevatedNav = next);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _openLogin() {
    Navigator.of(context).pushNamed('/login');
  }

  Future<void> _scrollTo(GlobalKey key) async {
    final ctx = key.currentContext;
    if (ctx == null) return;
    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 560),
      curve: Curves.easeOutCubic,
      alignment: 0.06,
    );
  }

  void _openMobileMenu() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SheetLink(
                  label: 'Product',
                  onTap: () {
                    Navigator.pop(ctx);
                    _scrollTo(_productKey);
                  },
                ),
                _SheetLink(
                  label: 'Roles',
                  onTap: () {
                    Navigator.pop(ctx);
                    _scrollTo(_rolesKey);
                  },
                ),
                _SheetLink(
                  label: 'Platform',
                  onTap: () {
                    Navigator.pop(ctx);
                    _scrollTo(_platformKey);
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _openLogin();
                    },
                    child: const Text('Open workspace'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 980;
    final compact = width < 720;

    return Scaffold(
      backgroundColor: AppTheme.pageSurface,
      body: Column(
        children: [
          _TopNav(
            elevated: _elevatedNav,
            compact: compact,
            onLogoTap: () => _scroll.animateTo(
              0,
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutCubic,
            ),
            onProduct: () => _scrollTo(_productKey),
            onRoles: () => _scrollTo(_rolesKey),
            onPlatform: () => _scrollTo(_platformKey),
            onSignIn: _openLogin,
            onMenu: _openMobileMenu,
          ),
          Expanded(
            child: Stack(
              children: [
                const _AmbientBackground(),
                SelectionArea(
                  child: SingleChildScrollView(
                    controller: _scroll,
                    child: Column(
                      children: [
                        _HeroSection(
                          compact: compact,
                          wide: wide,
                          onOpen: _openLogin,
                          onExplore: () => _scrollTo(_productKey),
                        ),
                        _StatsStrip(compact: compact),
                        KeyedSubtree(
                          key: _productKey,
                          child: const _FeaturesSection(),
                        ),
                        KeyedSubtree(
                          key: _rolesKey,
                          child: const _RolesSection(),
                        ),
                        const _HowItWorksSection(),
                        KeyedSubtree(
                          key: _platformKey,
                          child: _PlatformSection(
                            compact: compact,
                            onOpen: _openLogin,
                          ),
                        ),
                        _FinalCta(onOpen: _openLogin),
                        const _Footer(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SheetLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
      onTap: onTap,
    );
  }
}

class _TopNav extends StatelessWidget {
  final bool elevated;
  final bool compact;
  final VoidCallback onLogoTap;
  final VoidCallback onProduct;
  final VoidCallback onRoles;
  final VoidCallback onPlatform;
  final VoidCallback onSignIn;
  final VoidCallback onMenu;

  const _TopNav({
    required this.elevated,
    required this.compact,
    required this.onLogoTap,
    required this.onProduct,
    required this.onRoles,
    required this.onPlatform,
    required this.onSignIn,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.press,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: elevated ? 0.92 : 0.72),
        border: Border(
          bottom: BorderSide(
            color: Colors.black.withValues(alpha: elevated ? 0.06 : 0.03),
          ),
        ),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : const [],
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1160),
                  child: Row(
                    children: [
                    InkWell(
                      onTap: onLogoTap,
                      borderRadius: BorderRadius.circular(14),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                        child: _BrandMark(),
                      ),
                    ),
                    const Spacer(),
                    if (!compact) ...[
                      _NavText(label: 'Product', onTap: onProduct),
                      _NavText(label: 'Roles', onTap: onRoles),
                      _NavText(label: 'Platform', onTap: onPlatform),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: onSignIn,
                        child: const Text('Sign in'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: onSignIn,
                        child: const Text('Open workspace'),
                      ),
                    ] else ...[
                      TextButton(onPressed: onSignIn, child: const Text('Sign in')),
                      IconButton(
                        tooltip: 'Menu',
                        onPressed: onMenu,
                        icon: const Icon(Icons.menu_rounded),
                      ),
                    ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return const AppHeaderLogo(height: 48, maxWidth: 200);
  }
}

class _NavText extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _NavText({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade800,
        ),
      ),
    );
  }
}

class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Stack(
        children: [
          Positioned(top: -80, left: -60, child: _Glow(color: AppTheme.primary, size: 320)),
          Positioned(top: 120, right: -90, child: _Glow(color: AppTheme.secondary, size: 280)),
          Positioned(bottom: 80, left: 40, child: _Glow(color: AppTheme.tertiary, size: 220)),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final Color color;
  final double size;

  const _Glow({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.18),
            color.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}

class _MaxWidth extends StatelessWidget {
  final Widget child;

  const _MaxWidth({required this.child});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1160),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: child,
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final bool compact;
  final bool wide;
  final VoidCallback onOpen;
  final VoidCallback onExplore;

  const _HeroSection({
    required this.compact,
    required this.wide,
    required this.onOpen,
    required this.onExplore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headline = theme.textTheme.displaySmall?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -1.4,
      height: 1.08,
      fontSize: compact ? 36 : 56,
      color: const Color(0xFF0B1F3A),
    );

    final copy = Column(
      crossAxisAlignment: compact
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        FadeSlideIn(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.16)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  compact
                      ? 'Live attendance · Multi-company SaaS'
                      : 'Live attendance · Leave that stays in sync · Multi-company SaaS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        FadeSlideIn(
          delay: const Duration(milliseconds: 60),
          child: Text(
            'The operating system\nfor your workforce.',
            textAlign: compact ? TextAlign.center : TextAlign.start,
            style: headline,
          ),
        ),
        const SizedBox(height: 16),
        FadeSlideIn(
          delay: const Duration(milliseconds: 110),
          child: Text(
            'Dentassure 360 replaces spreadsheets and chat with one workspace: clock-in, leave, people, timesheets, expenses, and payslips — with the right view for every role.',
            textAlign: compact ? TextAlign.center : TextAlign.start,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.grey.shade700,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 28),
        FadeSlideIn(
          delay: const Duration(milliseconds: 160),
          child: Wrap(
            alignment: compact ? WrapAlignment.center : WrapAlignment.start,
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Open workspace'),
                ),
              ),
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: onExplore,
                  icon: const Icon(Icons.north_east_rounded),
                  label: const Text('Explore the product'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        FadeSlideIn(
          delay: const Duration(milliseconds: 210),
          child: Wrap(
            alignment: compact ? WrapAlignment.center : WrapAlignment.start,
            spacing: 16,
            runSpacing: 8,
            children: const [
              _HeroTrust(icon: Icons.verified_user_outlined, label: 'Role-based access'),
              _HeroTrust(icon: Icons.apartment_outlined, label: 'Company isolation'),
              _HeroTrust(icon: Icons.devices_outlined, label: 'Web, iOS & Android'),
            ],
          ),
        ),
      ],
    );

    final preview = FadeSlideIn(
      delay: const Duration(milliseconds: 120),
      beginOffset: const Offset(0.04, 0.02),
      child: const _ProductPreview(),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(0, compact ? 28 : 48, 0, compact ? 36 : 56),
      child: _MaxWidth(
        child: wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(flex: 11, child: copy),
                  const SizedBox(width: 36),
                  Expanded(flex: 12, child: preview),
                ],
              )
            : Column(
                children: [
                  copy,
                  const SizedBox(height: 28),
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 20),
                    child: preview,
                  ),
                ],
              ),
      ),
    );
  }
}

class _HeroTrust extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroTrust({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppTheme.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}

class _ProductPreview extends StatelessWidget {
  const _ProductPreview();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showPills = constraints.maxWidth >= 420;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0B1F3A), Color(0xFF1565D8)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.28),
                    blurRadius: 40,
                    offset: const Offset(0, 22),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF6B6B),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFD166),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFF06D6A0),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'HR Portal · Dentassure',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good morning, Dany',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Today’s workforce at a glance',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 16),
                        const Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _PreviewStat(label: 'Headcount', value: '48', color: AppTheme.primary),
                            _PreviewStat(label: 'Present', value: '41', color: AppTheme.secondary),
                            _PreviewStat(label: 'Late', value: '3', color: AppTheme.tertiary),
                            _PreviewStat(label: 'On leave', value: '4', color: Color(0xFF7C3AED)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F6FB),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppTheme.secondary.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.schedule_rounded,
                                  color: AppTheme.secondary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Live clock-in',
                                      style: TextStyle(fontWeight: FontWeight.w800),
                                    ),
                                    Text(
                                      'Late after 9:30 AM · half-day under 4 hours',
                                      style: TextStyle(fontSize: 12, color: Color(0xFF5B677A)),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F8F4),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  'On shift',
                                  style: TextStyle(
                                    color: AppTheme.secondary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (showPills) ...[
              const Positioned(
                top: -14,
                right: 18,
                child: _FloatingPill(
                  icon: Icons.check_circle_rounded,
                  color: AppTheme.secondary,
                  label: 'Leave approved',
                ),
              ),
              const Positioned(
                bottom: -12,
                left: 22,
                child: _FloatingPill(
                  icon: Icons.timer_outlined,
                  color: AppTheme.primary,
                  label: 'Timesheet pending · 2',
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _PreviewStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _PreviewStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 108,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingPill extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _FloatingPill({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      shadowColor: color.withValues(alpha: 0.28),
      borderRadius: BorderRadius.circular(999),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _StatsStrip extends StatelessWidget {
  final bool compact;

  const _StatsStrip({required this.compact});

  @override
  Widget build(BuildContext context) {
    final items = const [
      ('6', 'Role-based portals'),
      ('1 tap', 'Clock in / out'),
      ('4', 'Leave types with balances'),
      ('N companies', 'Isolated tenants'),
    ];

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: _MaxWidth(
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.spaceBetween,
          children: [
            for (var i = 0; i < items.length; i++)
              SizedBox(
                width: compact ? (MediaQuery.sizeOf(context).width - 60) / 2 : 230,
                child: FadeSlideIn(
                  delay: Duration(milliseconds: 40 * i),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        items[i].$1,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                          letterSpacing: -0.8,
                        ),
                      ),
                      Text(
                        items[i].$2,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: const Color(0xFF0B1F3A),
          ),
        ),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.45,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }
}

class _FeaturesSection extends StatelessWidget {
  const _FeaturesSection();

  @override
  Widget build(BuildContext context) {
    final features = <_FeatureData>[
      const _FeatureData(
        title: 'Attendance that tells the truth',
        body:
            'One-tap clock-in with a live clock. Late after 9:30 AM. Half-day under 4 hours. Leaders see present, late, and leave — not a spreadsheet lag.',
        icon: Icons.schedule_rounded,
        color: AppTheme.primary,
        kind: PlatformSuiteKind.analytics,
      ),
      const _FeatureData(
        title: 'Leave that updates the board',
        body:
            'Casual, sick, annual, and unpaid — with balances and approvals. Approved time off shows as Leave, not Absent.',
        icon: Icons.event_available_rounded,
        color: AppTheme.secondary,
        kind: PlatformSuiteKind.onboard,
      ),
      const _FeatureData(
        title: 'People & day-one onboarding',
        body:
            'Employee IDs, departments, reporting lines, and a checklist for documents, assets, and access before someone is “day-one ready.”',
        icon: Icons.people_alt_rounded,
        color: Color(0xFF7C3AED),
        kind: PlatformSuiteKind.directory,
      ),
      const _FeatureData(
        title: 'Timesheets & expenses',
        body:
            'Log project hours and claims. Team leads and managers approve what they own. HR sees the company queue.',
        icon: Icons.receipt_long_rounded,
        color: Color(0xFFC2410C),
        kind: PlatformSuiteKind.analytics,
      ),
      const _FeatureData(
        title: 'Assets & payslips',
        body:
            'Assign devices to people. Issue a monthly payslip from salary on the profile — simple, auditable, in one place.',
        icon: Icons.payments_rounded,
        color: AppTheme.tertiary,
        kind: PlatformSuiteKind.audit,
      ),
      const _FeatureData(
        title: 'Talent, without extra tools',
        body:
            'Move candidates from Applied to Hired. Set performance goals by cycle. Keep hiring and reviews next to the people record.',
        icon: Icons.insights_rounded,
        color: Color(0xFF0F766E),
        kind: PlatformSuiteKind.directory,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: _MaxWidth(
        child: Column(
          children: [
            const _SectionHeader(
              eyebrow: 'Product',
              title: 'Everything daily HR actually needs',
              subtitle:
                  'From the first clock-in to leave, hours, claims, and payslips — built as one system so the numbers stay consistent.',
            ),
            const SizedBox(height: 36),
            LayoutBuilder(
              builder: (context, constraints) {
                final cols = constraints.maxWidth >= 980
                    ? 3
                    : constraints.maxWidth >= 640
                    ? 2
                    : 1;
                final gap = 16.0;
                final cardW = (constraints.maxWidth - gap * (cols - 1)) / cols;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (var i = 0; i < features.length; i++)
                      SizedBox(
                        width: cardW,
                        child: _FeatureCard(data: features[i], delayMs: 50 * i),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureData {
  final String title;
  final String body;
  final IconData icon;
  final Color color;
  final PlatformSuiteKind kind;

  const _FeatureData({
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
    required this.kind,
  });
}

class _FeatureCard extends StatelessWidget {
  final _FeatureData data;
  final int delayMs;

  const _FeatureCard({required this.data, required this.delayMs});

  @override
  Widget build(BuildContext context) {
    return MotionCard(
      delay: Duration(milliseconds: delayMs),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: data.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(data.icon, color: data.color),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 72,
                    height: 56,
                    child: PlatformSuiteArt(kind: data.kind, color: data.color),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                data.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                data.body,
                style: TextStyle(
                  height: 1.45,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RolesSection extends StatelessWidget {
  const _RolesSection();

  @override
  Widget build(BuildContext context) {
    final roles = const [
      _RoleData('Employee', 'Clock in, leave, timesheet, expenses, payslips.', Icons.badge_outlined, AppTheme.primary),
      _RoleData('Team Lead', 'Approve leave and hours for direct reports.', Icons.group_outlined, AppTheme.secondary),
      _RoleData('Manager', 'Team attendance, expenses, and performance.', Icons.hub_outlined, Color(0xFF7C3AED)),
      _RoleData('HR', 'Full people ops: directory, onboarding, payroll basics.', Icons.favorite_outline, Color(0xFFBE185D)),
      _RoleData('Company Admin', 'Run the organisation end to end.', Icons.admin_panel_settings_outlined, AppTheme.tertiary),
      _RoleData('Platform Admin', 'Onboard companies, freeze tenants, audit the suite.', Icons.public_outlined, Color(0xFF0B1F3A)),
    ];

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: _MaxWidth(
        child: Column(
          children: [
            const _SectionHeader(
              eyebrow: 'Roles',
              title: 'One product. The right desk for each person.',
              subtitle:
                  'Staff stay in a simple workspace. Leads and managers only see their team. HR and admins run the company. Platform owners run the network.',
            ),
            const SizedBox(height: 32),
            LayoutBuilder(
              builder: (context, constraints) {
                final cols = constraints.maxWidth >= 980
                    ? 3
                    : constraints.maxWidth >= 640
                    ? 2
                    : 1;
                final gap = 14.0;
                final cardW = (constraints.maxWidth - gap * (cols - 1)) / cols;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final role in roles)
                      SizedBox(
                        width: cardW,
                        child: _RoleCard(data: role),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleData {
  final String title;
  final String body;
  final IconData icon;
  final Color color;

  const _RoleData(this.title, this.body, this.icon, this.color);
}

class _RoleCard extends StatelessWidget {
  final _RoleData data;

  const _RoleCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return MotionCard(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: data.color.withValues(alpha: 0.12)),
          color: data.color.withValues(alpha: 0.04),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(data.icon, color: data.color, size: 28),
            const SizedBox(height: 14),
            Text(
              data.title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            const SizedBox(height: 6),
            Text(data.body, style: TextStyle(color: Colors.grey.shade700, height: 1.4)),
          ],
        ),
      ),
    );
  }
}

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection();

  @override
  Widget build(BuildContext context) {
    const steps = [
      ('01', 'Provision the company', 'A platform admin creates the tenant and the first company administrator.'),
      ('02', 'People work in one place', 'Staff clock in, apply for leave, and log hours. Nothing lives in chat.'),
      ('03', 'Approvals become the record', 'Managers approve. Attendance, leave, and payroll basics stay aligned.'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: _MaxWidth(
        child: Column(
          children: [
            const _SectionHeader(
              eyebrow: 'How it works',
              title: 'From tenant to today’s shift',
              subtitle: 'A short path from “new company” to a live attendance board.',
            ),
            const SizedBox(height: 36),
            LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 840;
                if (stacked) {
                  return Column(
                    children: [
                      for (var i = 0; i < steps.length; i++) ...[
                        _StepCard(
                          index: steps[i].$1,
                          title: steps[i].$2,
                          body: steps[i].$3,
                        ),
                        if (i < steps.length - 1) const SizedBox(height: 12),
                      ],
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < steps.length; i++) ...[
                      if (i > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 28),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      Expanded(
                        child: _StepCard(
                          index: steps[i].$1,
                          title: steps[i].$2,
                          body: steps[i].$3,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String index;
  final String title;
  final String body;

  const _StepCard({
    required this.index,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              index,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(body, style: TextStyle(color: Colors.grey.shade700, height: 1.45)),
          ],
        ),
      ),
    );
  }
}

class _PlatformSection extends StatelessWidget {
  final bool compact;
  final VoidCallback onOpen;

  const _PlatformSection({required this.compact, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF0B1F3A),
      padding: EdgeInsets.symmetric(vertical: compact ? 48 : 72, horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1160),
        child: compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _platformCopy(context),
                  const SizedBox(height: 28),
                  const SizedBox(height: 220, child: _PlatformVisual()),
                ],
              )
            : Row(
                children: [
                  Expanded(child: _platformCopy(context)),
                  const SizedBox(width: 40),
                  const Expanded(child: SizedBox(height: 280, child: _PlatformVisual())),
                ],
              ),
      ),
    );
  }

  Widget _platformCopy(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PLATFORM',
          style: TextStyle(
            color: Color(0xFF7DB4FF),
            fontWeight: FontWeight.w800,
            letterSpacing: 1.6,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'One suite. Many companies. Zero mixed data.',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Platform admins create and suspend tenants, review global users, and read audit activity. Each company only sees its own people, attendance, and money.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.78),
            height: 1.5,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: onOpen,
          style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppTheme.primary),
          child: const Text('Sign in to the platform'),
        ),
      ],
    );
  }
}

class _PlatformVisual extends StatelessWidget {
  const _PlatformVisual();

  @override
  Widget build(BuildContext context) {
    return const PlatformSuiteArt(
      kind: PlatformSuiteKind.audit,
      color: Color(0xFF7DB4FF),
    );
  }
}

class _FinalCta extends StatelessWidget {
  final VoidCallback onOpen;

  const _FinalCta({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1160),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.primary, Color(0xFF0F9D8A)],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.28),
                blurRadius: 28,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Ready to see today\'s board?',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Open the workspace with your company login. Accounts are provisioned by your administrator.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: onOpen,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primary,
                  minimumSize: const Size(220, 52),
                ),
                child: const Text('Open workspace'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1160),
        child: Column(
          children: [
            const Divider(),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 8,
              children: [
                const _BrandMark(),
                Text(
                  '© ${DateTime.now().year} Dentassure 360  ·  Workforce & HR platform',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
