import 'dart:io' show Platform;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../providers/auth_provider.dart';
import '../models/app_user.dart';
import '../theme/theme.dart';
import '../widgets/widgets.dart';
import 'home_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  UserType _selectedUserType = UserType.teacher;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    String cleaned = value.replaceAll(RegExp(r'[^\d+]'), '');

    if (cleaned.length < 8) {
      return 'Phone number must have at least 8 digits';
    }

    return null;
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    String cleanedPhone =
        _phoneController.text.trim().replaceAll(RegExp(r'[^\d+]'), '');

    bool success = await authProvider.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      displayName: _nameController.text.trim(),
      userType: _selectedUserType,
      phone: cleanedPhone,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      showAppSnack(
        context,
        authProvider.errorMessage ?? 'Sign up failed',
        type: AppSnackType.error,
      );
    }
  }

  Future<void> _handleGoogleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final credential = await authProvider.signInWithGoogle();

      if (!mounted) return;

      if (credential.isExisting) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else if (credential.isNewUser) {
        final ok = await authProvider.createGoogleUser(
          firebaseUser: credential.firebaseUser!,
          userType: _selectedUserType,
        );

        if (!mounted) return;
        if (ok) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        } else {
          showAppSnack(
            context,
            authProvider.errorMessage ?? 'Error creating account',
            type: AppSnackType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showAppSnack(context, 'Google Sign-Up cancelled');
      }
    }
  }

  Future<void> _handleAppleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final result = await authProvider.signInWithApple();

      if (!mounted) return;

      if (result.isExisting) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else if (result.isNewUser) {
        final ok = await authProvider.createSocialUser(
          firebaseUser: result.firebaseUser!,
          userType: _selectedUserType,
        );

        if (!mounted) return;
        if (ok) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        } else {
          showAppSnack(
            context,
            authProvider.errorMessage ?? 'Error creating account',
            type: AppSnackType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showAppSnack(context, 'Apple Sign-Up cancelled');
      }
    }
  }

  // Sign in with Apple is only available on Apple platforms.
  bool get _showAppleSignIn =>
      !kIsWeb && (Platform.isIOS || Platform.isMacOS);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final decor = Theme.of(context).extension<AppDecor>()!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Spacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: Spacing.lg),

                    // User type selection
                    Text(
                      'I am a:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: Spacing.lg),

                    Row(
                      children: [
                        Expanded(
                          child: _UserTypeCard(
                            icon: Icons.school,
                            title: 'Teacher',
                            subtitle: 'Find jobs & access teaching materials',
                            color: scheme.primary,
                            selected: _selectedUserType == UserType.teacher,
                            onTap: () => setState(
                                () => _selectedUserType = UserType.teacher),
                          ),
                        ),
                        const SizedBox(width: Spacing.md),
                        Expanded(
                          child: _UserTypeCard(
                            icon: Icons.business,
                            title: 'Institution',
                            subtitle: 'Post jobs & find qualified teachers',
                            color: scheme.secondary,
                            selected:
                                _selectedUserType == UserType.institution,
                            onTap: () => setState(() =>
                                _selectedUserType = UserType.institution),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.xl),

                    // Name field
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: _selectedUserType == UserType.teacher
                            ? 'Full Name *'
                            : 'Institution Name *',
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: Spacing.lg),

                    // Email field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email *',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: Spacing.lg),

                    // Phone field
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[\d\s\+\-\(\)]')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Phone Number *',
                        hintText: '+598 99 123 456',
                        prefixIcon: Icon(Icons.phone_outlined),
                        helperText: 'Required for WhatsApp notifications',
                      ),
                      validator: _validatePhone,
                    ),
                    const SizedBox(height: Spacing.lg),

                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password *',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
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
                          return 'Please enter a password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: Spacing.lg),

                    // Confirm Password field
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password *',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: Spacing.xl),

                    // Info box about WhatsApp
                    Container(
                      padding: const EdgeInsets.all(Spacing.md),
                      decoration: BoxDecoration(
                        color: decor.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(Radii.sm),
                        border: Border.all(
                          color: decor.success.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: decor.success, size: 20),
                          const SizedBox(width: Spacing.md),
                          Expanded(
                            child: Text(
                              'We\'ll use WhatsApp to send you job alerts and important updates',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: scheme.onSurface),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Spacing.xl),

                    // Sign up button
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, _) {
                        return ElevatedButton(
                          onPressed:
                              authProvider.isLoading ? null : _handleSignUp,
                          child: authProvider.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Create Account'),
                        );
                      },
                    ),
                    const SizedBox(height: Spacing.lg),

                    // Sign up with Apple (required on iOS by App Store
                    // guideline 4.8)
                    if (_showAppleSignIn) ...[
                      SignInWithAppleButton(
                        onPressed: _handleAppleSignUp,
                        text: 'Sign up with Apple',
                        height: 52,
                        style: Theme.of(context).brightness == Brightness.dark
                            ? SignInWithAppleButtonStyle.white
                            : SignInWithAppleButtonStyle.black,
                        borderRadius: BorderRadius.circular(Radii.md),
                      ),
                      const SizedBox(height: Spacing.lg),
                    ],

                    // Google Sign-Up
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, _) {
                        return OutlinedButton.icon(
                          onPressed: authProvider.isLoading
                              ? null
                              : _handleGoogleSignUp,
                          icon: CachedNetworkImage(
                            imageUrl:
                                'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                            width: 20,
                            height: 20,
                            errorWidget: (_, __, ___) =>
                                const Icon(Icons.account_circle, size: 20),
                          ),
                          label: const Text('Sign up with Google'),
                        );
                      },
                    ),
                    const SizedBox(height: Spacing.lg),

                    // Login link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account?',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Log In'),
                        ),
                      ],
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

class _UserTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _UserTypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Motion.fast,
        curve: Motion.curve,
        padding: const EdgeInsets.all(Spacing.lg),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.08)
              : scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(
            color: selected ? color : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: selected ? color : scheme.onSurfaceVariant,
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: selected ? color : scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
