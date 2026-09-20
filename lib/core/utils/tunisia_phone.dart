class TunisiaPhone {
  TunisiaPhone._();

  static const String countryCode = '+216';

  static String digitsOnly(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }

  static String normalize(String value) {
    final digits = digitsOnly(value);

    if (digits.startsWith('216') && digits.length >= 11) {
      return '$countryCode${digits.substring(3, 11)}';
    }

    final localDigits =
        digits.length > 8 ? digits.substring(digits.length - 8) : digits;
    return '$countryCode$localDigits';
  }

  static String localPart(String value) {
    final digits = digitsOnly(value);

    if (digits.startsWith('216') && digits.length >= 11) {
      return digits.substring(3, 11);
    }

    return digits.length > 8 ? digits.substring(digits.length - 8) : digits;
  }

  static bool isValidLocalPart(String value) {
    return RegExp(r'^\d{8}$').hasMatch(digitsOnly(value));
  }
}
