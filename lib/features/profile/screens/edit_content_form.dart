import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/app_filter_widgets.dart';
import 'package:bombay_casting/core/widgets/option_picker.dart';

class EditContentFieldsScreen extends StatefulWidget {
  const EditContentFieldsScreen({super.key});

  @override
  State<EditContentFieldsScreen> createState() => _EditContentFieldsScreenState();
}

class _EditContentFieldsScreenState extends State<EditContentFieldsScreen> {
  final Set<String> _selectedNiches = {};
  final Set<String> _selectedFormats = {};
  final Set<String> _selectedBrandCategories = {};
  String _selectedStyle = 'On-camera';

  final List<String> _styleOptions = [
    'On-camera',
    'Voiceover',
    'Unboxing',
    'Reviews',
    'Tutorials',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final profile = context.read<AppState>().profile;
    if (profile == null) return;
    final content = profile.formSection('content');
    setState(() {
      _selectedStyle = (content['content_style'] ?? _selectedStyle).toString();
      _selectedNiches
        ..clear()
        ..addAll(
          content['niches'] is List
              ? (content['niches'] as List).map((item) => item.toString())
              : profile.niches,
        );
      _selectedFormats
        ..clear()
        ..addAll(
          content['formats'] is List
              ? (content['formats'] as List).map((item) => item.toString())
              : const <String>[],
        );
      _selectedBrandCategories
        ..clear()
        ..addAll(
          content['brand_categories'] is List
              ? (content['brand_categories'] as List)
                  .map((item) => item.toString())
              : const <String>[],
        );
    });
  }

  Future<void> _save() async {
    await saveProfileSection(
      context: context,
      section: 'content',
      data: {
        'niches': _selectedNiches.toList(),
        'formats': _selectedFormats.toList(),
        'brand_categories': _selectedBrandCategories.toList(),
        'content_style': _selectedStyle,
      },
      extra: (profile) => profile.copyWith(
        niches: _selectedNiches.toList(),
      ),
    );
  }

  void _toggle(Set<String> target, String value) {
    setState(() {
      if (target.contains(value)) {
        target.remove(value);
      } else {
        target.add(value);
      }
    });
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
        title: Text(AppLocalizations.of(context)!.content,
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
                    const AppFormSectionTitle('Niches'),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ProfileOptions.niches.map((niche) {
                        final isSelected = _selectedNiches.contains(niche);
                        return AppPillChip(
                          label: niche,
                          isSelected: isSelected,
                          icon: isSelected ? Icons.check : Icons.add,
                          onTap: () => _toggle(_selectedNiches, niche),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    const AppFormSectionTitle('Content formats'),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ProfileOptions.contentFormats.map((format) {
                        final isSelected = _selectedFormats.contains(format);
                        return AppPillChip(
                          label: format,
                          isSelected: isSelected,
                          icon: isSelected ? Icons.check : Icons.add,
                          onTap: () => _toggle(_selectedFormats, format),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    const AppFormSectionTitle('Brand categories you take'),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ProfileOptions.niches.map((category) {
                        final isSelected =
                            _selectedBrandCategories.contains(category);
                        return AppPillChip(
                          label: category,
                          isSelected: isSelected,
                          icon: isSelected ? Icons.check : Icons.add,
                          onTap: () =>
                              _toggle(_selectedBrandCategories, category),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    const AppFormSectionTitle('Comfortable with'),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _styleOptions.map((style) {
                        return AppPillChip(
                          label: style,
                          isSelected: _selectedStyle == style,
                          onTap: () =>
                              setState(() => _selectedStyle = style),
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

