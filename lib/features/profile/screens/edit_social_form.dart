import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/core/models/models.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/app_form_fields.dart';
import 'package:bombay_casting/core/widgets/app_primary_button.dart';
import 'package:bombay_casting/core/widgets/option_picker.dart';
import 'package:bombay_casting/core/utils/social_link_utils.dart';
import 'package:bombay_casting/core/widgets/social_platforms.dart';

class EditSocialFieldsScreen extends StatefulWidget {
  const EditSocialFieldsScreen({super.key});

  @override
  State<EditSocialFieldsScreen> createState() => _EditSocialFieldsScreenState();
}

class _EditSocialFieldsScreenState extends State<EditSocialFieldsScreen> {
  final Map<String, TextEditingController> _urlControllers = {
    for (final platform in SocialPlatformInfo.linkFormPlatforms)
      platform.name: TextEditingController(),
  };
  final Map<String, String?> _linkErrors = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    for (final controller in _urlControllers.values) {
      controller.addListener(_clearLinkErrors);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final profile = context.read<AppState>().profile;
    if (profile == null) return;
    final social = profile.formSection('social');
    final urls = <String, String>{};

    void putUrl(String platform, String value) {
      final name = platform.trim();
      final url = value.trim();
      if (name.isEmpty || url.isEmpty) return;
      urls.putIfAbsent(name, () => url);
    }

    for (final metric in profile.platformMetrics) {
      putUrl(
        metric.platform,
        metric.url.isNotEmpty ? metric.url : metric.handle,
      );
    }
    putUrl(
      (social['primary_platform'] ?? '').toString(),
      (social['handle'] ?? '').toString(),
    );

    setState(() {
      for (final platform in SocialPlatformInfo.linkFormPlatforms) {
        final controller = _urlControllers[platform.name];
        if (controller == null) continue;
        final stored = urls[platform.name] ??
            urls.entries
                .where(
                  (entry) =>
                      entry.key.toLowerCase() == platform.name.toLowerCase(),
                )
                .map((entry) => entry.value)
                .firstOrNull ??
            '';
        controller.text = stored.isEmpty
            ? ''
            : SocialLinkUtils.displayValue(
                platform.name,
                url: stored,
                handle: SocialLinkUtils.extractHandle(platform.name, stored),
              );
      }
    });
  }

  void _clearLinkErrors() {
    if (_linkErrors.isEmpty) return;
    setState(_linkErrors.clear);
  }

  bool _validateLinks() {
    var valid = true;
    final nextErrors = <String, String?>{};
    for (final platform in SocialPlatformInfo.linkFormPlatforms) {
      final raw = _urlControllers[platform.name]?.text ?? '';
      final error = SocialLinkUtils.validationError(platform.name, raw);
      nextErrors[platform.name] = error;
      if (error != null) valid = false;
    }
    setState(() {
      _linkErrors
        ..clear()
        ..addAll(nextErrors);
    });
    return valid;
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_validateLinks()) return;
    setState(() => _saving = true);
    final metrics = <SocialPlatformMetric>[];
    for (final platform in SocialPlatformInfo.linkFormPlatforms) {
      final raw = _urlControllers[platform.name]?.text.trim() ?? '';
      if (raw.isEmpty) continue;
      final url = SocialLinkUtils.normalizeUrl(platform.name, raw);
      metrics.add(
        SocialPlatformMetric(
          platform: platform.name,
          handle: SocialLinkUtils.extractHandle(platform.name, url),
          url: url,
        ),
      );
    }
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
  void dispose() {
    for (final controller in _urlControllers.values) {
      controller.removeListener(_clearLinkErrors);
      controller.dispose();
    }
    super.dispose();
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
                  AppFormFields(
                    children: [
                      for (final platform
                          in SocialPlatformInfo.linkFormPlatforms)
                        AppPlatformLinkField(
                          label: platform.profileLinkLabel,
                          controller: _urlControllers[platform.name]!,
                          icon: SocialPlatformIcon(info: platform, size: 28),
                          errorText: _linkErrors[platform.name],
                        ),
                    ],
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
