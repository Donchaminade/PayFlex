import 'package:shared_preferences/shared_preferences.dart';

/// Préférence locale (par appareil) d'activation des alertes push PayFlex.
///
/// Ce service est le point de vérité unique consulté par [LocalNotificationService]
/// avant d'afficher une alerte système, que la notification provienne du poll
/// PayFlex sans Firebase ([PayflexPushSyncService]) ou du canal FCM au premier
/// plan ([PayflexFcmService]). Il n'existe volontairement aucun mécanisme
/// d'affichage parallèle : toute nouvelle source de notification locale doit
/// passer par `LocalNotificationService.showPayFlexAlert`.
class NotificationPreferencesService {
  NotificationPreferencesService._();

  static const _prefKey = 'payflex_notifications_enabled_v1';

  /// Activées par défaut (comportement historique inchangé si l'utilisateur
  /// ne touche jamais au réglage).
  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? true;
  }

  static Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
  }
}
