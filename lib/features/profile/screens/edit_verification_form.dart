import 'package:bombay_casting/l10n/app_localizations.dart';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/app_primary_button.dart';
import 'package:bombay_casting/core/widgets/app_form_fields.dart';
import 'package:bombay_casting/core/widgets/app_success_toast.dart';
import 'package:bombay_casting/core/widgets/option_picker.dart';
import 'package:bombay_casting/core/utils/input_validators.dart';
import 'package:flutter/services.dart';

class EditVerificationFormScreen extends StatefulWidget {
  const EditVerificationFormScreen({super.key});

  @override
  State<EditVerificationFormScreen> createState() =>
      _EditVerificationFormScreenState();
}

class _EditVerificationFormScreenState
    extends State<EditVerificationFormScreen> {
  final TextEditingController _panController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  _DocPick? _panCard;
  _DocPick? _photo;
  _DocPick? _voterId;
  final List<_ExtraDoc> _otherDocs = [];
  bool _saving = false;
  String? _panError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final profile = context.read<AppState>().profile;
    if (profile == null) return;
    final data = profile.formSection('verification');
    setState(() {
      _panController.text = (data['pan_number'] ?? '').toString();
      _panCard = _DocPick.fromUrl(data['pan_card']);
      _photo = _DocPick.fromUrl(data['photo']);
      _voterId = _DocPick.fromUrl(data['voter_id']);
      _otherDocs
        ..clear()
        ..addAll(_extraDocsFrom(data['other_documents']));
    });
  }

  List<_ExtraDoc> _extraDocsFrom(dynamic stored) {
    if (stored is! List) return const [];
    return stored
        .whereType<Map>()
        .map((item) {
          final map = Map<String, dynamic>.from(item);
          final label = (map['label'] ?? '').toString();
          final url = (map['url'] ?? '').toString();
          if (label.isEmpty || url.isEmpty) return null;
          return _ExtraDoc(label: label, pick: _DocPick(url: url));
        })
        .whereType<_ExtraDoc>()
        .toList();
  }

  Future<void> _pick(_DocPick? current, ValueChanged<_DocPick> onPicked) async {
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
    if (source == null) return;
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 2000,
      imageQuality: 88,
    );
    if (picked == null) return;
    onPicked(_DocPick(file: File(picked.path), url: current?.url));
  }

  Future<void> _addOtherDoc() async {
    final label = await showOptionPicker(
      context: context,
      title: 'Document type',
      options: const [
        'Aadhaar',
        'Passport',
        'Driving licence',
        'Other',
      ],
    );
    if (label == null || !mounted) return;
    await _pick(null, (pick) {
      setState(() => _otherDocs.add(_ExtraDoc(label: label, pick: pick)));
    });
  }

  Future<String?> _upload(_DocPick? pick) async {
    if (pick?.file != null) {
      return context.read<AppState>().uploadVerificationDocument(pick!.file!);
    }
    return pick?.url;
  }

  Future<void> _save() async {
    if (_saving) return;
    final panError = InputValidators.panError(_panController.text);
    if (panError != null) {
      setState(() => _panError = panError);
      return;
    }
    setState(() {
      _saving = true;
      _panError = null;
    });
    try {
      final panUrl = await _upload(_panCard);
      final photoUrl = await _upload(_photo);
      final voterUrl = await _upload(_voterId);
      final extras = <Map<String, String>>[];
      for (final doc in _otherDocs) {
        final url = await _upload(doc.pick);
        if (url == null || url.isEmpty) continue;
        extras.add({'label': doc.label, 'url': url});
      }
      if (!mounted) return;
      await saveProfileSection(
        context: context,
        section: 'verification',
        data: {
          'pan_number': _panController.text.trim().toUpperCase(),
          'pan_card': panUrl ?? '',
          'photo': photoUrl ?? '',
          'voter_id': voterUrl ?? '',
          'other_documents': extras,
        },
      );
    } catch (_) {
      if (!mounted) return;
      showAppToast(
        context,
        AppLocalizations.of(context)!.couldNotSaveDocuments,
        type: AppToastType.error,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _panController.dispose();
    super.dispose();
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(AppLocalizations.of(context)!.profileVerification,
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        titleSpacing: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context)!.uploadAClearPhotoOfEachDocument,
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'PAN card number',
                      controller: _panController,
                      hint: 'ABCDE1234F',
                      textCapitalization: TextCapitalization.characters,
                      errorText: _panError,
                      maxLength: 10,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                        LengthLimitingTextInputFormatter(10),
                        TextInputFormatter.withFunction((oldValue, newValue) {
                          return newValue.copyWith(
                            text: newValue.text.toUpperCase(),
                            selection: newValue.selection,
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.92,
                      children: [
                        _DocTile(
                          label: 'PAN card',
                          pick: _panCard,
                          onTap: () => _pick(
                            _panCard,
                            (value) => setState(() => _panCard = value),
                          ),
                          onClear: _panCard == null
                              ? null
                              : () => setState(() => _panCard = null),
                        ),
                        _DocTile(
                          label: 'Photo',
                          pick: _photo,
                          onTap: () => _pick(
                            _photo,
                            (value) => setState(() => _photo = value),
                          ),
                          onClear: _photo == null
                              ? null
                              : () => setState(() => _photo = null),
                        ),
                        _DocTile(
                          label: 'Voter ID',
                          pick: _voterId,
                          onTap: () => _pick(
                            _voterId,
                            (value) => setState(() => _voterId = value),
                          ),
                          onClear: _voterId == null
                              ? null
                              : () => setState(() => _voterId = null),
                        ),
                        ..._otherDocs.asMap().entries.map((entry) {
                          final index = entry.key;
                          final doc = entry.value;
                          return _DocTile(
                            label: doc.label,
                            pick: doc.pick,
                            onTap: () => _pick(
                              doc.pick,
                              (value) => setState(
                                () => _otherDocs[index] = _ExtraDoc(
                                  label: doc.label,
                                  pick: value,
                                ),
                              ),
                            ),
                            onClear: () =>
                                setState(() => _otherDocs.removeAt(index)),
                          );
                        }),
                        _AddDocTile(onTap: _addOtherDoc),
                      ],
                    ),
                    const SizedBox(height: 24),
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
      padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 24.0),
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
              Text(AppLocalizations.of(context)!.yourDocumentsAre100SafeWithUs,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AppPrimaryButton(
            label: AppLocalizations.of(context)!.update,
            onPressed: _save,
            loading: _saving,
          ),
        ],
      ),
    );
  }
}

