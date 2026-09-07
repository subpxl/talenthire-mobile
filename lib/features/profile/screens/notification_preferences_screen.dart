import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/features/profile/models/settings_node.dart';
import 'package:bombay_casting/features/profile/screens/settings_group_screen.dart';
import 'package:bombay_casting/features/profile/widgets/settings_section_list.dart';

/// Working notification settings. Each toggle is persisted to
/// [SharedPreferences] so the choices survive navigation and app restarts.
class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  static const _defaults = <String, bool>{
    'notif_push': true,
    'notif_email': true,
    'notif_sms': false,
    'notif_casting_alerts': true,
    'notif_messages': true,
    'notif_promotions': false,
  };

  SharedPreferences? _prefs;
  final Map<String, bool> _values = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final values = <String, bool>{};
    _defaults.forEach((key, fallback) {
      values[key] = prefs.getBool(key) ?? fallback;
    });
    if (!mounted) return;
    setState(() {
      _prefs = prefs;
      _values
        ..clear()
        ..addAll(values);
      _loaded = true;
    });
  }

  void _set(String key, bool value) {
    _values[key] = value;
    _prefs?.setBool(key, value);
  }

  SettingsNode _toggle(
    IconData icon,
    String title,
    String key, {
    String? subtitle,
  }) {
    return SettingsNode(
      icon: icon,
      title: title,
      subtitle: subtitle,
      toggle: SettingsToggle(
        initialValue: _values[key] ?? false,
        onChanged: (value) => _set(key, value),
      ),
    );
  }

  List<SettingsSection> _sections() {
    return [
      SettingsSection(
        title: 'Channels',
        items: [
          _toggle(Icons.notifications_active_outlined, 'Push Notifications',
              'notif_push'),
          _toggle(Icons.email_outlined, 'Email Notifications', 'notif_email'),
          _toggle(Icons.sms_outlined, 'SMS Notifications', 'notif_sms'),
        ],
      ),
      SettingsSection(
        title: 'What you hear about',
        items: [
          _toggle(
            Icons.campaign_outlined,
            'Casting Alerts',
            'notif_casting_alerts',
            subtitle: 'New roles that match you',
          ),
          _toggle(Icons.chat_bubble_outline, 'Messages', 'notif_messages'),
          _toggle(Icons.local_offer_outlined, 'Promotions & Offers',
              'notif_promotions'),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const SettingsAppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenH,
              AppSpacing.md,
              AppSpacing.screenH,
              0,
            ),
            child: Text(
              'Notifications',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: _loaded
                ? SettingsSectionList(sections: _sections())
                : const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
          ),
        ],
      ),
    );
  }
}
