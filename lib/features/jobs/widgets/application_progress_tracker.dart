import 'package:bombay_casting/core/models/models.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class ApplicationProgressTracker extends StatelessWidget {
  const ApplicationProgressTracker({super.key, required this.application});

  final Application application;

  static const _activeGreen = AppColors.chatGreen;
  static const _cancelledRed = AppColors.primary;
  static const _pendingGrey = Color(0xFFD9D9D9);

  bool get _isCancelled => application.status == ApplicationStatus.rejected;

  int get _completedStages {
    if (_isCancelled) return 4;
    switch (application.status) {
      case ApplicationStatus.applied:
        return 1;
      case ApplicationStatus.opened:
        return 2;
      case ApplicationStatus.interview:
        return 3;
      case ApplicationStatus.shortlisted:
      case ApplicationStatus.selected:
        return 4;
      case ApplicationStatus.rejected:
        return 4;
      case ApplicationStatus.withdrawn:
        return 0;
    }
  }

  Color _stageColor(int stageIndex) {
    final stage = stageIndex + 1;
    if (_isCancelled) return _cancelledRed;
    if (stage <= _completedStages) return _activeGreen;
    return _pendingGrey;
  }

  Color _lineColor(int afterStageIndex) {
    final stage = afterStageIndex + 1;
    if (_isCancelled) return _cancelledRed;
    if (stage < _completedStages) return _activeGreen;
    return _pendingGrey;
  }

  List<String> _labels(AppLocalizations l10n) {
    final shortlistedLabel = l10n.applicationStageShortlisted;
    final cancelledLabel = l10n.applicationStageCancelled;
    if (_isCancelled) {
      return [
        l10n.applicationStageApplied,
        l10n.applicationStageOpened,
        cancelledLabel,
        cancelledLabel,
      ];
    }
    return [
      l10n.applicationStageApplied,
      l10n.applicationStageOpened,
      shortlistedLabel,
      shortlistedLabel,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = _labels(l10n);

    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < 4; i++) ...[
              _StageDot(color: _stageColor(i)),
              if (i < 3)
                Expanded(
                  child: Container(
                    height: 2,
                    color: _lineColor(i),
                  ),
                ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < 4; i++)
              Expanded(
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    height: 1.2,
                    fontWeight: FontWeight.w500,
                    color: _stageColor(i) == _pendingGrey
                        ? AppColors.textHint
                        : _stageColor(i),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _StageDot extends StatelessWidget {
  const _StageDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
