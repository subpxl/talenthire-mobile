import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            'Frequently Asked Questions',
            style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildFAQItem(
            context,
            question: 'How do I apply for a job?',
            answer:
                'Navigate to the Jobs tab, find a job you like, tap on it to see the details, and press the "Apply Now" button.',
          ),
          _buildFAQItem(
            context,
            question: 'How do I contact an artist?',
            answer:
                'Go to the Artists tab, tap on an artist card to view their profile, then use the "Contact Artist" button to start a conversation.',
          ),
          _buildFAQItem(
            context,
            question: 'How do I update my profile?',
            answer:
                'Go to the Profile tab and tap "Edit Profile" to update your personal information.',
          ),
          _buildFAQItem(
            context,
            question: 'How do I save a job for later?',
            answer:
                'While viewing a job detail, tap the bookmark icon. You can find all saved jobs under Profile > Saved Jobs.',
          ),
          _buildFAQItem(
            context,
            question: 'How can I withdraw my application?',
            answer:
                'Go to Profile > My Applications, long-press on the application you want to withdraw, and confirm.',
          ),
          const SizedBox(height: 24),
          Text(
            'Contact Support',
            style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.email_outlined, color: context.colors.primary),
                  title: const Text('Email Support'),
                  subtitle: const Text('support@talentapp.com'),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening email client...')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.phone_outlined, color: context.colors.primary),
                  title: const Text('Phone Support'),
                  subtitle: const Text('+1 (555) 123-4567'),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening dialer...')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showReportBugDialog(context),
              icon: const Icon(Icons.bug_report_outlined),
              label: const Text('Report a Bug'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context,
      {required String question, required String answer}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            answer,
            style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }

  void _showReportBugDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report a Bug'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Describe the bug...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bug report submitted. Thank you!')),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
