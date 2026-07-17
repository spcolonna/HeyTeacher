import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/theme.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const _supportEmail = 'spcolonna@gmail.com';

  Future<void> _sendEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      query: 'subject=Help Request&body=',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: ListView(
        children: [
          const _SectionHeader('Common Questions'),
          const _FAQTile(
            question: 'How do I apply to a job?',
            answer:
                'Navigate to the Jobs tab, browse available positions, tap on a job to see details, and click "Apply Now" to submit your application.',
          ),
          const _FAQTile(
            question: 'How do I upload teaching materials?',
            answer:
                'Go to the Materials tab, tap the "+" button in the top right, fill in the details about your material, select a file, and tap "Upload".',
          ),
          const _FAQTile(
            question: 'How can I edit my profile?',
            answer:
                'Go to the Profile tab, tap "Edit Profile", update your information, and tap "Save".',
          ),
          const _FAQTile(
            question: 'How do I post a job? (Institutions)',
            answer:
                'Navigate to the Jobs tab, tap the "+" button, fill in the job details including title, description, shifts, and levels, then tap "Post Job".',
          ),
          const _FAQTile(
            question: 'How do I review applications? (Institutions)',
            answer:
                'Go to Profile → My Job Postings, select a job, tap "Applicants" to see all applications. You can then update the status of each applicant.',
          ),
          const Divider(),
          const _SectionHeader('Contact Us'),
          ListTile(
            leading: Icon(Icons.email, color: Theme.of(context).extension<AppDecor>()!.info),
            title: const Text('Email Support'),
            subtitle: const Text(_supportEmail),
            trailing: const Icon(Icons.chevron_right),
            onTap: _sendEmail,
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Card(
              color: Theme.of(context).extension<AppDecor>()!.info.softFill,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.help_outline,
                        size: 48, color: Theme.of(context).extension<AppDecor>()!.info),
                    const SizedBox(height: 12),
                    Text(
                      'Need more help?',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Our support team is here to help you with any questions or issues.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _sendEmail,
                      icon: const Icon(Icons.email),
                      label: const Text('Contact Support'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 28),
          // Developer attribution
          Padding(
            padding: const EdgeInsets.only(bottom: 36),
            child: Column(
              children: [
                Text(
                  'HeyTeacher is developed by',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipOval(
                      child: Image.asset(
                        'assets/images/spc_logo_compressed.jpg',
                        height: 48,
                        width: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 48, width: 48,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).colorScheme.surfaceContainerHigh),
                          child: Center(child: Text('SPC', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurfaceVariant))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SPC', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        Text('v1.0.1', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
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
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
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

class _FAQTile extends StatelessWidget {
  final String question;
  final String answer;

  const _FAQTile({
    required this.question,
    required this.answer,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            answer,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
