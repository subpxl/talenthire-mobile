import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/models/models.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/app_success_toast.dart';
import 'package:bombay_casting/features/jobs/widgets/apply_job_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> updateApplicationInterviewLink(
  BuildContext context, {
  required Application application,
  bool popOnSuccess = false,
}) async {
  final appState = context.read<AppState>();
  final result = await showApplyJobSheet(
    context,
    jobTitle: application.jobTitle,
    company: application.company,
    initialYoutubeShortUrl: application.youtubeShortUrl,
    updateLinkOnly: true,
    submitErrorMessage: 'Could not update the link',
    onSubmit: (applyResult) {
      return appState.updateApplicationLink(
        application,
        youtubeShortUrl: applyResult.youtubeShortUrl,
      );
    },
  );
  if (result == null || !context.mounted) return;
  if (popOnSuccess) Navigator.pop(context);
  showAppToast(context, 'Interview link updated');
}

Future<void> confirmAndCancelApplication(
  BuildContext context, {
  required Application application,
  bool popOnSuccess = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Cancel application?'),
      content: const Text(
        'This will withdraw your application. You can apply again later.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Keep'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text(
            'Cancel application',
            style: TextStyle(color: AppColors.primary),
          ),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  final withdrawn = await context.read<AppState>().withdrawApplication(
    application,
  );
  if (!context.mounted) return;
  if (withdrawn && popOnSuccess) Navigator.pop(context);
  showAppToast(
    context,
    withdrawn ? 'Application cancelled' : 'Could not cancel application',
    type: withdrawn ? AppToastType.success : AppToastType.error,
  );
}
