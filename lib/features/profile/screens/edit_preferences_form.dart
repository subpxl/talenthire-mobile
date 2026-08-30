import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/app_filter_widgets.dart';
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
      _selectedCollabTypes
        ..clear()
        ..addAll(
          (prefs['collaboration_type'] as List?)?.cast<String>() ?? ['Any'],
        );
      _selectedPlatforms
        ..clear()
        ..addAll((prefs['platforms'] as List?)?.cast<String>() ?? ['Any']);
      _selectedNiches
        ..clear()
        ..addAll((prefs['niches'] as List?)?.cast<String>() ?? ['Any']);
      _selectedDurations
        ..clear()
        ..addAll((prefs['duration'] as List?)?.cast<String>() ?? ['Any']);
    });
  }

  void _handleMultiSelect(Set<String> targetSet, String value) {
    setState(() {
      if (value == 'Any') {
        targetSet
          ..clear()
          ..add('Any');
        return;
      }
      targetSet.remove('Any');
      if (targetSet.contains(value)) {
        targetSet.remove(value);
      } else {
        targetSet.add(value);
      }
      if (targetSet.isEmpty) targetSet.add('Any');
    });
  }

  void _resetAllFilters() {
    setState(() {
      _payRange = const RangeValues(5000, 150000);
      _selectedLocation = 'Any';
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
      _selectedWorkMode = 'Any';
    });
  }

  String _payLabel(double value) {
    if (value >= 100000) {
      return '₹${(value / 100000).toStringAsFixed(1)}L';
    }
    return '₹${(value / 1000).round()}k';
  }

  Future<void> _save() async {
    await saveProfileSection(
      context: context,
      section: 'preferences',
      data: {
        'pay_min': _payRange.start.round(),
        'pay_max': _payRange.end.round(),
        'location': _selectedLocation ?? 'Any',
        'collaboration_type': _selectedCollabTypes.toList(),
        'platforms': _selectedPlatforms.toList(),
        'niches': _selectedNiches.toList(),
        'duration': _selectedDurations.toList(),
        'work_mode': _selectedWorkMode,
      },
    );
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
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(AppLocalizations.of(context)!.jobPreferences,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context)!.whatKindOfJobsAreYouLookingFor,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const AppFormSectionTitle('Pay range'),
                    const SizedBox(height: 6),
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
                    const SizedBox(height: 14),
                    AppDropdownField(
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
                    const SizedBox(height: 14),
                    const AppFormSectionTitle('Collaboration type'),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['Any', ...ProfileOptions.jobCollabTypes]
                          .map((type) {
                        return AppPillChip(
                          label: type,
                          isSelected: _selectedCollabTypes.contains(type),
                          showCheckmark: true,
                          onTap: () =>
                              _handleMultiSelect(_selectedCollabTypes, type),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    const AppFormSectionTitle('Platforms'),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          ['Any', ...ProfileOptions.platforms].map((platform) {
                        return AppPillChip(
                          label: platform,
                          isSelected: _selectedPlatforms.contains(platform),
                          icon: _selectedPlatforms.contains(platform)
                              ? Icons.check
                              : Icons.add,
                          onTap: () =>
                              _handleMultiSelect(_selectedPlatforms, platform),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    const AppFormSectionTitle('Niches'),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['Any', ...ProfileOptions.niches].map((niche) {
                        return AppPillChip(
                          label: niche,
                          isSelected: _selectedNiches.contains(niche),
                          icon: _selectedNiches.contains(niche)
                              ? Icons.check
                              : Icons.add,
                          onTap: () =>
                              _handleMultiSelect(_selectedNiches, niche),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    const AppFormSectionTitle('Duration'),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          ['Any', ...ProfileOptions.jobDurations].map((item) {
                        return AppPillChip(
                          label: item,
                          isSelected: _selectedDurations.contains(item),
                          icon: _selectedDurations.contains(item)
                              ? Icons.check
                              : Icons.add,
                          onTap: () =>
                              _handleMultiSelect(_selectedDurations, item),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    const AppFormSectionTitle('Work mode'),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: ['Any', ...ProfileOptions.workModes]
                          .map((mode) {
                        return AppPillChip(
                          label: mode,
                          isSelected: _selectedWorkMode == mode,
                          onTap: () =>
                              setState(() => _selectedWorkMode = mode),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 16.0),
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
                          height: 42,
                          child: TextButton(
                            onPressed: _resetAllFilters,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey.shade700,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: Text(AppLocalizations.of(context)!.clear,
                              style: const TextStyle(
                                fontSize: 13,
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
                            child: Text(AppLocalizations.of(context)!.update,
                              style: const TextStyle(
                                fontSize: 14,
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
            AppSliderBadge(minLabel, color: AppColors.primary),
            AppSliderBadge(maxLabel, color: AppColors.primary),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: Colors.grey.shade200,
            thumbColor: Colors.white,
            overlayColor: AppColors.primary.withValues(alpha: 0.12),
            trackHeight: 3.0,
            rangeThumbShape: const RoundRangeSliderThumbShape(
              enabledThumbRadius: 10.0,
              elevation: 2,
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
}
