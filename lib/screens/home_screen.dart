import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'jobs/jobs_screen.dart';
import 'materials/materials_screen.dart';
import 'marketplace/marketplace_screen.dart';
import 'profile/profile_screen.dart';
import 'classroom/classroom_screen.dart';
import '../widgets/sponsor_banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const _navItems = [
    _NavItem(icon: Icons.work_outline, activeIcon: Icons.work, label: 'Jobs'),
    _NavItem(
        icon: Icons.folder_outlined,
        activeIcon: Icons.folder,
        label: 'Materials'),
    _NavItem(
        icon: Icons.card_giftcard_outlined,
        activeIcon: Icons.card_giftcard,
        label: 'Benefits'),
    _NavItem(
        icon: Icons.school_outlined,
        activeIcon: Icons.school,
        label: 'Classroom'),
    _NavItem(
        icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final List<Widget> screens = [
      const JobsScreen(),
      const MaterialsScreen(),
      const MarketplaceScreen(),
      const ClassroomScreen(),
      const ProfileScreen(),
    ];

    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (_selectedIndex < 2) const SponsorBanner(),
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: IndexedStack(
                  index: _selectedIndex,
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
                children: List.generate(_navItems.length, (index) {
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
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              isSelected
                                  ? _navItems[index].activeIcon
                                  : _navItems[index].icon,
                              key: ValueKey(isSelected),
                              color: isSelected
                                  ? primary
                                  : Colors.blueGrey.shade300,
                              size: 24,
                            ),
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
                            child: Text(_navItems[index].label),
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
