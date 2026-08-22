import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/providers/app_state.dart';
import 'package:bombay_casting/theme/app_theme.dart';
import 'package:bombay_casting/widgets/option_picker.dart';

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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Rates',
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
                    _buildSectionTitle('Collaboration type'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ProfileOptions.collabTypes.map((type) {
                        return _buildChoiceChip(
                          label: type,
                          isSelected: _selectedCollabType == type,
                          onSelected: () =>
                              setState(() => _selectedCollabType = type),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    _buildDropdownField(
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
                    const SizedBox(height: 20),
                    _buildSectionTitle('Availability'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ProfileOptions.availability.map((option) {
                        return _buildChoiceChip(
                          label: option,
                          isSelected: _selectedAvailability == option,
                          onSelected: () =>
                              setState(() => _selectedAvailability = option),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    _buildSectionTitle('Can travel for shoots?'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _travelOptions.map((option) {
                        return _buildChoiceChip(
                          label: option,
                          isSelected: _selectedTravel == option,
                          onSelected: () =>
                              setState(() => _selectedTravel = option),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    _buildSectionTitle('Work mode'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ProfileOptions.workModes.map((mode) {
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
              Text(
                'Your data is 100% safe with us',
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
              child: const Text(
                'Update',
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
          color: isSelected ? AppColors.primary.withOpacity(0.06) : Colors.white,
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
