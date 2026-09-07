import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/utils/app_strings.dart';
import 'package:bombay_casting/core/utils/phone_utils.dart';
import 'package:bombay_casting/features/onboarding/first_login_step.dart';
import 'package:bombay_casting/features/onboarding/widgets/onboarding_step_scaffold.dart';

class EnterMobileScreen extends StatefulWidget {
  const EnterMobileScreen({super.key});

  @override
  State<EnterMobileScreen> createState() => _EnterMobileScreenState();
}

class _EnterMobileScreenState extends State<EnterMobileScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final existing = PhoneUtils.normalizeIndianMobile(
        context.read<AppState>().user?.mobile ?? '',
      );
      if (existing.isNotEmpty) {
        _controller.text = existing;
      }
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final error = PhoneUtils.validationError(_controller.text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      await context.read<AppState>().completeMobileOnboarding(
            PhoneUtils.normalizeIndianMobile(_controller.text),
          );
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not save mobile number. Try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      step: FirstLoginStep.mobile,
      icon: Icons.smartphone_outlined,
      title: context.enterMobileTitle,
      subtitle: context.enterMobileSubtitle,
      actionLabel: context.nextAction,
      actionLoading: _saving,
      onAction: _submit,
      child: Column(
        children: [
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: (_) => _submit(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              prefix: const Padding(
                padding: EdgeInsets.only(right: 10),
                child: Text(
                  '+91',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              hintText: context.mobileNumberHint,
              hintStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                letterSpacing: 0,
                color: AppColors.textHint,
              ),
              errorText: _error,
              filled: true,
              fillColor: AppFormStyle.fill,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppFormStyle.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: _error == null
                      ? AppFormStyle.border
                      : AppFormStyle.errorColor,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: _error == null
                      ? AppColors.primary
                      : AppFormStyle.errorColor,
                  width: 1.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
