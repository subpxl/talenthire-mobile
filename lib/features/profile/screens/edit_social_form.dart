import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/app_primary_button.dart';
import 'package:bombay_casting/core/widgets/option_picker.dart';
import 'package:bombay_casting/features/profile/widgets/social_links_fields_form.dart';

class EditSocialFieldsScreen extends StatefulWidget {
  const EditSocialFieldsScreen({super.key});

  @override
  State<EditSocialFieldsScreen> createState() => _EditSocialFieldsScreenState();
}

class _EditSocialFieldsScreenState extends State<EditSocialFieldsScreen> {
  final _formKey = GlobalKey<SocialLinksFieldsFormState>();
  late final Map<String, String> _initialUrls;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AppState>().profile;
    _initialUrls = profile != null ? computeInitialSocialUrls(profile) : const {};
  }

  Future<void> _save() async {
    if (_saving) return;
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;
    setState(() => _saving = true);
    final metrics = formState.buildMetrics();
    final primary = metrics.isNotEmpty ? metrics.first : null;
    try {
      await saveProfileSection(
        context: context,
        section: 'social',
        data: {
          'primary_platform': primary?.platform ?? '',
          'handle': primary?.handle ?? '',
          'other_platforms': [
            for (final metric in metrics.skip(1)) metric.platform,
          ],
        },
        extra: (profile) => profile.copyWith(
          contact: primary?.url ?? profile.contact,
          platformMetrics: metrics,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.social,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        titleSpacing: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  const Text(
                    'Links to other platforms',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add your links to showcase your work on other platforms',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SocialLinksFieldsForm(
                    key: _formKey,
                    initialUrls: _initialUrls,
                  ),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.verified_user_outlined,
                color: Colors.green,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                AppLocalizations.of(context)!.yourDataIs100SafeWithUs,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AppPrimaryButton(
            label: AppLocalizations.of(context)!.update,
            onPressed: _saving ? null : _save,
            loading: _saving,
          ),
        ],
      ),
    );
  }
}
