import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/app_filter_widgets.dart';
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

  @override
  void dispose() {
    _aboutController.dispose();
    super.dispose();
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
        title: Text(AppLocalizations.of(context)!.personal,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppFormSectionTitle('Gender'),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ProfileOptions.genders.map((gender) {
                        return AppPillChip(
                          label: gender,
                          isSelected: _selectedGender == gender,
                          onTap: () =>
                              setState(() => _selectedGender = gender),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    AppDropdownField(
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
                    const SizedBox(height: 14),
                    AppDropdownField(
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
                    const SizedBox(height: 14),
                    const AppFormSectionTitle('Content language'),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ProfileOptions.languages.map((language) {
                        return AppPillChip(
                          label: language,
                          isSelected: _selectedLanguages.contains(language),
                          onTap: () => _toggleLanguage(language),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    const AppFormSectionTitle('Creator type'),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ProfileOptions.creatorTypes.map((type) {
                        return AppPillChip(
                          label: type,
                          isSelected: _selectedCreatorType == type,
                          onTap: () =>
                              setState(() => _selectedCreatorType = type),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    const AppFormSectionTitle('Open to'),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _lookingForOptions.map((option) {
                        return AppPillChip(
                          label: option,
                          isSelected: _selectedLookingFor == option,
                          onTap: () =>
                              setState(() => _selectedLookingFor = option),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    const AppFormSectionTitle(
                      'Tell brands about yourself.',
                      optional: true,
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _aboutController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Type...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 13.5,
                        ),
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
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
      padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 16.0),
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
        ],
      ),
    );
  }
}
