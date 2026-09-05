import 'package:bombay_casting/core/widgets/app_success_toast.dart';
import 'package:bombay_casting/core/utils/app_strings.dart';
import 'package:bombay_casting/core/utils/legal_links.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/google_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLoading = false;
  bool _isRegisterMode = true;
  bool _showEmailForm = false;
  bool _obscurePassword = true;
  bool _googleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _googleLoading = true;
    });
    final appState = context.read<AppState>();
    final success = await appState.loginWithGoogle();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _googleLoading = false;
    });
    if (!success && appState.lastAuthError != null) {
      _showSnack(appState.lastAuthError!);
    }
  }

  Future<void> _submitEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final appState = context.read<AppState>();
    final success = _isRegisterMode
        ? await appState.registerWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            name: _nameController.text.trim(),
          )
        : await appState.loginWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (!success && appState.lastAuthError != null) {
      _showSnack(appState.lastAuthError!);
    }
  }

  void _showSnack(String message) {
    showAppToast(context, message, type: AppToastType.error);
  }

  void _openEmailForm({required bool registerMode}) {
    setState(() {
      _isRegisterMode = registerMode;
      _showEmailForm = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Center(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                      Image.asset(
                        'assets/splash.png',
                        width: 168,
                        height: 168,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        context.loginHeadline,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.loginSubtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _GoogleSignInButton(
                        label: context.loginWithGoogle,
                        loading: _googleLoading,
                        onPressed: _isLoading ? null : _signInWithGoogle,
                      ),
                      const SizedBox(height: 28),
                      if (_showEmailForm) ...[
                        if (_isRegisterMode) ...[
                          TextFormField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              labelText: context.creatorNameLabel,
                              prefixIcon: const Icon(Icons.person_outline),
                            ),
                            validator: (value) {
                              if (!_isRegisterMode) return null;
                              if (value == null || value.trim().isEmpty) {
                                return context.enterYourName;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                        ],
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: context.emailLabel,
                            prefixIcon: const Icon(Icons.mail_outline),
                          ),
                          validator: (value) {
                            if (value == null || !value.contains('@')) {
                              return context.enterValidEmail;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: context.passwordLabel,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword
                                  ? context.showPassword
                                  : context.hidePassword,
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.length < 6) {
                              return context.passwordMinLength;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitEmailAuth,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                              ),
                            ),
                            child: _isLoading && !_googleLoading
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        _isRegisterMode
                                            ? context.creatingAccount
                                            : context.signingIn,
                                      ),
                                    ],
                                  )
                                : Text(
                                    _isRegisterMode
                                        ? context.createAccountBtn
                                        : context.signInBtn,
                                  ),
                          ),
                        ),
                      ] else ...[
                        _EmailPasswordButton(
                          label: context.loginWithEmail,
                          onPressed: _isLoading
                              ? null
                              : () => _openEmailForm(
                                    registerMode: _isRegisterMode,
                                  ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                if (_showEmailForm) {
                                  setState(
                                    () => _isRegisterMode = !_isRegisterMode,
                                  );
                                } else {
                                  _openEmailForm(
                                    registerMode: !_isRegisterMode,
                                  );
                                }
                              },
                        child: Text.rich(
                          TextSpan(
                            text: _isRegisterMode
                                ? '${context.alreadyHaveAccount} '
                                : '${context.newHere} ',
                            style: context.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.45,
                              letterSpacing: 0.2,
                            ),
                            children: [
                              TextSpan(
                                text: _isRegisterMode
                                    ? context.logInAction
                                    : context.createAccountAction,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(32, 4, 32, 16),
              child: _TermsFooter(),
            ),
          ],
        ),
      ),
    );
  }
}

class _TermsFooter extends StatelessWidget {
  const _TermsFooter();

  static const _body = TextStyle(
    fontSize: 11.5,
    height: 1.45,
    color: AppColors.textHint,
  );

  static const _link = TextStyle(
    fontSize: 11.5,
    height: 1.45,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.primary, thickness: 1)),
        const SizedBox(width: 10),
        Expanded(
          flex: 8,
          child: Text.rich(
            TextSpan(
              text: 'By continuing, you agree to our ',
              style: _body,
              children: [
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: GestureDetector(
                    onTap: () => openLegalPage(context, LegalLinks.terms),
                    child: const Text('Terms of Service', style: _link),
                  ),
                ),
                const TextSpan(text: ' and '),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: GestureDetector(
                    onTap: () => openLegalPage(context, LegalLinks.privacy),
                    child: const Text('Privacy Policy', style: _link),
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(child: Divider(color: AppColors.primary, thickness: 1)),
      ],
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  static const _googleText = Color(0xFF3C4043);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: _googleText,
          disabledBackgroundColor: Colors.white,
          disabledForegroundColor: _googleText.withValues(alpha: 0.5),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            side: const BorderSide(color: Color(0xFF4285F4), width: 1.3),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
        child: loading
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const GoogleLogo(size: 18),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.15,
                      height: 1.2,
                      color: _googleText,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _EmailPasswordButton extends StatelessWidget {
  const _EmailPasswordButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.primary,
          disabledForegroundColor: AppColors.primary.withValues(alpha: 0.45),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          side: const BorderSide(color: Color(0xFFF0C4C8), width: 1.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mail_outline, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.15,
                height: 1.2,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
