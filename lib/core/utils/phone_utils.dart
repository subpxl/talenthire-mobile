class PhoneUtils {
  PhoneUtils._();

  static final _indianMobile = RegExp(r'^[6-9]\d{9}$');

  static String digitsOnly(String value) =>
      value.replaceAll(RegExp(r'\D'), '');

  static String normalizeIndianMobile(String value) {
    var digits = digitsOnly(value);
    if (digits.length == 12 && digits.startsWith('91')) {
      digits = digits.substring(2);
    } else if (digits.length == 11 && digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    return digits;
  }

  static bool isValidIndianMobile(String value) {
    return _indianMobile.hasMatch(normalizeIndianMobile(value));
  }

  static String? validationError(String value) {
    final normalized = normalizeIndianMobile(value);
    if (normalized.isEmpty) {
      return 'Enter a 10-digit mobile number';
    }
    if (normalized.length != 10) {
      return 'Mobile number must be 10 digits';
    }
    if (!RegExp(r'^[6-9]').hasMatch(normalized)) {
      return 'Enter a valid 10-digit mobile number';
    }
    return null;
  }
}
