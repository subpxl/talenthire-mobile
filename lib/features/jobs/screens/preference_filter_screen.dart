import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/app_filter_widgets.dart';
import 'package:bombay_casting/core/widgets/option_picker.dart';
import 'package:bombay_casting/core/widgets/searchable_option_picker.dart';
import 'package:bombay_casting/features/jobs/models/job_listing.dart';

class PreferenceScreen extends StatefulWidget {
  const PreferenceScreen({super.key});

  @override
  State<PreferenceScreen> createState() => _PreferenceScreenState();
}

class _PreferenceScreenState extends State<PreferenceScreen> {
  RangeValues _salaryRange = const RangeValues(0, 500000);
  final Set<String> _selectedJobTypes = {'Any'};
  String _selectedLocation = 'Any';
  final Set<String> _selectedLanguages = {'Any'};
  final Set<String> _selectedCategories = {'Any'};
  String _selectedGender = 'Any';
  RangeValues _ageRange = const RangeValues(0, 100);

  List<String> get _categoryOptions {
    final posted = postedJobCategories(
      context.read<AppState>().jobs,
      fallback: const [],
    );
    final extras = posted.where(
      (category) => !ProfileOptions.talentCategories.any(
        (item) => item.toLowerCase() == category.toLowerCase(),
      ),
    );
    return [
      'Any',
      ...ProfileOptions.talentCategories,
      ...extras,
    ];
  }

  final List<String> _genderOptions = [
    'Any',
    'Male',
    'Female',
    'Other',
  ];

