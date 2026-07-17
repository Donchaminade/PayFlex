import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/local_notification_service.dart';
import '../../core/services/notification_preferences_service.dart';

/// Préférences d'alertes PayFlex : active/désactive l'affichage des
/// notifications push localement sur cet appareil (cotisations validées,
/// messages du centre, épargne bonus, annonces).
///
/// Le réglage est stocké via `shared_preferences` et consulté directement par
/// `LocalNotificationService.showPayFlexAlert`, seul point d'affichage utilisé
/// par le poll PayFlex (sans Firebase) et par FCM au premier plan. Désactiver
/// ce réglage ne révoque pas l'autorisation système Android/iOS ; il empêche
/// PayFlex d'afficher une alerte même si un message est reçu.
class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends State<NotificationPreferencesScreen> {
  bool _loading = true;
  bool _enabled = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await NotificationPreferencesService.isEnabled();
    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      _loading = false;
    });
  }

  Future<void> _toggle(bool value) async {
    setState(() => _enabled = value);
    await NotificationPreferencesService.setEnabled(value);
    if (value) {
      // Redemande l'autorisation système si l'utilisateur l'avait refusée
      // puis change d'avis ; sans effet si déjà accordée/refusée définitivement.
      await LocalNotificationService.requestPermissions();
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? 'Notifications PayFlex activées.'
              : 'Notifications PayFlex désactivées sur cet appareil.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w800, color: AppColors.secondary),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.secondary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    'Recevez une alerte pour vos cotisations validées, les messages du centre, '
                    'l\'épargne bonus et les annonces importantes.',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.secondary, height: 1.4),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.secondary.withValues(alpha: 0.06)),
                  ),
                  child: SwitchListTile.adaptive(
                    value: _enabled,
                    onChanged: _toggle,
                    activeThumbColor: AppColors.primary,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    secondary: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        _enabled ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    title: Text(
                      'Alertes PayFlex',
                      style: GoogleFonts.manrope(fontWeight: FontWeight.w800, color: AppColors.secondary),
                    ),
                    subtitle: Text(
                      _enabled ? 'Activées sur cet appareil' : 'Désactivées sur cet appareil',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.secondary.withValues(alpha: 0.5)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'Ce réglage s\'applique uniquement à cet appareil. Si vous désactivez les '
                    'notifications, vous continuerez à voir vos messages et alertes directement '
                    'dans l\'application.',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.secondary.withValues(alpha: 0.5), height: 1.4),
                  ),
                ),
              ],
            ),
    );
  }
}
