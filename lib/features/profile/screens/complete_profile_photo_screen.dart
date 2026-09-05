import 'dart:io';

import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/app_success_toast.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class CompleteProfilePhotoScreen extends StatefulWidget {
  const CompleteProfilePhotoScreen({super.key});

  @override
  State<CompleteProfilePhotoScreen> createState() =>
      _CompleteProfilePhotoScreenState();
}

class _CompleteProfilePhotoScreenState
    extends State<CompleteProfilePhotoScreen> {
  File? _picked;
  bool _saving = false;

  Future<void> _chooseSource() async {
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
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 2000,
      imageQuality: 88,
    );
    if (file == null || !mounted) return;
    setState(() => _picked = File(file.path));
  }

  Future<void> _upload() async {
    final file = _picked;
    if (file == null || _saving) return;
    setState(() => _saving = true);
    try {
      await context.read<AppState>().uploadProfilePhotos(
            [file],
            mainIndex: 0,
          );
      if (!mounted) return;
      showAppSuccessToast(context, 'Main photo saved');
      Navigator.maybePop(context);
    } catch (_) {
      if (!mounted) return;
      showAppToast(
        context,
        'Could not upload photo',
        type: AppToastType.error,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Complete profile',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            children: [
              const Text(
                'Add your main photo',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This is the photo agencies see first. Upload 1 clear photo of you.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: _saving ? null : _chooseSource,
                    child: AspectRatio(
                      aspectRatio: 3 / 4,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.primaryTint,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.35),
                          ),
                          image: _picked == null
                              ? null
                              : DecorationImage(
                                  image: FileImage(_picked!),
                                  fit: BoxFit.cover,
                                ),
                        ),
                        child: _picked == null
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo_outlined,
                                    size: 42,
                                    color: AppColors.primary,
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Tap to upload',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              )
                            : Align(
                                alignment: Alignment.bottomCenter,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: TextButton(
                                    onPressed: _saving ? null : _chooseSource,
                                    child: const Text('Change photo'),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _picked == null || _saving ? null : _upload,
                  style: AppButtonStyle.banner(),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save as main photo'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
