import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../home_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // TODO(spcolonna): if your support repo has a different name, update these URLs.
  static const _privacyPolicyUrl =
      'https://spcolonna.github.io/heyteacher-support/privacy.html';
  static const _termsUrl =
      'https://spcolonna.github.io/heyteacher-support/terms.html';
  static const _supportEmail = 'spcolonna@gmail.com';

  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _jobAlerts = true;
  bool _materialUpdates = false;

  bool get _isPasswordUser =>
      FirebaseAuth.instance.currentUser?.providerData
          .any((p) => p.providerId == 'password') ??
      false;

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const _SectionHeader('Account'),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Account Information'),
            subtitle: Text(user?.email ?? ''),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showAccountInfo(context),
          ),
          if (_isPasswordUser)
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('Change Password'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showChangePasswordDialog(context),
            ),
          const Divider(),
          const _SectionHeader('Notifications'),
          SwitchListTile(
            secondary: const Icon(Icons.email),
            title: const Text('Email Notifications'),
            subtitle: const Text('Receive updates via email'),
            value: _emailNotifications,
            onChanged: (value) {
              setState(() => _emailNotifications = value);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: const Text('Push Notifications'),
            subtitle: const Text('Receive push notifications'),
            value: _pushNotifications,
            onChanged: (value) {
              setState(() => _pushNotifications = value);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.work),
            title: const Text('Job Alerts'),
            subtitle: const Text('Get notified about new job postings'),
            value: _jobAlerts,
            onChanged: (value) {
              setState(() => _jobAlerts = value);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.folder),
            title: const Text('Material Updates'),
            subtitle: const Text('Get notified about new materials'),
            value: _materialUpdates,
            onChanged: (value) {
              setState(() => _materialUpdates = value);
            },
          ),
          const Divider(),
          const _SectionHeader('Privacy & Security'),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _openUrl(_privacyPolicyUrl),
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _openUrl(_termsUrl),
          ),
          const Divider(),
          const _SectionHeader('App'),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            subtitle: const Text('Version 1.0.1'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'HeyTeacher!',
                applicationVersion: '1.0.1',
                applicationLegalese: '© 2026 HeyTeacher',
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: const Text('Report a Bug'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _openUrl(
              'mailto:$_supportEmail?subject=HeyTeacher%20Bug%20Report',
            ),
          ),
          const Divider(),
          const _SectionHeader('Danger Zone'),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text(
              'Delete Account',
              style: TextStyle(color: Colors.red),
            ),
            subtitle: const Text('Permanently delete your account and data'),
            onTap: () => _confirmDeleteAccount(context),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showAccountInfo(BuildContext context) {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Account Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow('Name', user?.displayName ?? '-'),
            _InfoRow('Email', user?.email ?? '-'),
            _InfoRow(
              'Account type',
              user?.userType.name == 'institution' ? 'Institution' : 'Teacher',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final email = auth.currentUser?.email;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change Password'),
        content: Text(
          email == null
              ? 'No email is associated with this account.'
              : "We'll send a password reset link to $email.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: email == null
                ? null
                : () async {
                    Navigator.pop(dialogContext);
                    final ok = await auth.resetPassword(email);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ok
                            ? 'Password reset email sent'
                            : auth.errorMessage ?? 'Could not send email'),
                        backgroundColor: ok ? Colors.green : Colors.red,
                      ),
                    );
                  },
            child: const Text('Send Email'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final passwordController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will permanently delete your account and all associated '
              'data. This action cannot be undone.',
            ),
            if (_isPasswordUser) ...[
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm your password',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final ok = await auth.deleteAccount(
      password: _isPasswordUser ? passwordController.text : null,
    );

    if (!mounted) return;

    if (ok) {
      // Deleting the account returns to guest browsing (Jobs/Materials),
      // not a login wall — required by App Store guideline 5.1.1(v).
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Could not delete account'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}
