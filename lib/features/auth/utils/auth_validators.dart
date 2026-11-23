/// Validadores para el registro (SignUpScreen) y recuperacion de contrasena.
/// Nota OWASP: estas reglas NO se usan en el Login para evitar filtracion de politicas.
class AuthValidators {
  AuthValidators._();

  static const String institutionalDomain = '@tecdesoftware.edu.mx';

  static final RegExp _basicEmailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final RegExp _upperRegex = RegExp(r'[A-Z]');
  static final RegExp _lowerRegex = RegExp(r'[a-z]');
  static final RegExp _digitRegex = RegExp(r'\d');
  static final RegExp _symbolRegex = RegExp(r'[^A-Za-z0-9\s]');

  static bool isBasicEmail(String email) {
    return _basicEmailRegex.hasMatch(email.trim());
  }

  static bool isInstitutionalEmail(String email) {
    final normalized = email.trim().toLowerCase();
    return _basicEmailRegex.hasMatch(normalized) &&
        normalized.endsWith(institutionalDomain);
  }

  static bool hasMinLength(String password) => password.length >= 8;
  static bool hasUppercase(String password) => _upperRegex.hasMatch(password);
  static bool hasLowercase(String password) => _lowerRegex.hasMatch(password);
  static bool hasDigit(String password) => _digitRegex.hasMatch(password);
  static bool hasSymbol(String password) => _symbolRegex.hasMatch(password);

  static bool isStrongPassword(String password) {
    return hasMinLength(password) &&
        hasUppercase(password) &&
        hasLowercase(password) &&
        hasDigit(password) &&
        hasSymbol(password);
  }
}
