import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/app_filter_widgets.dart';
import 'package:bombay_casting/core/widgets/option_picker.dart';

class EditRatesFieldsScreen extends StatefulWidget {
  const EditRatesFieldsScreen({super.key});

  @override
  State<EditRatesFieldsScreen> createState() =>
      _EditRatesFieldsScreenState();
}

class _EditRatesFieldsScreenState extends State<EditRatesFieldsScreen> {
  String _selectedCollabType = 'Paid';
  String _selectedPay = '₹ 15,000 - ₹ 40,000';
  String _selectedAvailability = 'This week';
  String _selectedTravel = 'Sometimes';
  String _selectedWorkMode = 'Remote';

  final List<String> _travelOptions = ['Yes', 'No', 'Sometimes'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final profile = context.read<AppState>().profile;
    if (profile == null) return;
    final rates = profile.formSection('rates');
    setState(() {
      _selectedCollabType =
          (rates['collab_type'] ?? _selectedCollabType).toString();
      _selectedPay = (rates['expected_pay'] ?? _selectedPay).toString();
      _selectedAvailability =
          (rates['availability'] ?? _selectedAvailability).toString();
      _selectedTravel = (rates['can_travel'] ?? _selectedTravel).toString();
      _selectedWorkMode = (rates['work_mode'] ?? _selectedWorkMode).toString();
    });
  }

  Future<void> _save() async {
    await saveProfileSection(
      context: context,
      section: 'rates',
      data: {
        'collab_type': _selectedCollabType,
        'expected_pay': _selectedPay,
        'availability': _selectedAvailability,
        'can_travel': _selectedTravel,
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
        title: Text(AppLocalizations.of(context)!.rates,
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
                    const AppFormSectionTitle('Collaboration type'),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ProfileOptions.collabTypes.map((type) {
                        return AppPillChip(
                          label: type,
                          isSelected: _selectedCollabType == type,
                          onTap: () =>
                              setState(() => _selectedCollabType = type),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    AppDropdownField(
                      label: 'Expected pay per collab',
                      value: _selectedPay,
                      onTap: () async {
                        final value = await showOptionPicker(
                          context: context,
                          title: 'Expected pay per collab',
                          options: ProfileOptions.collabPays,
                          selected: _selectedPay,
                        );
                        if (value != null) setState(() => _selectedPay = value);
                      },
                    ),
                    const SizedBox(height: 14),
                    const AppFormSectionTitle('Availability'),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ProfileOptions.availability.map((option) {
                        return AppPillChip(
                          label: option,
                          isSelected: _selectedAvailability == option,
                          onTap: () =>
                              setState(() => _selectedAvailability = option),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    const AppFormSectionTitle('Can travel for shoots?'),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _travelOptions.map((option) {
                        return AppPillChip(
                          label: option,
                          isSelected: _selectedTravel == option,
                          onTap: () =>
                              setState(() => _selectedTravel = option),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    const AppFormSectionTitle('Work mode'),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ProfileOptions.workModes.map((mode) {
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

