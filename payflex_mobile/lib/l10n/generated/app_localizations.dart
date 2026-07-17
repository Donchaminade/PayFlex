import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('fr')];

  /// Nom de l'application, affiché sur l'écran d'accueil et le titre de la fenêtre.
  ///
  /// In fr, this message translates to:
  /// **'PayFlex'**
  String get appName;

  /// Titre de l'écran d'accueil (welcome_screen).
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue sur PayFlex'**
  String get welcomeTitle;

  /// Libellé du bouton de connexion (login_screen).
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get loginButton;

  /// Libellé du bouton de déconnexion (profile_screen, agent_profile_screen).
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get logoutButton;

  /// Terme métier « cotisation », utilisé dans le catalogue et le tableau de bord.
  ///
  /// In fr, this message translates to:
  /// **'Cotisation'**
  String get contribution;

  /// Libellé « Solde » affiché dans le tableau de bord client.
  ///
  /// In fr, this message translates to:
  /// **'Solde'**
  String get balance;

  /// Libellé « Épargne », utilisé pour l'épargne bonus.
  ///
  /// In fr, this message translates to:
  /// **'Épargne'**
  String get savings;

  /// Titre/onglet du profil utilisateur.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get profile;

  /// Titre de l'écran des préférences de notifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Titre de la section sécurité du profil.
  ///
  /// In fr, this message translates to:
  /// **'Sécurité'**
  String get security;

  /// Libellé du centre d'assistance PayFlex.
  ///
  /// In fr, this message translates to:
  /// **'Aide & support'**
  String get help;

  /// Libellé générique du bouton d'annulation dans les dialogues.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// Libellé générique du bouton de sauvegarde.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// Message d'erreur réseau générique et non technique (identifié dans l'audit UX).
  ///
  /// In fr, this message translates to:
  /// **'Connexion impossible. Vérifiez votre réseau et réessayez.'**
  String get networkErrorGeneric;

  /// Message d'erreur générique quand le serveur ne répond pas, non technique.
  ///
  /// In fr, this message translates to:
  /// **'Le service PayFlex est momentanément indisponible. Réessayez dans un instant.'**
  String get serverUnavailableGeneric;

  /// Message d'erreur générique de repli, non technique, pour les cas non prévus.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur inattendue est survenue. Réessayez.'**
  String get unexpectedErrorGeneric;

  /// Message générique utilisé pour les fonctionnalités pas encore livrées.
  ///
  /// In fr, this message translates to:
  /// **'Bientôt disponible.'**
  String get comingSoon;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
