/// Centralized form-field validation rules, reused by every screen with a
/// Form. One shared email/phone pattern (instead of a dozen slightly
/// different `contains('@')` checks scattered per-screen) means the rules
/// - and their error messages - stay consistent across the whole app.
class Validators {
  Validators._();

  static final RegExp _emailPattern = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');

  // Rwandan mobile numbers: 07[2/3/8/9]xxxxxxx (10 digits), optionally
  // written with a "+250"/"250" country code instead of the leading 0, or
  // (RegisterScreen's case) with no prefix at all because the screen
  // already shows a fixed "+250" next to the field.
  static final RegExp _rwandaPhonePattern = RegExp(r'^(?:\+?250|0)?7[2389]\d{7}$');

  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!_emailPattern.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value, {int minLength = 8}) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < minLength) return 'Use at least $minLength characters';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != original) return "Passwords don't match";
    return null;
  }

  /// Optional field - only validates the format if the user actually typed
  /// something, since a phone number is never required for this app.
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (!_rwandaPhonePattern.hasMatch(value.trim().replaceAll(RegExp(r'[\s-]'), ''))) {
      return 'Enter a valid phone number (e.g. 0788123456)';
    }
    return null;
  }

  static String? price(String? value) {
    if (value == null || value.trim().isEmpty) return 'Price is required';
    final parsed = double.tryParse(value.trim());
    if (parsed == null) return 'Enter a valid number';
    if (parsed <= 0) return 'Price must be greater than zero';
    return null;
  }
}
