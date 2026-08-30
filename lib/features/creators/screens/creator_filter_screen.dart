import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/widgets/app_filter_widgets.dart';
import 'package:bombay_casting/core/widgets/option_picker.dart';
import 'package:bombay_casting/core/widgets/searchable_option_picker.dart';

class CreatorFilterScreen extends StatefulWidget {
  const CreatorFilterScreen({super.key});

  @override
  State<CreatorFilterScreen> createState() => _CreatorFilterScreenState();
}

class _CreatorFilterScreenState extends State<CreatorFilterScreen> {
  final Set<String> _selectedGenders = {'Any'};
  RangeValues _ageRange = const RangeValues(0, 100);
  final Set<String> _selectedCategories = {'Any'};
  String _selectedLocation = 'Any';

  final List<String> _genderOptions = [
    'Any',
    'Male',
    'Female',
    'Other'
  ];

  List<String> get _categoryOptions => [
        'Any',
        ...ProfileOptions.talentCategories,
      ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final filter = context.read<AppState>().creatorFilter;
      setState(() {
        _selectedGenders
          ..clear()
          ..addAll(filter.genders);
        _ageRange = RangeValues(filter.ageStart, filter.ageEnd);
        _selectedCategories
          ..clear()
          ..addAll(filter.categories);
        _selectedLocation = filter.location;
      });
    });
  }

  void _toggleGender(String type) {
    setState(() {
      if (type == 'Any') {
        _selectedGenders..clear()..add('Any');
        return;
      }
      _selectedGenders.remove('Any');
      if (_selectedGenders.contains(type)) {
        _selectedGenders.remove(type);
      } else {
        _selectedGenders.add(type);
      }
      if (_selectedGenders.isEmpty) _selectedGenders.add('Any');
    });
  }

  void _clear() {
    setState(() {
      _selectedGenders
        ..clear()
        ..add('Any');
      _ageRange = const RangeValues(0, 100);
      _selectedCategories
        ..clear()
        ..add('Any');
      _selectedLocation = 'Any';
    });
  }

  void _apply() {
    context.read<AppState>().setCreatorFilter(
          context.read<AppState>().creatorFilter.copyWith(
            genders: Set<String>.from(_selectedGenders),
            ageStart: _ageRange.start,
            ageEnd: _ageRange.end,
            categories: Set<String>.from(_selectedCategories),
            location: _selectedLocation,
          ),
        );
    Navigator.maybePop(context);
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFE53935);

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
        title: const Text('Creator Filters',
          style: TextStyle(
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
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('What kind of creators are you looking for?',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Category selection dropdown
                  AppDropdownField(
                    label: 'Category',
                    value: _selectedCategories.contains('Any') || _selectedCategories.isEmpty
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

                  // City selection dropdown
                  AppDropdownField(
                    label: 'City',
                    value: _selectedLocation == 'Any'
                        ? 'Any'
                        : ProfileOptions.shortCity(_selectedLocation),
                    onTap: () async {
                      final value = await showSearchableOptionPicker(
                        context: context,
                        title: 'City',
                        options: ['Any', ...ProfileOptions.cityNames],
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

                  const AppFormSectionTitle('Gender'),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _genderOptions.map((gender) {
                      final isSelected = _selectedGenders.contains(gender);
                      return AppPillChip(
                        label: gender,
                        isSelected: isSelected,
                        showCheckmark: true,
                        onTap: () => _toggleGender(gender),
                        activeColor: primaryColor,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  const AppFormSectionTitle('Age Range'),
                  const SizedBox(height: 4),
                  Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: SliderTheme(
                          data: _getSliderTheme(primaryColor),
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
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Text(AppLocalizations.of(context)!.update,
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
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

