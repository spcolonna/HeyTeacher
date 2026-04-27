import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_user.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';

class GoogleUserTypeScreen extends StatefulWidget {
  final User firebaseUser;

  const GoogleUserTypeScreen({super.key, required this.firebaseUser});

  @override
  State<GoogleUserTypeScreen> createState() => _GoogleUserTypeScreenState();
}

class _GoogleUserTypeScreenState extends State<GoogleUserTypeScreen> {
  UserType? _selected;

  Future<void> _continue() async {
    if (_selected == null) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);

    final ok = await auth.createGoogleUser(
      firebaseUser: widget.firebaseUser,
      userType: _selected!,
    );

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(auth.errorMessage ?? 'Error creating account'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: CircleAvatar(
                  radius: 36,
                  backgroundImage: widget.firebaseUser.photoURL != null
                      ? NetworkImage(widget.firebaseUser.photoURL!)
                      : null,
                  backgroundColor: primary.withValues(alpha: 0.12),
                  child: widget.firebaseUser.photoURL == null
                      ? Text(
                          (widget.firebaseUser.displayName ?? 'U')[0]
                              .toUpperCase(),
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: primary),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Hi, ${widget.firebaseUser.displayName?.split(' ').first ?? 'there'}!',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'How will you use HeyTeacher?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 40),
              _TypeCard(
                type: UserType.teacher,
                icon: Icons.school_outlined,
                title: 'I\'m a Teacher',
                subtitle:
                    'Browse job offers, apply to positions and manage your classes.',
                selected: _selected == UserType.teacher,
                onTap: () => setState(() => _selected = UserType.teacher),
              ),
              const SizedBox(height: 14),
              _TypeCard(
                type: UserType.institution,
                icon: Icons.business_outlined,
                title: 'I\'m an Institution',
                subtitle:
                    'Post job openings and find qualified English teachers.',
                selected: _selected == UserType.institution,
                onTap: () => setState(() => _selected = UserType.institution),
              ),
              const Spacer(),
              Consumer<AuthProvider>(
                builder: (_, auth, __) => ElevatedButton(
                  onPressed:
                      (_selected == null || auth.isLoading) ? null : _continue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: auth.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Continue',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final UserType type;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _TypeCard({
    required this.type,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? primary.withValues(alpha: 0.07) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? primary : Colors.grey.shade200,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: primary.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ]
              : [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: selected
                    ? primary.withValues(alpha: 0.15)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  size: 26, color: selected ? primary : Colors.grey.shade500),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: selected ? primary : Colors.black87)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: primary, size: 22)
            else
              Icon(Icons.radio_button_unchecked,
                  color: Colors.grey.shade300, size: 22),
          ],
        ),
      ),
    );
  }
}
