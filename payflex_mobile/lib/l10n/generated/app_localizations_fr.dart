// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'PayFlex';

  @override
  String get welcomeTitle => 'Bienvenue sur PayFlex';

  @override
  String get loginButton => 'Se connecter';

  @override
  String get logoutButton => 'Se déconnecter';

  @override
  String get contribution => 'Cotisation';

  @override
  String get balance => 'Solde';

  @override
  String get savings => 'Épargne';

  @override
  String get profile => 'Profil';

  @override
  String get notifications => 'Notifications';

  @override
  String get security => 'Sécurité';

  @override
  String get help => 'Aide & support';

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Enregistrer';

  @override
  String get networkErrorGeneric =>
      'Connexion impossible. Vérifiez votre réseau et réessayez.';

  @override
  String get serverUnavailableGeneric =>
      'Le service PayFlex est momentanément indisponible. Réessayez dans un instant.';

  @override
  String get unexpectedErrorGeneric =>
      'Une erreur inattendue est survenue. Réessayez.';

  @override
  String get comingSoon => 'Bientôt disponible.';
}
