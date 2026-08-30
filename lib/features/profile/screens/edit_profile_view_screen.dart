import 'package:bombay_casting/l10n/app_localizations.dart';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/core/models/models.dart';
import 'package:bombay_casting/core/navigation/app_navigation.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/social_platforms.dart';
import 'package:bombay_casting/features/profile/screens/edit_content_form.dart';
import 'package:bombay_casting/features/profile/screens/edit_rates_form.dart';
import 'package:bombay_casting/features/profile/screens/edit_social_form.dart';
import 'package:bombay_casting/features/profile/screens/edit_verification_form.dart';
import 'package:bombay_casting/features/profile/screens/edit_preferences_form.dart';
import 'package:bombay_casting/features/profile/screens/edit_occupation_screen.dart';
import 'package:bombay_casting/features/profile/screens/edit_personal_details_form.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final profile = appState.profile;
    final user = appState.user;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.editProfile,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        titleSpacing: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        child: Column(
          children: [
            _sectionCard(
              child: _UploadPhotoBox(profile: profile),
            ),
            const SizedBox(height: 12),
            _tappableSection(
              context: context,
              icon: Icons.verified_outlined,
              title: 'Verification',
              onTap: () => _openVerification(context),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _verificationTitle(profile),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _verificationSubtitle(profile),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _tappableSection(
              context: context,
              icon: Icons.person_outline_rounded,
              title: 'Personal',
              onTap: () => _open(context, const EditPersonalFieldsScreen()),
              child: Column(
                children: [
                  _item(profile, 'personal', 'name', 'Name', fallback: user?.name),
                  _item(profile, 'personal', 'email', 'Email', fallback: user?.email),
                  _item(profile, 'personal', 'gender', 'Gender'),
                  _item(
                    profile,
                    'personal',
                    'mobile',
                    'Mobile number',
                    fallback: user?.mobile,
                  ),
                  _item(profile, 'personal', 'whatsapp', 'WhatsApp number'),
                  _item(profile, 'personal', 'age', 'Age'),
                  _item(profile, 'personal', 'location', 'Location'),
                  _item(profile, 'personal', 'language', 'Language'),
                  _item(
                    profile,
                    'personal',
                    'categories',
                    'Category',
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _tappableSection(
              context: context,
              icon: Icons.work_outline_rounded,
              title: 'Work',
              onTap: () => _open(context, const EditOccupationScreen()),
              child: Column(
                children: [
                  _item(profile, 'work', 'role', 'Role'),
                  _item(profile, 'work', 'experience', 'Experience'),
                  _item(profile, 'work', 'monthly_income', 'Monthly income'),
                  _item(profile, 'work', 'based_in', 'Based in'),
                  _item(
                    profile,
                    'work',
                    'agency_name',
                    'Agency / manager',
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _tappableSection(
              context: context,
              icon: Icons.share_outlined,
              title: 'Social',
              onTap: () => _open(context, const EditSocialFieldsScreen()),
              child: _socialPreview(profile),
            ),
            const SizedBox(height: 12),
            _tappableSection(
              context: context,
              icon: Icons.payments_outlined,
              title: 'Rates',
              onTap: () => _open(context, const EditRatesFieldsScreen()),
              child: Column(
                children: [
                  _item(profile, 'rates', 'collab_type', 'Collaboration type'),
                  _item(profile, 'rates', 'expected_pay', 'Expected pay'),
                  _item(profile, 'rates', 'availability', 'Availability'),
                  _item(profile, 'rates', 'can_travel', 'Can travel'),
                  _item(profile, 'rates', 'work_mode', 'Work mode', isLast: true),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _tappableSection(
              context: context,
              icon: Icons.movie_outlined,
              title: 'Content',
              onTap: () => _open(context, const EditContentFieldsScreen()),
              child: Column(
                children: [
                  _item(profile, 'content', 'niches', 'Niches'),
                  _item(profile, 'content', 'formats', 'Formats'),
                  _item(profile, 'content', 'brand_categories', 'Brand categories'),
                  _item(
                    profile,
                    'content',
                    'content_style',
                    'Comfortable with',
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _tappableSection(
              context: context,
              icon: Icons.tune_rounded,
              title: 'Job preferences',
              onTap: () => _open(context, const EditPreferenceScreen()),
              child: Column(
                children: [
                  _item(profile, 'preferences', 'pay_limit', 'Pay range'),
                  _item(profile, 'preferences', 'location', 'Job location'),
                  _item(profile, 'preferences', 'collab_types', 'Collaboration type'),
                  _item(profile, 'preferences', 'platforms', 'Platforms'),
                  _item(profile, 'preferences', 'niches', 'Niches'),
                  _item(profile, 'preferences', 'durations', 'Duration'),
                  _item(
                    profile,
                    'preferences',
                    'work_mode',
                    'Work mode',
                    isLast: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _openVerification(BuildContext context) {
    if (!AppNavigation.requireSubscription(context)) return;
    _open(context, const EditVerificationFormScreen());
  }

  String _verificationTitle(Profile? profile) {
    if (profile?.isVerified == true) return 'Verified creator';
    if (_hasVerificationDocs(profile)) return 'Documents submitted';
    return 'Get more brand jobs';
  }

  String _verificationSubtitle(Profile? profile) {
    if (profile?.isVerified == true) return 'Your profile is verified';
    if (_hasVerificationDocs(profile)) {
      return 'Update PAN, photo or Voter ID';
    }
    return 'Verify your profile by uploading your Govt ID';
  }

  bool _hasVerificationDocs(Profile? profile) {
    if (profile == null) return false;
    final data = profile.formSection('verification');
    return [
      data['pan_card'],
      data['photo'],
      data['voter_id'],
    ].any((value) => value?.toString().isNotEmpty == true);
  }

  Widget _item(
    Profile? profile,
    String section,
    String key,
    String label, {
    bool isLast = false,
    String? fallback,
  }) {
    var value = profile?.formValue(section, key) ?? '-';
    if ((value.trim().isEmpty || value.trim() == '-') &&
        (fallback?.trim().isNotEmpty ?? false)) {
      value = fallback!.trim();
    }
    if (key == 'gender') {
      final lower = value.toLowerCase();
      if (lower == 'non-binary' || lower == 'nonbinary' || lower == 'non binary') {
        value = 'Other';
      }
    }
    return _detailRow(label, value, isLast: isLast);
  }

  Widget _socialPreview(Profile? profile) {
    final metrics = profile?.platformMetrics
            .where(
              (metric) =>
                  metric.platform.isNotEmpty ||
                  metric.handle.isNotEmpty ||
                  metric.url.isNotEmpty,
            )
            .toList() ??
        const <SocialPlatformMetric>[];
    if (metrics.isEmpty) {
      return Row(
        children: [
          Expanded(
            child: Text(
              'Add Instagram, YouTube, and other profiles with one tap.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          Text(
            'Add',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final metric in metrics)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SocialPlatformIcon(
                    info: SocialPlatformInfo.forName(metric.platform),
                    size: 32,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    metric.handle.isNotEmpty ? metric.handle : metric.platform,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 12),
        _detailRow(
          'Followers',
          profile?.formValue('social', 'followers') ?? '-',
        ),
        _detailRow(
          'Engagement',
          profile?.formValue('social', 'engagement') ?? '-',
          isLast: true,
        ),
      ],
    );
  }

  Widget _tappableSection({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 18, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context)!.update,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                ],
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }

  Widget _detailRow(String label, String value, {bool isLast = false}) {
    final empty = value.trim().isEmpty || value.trim() == '-';
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              empty ? 'Not set' : value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: empty ? AppColors.textHint : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadPhotoBox extends StatelessWidget {
  const _UploadPhotoBox({required this.profile});

  final Profile? profile;

  static const double _cardWidth = 210;
  static const double _cardHeight = 280;

  Future<void> _pick(BuildContext context) async {
    if ((profile?.galleryPhotos.length ?? 0) >= Profile.maxPhotos) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(AppLocalizations.of(context)!.chooseFromGallery),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(AppLocalizations.of(context)!.takeAPhoto),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null || !context.mounted) return;
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 2000,
      imageQuality: 88,
    );
    if (picked == null || !context.mounted) return;
    try {
      await context.read<AppState>().uploadProfilePhoto(File(picked.path));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.couldNotUploadPhoto)),
      );
    }
  }

  Future<void> _remove(BuildContext context, String url) async {
    try {
      await context.read<AppState>().removeProfilePhoto(url);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.couldNotRemovePhoto)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uploading = context.watch<AppState>().isUploadingPhoto;
    final photos = profile?.galleryPhotos ?? const <String>[];
    final canAdd = photos.length < Profile.maxPhotos;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Row(
            children: [
              Text(AppLocalizations.of(context)!.photos,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Text(
                '${photos.length}/${Profile.maxPhotos}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (photos.isEmpty)
          _AddPhotoCard(
            width: double.infinity,
            height: _cardHeight,
            uploading: uploading,
            onTap: uploading ? null : () => _pick(context),
          )
        else
          SizedBox(
            height: _cardHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length + (canAdd ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                if (index >= photos.length) {
                  return _AddPhotoCard(
                    width: _cardWidth,
                    height: _cardHeight,
                    uploading: uploading,
                    onTap: uploading ? null : () => _pick(context),
                  );
                }
                return _PhotoCard(
                  url: photos[index],
                  width: _cardWidth,
                  height: _cardHeight,
                  isCover: index == 0,
                  onRemove: () => _remove(context, photos[index]),
                );
              },
            ),
          ),
        const SizedBox(height: 10),
        Text(AppLocalizations.of(context)!.addUpTo4PhotosFirstPhotoIsYourMainProfilePicture,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({
    required this.url,
    required this.width,
    required this.height,
    required this.isCover,
    required this.onRemove,
  });

  final String url;
  final double width;
  final double height;
  final bool isCover;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedNetworkImage(
              imageUrl: url,
              width: width,
              height: height,
              fit: BoxFit.cover,
              placeholder: (_, _) => Container(
                color: const Color(0xFFF8F9FA),
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (_, _, _) => Container(
                color: const Color(0xFFF8F9FA),
                child: const Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
          if (isCover)
            Positioned(
              left: 10,
              bottom: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(AppLocalizations.of(context)!.main,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddPhotoCard extends StatelessWidget {
  const _AddPhotoCard({
    required this.width,
    required this.height,
    required this.uploading,
    required this.onTap,
  });

  final double width;
  final double height;
  final bool uploading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isFullWidth = width == double.infinity;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isFullWidth ? double.infinity : width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: uploading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 26),
                  ),
                  const SizedBox(height: 12),
                  Text(AppLocalizations.of(context)!.addPhoto,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(AppLocalizations.of(context)!.looksBetterInPortrait,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
      ),
    );
  }
}
