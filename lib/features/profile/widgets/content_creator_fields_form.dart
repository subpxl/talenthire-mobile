import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/app_filter_widgets.dart';
import 'package:bombay_casting/core/widgets/app_form_fields.dart';
import 'package:bombay_casting/core/widgets/option_picker.dart';
import 'package:bombay_casting/core/widgets/searchable_option_picker.dart';

/// Reusable "For content creators" field set (collab type, pay range,
/// platforms, content format, work mode, content types, niches).
///
/// This is the single source of truth for these fields so that the
/// standalone Edit Profile screen and the first-login onboarding wizard
/// always render and save the exact same fields/values.
class ContentCreatorFieldsForm extends StatefulWidget {
  const ContentCreatorFieldsForm({
    super.key,
    this.initialData = const {},
    this.initialNiches = const [],
  });

  /// Previously stored `profile.formSection('creator')` data, if any.
  final Map<String, dynamic> initialData;

  /// Fallback niches sourced from `profile.niches` when the creator form
  /// section itself doesn't have niches saved yet.
  final List<String> initialNiches;

  @override
  State<ContentCreatorFieldsForm> createState() =>
      ContentCreatorFieldsFormState();
}

class ContentCreatorFieldsFormState extends State<ContentCreatorFieldsForm> {
  static const _payMax = 200000.0;

  final Set<String> collabTypes = {};
  final Set<String> platforms = {};
  final Set<String> formats = {};
  final Set<String> workModes = {};
  final Set<String> contentTypes = {};
  final Set<String> niches = {};
  RangeValues payRange = const RangeValues(0, _payMax);

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    collabTypes.addAll(_stringSet(data['collab_types']));
    platforms.addAll(_stringSet(data['platforms']));
    formats.addAll(_stringSet(data['formats']));
    workModes.addAll(_stringSet(data['work_modes']));
    contentTypes.addAll(_stringSet(data['content_types']));
    niches.addAll(_stringSet(data['niches']));
    if (niches.isEmpty && widget.initialNiches.isNotEmpty) {
      niches.addAll(widget.initialNiches);
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
    payRange = RangeValues(start, end);
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
      '${_formatPay(payRange.start)} – ${_formatPay(payRange.end)}';

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

  /// Data shaped for `profile.mergeFormSection('creator', ...)`.
  Map<String, dynamic> buildData() => {
        'collab_types': collabTypes.toList(),
        'platforms': platforms.toList(),
        'formats': formats.toList(),
        'work_modes': workModes.toList(),
        'content_types': contentTypes.toList(),
        'niches': niches.toList(),
        'pay_min': payRange.start.round(),
        'pay_max': payRange.end.round(),
        'pay_range': _payLabel,
      };

  List<String> get selectedNiches => niches.toList();

  @override
  Widget build(BuildContext context) {
    return AppFormFields(
      children: [
        AppChipField(
          label: 'Collab type',
          options: ProfileOptions.creatorCollabTypes,
          isSelected: collabTypes.contains,
          onTap: (option) => _toggle(collabTypes, option),
        ),
        _PayRangeField(
          values: payRange,
          max: _payMax,
          formatValue: _formatPay,
          onChanged: (values) => setState(() => payRange = values),
        ),
        AppChipField(
          label: 'Platforms',
          options: ProfileOptions.creatorPlatforms,
          isSelected: platforms.contains,
          onTap: (option) => _toggle(platforms, option),
        ),
        AppChipField(
          label: 'Content format',
          options: ProfileOptions.creatorContentFormats,
          isSelected: formats.contains,
          onTap: (option) => _toggle(formats, option),
        ),
        AppChipField(
          label: 'Work mode',
          options: ProfileOptions.creatorWorkModes,
          isSelected: workModes.contains,
          onTap: (option) => _toggle(workModes, option),
        ),
        AppDropdownField(
          label: 'Type of content',
          value: _display(contentTypes),
          hint: 'Select',
          onTap: () => _pickMulti(
            title: 'Type of content',
            options: ProfileOptions.contentTypes,
            selected: contentTypes,
          ),
        ),
        AppDropdownField(
          label: 'Niches',
          value: _display(niches),
          hint: 'Select',
          onTap: () => _pickMulti(
            title: 'Niches',
            options: ProfileOptions.niches,
            selected: niches,
          ),
        ),
      ],
    );
  }
}

class _PayRangeField extends StatefulWidget {
  const _PayRangeField({
    required this.values,
    required this.max,
    required this.formatValue,
    required this.onChanged,
  });