class _DocPick {
  const _DocPick({this.file, this.url});

  final File? file;
  final String? url;

  bool get hasImage => file != null || (url != null && url!.isNotEmpty);

  static _DocPick? fromUrl(dynamic value) {
    final url = value?.toString() ?? '';
    if (url.isEmpty) return null;
    return _DocPick(url: url);
  }
}

class _ExtraDoc {
  const _ExtraDoc({required this.label, required this.pick});

  final String label;
  final _DocPick pick;
}

class _DocTile extends StatelessWidget {
  const _DocTile({
    required this.label,
    required this.pick,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final _DocPick? pick;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            if (pick?.hasImage == true)
              Positioned.fill(child: _preview(pick!))
            else
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_a_photo_outlined,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(AppLocalizations.of(context)!.tapToUpload,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            if (pick?.hasImage == true)
              Positioned(
                left: 8,
                bottom: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            if (onClear != null && pick?.hasImage == true)
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: onClear,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _preview(_DocPick pick) {
    if (pick.file != null) {
      return Image.file(pick.file!, fit: BoxFit.cover);
    }
    return CachedNetworkImage(
      imageUrl: pick.url!,
      fit: BoxFit.cover,
      placeholder: (_, _) => const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      errorWidget: (_, _, _) => const Icon(Icons.broken_image_outlined),
    );
  }
}

class _AddDocTile extends StatelessWidget {
  const _AddDocTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 32, color: AppColors.primary),
              SizedBox(height: 6),
              Text(AppLocalizations.of(context)!.addDocument,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
