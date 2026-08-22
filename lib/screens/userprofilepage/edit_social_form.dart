import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/models/models.dart';
import 'package:bombay_casting/providers/app_state.dart';
import 'package:bombay_casting/theme/app_theme.dart';
import 'package:bombay_casting/widgets/option_picker.dart';

class EditSocialFieldsScreen extends StatefulWidget {
  const EditSocialFieldsScreen({super.key});

  @override
  State<EditSocialFieldsScreen> createState() => _EditSocialFieldsScreenState();
}

class _EditSocialFieldsScreenState extends State<EditSocialFieldsScreen> {
  String _selectedPlatform = 'Instagram';
  String _selectedFollowers = '10K - 50K';
  String _selectedEngagement = '1-3%';
  String _selectedAudience = 'Gen Z';
  final Set<String> _selectedOtherPlatforms = {};
  final TextEditingController _handleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final profile = context.read<AppState>().profile;
    if (profile == null) return;
    final social = profile.formSection('social');
    final metric = profile.platformMetrics.isNotEmpty
        ? profile.platformMetrics.first
        : null;
    setState(() {
      _selectedPlatform =
          (social['primary_platform'] ?? metric?.platform ?? _selectedPlatform)
              .toString();
      _selectedFollowers =
          (social['followers'] ?? _selectedFollowers).toString();
      _selectedEngagement =
          (social['engagement'] ?? _selectedEngagement).toString();
      _selectedAudience = (social['audience'] ?? _selectedAudience).toString();
      _handleController.text =
          (social['handle'] ?? metric?.handle ?? '').toString();
      _selectedOtherPlatforms
        ..clear()
        ..addAll(
          social['other_platforms'] is List
              ? (social['other_platforms'] as List)
                  .map((item) => item.toString())
              : const <String>[],
        );
    });
  }

  Future<void> _save() async {
    final handle = _handleController.text.trim();
    await saveProfileSection(
      context: context,
      section: 'social',
      data: {
        'primary_platform': _selectedPlatform,
        'handle': handle,
        'followers': _selectedFollowers,
        'engagement': _selectedEngagement,
        'audience': _selectedAudience,
        'other_platforms': _selectedOtherPlatforms.toList(),
      },
      extra: (profile) => profile.copyWith(
        contact: handle,
        platformMetrics: [
          SocialPlatformMetric(
            platform: _selectedPlatform,
            handle: handle,
            url: handle,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _handleController.dispose();
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
        title: const Text(
          'Social',
          style: TextStyle(
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
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Primary platform'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ProfileOptions.platforms.map((platform) {
                        return _buildChoiceChip(
                          label: platform,
                          isSelected: _selectedPlatform == platform,
                          onSelected: () =>
                              setState(() => _selectedPlatform = platform),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      label: 'Handle / username',
                      controller: _handleController,
                      hintText: '@yourhandle',
                    ),
                    const SizedBox(height: 16),
                    _buildDropdownField(
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
                    const SizedBox(height: 20),
                    _buildSectionTitle('Engagement rate'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ProfileOptions.engagementRates.map((rate) {
                        return _buildChoiceChip(
                          label: rate,
                          isSelected: _selectedEngagement == rate,
                          onSelected: () =>
                              setState(() => _selectedEngagement = rate),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    _buildSectionTitle('Other platforms'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ProfileOptions.platforms
                          .where((platform) => platform != _selectedPlatform)
                          .map((platform) {
                        final isSelected =
                            _selectedOtherPlatforms.contains(platform);
                        return _buildMultiSelectChip(
                          label: '$platform +',
                          isSelected: isSelected,
                          onSelected: () {
                            setState(() {
                              if (isSelected) {
                                _selectedOtherPlatforms.remove(platform);
                              } else {
                                _selectedOtherPlatforms.add(platform);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    _buildSectionTitle('Audience'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ProfileOptions.audiences.map((audience) {
                        return _buildChoiceChip(
                          label: audience,
                          isSelected: _selectedAudience == audience,
                          onSelected: () =>
                              setState(() => _selectedAudience = audience),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
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
      padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 24.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified_user_outlined,
                  color: Colors.green, size: 16),
              const SizedBox(width: 6),
              Text(
                'Your data is 100% safe with us',
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
            height: 48,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text(
                'Update',
                style: TextStyle(
                  fontSize: 16,
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isSelected ? AppColors.primary : Colors.grey.shade800,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildMultiSelectChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return _buildChoiceChip(
      label: label,
      isSelected: isSelected,
      onSelected: onSelected,
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hintText,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.only(top: 4, bottom: 4),
            ),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
