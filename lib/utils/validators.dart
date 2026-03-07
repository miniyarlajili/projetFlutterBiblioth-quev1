class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Email obligatoire';
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value)) return 'Email invalide';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Mot de passe obligatoire';
    if (value.length < 6) return 'Minimum 6 caractères';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Confirmez le mot de passe';
    if (value != password) return 'Les mots de passe ne correspondent pas';
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.isEmpty) return 'Nom obligatoire';
    if (value.length < 3) return 'Minimum 3 caractères';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.isEmpty) return null; // optionnel
    final regex = RegExp(r'^\+?[0-9]{8,15}$');
    if (!regex.hasMatch(value)) return 'Numéro invalide';
    return null;
  }
}