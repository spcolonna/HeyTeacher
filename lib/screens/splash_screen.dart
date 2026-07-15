import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/theme.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    // Give the intro animation time to play.
    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted) return;

    // HomeScreen handles both signed-in users and guests (browsing without
    // an account is allowed for non-account-based features per App Store
    // guideline 5.1.1).
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: Motion.slow,
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final decor = Theme.of(context).extension<AppDecor>()!;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: decor.primaryGradient),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo: scale + fade entrance
              ClipRRect(
                borderRadius: BorderRadius.circular(Radii.xl + 4),
                child: Image.asset(
                  'assets/images/hey_teacher_logo.jpeg',
                  height: 140,
                  width: 140,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 140,
                      width: 140,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(Radii.xl + 4),
                      ),
                      child: Icon(
                        Icons.school,
                        size: 70,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    );
                  },
                ),
              )
                  .animate()
                  .fadeIn(duration: Motion.slow, curve: Motion.curve)
                  .scale(
                    begin: const Offset(0.8, 0.8),
                    duration: Motion.slow,
                    curve: Motion.curve,
                  ),
              const SizedBox(height: Spacing.xxl),

              // App name
              Text(
                'HeyTeacher!',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: decor.onGradient,
                      letterSpacing: 1.2,
                    ),
              )
                  .animate(delay: 200.ms)
                  .fadeIn(duration: Motion.slow, curve: Motion.curve)
                  .slideY(begin: 0.2, curve: Motion.curve),
              const SizedBox(height: Spacing.sm),

              // Tagline
              Text(
                'Connect • Teach • Grow',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: decor.onGradient.withValues(alpha: 0.8),
                      letterSpacing: 2,
                    ),
              )
                  .animate(delay: 350.ms)
                  .fadeIn(duration: Motion.slow, curve: Motion.curve),
              const SizedBox(height: 48),

              // Loading indicator
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(decor.onGradient),
                  strokeWidth: 3,
                ),
              ).animate(delay: 500.ms).fadeIn(duration: Motion.base),
              const SizedBox(height: 36),

              // Developer branding
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipOval(
                    child: Image.asset(
                      'assets/images/spc_logo_compressed.jpg',
                      height: 40,
                      width: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 40,
                        width: 40,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white24,
                        ),
                        child: const Center(
                          child: Text(
                            'SPC',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: Spacing.sm + 2),
                  Text(
                    'Made by SPC',
                    style: TextStyle(
                      fontSize: 13,
                      color: decor.onGradient.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ).animate(delay: 600.ms).fadeIn(duration: Motion.base),
            ],
          ),
        ),
      ),
    );
  }
}
