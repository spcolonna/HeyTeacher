import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import '../../models/app_user.dart';
import '../../models/teacher_profile.dart';
import '../../services/firestore_wrapper.dart';
import 'edit_teacher_profile_screen.dart';
import 'edit_institution_profile_screen.dart';
import 'my_applications_screen.dart';
import '../notifications/notifications_screen.dart';
import '../jobs/my_job_postings_screen.dart';
import '../materials/materials_screen.dart';
import '../institution/manage_staff_screen.dart';
import '../teacher/my_institutions_screen.dart';
import '../home_screen.dart';
import 'settings_screen.dart';
import 'help_support_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  TeacherProfile? _teacherProfile;

  @override
  void initState() {
    super.initState();
    _loadTeacherProfile();
  }

  Future<void> _loadTeacherProfile() async {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user == null || user.userType != UserType.teacher) {
      return;
    }

    try {
      DocumentSnapshot doc =
          await FirestoreWrapper.getDocument('teacher_profiles', user.uid);
      if (doc.exists && mounted) {
        setState(() {
          _teacherProfile = TeacherProfile.fromFirestore(doc);
        });
      }
    } catch (_) {
      // Profile stays null; header falls back to initials avatar.
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Usar photoUrl del TeacherProfile si existe, sino null
    String? photoUrl =
        user.userType == UserType.teacher ? _teacherProfile?.photoUrl : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          // Profile header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient:
                  Theme.of(context).extension<AppDecor>()!.primaryGradient,
            ),
            child: Row(
              children: [
                _buildProfileAvatar(photoUrl, user.displayName),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        user.email,
                        style: const TextStyle(fontSize: 13, color: Colors.white70),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Chip(
                        label: Text(
                          user.userType.toString().split('.').last.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Menu options - TEACHER
          if (user.userType == UserType.teacher) ...[
            _buildMenuItem(
              context,
              icon: Icons.person,
              title: 'Edit Profile',
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const EditTeacherProfileScreen()),
                );
                // Recargar profile después de editar
                _loadTeacherProfile();
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.work,
              title: 'My Applications',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MyApplicationsScreen(teacherId: user.uid),
                ),
              ),
            ),
            _buildMenuItem(
              context,
              icon: Icons.folder,
              title: 'My Materials',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MaterialsScreen()),
                );
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.apartment,
              title: 'My Institutions',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyInstitutionsScreen()),
              ),
            ),
          ],

          // Menu options - INSTITUTION
          if (user.userType == UserType.institution) ...[
            _buildMenuItem(
              context,
              icon: Icons.person,
              title: 'Edit Profile',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const EditInstitutionProfileScreen()),
              ),
            ),
            _buildMenuItem(
              context,
              icon: Icons.work_outline,
              title: 'My Job Postings',
              onTap: () {
                // ← ARREGLADO: ahora va a MyJobPostingsScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const MyJobPostingsScreen()),
                );
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.people,
              title: 'All Applicants',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Go to a specific job to see its applicants'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.group_work_outlined,
              title: 'Manage Staff',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageStaffScreen()),
              ),
            ),
          ],

          // Common menu items
          _buildMenuItem(
            context,
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),

          _buildMenuItem(
            context,
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
            ),
          ),

          _buildMenuItem(
            context,
            icon: Icons.info_outline,
            title: 'About',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'HeyTeacher',
                applicationVersion: '1.0.1',
                applicationLegalese:
                    '© 2026 HeyTeacher\nConnecting teachers with opportunities',
              );
            },
          ),

          const Divider(height: 32),

          _buildMenuItem(
            context,
            icon: Icons.logout,
            title: 'Sign Out',
            onTap: () async {
              bool? confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );

              if (confirm == true && mounted) {
                await authProvider.signOut();
                if (!context.mounted) return;
                // Signing out returns to guest browsing (Jobs/Materials),
                // not a login wall — required by App Store guideline 5.1.1(v).
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
                );
              }
            },
            textColor: Colors.red,
          ),

          const SizedBox(height: 32),
          // Developer branding footer
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
                    height: 44, width: 44,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).colorScheme.surfaceContainerHigh),
                    child: Center(child: Text('SPC', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurfaceVariant))),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Made by SPC', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  Text('v1.0.1', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(String? photoUrl, String displayName) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: AppAvatar(url: photoUrl, name: displayName, radius: 36),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor),
      title: Text(title, style: TextStyle(color: textColor)),
      trailing: Icon(Icons.chevron_right, color: textColor ?? Colors.grey),
      onTap: onTap,
    );
  }
}
