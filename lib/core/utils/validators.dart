import 'tunisia_phone.dart';

/// Shared form validators used across the app.
class Validators {
  Validators._();

  static String? required(String? value, [String field = 'Ce champ']) {
    if (value == null || value.trim().isEmpty) return '$field est requis';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'E-mail requis';
    final re = RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
    if (!re.hasMatch(value.trim())) return 'Adresse e-mail invalide';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Mot de passe requis';
    if (value.length < 6) return 'Minimum 6 caractères';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Numéro requis';
    if (!TunisiaPhone.isValidLocalPart(value)) {
      return 'Entrez un numéro à 8 chiffres';
    }
    return null;
  }

  static String? positiveInt(String? value, [String field = 'Quantité']) {
    if (value == null || value.trim().isEmpty) return '$field requise';
    final n = int.tryParse(value.trim());
    if (n == null || n < 1) return '$field invalide (minimum 1)';
    return null;
  }

  static String? positiveDouble(String? value, [String field = 'Montant']) {
    if (value == null || value.trim().isEmpty) return '$field requis';
    final n = double.tryParse(value.trim().replaceAll(',', '.'));
    if (n == null || n <= 0) return '$field invalide';
    return null;
  }
}
