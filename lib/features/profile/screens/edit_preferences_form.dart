import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/option_picker.dart';

class EditPreferenceScreen extends StatefulWidget {
  const EditPreferenceScreen({super.key});

  @override
  State<EditPreferenceScreen> createState() => _EditPreferenceScreenState();
}

class _EditPreferenceScreenState extends State<EditPreferenceScreen> {
  RangeValues _payRange = const RangeValues(5000, 150000);
  String? _selectedLocation = 'Any';
  String _selectedWorkMode = 'Any';

  final Set<String> _selectedCollabTypes = {'Any'};
  final Set<String> _selectedPlatforms = {'Any'};
  final Set<String> _selectedNiches = {'Any'};
  final Set<String> _selectedDurations = {'Any'};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final profile = context.read<AppState>().profile;
    if (profile == null) return;
    final prefs = profile.formSection('preferences');
    setState(() {
      _payRange = RangeValues(
        (prefs['pay_min'] as num?)?.toDouble() ?? 5000,
        (prefs['pay_max'] as num?)?.toDouble() ?? 150000,
      );
      _selectedLocation = (prefs['location'] ?? 'Any').toString();
      _selectedWorkMode = (prefs['work_mode'] ?? 'Any').toString();
      _replaceSet(_selectedCollabTypes, prefs['collab_types']);
      _replaceSet(_selectedPlatforms, prefs['platforms']);
      _replaceSet(_selectedNiches, prefs['niches']);
      _replaceSet(_selectedDurations, prefs['durations']);
    });
  }

  void _replaceSet(Set<String> target, dynamic value) {
    target.clear();
    if (value is List && value.isNotEmpty) {
      target.addAll(value.map((item) => item.toString()));
    } else {
      target.add('Any');
    }
  }

  Future<void> _save() async {
    await saveProfileSection(
      context: context,
      section: 'preferences',
      data: {
        'pay_min': _payRange.start.round(),
        'pay_max': _payRange.end.round(),
        'pay_limit':
            '₹ ${_payRange.start.round()} - ₹ ${_payRange.end.round()}',
        'location': _selectedLocation ?? 'Any',
        'work_mode': _selectedWorkMode,
        'collab_types': _selectedCollabTypes.toList(),
        'platforms': _selectedPlatforms.toList(),
        'niches': _selectedNiches.toList(),
        'durations': _selectedDurations.toList(),
      },
    );
  }

  void _handleMultiSelect(Set<String> targetSet, String value) {
    setState(() {
      if (value == 'Any') {
        targetSet.clear();
        targetSet.add('Any');
      } else {
        targetSet.remove('Any');
        if (targetSet.contains(value)) {
          targetSet.remove(value);
          if (targetSet.isEmpty) targetSet.add('Any');
        } else {
          targetSet.add(value);
        }
      }
    });
  }

  void _resetAllFilters() {
    setState(() {
      _payRange = const RangeValues(5000, 150000);
      _selectedLocation = 'Any';
      _selectedWorkMode = 'Any';
      _selectedCollabTypes
        ..clear()
        ..add('Any');
      _selectedPlatforms
        ..clear()
        ..add('Any');
      _selectedNiches
        ..clear()
        ..add('Any');
      _selectedDurations
        ..clear()
        ..add('Any');
    });
  }

  String _payLabel(double value) {
    if (value >= 300000) return '₹3L+';
    if (value >= 100000) return '₹${(value / 100000).toStringAsFixed(1)}L';
    return '₹${(value / 1000).round()}k';
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
        title: Text(AppLocalizations.of(context)!.jobPreferences,
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
                    Text(AppLocalizations.of(context)!.whatKindOfJobsAreYouLookingFor,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionTitle('Pay range'),
                    const SizedBox(height: 8),
                    _buildRangeSlider(
                      values: _payRange,
                      min: 0,
                      max: 300000,
                      minLabel: _payLabel(_payRange.start),
                      maxLabel: _payRange.end >= 300000
                          ? '₹3L+'
                          : _payLabel(_payRange.end),
                      onChanged: (values) => setState(() => _payRange = values),
                    ),
                    const SizedBox(height: 16),
                    _buildDropdownField(
                      label: 'Job location',
                      value: _selectedLocation ?? 'Any',
                      onTap: () async {
                        final value = await showOptionPicker(
                          context: context,
                          title: 'Job location',
                          options: ['Any', ...ProfileOptions.cities],
                          selected: _selectedLocation,
                        );
                        if (value != null) {
                          setState(() => _selectedLocation = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildSectionTitle('Collaboration type'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['Any', ...ProfileOptions.jobCollabTypes]
                          .map((type) {
                        return _buildCheckmarkChip(
                          label: type,
                          isSelected: _selectedCollabTypes.contains(type),
                          onSelected: () =>
                              _handleMultiSelect(_selectedCollabTypes, type),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionTitle('Platforms'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          ['Any', ...ProfileOptions.platforms].map((platform) {
                        return _buildPlusOrCheckChip(
                          label: platform,
                          isSelected: _selectedPlatforms.contains(platform),
                          onSelected: () =>
                              _handleMultiSelect(_selectedPlatforms, platform),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionTitle('Niches'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['Any', ...ProfileOptions.niches].map((niche) {
                        return _buildPlusOrCheckChip(
                          label: niche,
                          isSelected: _selectedNiches.contains(niche),
                          onSelected: () =>
                              _handleMultiSelect(_selectedNiches, niche),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionTitle('Duration'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          ['Any', ...ProfileOptions.jobDurations].map((item) {
                        return _buildPlusOrCheckChip(
                          label: item,
                          isSelected: _selectedDurations.contains(item),
                          onSelected: () =>
                              _handleMultiSelect(_selectedDurations, item),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionTitle('Work mode'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['Any', ...ProfileOptions.workModes]
                          .map((mode) {
                        return _buildChoiceChip(
                          label: mode,
                          isSelected: _selectedWorkMode == mode,
                          onSelected: () =>
                              setState(() => _selectedWorkMode = mode),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 24.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.verified_user_outlined,
                          color: Colors.green, size: 16),
                      const SizedBox(width: 6),
                      Text(AppLocalizations.of(context)!.yourDataIs100SafeWithUs,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: TextButton(
                            onPressed: _resetAllFilters,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey.shade700,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: Text(AppLocalizations.of(context)!.clear,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: SizedBox(
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
                            child: Text(AppLocalizations.of(context)!.update,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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

  Widget _buildRangeSlider({
    required RangeValues values,
    required double min,
    required double max,
    required String minLabel,
    required String maxLabel,
    required ValueChanged<RangeValues> onChanged,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(minLabel, style: const TextStyle(fontSize: 12)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(maxLabel, style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: Colors.grey.shade200,
            thumbColor: Colors.white,
            overlayColor: AppColors.primary.withValues(alpha: 0.12),
            trackHeight: 4.0,
            rangeThumbShape: const RoundRangeSliderThumbShape(
              enabledThumbRadius: 10.0,
              elevation: 3,
            ),
          ),
          child: RangeSlider(
            values: values,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
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
          color: isSelected ? AppColors.primary.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isSelected ? AppColors.primary : Colors.grey.shade800,
          ),
        ),
      ),
    );
  }

  Widget _buildCheckmarkChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? AppColors.primary : Colors.grey.shade800,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              const Icon(Icons.check, size: 14, color: AppColors.primary),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildPlusOrCheckChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? AppColors.primary : Colors.grey.shade800,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              isSelected ? Icons.check : Icons.add,
              size: 14,
              color: isSelected ? AppColors.primary : Colors.grey.shade600,
            ),
          ],
        ),
      ),
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
}
