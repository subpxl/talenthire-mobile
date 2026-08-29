import 'package:bombay_casting/core/utils/app_strings.dart';
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: AppColors.primary, size: 28),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        context.appName,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _isRegisterMode
                      ? context.createCreatorAccount
                      : context.signInToFindCollabs,
                  style: context.bodyMedium.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 36),
                _GoogleSignInButton(
                  label: context.continueWithGoogle,
                  loading: _googleLoading,
                  onPressed: _isLoading ? null : _signInWithGoogle,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        context.or.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
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
                    const SizedBox(height: AppSpacing.md),
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
                  const SizedBox(height: AppSpacing.md),
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
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
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
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitEmailAuth,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.pill),
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
                              _isRegisterMode ? context.createAccountBtn : context.signInBtn,
                            ),
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () => _openEmailForm(registerMode: _isRegisterMode),
                      style: ElevatedButton.styleFrom(
                        elevation: 2,
                        shadowColor: AppColors.primary.withValues(alpha: 0.35),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                      child: Text(context.continueWithEmail),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            if (_showEmailForm) {
                              setState(
                                () => _isRegisterMode = !_isRegisterMode,
                              );
                            } else {
                              _openEmailForm(registerMode: !_isRegisterMode);
                            }
                          },
                    child: Text.rich(
                      TextSpan(
                        text: _isRegisterMode
                            ? '${context.alreadyHaveAccount} '
                            : '${context.newHere} ',
                        style: context.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        children: [
                          TextSpan(
                            text: _isRegisterMode
                                ? context.logInAction
                                : context.createAccountAction,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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

  static const _googleBlue = Color(0xFF4285F4);
  static const _googleText = Color(0xFF3C4043);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: _googleText,
          disabledForegroundColor: _googleText.withValues(alpha: 0.5),
          side: const BorderSide(color: _googleBlue, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _googleBlue,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const GoogleLogo(size: 20),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _googleText,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
