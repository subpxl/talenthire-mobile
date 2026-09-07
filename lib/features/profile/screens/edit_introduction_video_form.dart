import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/app_form_fields.dart';
import 'package:bombay_casting/core/widgets/app_primary_button.dart';
import 'package:bombay_casting/core/widgets/option_picker.dart';
import 'package:bombay_casting/features/jobs/utils/video_link_utils.dart';

class EditIntroductionVideoFormScreen extends StatefulWidget {
  const EditIntroductionVideoFormScreen({super.key});

  @override
  State<EditIntroductionVideoFormScreen> createState() =>
      _EditIntroductionVideoFormScreenState();
}

class _EditIntroductionVideoFormScreenState
    extends State<EditIntroductionVideoFormScreen> {
  static const _section = 'videos';

  final TextEditingController _introController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _otherController = TextEditingController();
  bool _saving = false;
  String? _introError;
  String? _experienceError;
  String? _otherError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final profile = context.read<AppState>().profile;
    if (profile == null) return;
    final videos = profile.formSection(_section);
    setState(() {
      _introController.text = (videos['introduction_link'] ?? '').toString();
      _experienceController.text =
          (videos['previous_experience'] ?? '').toString();
      _otherController.text = (videos['other_video_link'] ?? '').toString();
    });
  }

  String _normalizeLink(String input) => VideoLinkUtils.normalize(input);

  Future<void> _save() async {
    if (_saving) return;
    final introError = VideoLinkUtils.introVideoError(_introController.text);
    final experienceError =
        VideoLinkUtils.introVideoError(_experienceController.text);
    final otherError = VideoLinkUtils.introVideoError(_otherController.text);
    if (introError != null || experienceError != null || otherError != null) {
      setState(() {
        _introError = introError;
        _experienceError = experienceError;
        _otherError = otherError;
      });
      return;
    }
    setState(() {
      _saving = true;
      _introError = null;
      _experienceError = null;
      _otherError = null;
    });
    final intro = _normalizeLink(_introController.text);
    final experience = _normalizeLink(_experienceController.text);
    final other = _normalizeLink(_otherController.text);
    try {
      await saveProfileSection(
        context: context,
        section: _section,
        data: {
          'introduction_link': intro,
          'previous_experience': experience,
          'other_video_link': other,
        },
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _introController.dispose();
    _experienceController.dispose();
    _otherController.dispose();
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
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Introduction video',
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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  const Text(
                    'Show brands how you present on camera',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Paste YouTube or Instagram links to your videos.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  AppFormFields(
                    children: [
                      AppTextField(
                        label: 'Introduction link',
                        controller: _introController,
                        hint: 'https://youtube.com/shorts/...',
                        keyboardType: TextInputType.url,
                        optional: true,
                        errorText: _introError,
                      ),
                      AppTextField(
                        label: 'Previous experience',
                        controller: _experienceController,
                        hint: 'https://instagram.com/reel/...',
                        keyboardType: TextInputType.url,
                        optional: true,
                        errorText: _experienceError,
                      ),
                      AppTextField(
                        label: 'Other video link',
                        controller: _otherController,
                        hint: 'https://youtube.com/shorts/...',
                        keyboardType: TextInputType.url,
                        optional: true,
                        errorText: _otherError,
                      ),
                    ],
                  ),
                ],
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
          AppPrimaryButton(
            label: AppLocalizations.of(context)!.update,
            onPressed: _saving ? null : _save,
            loading: _saving,
          ),
        ],
      ),
    );
  }
}
