import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _sendEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@heyteacher.uy',
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
            leading: const Icon(Icons.email, color: Colors.blue),
            title: const Text('Email Support'),
            subtitle: const Text('support@heyteacher.uy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _sendEmail,
          ),
          ListTile(
            leading: const Icon(Icons.chat, color: Colors.green),
            title: const Text('Live Chat'),
            subtitle: const Text('Available Mon-Fri 9am-6pm'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Live chat coming soon')),
              );
            },
          ),
          const Divider(),
          const _SectionHeader('Resources'),
          ListTile(
            leading: const Icon(Icons.book, color: Colors.orange),
            title: const Text('User Guide'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User guide coming soon')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.video_library, color: Colors.red),
            title: const Text('Video Tutorials'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Video tutorials coming soon')),
              );
            },
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.help_outline,
                        size: 48, color: Colors.blue.shade700),
                    const SizedBox(height: 12),
                    Text(
                      'Need more help?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Our support team is here to help you with any questions or issues.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade700),
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
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ),
      ],
    );
  }
}
