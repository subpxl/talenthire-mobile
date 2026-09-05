import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/models/models.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/utils/app_links.dart';
import 'package:bombay_casting/core/widgets/app_success_toast.dart';
import 'package:bombay_casting/features/jobs/utils/video_link_utils.dart';
import 'package:bombay_casting/features/jobs/widgets/apply_job_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> updateApplicationInterviewLink(
  BuildContext context, {
  required Application application,
  bool popOnSuccess = false,
}) async {
  final result = await showApplyJobSheet(
    context,
    jobTitle: application.jobTitle,
    company: application.company,
    initialYoutubeShortUrl: application.youtubeShortUrl,
    updateLinkOnly: true,
  );
  if (result == null || !context.mounted) return;
  final updated = await context.read<AppState>().updateApplicationLink(
        application,
        youtubeShortUrl: result.youtubeShortUrl,
      );
  if (!context.mounted) return;
  if (updated && popOnSuccess) Navigator.pop(context);
  showAppToast(
    context,
    updated ? 'Interview link updated' : 'Could not update the link',
    type: updated ? AppToastType.success : AppToastType.error,
  );
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
  final withdrawn =
      await context.read<AppState>().withdrawApplication(application);
  if (!context.mounted) return;
  if (withdrawn && popOnSuccess) Navigator.pop(context);
  showAppToast(
    context,
    withdrawn ? 'Application cancelled' : 'Could not cancel application',
    type: withdrawn ? AppToastType.success : AppToastType.error,
  );
}

Future<void> showManageApplicationSheet(
  BuildContext context, {
  required Application application,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
    ),
    builder: (context) => ManageApplicationSheet(application: application),
  );
}

class ManageApplicationSheet extends StatelessWidget {
  const ManageApplicationSheet({super.key, required this.application});

  final Application application;

  @override
  Widget build(BuildContext context) {
    final link = application.youtubeShortUrl.trim();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              application.jobTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Your application',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            if (link.isNotEmpty) ...[
              const SizedBox(height: 16),
              _SubmittedVideoThumb(
                url: link,
                onTap: () => openAppLink(context, link),
              ),
            ],
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: () => updateApplicationInterviewLink(
                context,
                application: application,
                popOnSuccess: true,
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                minimumSize: const Size.fromHeight(44),
              ),
              child: const Text('Update interview link'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => confirmAndCancelApplication(
                context,
                application: application,
                popOnSuccess: true,
              ),
              child: const Text(
                'Cancel application',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubmittedVideoThumb extends StatelessWidget {
  const _SubmittedVideoThumb({required this.url, required this.onTap});

  final String url;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final thumb = VideoLinkUtils.youtubeThumbnailUrl(url);
    final isInstagram = VideoLinkUtils.isInstagram(url);
    return Material(
      color: AppColors.primaryTint,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 72,
                  height: 96,
                  child: thumb != null
                      ? CachedNetworkImage(
                          imageUrl: thumb,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const ColoredBox(
                            color: Color(0xFFECECEC),
                          ),
                          errorWidget: (context, url, error) =>
                              const _VideoFallback(),
                        )
                      : _VideoFallback(instagram: isInstagram),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your submitted short',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tap thumbnail to open the link',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.play_circle_outline,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoFallback extends StatelessWidget {
  const _VideoFallback({this.instagram = false});

  final bool instagram;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFECECEC),
      child: Icon(
        instagram ? Icons.photo_camera_outlined : Icons.play_arrow_rounded,
        color: AppColors.textSecondary,
      ),
    );
  }
}
