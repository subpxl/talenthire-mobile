import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/app_filter_widgets.dart';
import 'package:bombay_casting/core/widgets/app_form_fields.dart';
import 'package:bombay_casting/core/widgets/option_picker.dart';
import 'package:bombay_casting/core/widgets/searchable_option_picker.dart';

class EditPersonalFieldsScreen extends StatefulWidget {
  const EditPersonalFieldsScreen({super.key});

  @override
  State<EditPersonalFieldsScreen> createState() =>
      _EditPersonalFieldsScreenState();
}

class _EditPersonalFieldsScreenState extends State<EditPersonalFieldsScreen> {
  String _selectedGender = 'Female';
  String _selectedAge = '';
  String _selectedLocation = '';
  final Set<String> _selectedLanguages = {'Hindi'};
  final Set<String> _selectedCategories = {};
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  bool _whatsappSameAsMobile = true;

  @override
  void initState() {
    super.initState();
    _mobileController.addListener(_syncWhatsappFromMobile);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final appState = context.read<AppState>();
    final profile = appState.profile;
    final user = appState.user;
    if (profile == null) return;
    final personal = profile.formSection('personal');
    final location = [
      profile.city,
      profile.state,
    ].where((item) => item.isNotEmpty).join(', ');
    setState(() {
      _nameController.text = _firstValue(
        personal['name'],
        user?.name,
      );
      _emailController.text = _firstValue(
        personal['email'],
        user?.email,
      );
      _mobileController.text = _firstValue(
        personal['mobile'],
        user?.mobile,
      );
      final whatsapp = _firstValue(personal['whatsapp'], '');
      final sameAsStored = personal['whatsapp_same_as_mobile'];
      _whatsappSameAsMobile = sameAsStored == true ||
          (sameAsStored != false &&
              (whatsapp.isEmpty || whatsapp == _mobileController.text));
      _whatsappController.text =
          _whatsappSameAsMobile ? _mobileController.text : whatsapp;
      _selectedGender = _normalizeGender(
        (personal['gender'] ??
                (profile.gender.isNotEmpty ? profile.gender : _selectedGender))
            .toString(),
      );
      _selectedAge = (personal['age'] ??
              (profile.age != null ? '${profile.age}' : _selectedAge))
          .toString();
      _selectedLocation = (personal['location'] ??
              (location.isNotEmpty ? location : _selectedLocation))
          .toString();
      _selectedLanguages
        ..clear()
        ..addAll(_languagesFrom(personal['language'], profile.languages));
      _selectedCategories
        ..clear()
        ..addAll(_categoriesFrom(personal['categories'], profile.talent));
      _aboutController.text = profile.bio;
    });
  }

  String _firstValue(dynamic stored, String? fallback) {
    final value = stored?.toString().trim() ?? '';
    if (value.isNotEmpty) return value;
    return fallback?.trim() ?? '';
  }

  String _normalizeGender(String value) {
    final lower = value.trim().toLowerCase();
    if (lower == 'non-binary' ||
        lower == 'nonbinary' ||
        lower == 'non binary' ||
        lower == 'prefer not to say') {
      return 'Other';
    }
    return value;
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

  List<String> _categoriesFrom(dynamic stored, String fallback) {
    if (stored is List && stored.isNotEmpty) {
      return stored
          .map((item) => item.toString())
          .where((item) => item.isNotEmpty && item != 'Any')
          .toList();
    }
    if (stored is String && stored.trim().isNotEmpty) {
      return stored
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty && item != 'Any')
          .toList();
    }
    if (fallback.isNotEmpty && fallback != 'influencer') return [fallback];
    return const [];
  }

  String get _categoryDisplay {
    if (_selectedCategories.isEmpty) return '';
    if (_selectedCategories.length > 2) {
      return '${_selectedCategories.length} selected';
    }
    return _selectedCategories.join(', ');
  }

