import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/providers/app_state.dart';
import 'package:bombay_casting/theme/app_theme.dart';
import 'package:bombay_casting/widgets/option_picker.dart';

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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Work',
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
                    _buildSectionTitle('Role'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ProfileOptions.creatorRoles.map((role) {
                        return _buildChoiceChip(
                          label: role,
                          isSelected: _selectedRole == role,
                          onSelected: () =>
                              setState(() => _selectedRole = role),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    _buildSectionTitle('Experience'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ProfileOptions.experienceLevels.map((level) {
                        return _buildChoiceChip(
                          label: level,
                          isSelected: _selectedExperience == level,
                          onSelected: () =>
                              setState(() => _selectedExperience = level),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    _buildDropdownField(
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
                    const SizedBox(height: 16),
                    _buildDropdownField(
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
                    const SizedBox(height: 16),
                    _buildInputField(
                      label: 'Agency / manager name (Optional)',
                      controller: _agencyController,
                      hintText: 'Type...',
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

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hintText,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.only(top: 4, bottom: 4),
            ),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