  final List<String> _jobTypeOptions = [
    'Any',
    'Paid',
    'Barter',
    'Collab',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final filter = context.read<AppState>().jobFilter;
      setState(() {
        _salaryRange = RangeValues(filter.payStart, filter.payEnd);
        _selectedLocation = filter.location;
        _selectedLanguages
          ..clear()
          ..addAll(filter.languages);
        _selectedCategories
          ..clear()
          ..addAll(filter.categories);
        _selectedGender = filter.gender;
        _ageRange = RangeValues(filter.ageStart, filter.ageEnd);
        _selectedJobTypes
          ..clear()
          ..addAll(filter.jobTypes);
      });
    });
  }

  void _toggleJobType(String type) {
    setState(() {
      if (type == 'Any') {
        _selectedJobTypes
          ..clear()
          ..add('Any');
        return;
      }
      _selectedJobTypes.remove('Any');
      if (_selectedJobTypes.contains(type)) {
        _selectedJobTypes.remove(type);
      } else {
        _selectedJobTypes.add(type);
      }
      if (_selectedJobTypes.isEmpty) _selectedJobTypes.add('Any');
    });
  }

  void _toggleLanguage(String type) {
    setState(() {
      if (type == 'Any') {
        _selectedLanguages..clear()..add('Any');
        return;
      }
      _selectedLanguages.remove('Any');
      if (_selectedLanguages.contains(type)) {
        _selectedLanguages.remove(type);
      } else {
        _selectedLanguages.add(type);
      }
      if (_selectedLanguages.isEmpty) _selectedLanguages.add('Any');
    });
  }

  void _clear() {
    setState(() {
      _salaryRange = const RangeValues(0, 500000);
      _selectedLocation = 'Any';
      _selectedLanguages
        ..clear()
        ..add('Any');
      _selectedCategories
        ..clear()
        ..add('Any');
      _selectedGender = 'Any';
      _ageRange = const RangeValues(0, 100);
      _selectedJobTypes
        ..clear()
        ..add('Any');
    });
  }

  void _apply() {
    context.read<AppState>().setJobFilter(
          context.read<AppState>().jobFilter.copyWith(
            payStart: _salaryRange.start,
            payEnd: _salaryRange.end,
            location: _selectedLocation,
            jobTypes: Set<String>.from(_selectedJobTypes),
            languages: Set<String>.from(_selectedLanguages),
            categories: Set<String>.from(_selectedCategories),
            gender: _selectedGender,
            ageStart: _ageRange.start,
            ageEnd: _ageRange.end,
          ),
        );
    Navigator.maybePop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(AppLocalizations.of(context)!.jobFilters,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.whatKindOfJobsAreYouLookingFor,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Category section
                  AppDropdownField(
                    label: 'Category',
                    value: _selectedCategories.contains('Any')
                        ? 'Any'
                        : (_selectedCategories.length > 2
                            ? '${_selectedCategories.length} selected'
                            : _selectedCategories.join(', ')),
                    onTap: () async {
                      final value = await showMultiSearchableOptionPicker(
                        context: context,
                        title: 'Category',
                        options: _categoryOptions,
                        selected: _selectedCategories,
                      );
                      if (value != null) {
                        setState(() {
                          _selectedCategories.clear();
                          _selectedCategories.addAll(value);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 14),

                  // City selection
                  AppDropdownField(
                    label: 'City',
                    value: _selectedLocation == 'Any'
                        ? 'Any'
                        : ProfileOptions.shortCity(_selectedLocation),
                    onTap: () async {
                      final posted = postedJobCities(
                        context.read<AppState>().jobs,
                      );
                      final cityOptions = <String>['Any'];
                      for (final city in [...posted, ...ProfileOptions.cityNames]) {
                        if (!cityOptions.any(
                          (item) => item.toLowerCase() == city.toLowerCase(),
                        )) {
                          cityOptions.add(city);
                        }
                      }
                      if (!cityOptions.contains('Remote')) {
                        cityOptions.add('Remote');
                      }
                      final value = await showSearchableOptionPicker(
                        context: context,
                        title: 'City',
                        options: cityOptions,
                        selected: _selectedLocation == 'Any'
                            ? 'Any'
                            : ProfileOptions.shortCity(_selectedLocation),
                      );
                      if (value != null) {
                        setState(() => _selectedLocation = value);
                      }
                    },
                  ),
                  const SizedBox(height: 14),

                  // Gender section
                  const AppFormSectionTitle('Gender'),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _genderOptions.map((gender) {
                      final isSelected = _selectedGender == gender;
                      return AppPillChip(
                        label: gender,
                        isSelected: isSelected,
                        onTap: () => setState(() => _selectedGender = gender),
                        activeColor: AppColors.primary,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // Age Range section
                  const AppFormSectionTitle('Age Range'),
                  const SizedBox(height: 4),
                  Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: SliderTheme(
                          data: _getSliderTheme(AppColors.primary),
                          child: RangeSlider(
                            values: _ageRange,
                            min: 0,
                            max: 100,
                            onChanged: (values) {
                              setState(() => _ageRange = values);
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        top: 0,
                        child: AppSliderBadge('${_ageRange.start.round()} yrs'),
                      ),
                      Positioned(
                        right: 12,
                        top: 0,
                        child: AppSliderBadge(
                          _ageRange.end >= 100 ? '100+ yrs' : '${_ageRange.end.round()} yrs',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  AppFormSectionTitle(AppLocalizations.of(context)!.jobType),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _jobTypeOptions.map((type) {
                      final isSelected = _selectedJobTypes.contains(type);
                      return AppPillChip(
                        label: type,
                        isSelected: isSelected,
                        showCheckmark: true,
                        onTap: () => _toggleJobType(type),
                        activeColor: AppColors.primary,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  const AppFormSectionTitle('Content language'),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Any', ...ProfileOptions.languages].map((language) {
                      final isSelected = _selectedLanguages.contains(language);
                      return AppPillChip(
                        label: language,
                        isSelected: isSelected,
                        showCheckmark: true,
                        onTap: () => _toggleLanguage(language),
                        activeColor: AppColors.primary,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  AppFormSectionTitle(AppLocalizations.of(context)!.payRange),
                  const SizedBox(height: 4),
                  Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: SliderTheme(
                          data: _getSliderTheme(AppColors.primary),
                          child: RangeSlider(
                            values: _salaryRange,
                            min: 0,
                            max: 500000,
                            onChanged: (values) {
                              setState(() => _salaryRange = values);
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        top: 0,
                        child: AppSliderBadge('₹${(_salaryRange.start / 1000).round()}'),
                      ),
                      Positioned(
                        right: 12,
                        top: 0,
                        child: AppSliderBadge(
                          _salaryRange.end >= 500000 ? '₹5L+' : '₹${(_salaryRange.end / 100000).toStringAsFixed(1)}L',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          SafeArea(
            minimum: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200, width: 1.0),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.green.shade600, size: 16),
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
                        child: OutlinedButton(
                          onPressed: _clear,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Text(AppLocalizations.of(context)!.clear,
                            style: const TextStyle(color: Colors.black87, fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _apply,
                          style: AppButtonStyle.banner().copyWith(
                            padding: const WidgetStatePropertyAll(
                              EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                          child: Text(AppLocalizations.of(context)!.update),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  SliderThemeData _getSliderTheme(Color primaryColor) {
    return SliderThemeData(
      activeTrackColor: primaryColor,
      inactiveTrackColor: primaryColor.withAlpha(50),
      thumbColor: Colors.white,
      overlayColor: primaryColor.withAlpha(30),
      rangeThumbShape: const RoundRangeSliderThumbShape(
        enabledThumbRadius: 10,
        elevation: 2,
      ),
      trackHeight: 3,
    );
  }
}