  final RangeValues values;
  final double max;
  final String Function(double value) formatValue;
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
    _minController = TextEditingController(text: _digits(_localRange.start));
    _maxController = TextEditingController(text: _digits(_localRange.end));
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

  String _digits(double value) => value.round().toString();

  void _syncControllers(RangeValues values, {bool syncMin = true, bool syncMax = true}) {
    if (syncMin) {
      final minText = _digits(values.start);
      if (_minController.text != minText) {
        _minController.text = minText;
      }
    }
    if (syncMax) {
      final maxText = _digits(values.end);
      if (_maxController.text != maxText) {
        _maxController.text = maxText;
      }
    }
  }

  void _handleMinFocus() {
    if (!_minFocus.hasFocus) {
      _minController.text = _digits(_localRange.start);
    }
    setState(() {});
  }

  void _handleMaxFocus() {
    if (!_maxFocus.hasFocus) {
      _maxController.text = _digits(_localRange.end);
    }
    setState(() {});
  }

  bool get _anyInputFocused => _minFocus.hasFocus || _maxFocus.hasFocus;

  BoxDecoration get _inputBarDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppFormStyle.fieldRadius),
        border: Border.all(
          color: _anyInputFocused ? AppColors.primary : AppFormStyle.border,
          width: _anyInputFocused ? 1.5 : 1,
        ),
      );

  static const _compactLabelStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: Color(0xFF9E9E9E),
    height: 1.1,
  );

  static const _compactValueStyle = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    color: AppFormStyle.valueColor,
    height: 1.2,
  );

  static const _currencyStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Color(0xFF757575),
    height: 1.2,
  );

  void _emitRange(RangeValues values, {bool syncMin = true, bool syncMax = true}) {
    setState(() => _localRange = values);
    _syncControllers(values, syncMin: syncMin, syncMax: syncMax);
    widget.onChanged(values);
  }

  void _onMinChanged(String text) {
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

  void _onMaxChanged(String text) {
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

  SliderThemeData _sliderTheme() {
    return SliderThemeData(
      activeTrackColor: AppColors.primary,
      inactiveTrackColor: AppColors.primary.withAlpha(50),
      thumbColor: Colors.white,
      overlayColor: AppColors.primary.withAlpha(30),
      rangeThumbShape: const RoundRangeSliderThumbShape(
        enabledThumbRadius: 10,
        elevation: 2,
      ),
      trackHeight: 3,
    );
  }

  Widget _amountInputCell({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required ValueChanged<String> onChanged,
    required TextInputAction textInputAction,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: _compactLabelStyle),
          const SizedBox(height: 3),
          Row(
            children: [
              const Text('₹', style: _currencyStyle),
              const SizedBox(width: 3),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: _compactValueStyle,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    isCollapsed: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: onChanged,
                  textInputAction: textInputAction,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppFormSectionTitle('Pay range'),
        const SizedBox(height: 6),
        Container(
          decoration: _inputBarDecoration,
          clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _amountInputCell(
                    label: 'Minimum',
                    controller: _minController,
                    focusNode: _minFocus,
                    onChanged: _onMinChanged,
                    textInputAction: TextInputAction.next,
                  ),
                ),
                Container(
                  width: 1,
                  color: AppFormStyle.border,
                ),
                Expanded(
                  child: _amountInputCell(
                    label: 'Maximum',
                    controller: _maxController,
                    focusNode: _maxFocus,
                    onChanged: _onMaxChanged,
                    textInputAction: TextInputAction.done,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: SliderTheme(
                data: _sliderTheme(),
                child: RangeSlider(
                  values: _localRange,
                  min: 0,
                  max: widget.max,
                  onChanged: _onSliderChanged,
                ),
              ),
            ),
            Positioned(
              left: 12,
              top: 0,
              child: AppSliderBadge(widget.formatValue(_localRange.start)),
            ),
            Positioned(
              right: 12,
              top: 0,
              child: AppSliderBadge(widget.formatValue(_localRange.end)),
            ),
          ],
        ),
      ],
    );
  }
}
