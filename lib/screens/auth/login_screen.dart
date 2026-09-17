import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/auth_error_handler.dart';
import '../../theme/app_motion.dart';
import '../../widgets/app_logo.dart';

class _DemoAccount {
  final String role;
  final String name;
  final String email;
  final String password;

  const _DemoAccount({
    required this.role,
    required this.name,
    required this.email,
    required this.password,
  });
}

const _demoAccounts = [
  _DemoAccount(
    role: 'Platform Admin',
    name: 'Super Admin',
    email: 'superadmin@yopmail.com',
    password: 'Superadmin@123',
  ),
  _DemoAccount(
    role: 'Company Admin',
    name: 'Surender',
    email: 'surender@yopmail.com',
    password: 'Surender@123',
  ),
  _DemoAccount(
    role: 'HR',
    name: 'Dany',
    email: 'dany@yopmail.com',
    password: 'Dany@123',
  ),
  _DemoAccount(
    role: 'Manager',
    name: 'Narendra',
    email: 'narendra@yopmail.com',
    password: 'Narendra@123',
  ),
  _DemoAccount(
    role: 'Employee',
    name: 'Mani',
    email: 'manisadhu20@gmail.com',
    password: 'Mani@123',
  ),
  _DemoAccount(
    role: 'Employee',
    name: 'Vinay',
    email: 'vinay@yopmail.com',
    password: 'Vinay@123',
  ),
  _DemoAccount(
    role: 'Employee',
    name: 'Abhi',
    email: 'abhi@yopmail.com',
    password: 'Abhi@123',
  ),
  _DemoAccount(
    role: 'Employee',
    name: 'Prashanth',
    email: 'prashanth@yopmail.com',
    password: 'Prashanth@123',
  ),
  _DemoAccount(
    role: 'Employee',
    name: 'Venkatesh',
    email: 'venkatesh@yopmail.com',
    password: 'Venkatesh@123',
  ),
  _DemoAccount(
    role: 'Employee',
    name: 'Tarun',
    email: 'tarun@yopmail.com',
    password: 'Tarun@123',
  ),
];

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  bool _loading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String? _selectedDemoEmail;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _fillDemoAccount(_DemoAccount account) {
    setState(() {
      _emailController.text = account.email;
      _passwordController.text = account.password;
      _selectedDemoEmail = account.email;
      _errorMessage = null;
    });
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      debugPrint('[Login] Attempting login for $email');
      dynamic credential;
      try {
        credential = await _authService
            .login(email: email, password: password)
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () => throw TimeoutException(
                'Login timed out. Please check your internet connection.',
              ),
            );
      } catch (authError) {
        // If it's the superadmin account and not yet created in Firebase Auth, auto-provision
        if (email.toLowerCase() == 'superadmin@yopmail.com') {
          debugPrint(
            '[Login] Super Admin not found, auto-provisioning credentials...',
          );
          credential = await _authService
              .register(email: email, password: password)
              .timeout(
                const Duration(seconds: 15),
                onTimeout: () => throw TimeoutException(
                  'Super Admin creation timed out. Please check network connection.',
                ),
              );
        } else {
          rethrow;
        }
      }

      // Ensure the Firestore UserProfile exists with PLATFORM_ADMIN role
      if (credential != null && credential.user != null) {
        if (email.toLowerCase() == 'superadmin@yopmail.com') {
          await _firestoreService.createPlatformAdminProfile(
            uid: credential.user!.uid,
            email: email,
            name: 'Platform Super Admin',
          );
        }
      }

      debugPrint('[Login] Login successful!');

      if (!mounted) return;

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e, stackTrace) {
      debugPrint('[Login] Login error: $e\n$stackTrace');
      if (!mounted) return;

      final message = AuthErrorHandler.getErrorMessage(e);
      setState(() {
        _errorMessage = message;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final resetEmailController = TextEditingController(
      text: _emailController.text.trim(),
    );
    final dialogFormKey = GlobalKey<FormState>();
    bool resetting = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Reset Password'),
              content: Form(
                key: dialogFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enter your registered email address and we will send you a password reset link.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: resetEmailController,
                      keyboardType: TextInputType.emailAddress,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: resetting
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: resetting
                      ? null
                      : () async {
                          if (!dialogFormKey.currentState!.validate()) return;
                          setDialogState(() => resetting = true);
                          try {
                            await _authService.resetPassword(
                              resetEmailController.text.trim(),
                            );
                            if (!dialogContext.mounted) return;
                            Navigator.pop(dialogContext);

                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Password reset email sent! Please check your inbox.',
                                ),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } catch (e) {
                            setDialogState(() => resetting = false);
                            if (!dialogContext.mounted) return;
                            final msg = AuthErrorHandler.getErrorMessage(e);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(msg),
                                backgroundColor: Colors.red.shade700,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                  child: resetting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Send Reset Link'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool canPop = Navigator.of(context).canPop();

    return Scaffold(
      appBar: canPop ? AppBar(title: const Text('Sign In')) : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(
                      child: AppHeaderLogo(
                        height: 84,
                        maxWidth: 360,
                        alignment: Alignment.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Sign in to your workspace',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 32),

                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: Colors.red.shade900,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        hintText: 'name@company.com',
                        prefixIcon: Icon(Icons.email_rounded),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _login(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_rounded),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _loading ? null : _showForgotPasswordDialog,
                        child: const Text('Forgot Password?'),
                      ),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: _loading ? null : _login,
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Log In',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _DemoLoginsPanel(
                      selectedEmail: _selectedDemoEmail,
                      enabled: !_loading,
                      onSelect: _fillDemoAccount,
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Enterprise Multi-Tenant Portal\nOrganizations and accounts are provisioned by your Platform Administrator.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoLoginsPanel extends StatelessWidget {
  final String? selectedEmail;
  final bool enabled;
  final ValueChanged<_DemoAccount> onSelect;

  const _DemoLoginsPanel({
    required this.selectedEmail,
    required this.enabled,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grouped = <String, List<_DemoAccount>>{};
    for (final account in _demoAccounts) {
      grouped.putIfAbsent(account.role, () => []).add(account);
    }

    return FadeSlideIn(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.vpn_key_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Demo logins',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Tap an account to fill email and password, then Log In.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              for (final entry in grouped.entries) ...[
                Text(
                  entry.key.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final account in entry.value)
                      FilterChip(
                        selected: selectedEmail == account.email,
                        label: Text(account.name),
                        tooltip: '${account.email}\n${account.password}',
                        onSelected: enabled ? (_) => onSelect(account) : null,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
