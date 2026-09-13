import 'package:flutter/material.dart';
import 'package:bombay_casting/core/models/models.dart';
import 'package:bombay_casting/core/utils/social_link_utils.dart';
import 'package:bombay_casting/core/widgets/app_form_fields.dart';
import 'package:bombay_casting/core/widgets/social_platforms.dart';

/// Reads the platform links currently saved on [profile] into a
/// `platform name -> url/handle` map, suitable for
/// [SocialLinksFieldsForm.initialUrls].
///
/// Shared by the standalone Edit Profile "Social" screen and the
/// first-login onboarding wizard so both read the exact same source data.
Map<String, String> computeInitialSocialUrls(Profile profile) {
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

  return urls;
}

/// Reusable "Links to other platforms" field set (Instagram, Website,
/// IMDb, YouTube, Facebook).
///
/// This is the single source of truth for these fields so that the
/// standalone Edit Profile screen and the first-login onboarding wizard
/// always render and save the exact same fields/values.
class SocialLinksFieldsForm extends StatefulWidget {
  const SocialLinksFieldsForm({
    super.key,
    this.initialUrls = const {},
    this.platforms,
  });

  /// Platform name -> stored url/handle, e.g. from [computeInitialSocialUrls].
  final Map<String, String> initialUrls;

  /// When null, uses [SocialPlatformInfo.linkFormPlatforms] (full edit profile).
  final List<SocialPlatformInfo>? platforms;

  @override
  State<SocialLinksFieldsForm> createState() => SocialLinksFieldsFormState();
}

class SocialLinksFieldsFormState extends State<SocialLinksFieldsForm> {
  late final Map<String, TextEditingController> _urlControllers;
  final Map<String, String?> linkErrors = {};

  List<SocialPlatformInfo> get _platforms =>
      widget.platforms ?? SocialPlatformInfo.linkFormPlatforms;

  @override
  void initState() {
    super.initState();
    _urlControllers = {
      for (final platform in _platforms)
        platform.name: TextEditingController(),
    };
    for (final controller in _urlControllers.values) {
      controller.addListener(_clearLinkErrors);
    }
    _applyInitialUrls();
  }

  void _applyInitialUrls() {
    final urls = widget.initialUrls;
    for (final platform in _platforms) {
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
  }

  void _clearLinkErrors() {
    if (linkErrors.isEmpty) return;
    setState(linkErrors.clear);
  }

  /// Validates all links, populating [linkErrors]. Returns true if valid.
  bool validate() {
    var valid = true;
    final nextErrors = <String, String?>{};
    for (final platform in _platforms) {
      final raw = _urlControllers[platform.name]?.text ?? '';
      final error = SocialLinkUtils.validationError(platform.name, raw);
      nextErrors[platform.name] = error;
      if (error != null) valid = false;
    }
    setState(() {
      linkErrors
        ..clear()
        ..addAll(nextErrors);
    });
    return valid;
  }

  /// Builds the list of filled-in platform metrics. Call [validate] first.
  List<SocialPlatformMetric> buildMetrics() {
    final metrics = <SocialPlatformMetric>[];
    for (final platform in _platforms) {
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
    return metrics;
  }

  bool get hasAnyLink =>
      _urlControllers.values.any((c) => c.text.trim().isNotEmpty);

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
    return AppFormFields(
      children: [
        for (final platform in _platforms)
          AppPlatformLinkField(
            label: platform.profileLinkLabel,
            controller: _urlControllers[platform.name]!,
            icon: SocialPlatformIcon(info: platform, size: 28),
            errorText: linkErrors[platform.name],
          ),
      ],
    );
  }
}
