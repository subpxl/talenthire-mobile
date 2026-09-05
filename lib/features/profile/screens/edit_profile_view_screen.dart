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
import 'package:bombay_casting/core/widgets/app_success_toast.dart';
import 'package:bombay_casting/features/profile/screens/edit_social_form.dart';
import 'package:bombay_casting/features/profile/screens/edit_verification_form.dart';
import 'package:bombay_casting/features/profile/screens/edit_personal_details_form.dart';
import 'package:bombay_casting/features/profile/screens/edit_content_creator_form.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final profile = appState.profile;
    final user = appState.user;
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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 56),
        child: Column(
          children: [
            _sectionCard(
              child: ProfilePhotoPicker(profile: profile),
            ),
            const SizedBox(height: 12),
            EditProfileSectionList(profile: profile, user: user),
          ],
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
}

class EditProfileSectionList extends StatelessWidget {
  const EditProfileSectionList({
    super.key,
    required this.profile,
    required this.user,
  });

  final Profile? profile;
  final User? user;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
              _item(profile, 'personal', 'gender', 'Gender', isLast: true),
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
          icon: Icons.movie_outlined,
          title: 'For content creators',
          onTap: () => _open(context, const EditContentCreatorFormScreen()),
          child: Column(
            children: [
              _item(profile, 'creator', 'collab_types', 'Collab type'),
              _item(profile, 'creator', 'platforms', 'Platforms'),
              _item(profile, 'creator', 'niches', 'Niches', isLast: true),
            ],
          ),
        ),
      ],
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
      return Text(
        'Add links to your other platforms.',
        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
      );
    }
    final preview = metrics.take(3).toList();
    return Column(
      children: [
        for (var i = 0; i < preview.length; i++)
          _detailRow(
            preview[i].platform,
            preview[i].url.isNotEmpty
                ? preview[i].url
                : (preview[i].handle.isNotEmpty
                    ? preview[i].handle
                    : preview[i].platform),
            isLast: i == preview.length - 1,
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
                  const Text(
                    'Edit',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
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

  Widget _detailRow(String label, String value, {bool isLast = false}) {
    final empty = value.trim().isEmpty || value.trim() == '-';
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              empty ? 'Not set' : value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfilePhotoPicker extends StatelessWidget {
  const ProfilePhotoPicker({super.key, required this.profile});

  final Profile? profile;

  Future<void> _pick(BuildContext context) async {
    final remaining =
        Profile.maxPhotos - (profile?.galleryPhotos.length ?? 0);
    if (remaining <= 0) return;
    FocusManager.instance.primaryFocus?.unfocus();
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

    final picker = ImagePicker();
    List<XFile> picked;
    if (source == ImageSource.camera) {
      final file = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2000,
        imageQuality: 88,
      );
      picked = file == null ? const [] : [file];
    } else {
      picked = await picker.pickMultiImage(
        maxWidth: 2000,
        imageQuality: 88,
        limit: remaining,
        requestFullMetadata: false,
      );
    }
    if (picked.isEmpty || !context.mounted) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (picked.length > remaining) {
      picked = picked.take(remaining).toList();
    }

    final result = await showModalBottomSheet<_PendingUploadResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _PendingUploadSheet(
        files: picked,
        hasExistingMain: profile?.galleryPhotos.isNotEmpty ?? false,
      ),
    );
    if (result == null || result.files.isEmpty || !context.mounted) return;

    try {
      await context.read<AppState>().uploadProfilePhotos(
            result.files,
            mainIndex: result.mainIndex,
          );
      if (!context.mounted) return;
      showAppSuccessToast(context, AppLocalizations.of(context)!.saved);
    } catch (_) {
      if (!context.mounted) return;
      showAppToast(
        context,
        AppLocalizations.of(context)!.couldNotUploadPhoto,
        type: AppToastType.error,
      );
    }
  }

  Future<void> _remove(BuildContext context, String url) async {
    try {
      await context.read<AppState>().removeProfilePhoto(url);
      if (!context.mounted) return;
      showAppSuccessToast(context, AppLocalizations.of(context)!.saved);
    } catch (_) {
      if (!context.mounted) return;
      showAppToast(
        context,
        AppLocalizations.of(context)!.couldNotRemovePhoto,
        type: AppToastType.error,
      );
    }
  }

  void _preview(BuildContext context, List<String> photos, int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    final appState = context.read<AppState>();
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => _PhotoPreviewScreen(
              photos: photos,
              initialIndex: index,
              onSetMain: appState.setMainProfilePhoto,
            ),
          ),
        )
        .whenComplete(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusManager.instance.primaryFocus?.unfocus();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final uploading = context.watch<AppState>().isUploadingPhoto;
    final photos = profile?.galleryPhotos ?? const <String>[];
    final canAdd = photos.length < Profile.maxPhotos;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.photos,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              '${photos.length}/${Profile.maxPhotos}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 8.0;
            const slots = Profile.maxPhotos;
            final width =
                (constraints.maxWidth - gap * (slots - 1)) / slots;
            final height = width * 4 / 3;
            return Row(
              children: [
                for (var i = 0; i < slots; i++) ...[
                  if (i > 0) const SizedBox(width: gap),
                  SizedBox(
                    width: width,
                    height: height,
                    child: i < photos.length
                        ? _PhotoCard(
                            url: photos[i],
                            width: width,
                            height: height,
                            isCover: i == 0,
                            onPreview: () => _preview(context, photos, i),
                            onRemove: () => _remove(context, photos[i]),
                          )
                        : i == photos.length && canAdd
                            ? _AddPhotoCard(
                                width: width,
                                height: height,
                                uploading: uploading,
                                onTap: uploading ? null : () => _pick(context),
                              )
                            : _EmptyPhotoSlot(
                                onTap: canAdd && !uploading
                                    ? () => _pick(context)
                                    : null,
                              ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _PendingUploadResult {
  const _PendingUploadResult({required this.files, this.mainIndex});

  final List<File> files;
  final int? mainIndex;
}

class _PendingUploadSheet extends StatefulWidget {
  const _PendingUploadSheet({
    required this.files,
    required this.hasExistingMain,
  });

  final List<XFile> files;
  final bool hasExistingMain;

  @override
  State<_PendingUploadSheet> createState() => _PendingUploadSheetState();
}

class _PendingUploadSheetState extends State<_PendingUploadSheet> {
  late List<XFile> _files;
  int? _mainIndex;

  @override
  void initState() {
    super.initState();
    _files = List<XFile>.of(widget.files);
    _mainIndex = widget.hasExistingMain ? null : 0;
  }

  void _removeAt(int index) {
    setState(() {
      _files.removeAt(index);
      if (_files.isEmpty) {
        _mainIndex = null;
        return;
      }
      if (_mainIndex == null) return;
      if (_mainIndex == index) {
        _mainIndex = widget.hasExistingMain ? null : 0;
      } else if (_mainIndex! > index) {
        _mainIndex = _mainIndex! - 1;
      }
    });
  }

  void _confirm() {
    if (_files.isEmpty) {
      Navigator.pop(context);
      return;
    }
    Navigator.pop(
      context,
      _PendingUploadResult(
        files: _files.map((file) => File(file.path)).toList(),
        mainIndex: _mainIndex,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.previewPhotos,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '${_files.length}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_files.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Center(
                  child: Text(
                    l10n.addPhoto,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              )
            else
              SizedBox(
                height: 220,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _files.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final isMain = _mainIndex == index;
                    return GestureDetector(
                      onTap: () => setState(() => _mainIndex = index),
                      child: SizedBox(
                        width: 156,
                        child: Stack(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isMain
                                      ? AppColors.primary
                                      : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                              padding: const EdgeInsets.all(2),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(13),
                                child: Image.file(
                                  File(_files[index].path),
                                  width: 152,
                                  height: 216,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            if (isMain)
                              Positioned(
                                left: 10,
                                bottom: 10,
                                child: _MainBadge(label: l10n.main),
                              ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: _CircleIconButton(
                                icon: Icons.close,
                                onTap: () => _removeAt(index),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 10),
            Text(
              l10n.tapToSetAsMain,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _files.isEmpty ? null : _confirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(l10n.uploadPhotos),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoPreviewScreen extends StatefulWidget {
  const _PhotoPreviewScreen({
    required this.photos,
    required this.initialIndex,
    required this.onSetMain,
  });

  final List<String> photos;
  final int initialIndex;
  final Future<void> Function(String url) onSetMain;

  @override
  State<_PhotoPreviewScreen> createState() => _PhotoPreviewScreenState();
}

class _PhotoPreviewScreenState extends State<_PhotoPreviewScreen> {
  late final PageController _controller;
  late List<String> _photos;
  late int _index;
  bool _settingMain = false;

  @override
  void initState() {
    super.initState();
    _photos = List<String>.of(widget.photos);
    _index = widget.initialIndex.clamp(0, _photos.length - 1);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _setMain() async {
    if (_photos.isEmpty || _index == 0 || _settingMain) return;
    final url = _photos[_index];
    setState(() => _settingMain = true);
    try {
      await widget.onSetMain(url);
      if (!mounted) return;
      setState(() {
        _photos = [url, ..._photos.where((item) => item != url)];
        _index = 0;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_controller.hasClients) _controller.jumpToPage(0);
      });
      showAppSuccessToast(context, AppLocalizations.of(context)!.saved);
    } catch (_) {
      if (!mounted) return;
      showAppToast(
        context,
        AppLocalizations.of(context)!.couldNotSetMainPhoto,
        type: AppToastType.error,
      );
    } finally {
      if (mounted) setState(() => _settingMain = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isMain = _index == 0;
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              Navigator.maybePop(context);
            },
          ),
          title: Text(
            '${_index + 1}/${_photos.length}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _photos.length,
                onPageChanged: (index) => setState(() => _index = index),
                itemBuilder: (context, index) {
                  return InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    panEnabled: false,
                    child: Center(
                      child: CachedNetworkImage(
                        imageUrl: _photos[index],
                        fit: BoxFit.contain,
                        placeholder: (_, _) => const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        errorWidget: (_, _, _) => const Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white70,
                          size: 48,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: isMain
                    ? Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white54),
                          ),
                          child: Text(
                            l10n.main,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                    : SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _settingMain ? null : _setMain,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _settingMain
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(l10n.setAsMain),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({
    required this.url,
    required this.width,
    required this.height,
    required this.isCover,
    required this.onPreview,
    required this.onRemove,
  });

  final String url;
  final double width;
  final double height;
  final bool isCover;
  final VoidCallback onPreview;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: onPreview,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: url,
                  width: width,
                  height: height,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => const ColoredBox(
                    color: Color(0xFFF4F4F5),
                    child: Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  errorWidget: (_, _, _) => const ColoredBox(
                    color: Color(0xFFF4F4F5),
                    child: Icon(Icons.broken_image_outlined, size: 20),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 5,
            bottom: 5,
            child: isCover ? _MainBadge(label: l10n.main) : const SizedBox.shrink(),
          ),
          Positioned(
            top: 5,
            right: 5,
            child: _CircleIconButton(icon: Icons.close, onTap: onRemove),
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
    return Material(
      color: AppColors.primaryLight,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: width,
          height: height,
          child: uploading
              ? const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _EmptyPhotoSlot extends StatelessWidget {
  const _EmptyPhotoSlot({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Material(
        color: const Color(0xFFF7F7F8),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: CustomPaint(
            painter: _DashedRRectPainter(color: AppColors.border),
            child: const Center(
              child: Icon(
                Icons.photo_outlined,
                size: 18,
                color: AppColors.textHint,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(12),
    );
    const dash = 4.0;
    const gap = 3.0;
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + dash).clamp(0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _MainBadge extends StatelessWidget {
  const _MainBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 4,
            ),
          ],
        ),
        child: Icon(icon, size: 13, color: Colors.black87),
      ),
    );
  }
}
