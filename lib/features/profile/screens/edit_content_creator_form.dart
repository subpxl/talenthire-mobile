import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/app_filter_widgets.dart';
import 'package:bombay_casting/core/widgets/app_form_fields.dart';
import 'package:bombay_casting/core/widgets/option_picker.dart';
import 'package:bombay_casting/core/widgets/searchable_option_picker.dart';

class EditContentCreatorFormScreen extends StatefulWidget {
  const EditContentCreatorFormScreen({super.key});

  @override
  State<EditContentCreatorFormScreen> createState() =>
      _EditContentCreatorFormScreenState();
}

class _EditContentCreatorFormScreenState
    extends State<EditContentCreatorFormScreen> {
  static const _section = 'creator';
  static const _payMax = 200000.0;

  final Set<String> _collabTypes = {};
  final Set<String> _platforms = {};
  final Set<String> _formats = {};
  final Set<String> _workModes = {};
  final Set<String> _contentTypes = {};
  final Set<String> _niches = {};
  RangeValues _payRange = const RangeValues(0, _payMax);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final profile = context.read<AppState>().profile;
    if (profile == null) return;
    final data = profile.formSection(_section);
    setState(() {
      _collabTypes
        ..clear()
        ..addAll(_stringSet(data['collab_types']));
      _platforms
        ..clear()
        ..addAll(_stringSet(data['platforms']));
      _formats
        ..clear()
        ..addAll(_stringSet(data['formats']));
      _workModes
        ..clear()
        ..addAll(_stringSet(data['work_modes']));
      _contentTypes
        ..clear()
        ..addAll(_stringSet(data['content_types']));
      _niches
        ..clear()
        ..addAll(_stringSet(data['niches']));
      if (_niches.isEmpty && profile.niches.isNotEmpty) {
        _niches.addAll(profile.niches);
      }
      final min = (data['pay_min'] as num?)?.toDouble();
      final max = (data['pay_max'] as num?)?.toDouble();
      var start = (min ?? 0).clamp(0, _payMax).toDouble();
      var end = (max ?? _payMax).clamp(0, _payMax).toDouble();
      if (start > end) {
        final swap = start;
        start = end;
        end = swap;
      }
      _payRange = RangeValues(start, end);
    });
  }

  Set<String> _stringSet(dynamic stored) {
    if (stored is List) {
      return stored
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty && item != 'Any')
          .toSet();
    }
    if (stored is String && stored.trim().isNotEmpty) {
      return stored
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty && item != 'Any')
          .toSet();
    }
    return {};
  }

  void _toggle(Set<String> values, String option) {
    setState(() {
      if (!values.remove(option)) values.add(option);
    });
  }

  String _display(Set<String> values) {
    if (values.isEmpty) return '';
    if (values.length > 2) return '${values.length} selected';
    return values.join(', ');
  }

  String _formatPay(double value) {
    if (value <= 0) return '₹0';
    if (value >= _payMax) return '₹2L';
    if (value >= 100000) {
      final lakh = value / 100000;
      final text = lakh == lakh.roundToDouble()
          ? '${lakh.round()}'
          : lakh.toStringAsFixed(1);
      return '₹${text}L';
    }
    if (value >= 1000) return '₹${(value / 1000).round()}K';
    return '₹${value.round()}';
  }

  String get _payLabel =>
      '${_formatPay(_payRange.start)} – ${_formatPay(_payRange.end)}';

  Future<void> _pickMulti({
    required String title,
    required List<String> options,
    required Set<String> selected,
  }) async {
    final value = await showMultiSearchableOptionPicker(
      context: context,
      title: title,
      options: options,
      selected: selected,
    );
    if (value == null) return;
    setState(() {
      selected
        ..clear()
        ..addAll(value.where((item) => item != 'Any'));
    });
  }

  Future<void> _save() async {
    await saveProfileSection(
      context: context,
      section: _section,
      data: {
        'collab_types': _collabTypes.toList(),
        'platforms': _platforms.toList(),
        'formats': _formats.toList(),
        'work_modes': _workModes.toList(),
        'content_types': _contentTypes.toList(),
        'niches': _niches.toList(),
        'pay_min': _payRange.start.round(),
        'pay_max': _payRange.end.round(),
        'pay_range': _payLabel,
      },
      extra: (profile) => profile.copyWith(
        niches: _niches.toList(),
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
        title: const Text(
          'For content creators',
          style: TextStyle(
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
                padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 32.0),
                child: AppFormFields(
                  children: [
                    AppChipField(
                      label: 'Collab type',
                      options: ProfileOptions.creatorCollabTypes,
                      isSelected: _collabTypes.contains,
                      onTap: (option) => _toggle(_collabTypes, option),
                    ),
                    _PayRangeField(
                      label: _payLabel,
                      values: _payRange,
                      max: _payMax,
                      onChanged: (values) =>
                          setState(() => _payRange = values),
                    ),
                    AppChipField(
                      label: 'Platforms',
                      options: ProfileOptions.creatorPlatforms,
                      isSelected: _platforms.contains,
                      onTap: (option) => _toggle(_platforms, option),
                    ),
                    AppChipField(
                      label: 'Content format',
                      options: ProfileOptions.creatorContentFormats,
                      isSelected: _formats.contains,
                      onTap: (option) => _toggle(_formats, option),
                    ),
                    AppChipField(
                      label: 'Work mode',
                      options: ProfileOptions.creatorWorkModes,
                      isSelected: _workModes.contains,
                      onTap: (option) => _toggle(_workModes, option),
                    ),
                    AppDropdownField(
                      label: 'Type of content',
                      value: _display(_contentTypes),
                      hint: 'Select',
                      onTap: () => _pickMulti(
                        title: 'Type of content',
                        options: ProfileOptions.contentTypes,
                        selected: _contentTypes,
                      ),
                    ),
                    AppDropdownField(
                      label: 'Niches',
                      value: _display(_niches),
                      hint: 'Select',
                      onTap: () => _pickMulti(
                        title: 'Niches',
                        options: ProfileOptions.niches,
                        selected: _niches,
                      ),
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
              const Icon(
                Icons.verified_user_outlined,
                color: Colors.green,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                AppLocalizations.of(context)!.yourDataIs100SafeWithUs,
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
              child: Text(
                AppLocalizations.of(context)!.update,
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

class _PayRangeField extends StatefulWidget {
  const _PayRangeField({
    required this.label,
    required this.values,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final RangeValues values;
  final double max;
  final ValueChanged<RangeValues> onChanged;

  @override
  State<_PayRangeField> createState() => _PayRangeFieldState();
}

class _PayRangeFieldState extends State<_PayRangeField> {
  late RangeValues _localRange;
  late final TextEditingController _minController;
  late final TextEditingController _maxController;
  late final FocusNode _minFocus;
  late final FocusNode _maxFocus;

  @override
  void initState() {
    super.initState();
    _localRange = widget.values;
    _minController = TextEditingController(text: _payDigits(_localRange.start));
    _maxController = TextEditingController(text: _payDigits(_localRange.end));
    _minFocus = FocusNode()..addListener(_handleMinFocus);
    _maxFocus = FocusNode()..addListener(_handleMaxFocus);
  }

  @override
  void didUpdateWidget(covariant _PayRangeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.values != widget.values &&
        !_minFocus.hasFocus &&
        !_maxFocus.hasFocus) {
      _localRange = widget.values;
      _syncControllers(_localRange);
    }
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    _minFocus.dispose();
    _maxFocus.dispose();
    super.dispose();
  }

  String _payDigits(double value) => value.round().toString();

  void _syncControllers(RangeValues values, {bool syncMin = true, bool syncMax = true}) {
    if (syncMin) {
      final minText = _payDigits(values.start);
      if (_minController.text != minText) {
        _minController.text = minText;
      }
    }
    if (syncMax) {
      final maxText = _payDigits(values.end);
      if (_maxController.text != maxText) {
        _maxController.text = maxText;
      }
    }
  }

  void _handleMinFocus() {
    if (!_minFocus.hasFocus) {
      _minController.text = _payDigits(_localRange.start);
    }
  }

  void _handleMaxFocus() {
    if (!_maxFocus.hasFocus) {
      _maxController.text = _payDigits(_localRange.end);
    }
  }

  void _emitRange(RangeValues values, {bool syncMin = true, bool syncMax = true}) {
    setState(() => _localRange = values);
    _syncControllers(values, syncMin: syncMin, syncMax: syncMax);
    widget.onChanged(values);
  }

  void _onMinTextChanged(String text) {
    final parsed = int.tryParse(text);
    if (parsed == null && text.isNotEmpty) return;

    var start = (parsed ?? 0).clamp(0, widget.max.round()).toDouble();
    var end = _localRange.end;
    final syncMax = start > end;
    if (syncMax) end = start;

    _emitRange(
      RangeValues(start, end),
      syncMin: false,
      syncMax: syncMax,
    );
  }

  void _onMaxTextChanged(String text) {
    final parsed = int.tryParse(text);
    if (parsed == null && text.isNotEmpty) return;

    var end = (parsed ?? widget.max.round()).clamp(0, widget.max.round()).toDouble();
    var start = _localRange.start;
    final syncMin = end < start;
    if (syncMin) start = end;

    _emitRange(
      RangeValues(start, end),
      syncMin: syncMin,
      syncMax: false,
    );
  }

  void _onSliderChanged(RangeValues values) {
    _emitRange(
      values,
      syncMin: !_minFocus.hasFocus,
      syncMax: !_maxFocus.hasFocus,
    );
  }

  Widget _payInput({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required ValueChanged<String> onChanged,
  }) {
    return Expanded(
      child: Container(
        padding: AppFormStyle.fieldPadding,
        decoration: AppFormStyle.fieldBox,
        child: Row(
          children: [
            Text('₹', style: AppFormStyle.valueStyle),
            const SizedBox(width: 4),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: AppFormStyle.valueStyle,
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: AppFormStyle.hintStyle,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: onChanged,
                textInputAction: TextInputAction.done,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppFormSectionTitle('Pay range'),
        const SizedBox(height: 8),
        Row(
          children: [
            _payInput(
              controller: _minController,
              focusNode: _minFocus,
              hint: 'Min',
              onChanged: _onMinTextChanged,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                '–',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
              ),
            ),
            _payInput(
              controller: _maxController,
              focusNode: _maxFocus,
              hint: 'Max',
              onChanged: _onMaxTextChanged,
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.primary.withAlpha(50),
            thumbColor: Colors.white,
            overlayColor: AppColors.primary.withAlpha(30),
            rangeThumbShape: const RoundRangeSliderThumbShape(
              enabledThumbRadius: 10,
              elevation: 2,
            ),
            trackHeight: 3,
          ),
          child: RangeSlider(
            values: _localRange,
            min: 0,
            max: widget.max,
            divisions: 200,
            onChanged: _onSliderChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 12, right: 12, top: 2),
          child: Text(
            widget.label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ),
      ],
    );
  }
}
