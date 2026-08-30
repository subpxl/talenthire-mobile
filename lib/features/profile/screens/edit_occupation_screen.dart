import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/app_filter_widgets.dart';
import 'package:bombay_casting/core/widgets/option_picker.dart';

class EditOccupationScreen extends StatefulWidget {
  const EditOccupationScreen({super.key});

  @override
  State<EditOccupationScreen> createState() => _EditOccupationScreenState();
}

class _EditOccupationScreenState extends State<EditOccupationScreen> {
  String _selectedRole = 'Influencer';
  String _selectedExperience = 'Growing (1-3 yrs)';
  String _selectedIncome = '₹ 25,000 - ₹ 50,000';
  String _selectedLocation = 'Mumbai, Maharashtra';
  final TextEditingController _agencyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final profile = context.read<AppState>().profile;
    if (profile == null) return;
    final work = profile.formSection('work');
    final fallbackLocation = [
      profile.city,
      profile.state,
    ].where((item) => item.isNotEmpty).join(', ');
    setState(() {
      _selectedRole = (work['role'] ?? _selectedRole).toString();
      _selectedExperience =
          (work['experience'] ?? _selectedExperience).toString();
      _selectedIncome = (work['monthly_income'] ?? _selectedIncome).toString();
      _selectedLocation = (work['based_in'] ??
              (fallbackLocation.isNotEmpty
                  ? fallbackLocation
                  : _selectedLocation))
          .toString();
      _agencyController.text = (work['agency_name'] ?? '').toString();
    });
  }

  Future<void> _save() async {
    final parts = _selectedLocation.split(',');
    await saveProfileSection(
      context: context,
      section: 'work',
      data: {
        'role': _selectedRole,
        'experience': _selectedExperience,
        'monthly_income': _selectedIncome,
        'based_in': _selectedLocation,
        'agency_name': _agencyController.text.trim(),
      },
      extra: (profile) => profile.copyWith(
        city: parts.first.trim(),
        state:
            parts.length > 1 ? parts.sublist(1).join(',').trim() : profile.state,
      ),
    );
  }

  @override
  void dispose() {
    _agencyController.dispose();
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
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(AppLocalizations.of(context)!.work,
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
                    const AppFormSectionTitle('Role'),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ProfileOptions.creatorRoles.map((role) {
                        return AppPillChip(
                          label: role,
                          isSelected: _selectedRole == role,
                          onTap: () =>
                              setState(() => _selectedRole = role),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    const AppFormSectionTitle('Experience'),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ProfileOptions.experienceLevels.map((level) {
                        return AppPillChip(
                          label: level,
                          isSelected: _selectedExperience == level,
                          onTap: () =>
                              setState(() => _selectedExperience = level),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    AppDropdownField(
                      label: 'Monthly content income',
                      value: _selectedIncome,
                      onTap: () async {
                        final value = await showOptionPicker(
                          context: context,
                          title: 'Monthly content income',
                          options: ProfileOptions.salaries,
                          selected: _selectedIncome,
                        );
                        if (value != null) {
                          setState(() => _selectedIncome = value);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    AppDropdownField(
                      label: 'Based in',
                      value: _selectedLocation,
                      onTap: () async {
                        final value = await showOptionPicker(
                          context: context,
                          title: 'Based in',
                          options: ProfileOptions.cities,
                          selected: _selectedLocation,
                        );
                        if (value != null) {
                          setState(() => _selectedLocation = value);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    _buildInputField(
                      label: 'Agency / manager name',
                      controller: _agencyController,
                      hintText: 'Type...',
                      optional: true,
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

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    bool optional = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppFormSectionTitle(label, optional: optional),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
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
      ],
    );
  }
}

