import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/widgets/app_primary_button.dart';
import 'package:bombay_casting/core/widgets/app_success_toast.dart';
import 'package:bombay_casting/core/widgets/option_picker.dart';
import 'package:bombay_casting/features/profile/widgets/content_creator_fields_form.dart';

class EditContentCreatorFormScreen extends StatefulWidget {
  const EditContentCreatorFormScreen({super.key});

  @override
  State<EditContentCreatorFormScreen> createState() =>
      _EditContentCreatorFormScreenState();
}

class _EditContentCreatorFormScreenState
    extends State<EditContentCreatorFormScreen> {
  static const _section = 'creator';

  final _formKey = GlobalKey<ContentCreatorFieldsFormState>();
  late final Map<String, dynamic> _initialData;
  late final List<String> _initialNiches;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AppState>().profile;
    _initialData = profile?.formSection(_section) ?? const {};
    _initialNiches = profile?.niches ?? const [];
  }

  Future<void> _save() async {
    if (_saving) return;
    final formState = _formKey.currentState;
    if (formState == null) return;
    setState(() => _saving = true);
    try {
      await saveProfileSection(
        context: context,
        section: _section,
        data: formState.buildData(),
        extra: (profile) => profile.copyWith(
          niches: formState.selectedNiches,
        ),
      );
    } catch (_) {
      if (mounted) {
        showAppToast(
          context,
          AppLocalizations.of(context)!.couldNotSaveDocuments,
          type: AppToastType.error,
        );
      }
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
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'For content creators',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 32.0),
                child: ContentCreatorFieldsForm(
                  key: _formKey,
                  initialData: _initialData,
                  initialNiches: _initialNiches,
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
