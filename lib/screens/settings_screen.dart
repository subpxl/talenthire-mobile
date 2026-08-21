import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/app_state.dart';
import '../utils/legal_links.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const _SectionHeader(title: 'About'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('App Version'),
            subtitle: Text('1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms & Conditions'),
            subtitle: const Text('Opens on our website'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => openLegalPage(context, LegalLinks.terms),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            subtitle: const Text('Opens on our website'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => openLegalPage(context, LegalLinks.privacy),
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('Refund & Cancellation Policy'),
            subtitle: const Text('Opens on our website'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => openLegalPage(context, LegalLinks.refunds),
          ),
          const SizedBox(height: 16),
          const _SectionHeader(title: 'Account Actions'),
          ListTile(
            leading: const Icon(Icons.person_off_outlined, color: Colors.orange),
            title: const Text('Deactivate Account', style: TextStyle(color: Colors.orange)),
            subtitle: const Text('Temporarily disable your profile'),
            onTap: () => _showDeactivateDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
            title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
            subtitle: const Text('Schedule account deletion (30 days)'),
            onTap: () => _showDeleteDialog(context),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _showDeactivateDialog(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate Account'),
        content: const Text(
            'Are you sure you want to deactivate your account? Your profile will be hidden until you sign in again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await context.read<AppState>().deactivateAccount();
      if (context.mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _showDeleteDialog(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
            'Are you sure you want to delete your account? It will be permanently deleted after 30 days. You will be signed out immediately.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await context.read<AppState>().scheduleAccountDeletion();
      if (context.mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          color: context.colors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
