class InputValidators {
  InputValidators._();

  static final _email = RegExp(
    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
  );
  static final _pan = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$');

  static bool isValidEmail(String value) {
    final email = value.trim();
    return email.isNotEmpty && _email.hasMatch(email);
  }

  static String? emailError(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter a valid email';
    }
    if (!isValidEmail(value)) return 'Enter a valid email';
    return null;
  }

  static String? nameError(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter your name';
    }
    return null;
  }

  /// Indian PAN: five letters, four digits, one letter (e.g. ABCDE1234F).
  static bool isValidPan(String value) {
    return _pan.hasMatch(value.trim().toUpperCase());
  }

  static String? panError(String? value, {bool required = false}) {
    final pan = (value ?? '').trim().toUpperCase();
    if (pan.isEmpty) {
      return required ? 'Enter a PAN card number' : null;
    }
    if (!isValidPan(pan)) {
      return 'Enter a valid PAN (ABCDE1234F)';
    }
    return null;
  }
}
