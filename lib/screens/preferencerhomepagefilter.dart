import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/data/job_assets.dart';
import 'package:bombay_casting/providers/app_state.dart';
import 'package:bombay_casting/widgets/option_picker.dart';

class PreferenceScreen extends StatefulWidget {
  const PreferenceScreen({super.key});

  @override
  State<PreferenceScreen> createState() => _PreferenceScreenState();
}

class _PreferenceScreenState extends State<PreferenceScreen> {
  RangeValues _followerRange = const RangeValues(0, 100);
  RangeValues _salaryRange = const RangeValues(0, 500000);

  bool _includeOtherCities = false;
  final Set<String> _selectedJobTypes = {'Any'};
  String _selectedLocation = 'Any';
  String _selectedLanguage = 'Any';
  String _selectedCategory = 'Any';

  final List<String> _jobTypeOptions = [
    'Any',
    'Paid collab',
    'Barter',
    'Audition',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final filter = context.read<AppState>().jobFilter;
      setState(() {
        _followerRange = RangeValues(filter.followerStart, filter.followerEnd);
        _salaryRange = RangeValues(filter.payStart, filter.payEnd);
        _includeOtherCities = filter.includeOtherCities;
        _selectedLocation = filter.location;
        _selectedLanguage = filter.language;
        _selectedCategory = filter.category;
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

  void _clear() {
    setState(() {
      _followerRange = const RangeValues(0, 100);
      _salaryRange = const RangeValues(0, 500000);
      _includeOtherCities = false;
      _selectedLocation = 'Any';
      _selectedLanguage = 'Any';
      _selectedCategory = 'Any';
      _selectedJobTypes
        ..clear()
        ..add('Any');
    });
  }

  void _apply() {
    context.read<AppState>().setJobFilter(
          HomeJobFilter(
            followerStart: _followerRange.start,
            followerEnd: _followerRange.end,
            payStart: _salaryRange.start,
            payEnd: _salaryRange.end,
            includeOtherCities: _includeOtherCities,
            location: _selectedLocation,
            jobTypes: Set<String>.from(_selectedJobTypes),
            language: _selectedLanguage,
            category: _selectedCategory,
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
        title: const Text(
          'Job filters',
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
                  const Text(
                    'What kind of jobs are you looking for?',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Followers required',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: SliderTheme(
                          data: _getSliderTheme(primaryColor),
                          child: RangeSlider(
                            values: _followerRange,
                            min: 0,
                            max: 100,
                            onChanged: (values) {
                              setState(() => _followerRange = values);
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        top: 0,
                        child: _buildBadge(_followerLabel(_followerRange.start)),
                      ),
                      Positioned(
                        right: 12,
                        top: 0,
                        child: _buildBadge(_followerLabel(_followerRange.end)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Include jobs outside your city?',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildChip(
                        label: 'Yes',
                        isSelected: _includeOtherCities,
                        onTap: () => setState(() => _includeOtherCities = true),
                        activeColor: primaryColor,
                      ),
                      const SizedBox(width: 12),
                      _buildChip(
                        label: 'No',
                        isSelected: !_includeOtherCities,
                        onTap: () => setState(() => _includeOtherCities = false),
                        activeColor: primaryColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _buildDropdownField(
                    'Job location',
                    _selectedLocation,
                    () async {
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
                  const SizedBox(height: 24),

                  const Text(
                    'Job type',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _jobTypeOptions.map((type) {
                      final isSelected = _selectedJobTypes.contains(type);
                      return _buildChip(
                        label: type,
                        isSelected: isSelected,
                        showCheckmark: true,
                        onTap: () => _toggleJobType(type),
                        activeColor: primaryColor,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  _buildDropdownField(
                    'Content language',
                    _selectedLanguage,
                    () async {
                      final value = await showOptionPicker(
                        context: context,
                        title: 'Content language',
                        options: ['Any', ...ProfileOptions.languages],
                        selected: _selectedLanguage,
                      );
                      if (value != null) {
                        setState(() => _selectedLanguage = value);
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Pay range',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: SliderTheme(
                          data: _getSliderTheme(primaryColor),
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
                        child: _buildBadge('₹${(_salaryRange.start / 1000).round()}'),
                      ),
                      Positioned(
                        right: 12,
                        top: 0,
                        child: _buildBadge(
                          _salaryRange.end >= 500000 ? '₹5L+' : '₹${(_salaryRange.end / 100000).toStringAsFixed(1)}L',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _buildDropdownField(
                    'Category',
                    _selectedCategory,
                    () async {
                      final value = await showOptionPicker(
                        context: context,
                        title: 'Category',
                        options: ['Any', ...ProfileOptions.jobCategories],
                        selected: _selectedCategory,
                      );
                      if (value != null) {
                        setState(() => _selectedCategory = value);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          SafeArea(
            minimum: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                      Icon(Icons.check_circle_outline, color: Colors.green.shade600, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Your data is 100% safe with us',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _clear,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Clear',
                            style: TextStyle(color: Colors.black87, fontSize: 15),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _apply,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Update',
                            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
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

  String _followerLabel(double value) {
    final thousands = value.round();
    if (thousands >= 100) return '100K+';
    if (thousands == 0) return 'Any';
    return '${thousands}K';
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

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDC1C38).withAlpha(60), width: 1),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFFDC1C38),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color activeColor,
    bool showCheckmark = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor.withAlpha(150) : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? activeColor : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
            if (showCheckmark && isSelected) ...[
              const SizedBox(width: 4),
              Icon(Icons.check, size: 14, color: activeColor),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField(String label, String value, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
