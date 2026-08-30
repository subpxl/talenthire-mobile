import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/core/models/models.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/app_filter_widgets.dart';
import 'package:bombay_casting/core/widgets/option_picker.dart';
import 'package:bombay_casting/core/widgets/social_platforms.dart';

class EditSocialFieldsScreen extends StatefulWidget {
  const EditSocialFieldsScreen({super.key});

  @override
  State<EditSocialFieldsScreen> createState() => _EditSocialFieldsScreenState();
}

class _PlatformLink {
  _PlatformLink({
    required this.platform,
    String handle = '',
    String url = '',
  })  : handleController = TextEditingController(text: handle),
        urlController = TextEditingController(text: url);

  String platform;
  final TextEditingController handleController;
  final TextEditingController urlController;

  void dispose() {
    handleController.dispose();
    urlController.dispose();
  }
}

class _EditSocialFieldsScreenState extends State<EditSocialFieldsScreen> {
  final List<_PlatformLink> _links = [];
  String _selectedFollowers = '10K - 50K';
  String _selectedEngagement = '1-3%';
  String _selectedAudience = 'Gen Z';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final profile = context.read<AppState>().profile;
    if (profile == null) return;
    final social = profile.formSection('social');
    setState(() {
      _selectedFollowers =
          (social['followers'] ?? _selectedFollowers).toString();
      _selectedEngagement =
          (social['engagement'] ?? _selectedEngagement).toString();
      _selectedAudience = (social['audience'] ?? _selectedAudience).toString();
      for (final link in _links) {
        link.dispose();
      }
      _links
        ..clear()
        ..addAll(_linksFrom(profile, social));
    });
  }

  List<_PlatformLink> _linksFrom(Profile profile, Map<String, dynamic> social) {
    final links = <_PlatformLink>[];
    final seen = <String>{};

    void addLink(String platform, {String handle = '', String url = ''}) {
      final name = platform.trim();
      if (name.isEmpty) return;
      final key = name.toLowerCase();
      if (!seen.add(key)) return;
      links.add(_PlatformLink(platform: name, handle: handle, url: url));
    }

    for (final metric in profile.platformMetrics) {
      addLink(
        metric.platform,
        handle: metric.handle,
        url: metric.url == metric.handle ? '' : metric.url,
      );
    }

    addLink(
      (social['primary_platform'] ?? '').toString(),
      handle: (social['handle'] ?? '').toString(),
    );

    final others = social['other_platforms'];
    if (others is List) {
      for (final item in others) {
        addLink(item.toString());
      }
    }

    return links;
  }

  Set<String> get _addedPlatforms =>
      _links.map((link) => link.platform.toLowerCase()).toSet();

  void _addPlatform(String platform) {
    final name = platform.trim();
    if (name.isEmpty) return;
    if (_addedPlatforms.contains(name.toLowerCase())) return;
    setState(() {
      _links.add(_PlatformLink(platform: name));
    });
  }

  void _removePlatform(int index) {
    final link = _links.removeAt(index);
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => link.dispose());
  }

  Future<void> _addOtherPlatform() async {
    final nameController = TextEditingController();
    final handleController = TextEditingController();
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add another platform',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Use this for a site that is not in the icon list.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Platform name',
                  hintText: 'Behance, Threads, website…',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: handleController,
                decoration: const InputDecoration(
                  labelText: 'Handle or URL',
                  hintText: '@you or https://…',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Add platform'),
                ),
              ),
            ],
          ),
        );
      },
    );
    final name = nameController.text.trim();
    final handle = handleController.text.trim();
    nameController.dispose();
    handleController.dispose();
    if (added != true || name.isEmpty || !mounted) return;
    if (_addedPlatforms.contains(name.toLowerCase())) return;
    setState(() {
      _links.add(_PlatformLink(platform: name, handle: handle));
    });
  }

  Future<void> _save() async {
    final metrics = [
      for (final link in _links)
        if (link.platform.trim().isNotEmpty)
          SocialPlatformMetric(
            platform: link.platform.trim(),
            handle: link.handleController.text.trim(),
            url: link.urlController.text.trim().isNotEmpty
                ? link.urlController.text.trim()
                : link.handleController.text.trim(),
          ),
    ];
    final primary = metrics.isNotEmpty ? metrics.first : null;
    await saveProfileSection(
      context: context,
      section: 'social',
      data: {
        'primary_platform': primary?.platform ?? '',
        'handle': primary?.handle ?? '',
        'followers': _selectedFollowers,
        'engagement': _selectedEngagement,
        'audience': _selectedAudience,
        'other_platforms': [
          for (final metric in metrics.skip(1)) metric.platform,
        ],
      },
      extra: (profile) => profile.copyWith(
        contact: primary?.handle ?? profile.contact,
        platformMetrics: metrics,
      ),
    );
  }

  @override
  void dispose() {
    for (final link in _links) {
      link.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Add platforms',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap an icon to add it. Use Other if it is not listed.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 14,
                          runSpacing: 14,
                          children: [
                            for (final platform in SocialPlatformInfo.known)
                              _platformAddButton(platform),
                            _platformAddButton(
                              SocialPlatformInfo.other,
                              onTap: _addOtherPlatform,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_links.isEmpty)
                    _card(
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.primaryLight,
                            child: Icon(
                              Icons.link_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'No socials yet. Pick Instagram, YouTube, or Other to get started.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        'Your profiles',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    for (var i = 0; i < _links.length; i++) ...[
                      _linkCard(i),
                      const SizedBox(height: 10),
                    ],
                  ],
                  const SizedBox(height: 8),
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Audience',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        AppDropdownField(
                          label: 'Followers',
                          value: _selectedFollowers,
                          onTap: () async {
                            final value = await showOptionPicker(
                              context: context,
                              title: 'Followers',
                              options: ProfileOptions.followerRanges,
                              selected: _selectedFollowers,
                            );
                            if (value != null) {
                              setState(() => _selectedFollowers = value);
                            }
                          },
                        ),
                        const SizedBox(height: 14),
                        const AppFormSectionTitle('Engagement rate'),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: ProfileOptions.engagementRates.map((rate) {
                            return AppPillChip(
                              label: rate,
                              isSelected: _selectedEngagement == rate,
                              onTap: () =>
                                  setState(() => _selectedEngagement = rate),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),
                        const AppFormSectionTitle('Audience'),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: ProfileOptions.audiences.map((audience) {
                            return AppPillChip(
                              label: audience,
                              isSelected: _selectedAudience == audience,
                              onTap: () =>
                                  setState(() => _selectedAudience = audience),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
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

  Widget _platformAddButton(
    SocialPlatformInfo platform, {
    VoidCallback? onTap,
  }) {
    final added = _addedPlatforms.contains(platform.name.toLowerCase());
    return Column(
      children: [
        SocialPlatformIcon(
          info: platform,
          size: 52,
          selected: added,
          onTap: added ? null : (onTap ?? () => _addPlatform(platform.name)),
        ),
        const SizedBox(height: 6),
        Text(
          platform.name == 'Twitter / X' ? 'X' : platform.name,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: added ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _linkCard(int index) {
    final link = _links[index];
    final info = SocialPlatformInfo.forName(link.platform);
    return _card(
      child: Column(
        children: [
          Row(
            children: [
              SocialPlatformIcon(info: info, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  link.platform,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Remove',
                onPressed: () => _removePlatform(index),
                icon: Icon(Icons.close_rounded, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: link.handleController,
            decoration: InputDecoration(
              labelText: 'Handle / username',
              hintText: info.handleHint,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: link.urlController,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Profile URL (optional)',
              hintText: 'https://…',
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
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
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(
                AppLocalizations.of(context)!.update,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