  @override
  void dispose() {
    _mobileController.removeListener(_syncWhatsappFromMobile);
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _whatsappController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  void _syncWhatsappFromMobile() {
    if (!_whatsappSameAsMobile) return;
    final mobile = _mobileController.text;
    if (_whatsappController.text != mobile) {
      _whatsappController.text = mobile;
    }
  }

  void _setWhatsappSameAsMobile(bool value) {
    setState(() {
      _whatsappSameAsMobile = value;
      if (value) {
        _whatsappController.text = _mobileController.text;
      }
    });
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
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final mobile = _mobileController.text.trim();
    final whatsapp = _whatsappSameAsMobile
        ? mobile
        : _whatsappController.text.trim();
    await context.read<AppState>().updateUser(
          name: name,
          mobile: mobile,
        );
    if (!mounted) return;
    await saveProfileSection(
      context: context,
      section: 'personal',
      data: {
        'name': name,
        'email': email,
        'gender': _selectedGender,
        'mobile': mobile,
        'whatsapp': whatsapp,
        'whatsapp_same_as_mobile': _whatsappSameAsMobile,
        'age': _selectedAge,
        'location': _selectedLocation,
        'language': _selectedLanguages.toList(),
        'categories': _selectedCategories.toList(),
      },
      extra: (profile) => profile.copyWith(
        bio: _aboutController.text.trim(),
        gender: _selectedGender,
        age: int.tryParse(_selectedAge.replaceAll(RegExp(r'[^0-9]'), '')),
        city: parts.first.trim(),
        state:
            parts.length > 1 ? parts.sublist(1).join(',').trim() : profile.state,
        languages: _selectedLanguages.toList(),
        talent: _selectedCategories.isEmpty
            ? profile.talent
            : _selectedCategories.join(', '),
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
                child: AppFormFields(
                  children: [
                    AppTextField(
                      label: 'Name',
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      labelAsPlaceholder: true,
                    ),
                    AppReadOnlyField(
                      label: 'Email',
                      value: _emailController.text,
                      labelAsPlaceholder: true,
                    ),
                    AppChipField(
                      label: 'Gender',
                      options: ProfileOptions.genders,
                      isSelected: (option) => _selectedGender == option,
                      onTap: (option) =>
                          setState(() => _selectedGender = option),
                    ),
                    AppTextField(
                      label: 'Mobile number',
                      controller: _mobileController,
                      keyboardType: TextInputType.phone,
                      labelAsPlaceholder: true,
                    ),
                    AppTextField(
                      label: 'WhatsApp number',
                      controller: _whatsappController,
                      keyboardType: TextInputType.phone,
                      enabled: !_whatsappSameAsMobile,
                      labelAsPlaceholder: true,
                      trailing: AppFormCheckbox(
                        label: 'Same as above',
                        value: _whatsappSameAsMobile,
                        onChanged: _setWhatsappSameAsMobile,
                      ),
                    ),
                    AppDropdownField(
                      label: 'Age',
                      value: _selectedAge,
                      labelAsPlaceholder: true,
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
                    AppDropdownField(
                      label: 'Location',
                      value: _selectedLocation,
                      labelAsPlaceholder: true,
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
                    AppChipField(
                      label: 'Language',
                      options: ProfileOptions.languages,
                      isSelected: _selectedLanguages.contains,
                      onTap: _toggleLanguage,
                    ),
                    AppDropdownField(
                      label: 'Category',
                      value: _categoryDisplay,
                      labelAsPlaceholder: true,
                      onTap: () async {
                        final value = await showMultiSearchableOptionPicker(
                          context: context,
                          title: 'Category',
                          options: ProfileOptions.talentCategories,
                          selected: _selectedCategories,
                        );
                        if (value == null) return;
                        setState(() {
                          _selectedCategories
                            ..clear()
                            ..addAll(
                              value.where((item) => item != 'Any'),
                            );
                        });
                      },
                    ),
                    AppTextField(
                      label: 'About me',
                      controller: _aboutController,
                      maxLines: 3,
                      labelAsPlaceholder: true,
                    ),
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
