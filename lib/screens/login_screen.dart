import 'dart:io' show Platform;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../providers/auth_provider.dart';
import '../theme/theme.dart';
import '../widgets/widgets.dart';
import 'signup_screen.dart';
import 'home_screen.dart';
import 'google_user_type_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    bool success = await authProvider.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      showAppSnack(
        context,
        authProvider.errorMessage ?? 'Login failed',
        type: AppSnackType.error,
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final result = await authProvider.signInWithGoogle();

    if (!mounted) return;

    if (result.isExisting) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else if (result.isNewUser) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              GoogleUserTypeScreen(firebaseUser: result.firebaseUser!),
        ),
      );
    }
  }

  Future<void> _handleAppleSignIn() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final result = await authProvider.signInWithApple();

    if (!mounted) return;

    if (result.isExisting) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else if (result.isNewUser) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              GoogleUserTypeScreen(firebaseUser: result.firebaseUser!),
        ),
      );
    }
  }

  // Sign in with Apple is only available on Apple platforms.
  bool get _showAppleSignIn =>
      !kIsWeb && (Platform.isIOS || Platform.isMacOS);

  Future<void> _handleForgotPassword() async {
    if (_emailController.text.trim().isEmpty) {
      showAppSnack(context, 'Please enter your email address');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool success =
        await authProvider.resetPassword(_emailController.text.trim());

    if (!mounted) return;

    showAppSnack(
      context,
      success
          ? 'Password reset email sent'
          : authProvider.errorMessage ?? 'Failed to send reset email',
      type: success ? AppSnackType.success : AppSnackType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      // LoginScreen is always reached via push (from the guest "Sign In" tab
      // or "Sign In to Apply"), so a visible back button lets users return to
      // guest browsing without an account — required by App Store guideline
      // 5.1.1(v).
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Spacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo
                    Center(
                      child: Hero(
                        tag: 'app-logo',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(Radii.xl),
                          child: Image.asset(
                            'assets/images/hey_teacher_logo.jpeg',
                            height: 200,
                            width: 230,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 120,
                                width: 120,
                                decoration: BoxDecoration(
                                  gradient: Theme.of(context)
                                      .extension<AppDecor>()!
                                      .primaryGradient,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.school,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ).animate().fadeIn(duration: Motion.base).scale(
                          begin: const Offset(0.95, 0.95),
                          curve: Motion.curve,
                        ),

                    const SizedBox(height: Spacing.sm),
                    Text(
                      'Connect • Teach • Grow',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ).animate(delay: 100.ms).fadeIn(duration: Motion.base),
                    const SizedBox(height: 28),

                    // Email field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
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

                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
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
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: Spacing.sm),

                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _handleForgotPassword,
                        child: const Text('Forgot Password?'),
                      ),
                    ),
                    const SizedBox(height: Spacing.lg),

                    // Login button
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, _) {
                        return ElevatedButton(
                          onPressed:
                              authProvider.isLoading ? null : _handleLogin,
                          child: authProvider.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Login'),
                        );
                      },
                    ),
                    const SizedBox(height: Spacing.lg),

                    // Sign in with Apple (required on iOS by App Store
                    // guideline 4.8)
                    if (_showAppleSignIn) ...[
                      SignInWithAppleButton(
                        onPressed: _handleAppleSignIn,
                        height: 52,
                        style: Theme.of(context).brightness == Brightness.dark
                            ? SignInWithAppleButtonStyle.white
                            : SignInWithAppleButtonStyle.black,
                        borderRadius: BorderRadius.circular(Radii.md),
                      ),
                      const SizedBox(height: Spacing.lg),
                    ],

                    // Google Sign-In
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, _) {
                        return OutlinedButton.icon(
                          onPressed: authProvider.isLoading
                              ? null
                              : _handleGoogleSignIn,
                          icon: CachedNetworkImage(
                            imageUrl:
                                'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                            width: 20,
                            height: 20,
                            errorWidget: (_, __, ___) =>
                                const Icon(Icons.account_circle, size: 20),
                          ),
                          label: const Text('Sign in with Google'),
                        );
                      },
                    ),
                    const SizedBox(height: Spacing.lg),

                    // Sign up link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            "Don't have an account?",
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodyMedium
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const SignUpScreen(),
                              ),
                            );
                          },
                          child: const Text('Sign Up'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Developer branding
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipOval(
                          child: Image.asset(
                            'assets/images/spc_logo_compressed.jpg',
                            height: 44,
                            width: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 44,
                              width: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: scheme.surfaceContainerHigh,
                              ),
                              child: Center(
                                child: Text(
                                  'SPC',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Made by SPC',
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
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
