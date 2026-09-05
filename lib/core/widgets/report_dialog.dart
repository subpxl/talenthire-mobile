import 'package:bombay_casting/core/widgets/app_success_toast.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

enum ReportReason { spam, inappropriate, other }

class ReportResult {
  const ReportResult({
    required this.reason,
    this.otherDetails,
  });

  final ReportReason reason;
  final String? otherDetails;

  String reasonLabel(AppLocalizations l10n) {
    switch (reason) {
      case ReportReason.spam:
        return l10n.reportReasonSpam;
      case ReportReason.inappropriate:
        return l10n.reportReasonInappropriate;
      case ReportReason.other:
        return l10n.reportReasonOther;
    }
  }
}

Future<ReportResult?> showReportDialog(
  BuildContext context, {
  required String title,
}) {
  return showDialog<ReportResult>(
    context: context,
    builder: (context) => ReportDialog(title: title),
  );
}

class ReportDialog extends StatefulWidget {
  const ReportDialog({super.key, required this.title});

  final String title;

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  ReportReason? _selectedReason;
  final _otherController = TextEditingController();

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedReason == null) {
      showAppToast(context, l10n.reportSelectReason, type: AppToastType.error);
      return;
    }
    if (_selectedReason == ReportReason.other &&
        _otherController.text.trim().isEmpty) {
      showAppToast(context, l10n.reportOtherRequired, type: AppToastType.error);
      return;
    }

    Navigator.pop(
      context,
      ReportResult(
        reason: _selectedReason!,
        otherDetails: _selectedReason == ReportReason.other
            ? _otherController.text.trim()
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            RadioGroup<ReportReason>(
              groupValue: _selectedReason,
              onChanged: (value) => setState(() => _selectedReason = value),
              child: Column(
                children: [
                  _ReportOption(
                    title: l10n.reportReasonSpam,
                    value: ReportReason.spam,
                  ),
                  _ReportOption(
                    title: l10n.reportReasonInappropriate,
                    value: ReportReason.inappropriate,
                  ),
                  _ReportOption(
                    title: l10n.reportReasonOther,
                    value: ReportReason.other,
                  ),
                ],
              ),
            ),
            if (_selectedReason == ReportReason.other) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _otherController,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                style: AppFormStyle.valueStyle,
                decoration: AppFormStyle.inputDecoration(
                  hint: l10n.reportOtherHint,
                ),
              ),
            ],
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.reportCancel),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm + 4),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: Text(l10n.reportSubmit),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportOption extends StatelessWidget {
  const _ReportOption({
    required this.title,
    required this.value,
  });

  final String title;
  final ReportReason value;

  @override
  Widget build(BuildContext context) {
    return RadioListTile<ReportReason>(
      value: value,
      activeColor: AppColors.primary,
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
