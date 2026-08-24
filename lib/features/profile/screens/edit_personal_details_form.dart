import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/option_picker.dart';

class EditPersonalFieldsScreen extends StatefulWidget {
  const EditPersonalFieldsScreen({super.key});

  @override
  State<EditPersonalFieldsScreen> createState() =>
      _EditPersonalFieldsScreenState();
}

class _EditPersonalFieldsScreenState extends State<EditPersonalFieldsScreen> {
  String _selectedGender = 'Female';
  String _selectedAge = '24';
  String _selectedLocation = 'Mumbai, Maharashtra';
  final Set<String> _selectedLanguages = {'Hindi'};
  String _selectedCreatorType = 'Full-time creator';
  String _selectedLookingFor = 'Brand deals';
  final TextEditingController _aboutController = TextEditingController();

  final List<String> _lookingForOptions = [
    'Brand deals',
    'UGC work',
    'Ambassadorships',
    'All',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final profile = context.read<AppState>().profile;
    if (profile == null) return;
    final personal = profile.formSection('personal');
    final location = [
      profile.city,
      profile.state,
    ].where((item) => item.isNotEmpty).join(', ');
    setState(() {
      _selectedGender = (personal['gender'] ??
              (profile.gender.isNotEmpty ? profile.gender : _selectedGender))
          .toString();
      _selectedAge = (personal['age'] ??
              (profile.age != null ? '${profile.age}' : _selectedAge))
          .toString();
      _selectedLocation = (personal['location'] ??
              (location.isNotEmpty ? location : _selectedLocation))
          .toString();
      _selectedLanguages
        ..clear()
        ..addAll(_languagesFrom(personal['language'], profile.languages));
      _selectedCreatorType =
          (personal['creator_type'] ?? _selectedCreatorType).toString();
      _selectedLookingFor =
          (personal['looking_for'] ?? _selectedLookingFor).toString();
      _aboutController.text = profile.bio;
    });
  }

  List<String> _languagesFrom(dynamic stored, List<String> fallback) {
    if (stored is List && stored.isNotEmpty) {
      return stored.map((item) => item.toString()).where((item) => item.isNotEmpty).toList();
    }
    if (stored is String && stored.trim().isNotEmpty) {
      return stored
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    if (fallback.isNotEmpty) return fallback;
    return const ['Hindi'];
  }

  void _toggleLanguage(String language) {
    setState(() {
      if (_selectedLanguages.contains(language)) {
        if (_selectedLanguages.length > 1) {
          _selectedLanguages.remove(language);
        }
      } else {
        _selectedLanguages.add(language);
      }
    });
  }

  Future<void> _save() async {
    final parts = _selectedLocation.split(',');
    await saveProfileSection(
      context: context,
      section: 'personal',
      data: {
        'gender': _selectedGender,
        'age': _selectedAge,
        'location': _selectedLocation,
        'language': _selectedLanguages.toList(),
        'creator_type': _selectedCreatorType,
        'looking_for': _selectedLookingFor,
      },
      extra: (profile) => profile.copyWith(
        bio: _aboutController.text.trim(),
        gender: _selectedGender,
        age: int.tryParse(_selectedAge.replaceAll(RegExp(r'[^0-9]'), '')),
        city: parts.first.trim(),
        state:
            parts.length > 1 ? parts.sublist(1).join(',').trim() : profile.state,
        languages: _selectedLanguages.toList(),
        talent: _selectedCreatorType,
      ),
    );
  }

  @override
  void dispose() {
    _aboutController.dispose();
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
        title: Text(AppLocalizations.of(context)!.personal,
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
                    _buildSectionTitle('Gender'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ProfileOptions.genders.map((gender) {
                        return _buildChoiceChip(
                          label: gender,
                          isSelected: _selectedGender == gender,
                          onSelected: () =>
                              setState(() => _selectedGender = gender),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    _buildDropdownField(
                      label: 'Age',
                      value: _selectedAge,
                      onTap: () async {
                        final value = await showOptionPicker(
                          context: context,
                          title: 'Age',
                          options: ProfileOptions.ages,
                          selected: _selectedAge,
                        );
                        if (value != null) setState(() => _selectedAge = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildDropdownField(
                      label: 'Location',
                      value: _selectedLocation,
                      onTap: () async {
                        final value = await showOptionPicker(
                          context: context,
                          title: 'Location',
                          options: ProfileOptions.cities,
                          selected: _selectedLocation,
                        );
                        if (value != null) {
                          setState(() => _selectedLocation = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildSectionTitle('Content language'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ProfileOptions.languages.map((language) {
                        return _buildChoiceChip(
                          label: language,
                          isSelected: _selectedLanguages.contains(language),
                          onSelected: () => _toggleLanguage(language),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    _buildSectionTitle('Creator type'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ProfileOptions.creatorTypes.map((type) {
                        return _buildChoiceChip(
                          label: type,
                          isSelected: _selectedCreatorType == type,
                          onSelected: () =>
                              setState(() => _selectedCreatorType = type),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    _buildSectionTitle('Open to'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _lookingForOptions.map((option) {
                        return _buildChoiceChip(
                          label: option,
                          isSelected: _selectedLookingFor == option,
                          onSelected: () =>
                              setState(() => _selectedLookingFor = option),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _buildSectionTitle('Tell brands about yourself.'),
                        const Spacer(),
                        Text(AppLocalizations.of(context)!.optional,
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _aboutController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Type...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary),
                        ),
                      ),
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
              child: Text(AppLocalizations.of(context)!.update,
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
          color: isSelected ? AppColors.primary.withValues(alpha: 0.06) : Colors.white,
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
}
