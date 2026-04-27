import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../models/app_user.dart';
import '../../models/teacher_profile.dart';
import '../../services/firestore_wrapper.dart';
import 'edit_teacher_profile_screen.dart';
import '../jobs/my_job_postings_screen.dart';  // ← CAMBIADO: era jobs_screen.dart
import '../materials/materials_screen.dart';
import '../login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  TeacherProfile? _teacherProfile;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadTeacherProfile();
  }

  Future<void> _loadTeacherProfile() async {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user == null || user.userType != UserType.teacher) {
      setState(() => _isLoadingProfile = false);
      return;
    }

    try {
      DocumentSnapshot doc = await FirestoreWrapper.getDocument('teacher_profiles', user.uid);
      if (doc.exists) {
        setState(() {
          _teacherProfile = TeacherProfile.fromFirestore(doc);
          _isLoadingProfile = false;
        });
      } else {
        setState(() => _isLoadingProfile = false);
      }
    } catch (e) {
      print('Error loading teacher profile: $e');
      setState(() => _isLoadingProfile = false);
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
    String? photoUrl = user.userType == UserType.teacher ? _teacherProfile?.photoUrl : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings - Coming soon')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          // Profile header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.purple.shade400],
              ),
            ),
            child: Column(
              children: [
                _buildProfileAvatar(photoUrl, user.displayName),
                const SizedBox(height: 16),
                Text(
                  user.displayName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                Chip(
                  label: Text(
                    user.userType.toString().split('.').last.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  backgroundColor: Colors.white,
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
                  MaterialPageRoute(builder: (_) => const EditTeacherProfileScreen()),
                );
                // Recargar profile después de editar
                _loadTeacherProfile();
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.work,
              title: 'My Applications',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('My Applications - Coming soon')),
                );
              },
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
          ],

          // Menu options - INSTITUTION
          if (user.userType == UserType.institution) ...[
            _buildMenuItem(
              context,
              icon: Icons.person,
              title: 'Edit Profile',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Institution profile editing - Coming soon')),
                );
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.work_outline,
              title: 'My Job Postings',
              onTap: () {
                // ← ARREGLADO: ahora va a MyJobPostingsScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyJobPostingsScreen()),
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
          ],

          // Common menu items
          _buildMenuItem(
            context,
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Help & Support - Coming soon')),
              );
            },
          ),

          _buildMenuItem(
            context,
            icon: Icons.info_outline,
            title: 'About',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'HeyTeacher',
                applicationVersion: '1.0.2',
                applicationLegalese: '© 2025 HeyTeacher\nConnecting teachers with opportunities',
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
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                );
              }
            },
            textColor: Colors.red,
          ),

          const SizedBox(height: 32),
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
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 50,
        backgroundColor: Colors.white,
        child: photoUrl != null
            ? ClipOval(
          child: Image.network(
            photoUrl,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholderAvatar(displayName);
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
          ),
        )
            : _buildPlaceholderAvatar(displayName),
      ),
    );
  }

  Widget _buildPlaceholderAvatar(String displayName) {
    return Text(
      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
      style: TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.bold,
        color: Colors.blue.shade700,
      ),
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