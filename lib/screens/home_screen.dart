import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_user.dart';
import '../providers/auth_provider.dart';
import '../services/notification_service.dart';
import 'jobs/jobs_screen.dart';
import 'materials/materials_screen.dart';
import 'marketplace/marketplace_screen.dart';
import 'profile/profile_screen.dart';
import 'classroom/classroom_screen.dart';
import 'institution/manage_staff_screen.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import '../widgets/sponsor_banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _unreadNotifications = 0;
  StreamSubscription<int>? _unreadSub;

  @override
  void initState() {
    super.initState();
    final uid =
        Provider.of<AuthProvider>(context, listen: false).currentUser?.uid;
    if (uid != null) {
      _unreadSub =
          NotificationService().getUnreadNotificationCount(uid).listen((count) {
        if (mounted) setState(() => _unreadNotifications = count);
      });
    }
  }

  @override
  void dispose() {
    _unreadSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    // Browsing Jobs, Materials and Benefits is allowed without an account
    // (App Store guideline 5.1.1 — only account-based features require login).
    final isGuest = user == null;
    final isInstitution = user?.userType == UserType.institution;

    final navItems = [
      const _NavItem(icon: Icons.work_outline, activeIcon: Icons.work, label: 'Jobs'),
      const _NavItem(icon: Icons.folder_outlined, activeIcon: Icons.folder, label: 'Materials'),
      // Benefits requires an account (QR redemption is tied to the user's
      // uid), so it's account-based and hidden from guests — only Jobs and
      // Materials must be freely browsable per App Store guideline 5.1.1.
      if (!isGuest)
        const _NavItem(icon: Icons.card_giftcard_outlined, activeIcon: Icons.card_giftcard, label: 'Benefits'),
      if (!isGuest)
        if (isInstitution)
          const _NavItem(icon: Icons.group_work_outlined, activeIcon: Icons.group_work, label: 'Staff')
        else
          const _NavItem(icon: Icons.school_outlined, activeIcon: Icons.school, label: 'Classroom'),
      if (!isGuest)
        const _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile')
      else
        const _NavItem(icon: Icons.login, activeIcon: Icons.login, label: 'Sign In'),
    ];

    final List<Widget> screens = [
      const JobsScreen(),
      const MaterialsScreen(),
      if (!isGuest) const MarketplaceScreen(),
      if (!isGuest)
        if (isInstitution) const ManageStaffScreen() else const ClassroomScreen(),
      if (!isGuest) const ProfileScreen() else const _GuestSignInTab(),
    ];

    final profileTabIndex = isGuest ? -1 : navItems.length - 1;
    final primary = Theme.of(context).colorScheme.primary;

    // Signing in/out changes the number of tabs (guest has 4, signed-in has
    // 5). Clamp so a stale _selectedIndex never points past the new list.
    final effectiveIndex = _selectedIndex.clamp(0, screens.length - 1);
    if (effectiveIndex != _selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedIndex = effectiveIndex);
      });
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (effectiveIndex < 2) const SponsorBanner(),
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: IndexedStack(
                  index: effectiveIndex,
                  children: screens,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: primary.withValues(alpha: 0.08),
                    blurRadius: 12,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(navItems.length, (index) {
                  final isSelected = _selectedIndex == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIndex = index),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                      padding: EdgeInsets.symmetric(
                        horizontal: isSelected ? 12 : 8,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primary.withValues(alpha: 0.18)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  isSelected
                                      ? navItems[index].activeIcon
                                      : navItems[index].icon,
                                  key: ValueKey(isSelected),
                                  color: isSelected
                                      ? primary
                                      : Colors.blueGrey.shade300,
                                  size: 24,
                                ),
                              ),
                              if (index == profileTabIndex &&
                                  _unreadNotifications > 0)
                                Positioned(
                                  top: -4,
                                  right: -6,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    constraints: const BoxConstraints(
                                        minWidth: 16, minHeight: 16),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      _unreadNotifications > 9
                                          ? '9+'
                                          : '$_unreadNotifications',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 220),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: isSelected
                                  ? primary
                                  : Colors.blueGrey.shade300,
                              letterSpacing: isSelected ? 0.2 : 0,
                            ),
                            child: Text(navItems[index].label),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Shown instead of Profile when browsing without an account. Applying to
/// jobs, uploading materials and other account-based features still require
/// signing in.
class _GuestSignInTab extends StatelessWidget {
  const _GuestSignInTab();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_outline, size: 72, color: primary),
              const SizedBox(height: 20),
              const Text(
                "You're browsing as a guest",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to apply for jobs, upload materials, and access your profile.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Log In'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SignUpScreen()),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Create Account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
