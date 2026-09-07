import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/utils/app_links.dart';
import 'package:bombay_casting/core/widgets/app_form_fields.dart';
import 'package:bombay_casting/core/widgets/app_primary_button.dart';
import 'package:bombay_casting/features/jobs/utils/video_link_utils.dart';
import 'package:flutter/material.dart';

const _presetScript =
    'Hi, I’m [your name]. I’m applying for this role.\n'
    'I can take direction, hit emotion quickly, and keep it natural on camera.\n'
    'Here’s a 20-second take — hope you like it.';

const _linkBorder = Color(0xFFE8A8AE);

class ApplyJobResult {
  const ApplyJobResult({
    required this.script,
    required this.youtubeShortUrl,
  });

  final String script;
  final String youtubeShortUrl;
}

Future<ApplyJobResult?> showApplyJobSheet(
  BuildContext context, {
  required String jobTitle,
  String company = '',
  String pay = '',
  String imageUrl = '',
  int imageIndex = 1,
  String initialYoutubeShortUrl = '',
  String auditionScript = '',
  String referenceVideoLink = '',
  bool updateLinkOnly = false,
}) {
  return showModalBottomSheet<ApplyJobResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
    ),
    builder: (context) => ApplyJobSheet(
      jobTitle: jobTitle,
      company: company,
      pay: pay,
      imageUrl: imageUrl,
      imageIndex: imageIndex,
      initialYoutubeShortUrl: initialYoutubeShortUrl,
      auditionScript: auditionScript,
      referenceVideoLink: referenceVideoLink,
      updateLinkOnly: updateLinkOnly,
    ),
  );
}

class ApplyJobSheet extends StatefulWidget {
  const ApplyJobSheet({
    super.key,
    required this.jobTitle,
    this.company = '',
    this.pay = '',
    this.imageUrl = '',
    this.imageIndex = 1,
    this.initialYoutubeShortUrl = '',
    this.auditionScript = '',
    this.referenceVideoLink = '',
    this.updateLinkOnly = false,
  });

  final String jobTitle;
  final String company;
  final String pay;
  final String imageUrl;
  final int imageIndex;
  final String initialYoutubeShortUrl;
  final String auditionScript;
  final String referenceVideoLink;
  final bool updateLinkOnly;

  @override
  State<ApplyJobSheet> createState() => _ApplyJobSheetState();
}

class _ApplyJobSheetState extends State<ApplyJobSheet> {
  late final TextEditingController _linkController;
  String? _linkError;

  @override
  void initState() {
    super.initState();
    _linkController = TextEditingController(
      text: widget.initialYoutubeShortUrl,
    );
  }

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  bool _isVideoLink(String value) {
    return VideoLinkUtils.isYouTubeOrInstagram(value);
  }

  void _submit() {
    final link = VideoLinkUtils.normalize(_linkController.text);

    setState(() {
      if (link.isEmpty) {
        _linkError = 'Paste a YouTube Short or Instagram Reel link';
      } else if (!_isVideoLink(link)) {
        _linkError = 'Use a YouTube Short or Instagram Reel link';
      } else {
        _linkError = null;
      }
    });

    if (_linkError != null) return;

    final script = widget.auditionScript.trim().isNotEmpty
        ? widget.auditionScript.trim()
        : _presetScript;

    Navigator.pop(
      context,
      ApplyJobResult(script: script, youtubeShortUrl: link),
    );
  }

  String get _scriptCopy {
    final custom = widget.auditionScript.trim();
    return custom.isNotEmpty ? custom : _presetScript;
  }

  String get _exampleVideoLink {
    final custom = widget.referenceVideoLink.trim();
    return custom.isNotEmpty ? custom : AppLinks.exampleIntroductionVideo;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final hasLinkError = _linkError != null;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        minimum: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        widget.jobTitle.trim().isNotEmpty
                            ? widget.jobTitle
                            : 'Job',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 16),
                if (!widget.updateLinkOnly) ...[
                  const Text(
                    'Read This Script',
                    style: AppFormStyle.labelStyle,
                  ),
                  const SizedBox(height: AppFormStyle.labelGap),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F7F7),
                      borderRadius: BorderRadius.circular(
                        AppFormStyle.fieldRadius,
                      ),
                      border: Border.all(color: AppFormStyle.border),
                    ),
                    child: Text(
                      _scriptCopy,
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.45,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppFormStyle.fieldGap + 4),
                ],
                Text(
                  widget.updateLinkOnly
                      ? 'Update your YouTube Short or Instagram Reel'
                      : 'Paste your script video or introduction video link here',
                  style: AppFormStyle.labelStyle,
                ),
                const SizedBox(height: AppFormStyle.labelGap),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: const Border.fromBorderSide(
                      BorderSide(color: _linkBorder),
                    ),
                  ),
                  child: TextField(
                    controller: _linkController,
                    keyboardType: TextInputType.url,
                    cursorColor: AppColors.primary,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textPrimary,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'YT Short link or Insta Reel link',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textHint,
                      ),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 13,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      filled: false,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => openAppLink(
                    context,
                    _exampleVideoLink,
                  ),
                  child: const Text(
                    'Intro video example',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6A5AE0),
                      decoration: TextDecoration.underline,
                      decorationColor: Color(0xFF6A5AE0),
                    ),
                  ),
                ),
                if (hasLinkError) ...[
                  const SizedBox(height: 6),
                  Text(
                    _linkError!,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppFormStyle.errorColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                AppPrimaryButton(
                  label: widget.updateLinkOnly ? 'Update link' : 'Submit',
                  onPressed: _submit,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
