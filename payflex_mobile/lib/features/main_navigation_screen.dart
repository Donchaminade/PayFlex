import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/design/pf_components.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/client_inbox_provider.dart';
import '../core/providers/finance_provider.dart';
import '../core/providers/navigation_provider.dart';
import '../core/widgets/inbox_banner.dart';
import '../core/widgets/payflex_app_exit_guard.dart';
import 'chat/chat_screen.dart';
import 'notifications/client_notifications_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'catalogue/catalogue_screen.dart';
import 'payment/payment_screen.dart';
import 'history/calendar_view_screen.dart';
import 'history/transaction_history_screen.dart';
import 'auth/widgets/registration_feature_guard.dart';
import 'auth/widgets/registration_locked_tab.dart';

/// Un seul onglet monté à la fois (moins de RAM / moins de requêtes parallèles).
class _ClientTabPage extends StatelessWidget {
  final int index;
  final bool pendingApproval;

  const _ClientTabPage({required this.index, required this.pendingApproval});

  @override
  Widget build(BuildContext context) {
    switch (index) {
      case 1:
        return const CatalogueScreen();
      case 2:
        return pendingApproval
            ? const RegistrationLockedTab(featureName: 'Paiement')
            : const PaymentScreen();
      case 3:
        return pendingApproval
            ? const RegistrationLockedTab(featureName: 'Suivi')
            : const CalendarViewScreen();
      case 4:
        return pendingApproval
            ? const RegistrationLockedTab(featureName: 'Historique')
            : const TransactionHistoryScreen();
      case 0:
      default:
        return const DashboardScreen();
    }
  }
}

class MainNavigationScreen extends ConsumerWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);
    final auth = ref.watch(authProvider);
    final inbox = auth.role == 'client' ? ref.watch(clientInboxProvider) : null;
    final pendingApproval = auth.awaitingAdminApproval;

    final topInset = MediaQuery.paddingOf(context).top;

    return PayflexAppExitGuard(
      child: Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: PfMotion.reduced(context) ? Duration.zero : const Duration(milliseconds: 260),
            switchInCurve: PfMotion.ease,
            child: KeyedSubtree(
              key: ValueKey(currentIndex),
              child: _ClientTabPage(index: currentIndex, pendingApproval: pendingApproval),
            ),
          ),
          if (pendingApproval)
            Positioned(
              top: topInset + 56,
              left: 12,
              right: 12,
              child: Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(14),
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.verified_user_outlined, color: Colors.blue.shade800),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Compte en attente : parcourez le catalogue et votre profil. Cotisations et paiements après validation PayFlex.',
                          style: TextStyle(fontSize: 12, color: Colors.blue.shade900, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (inbox != null && inbox.hasBanner)
            Positioned(
              top: topInset + 56 + (pendingApproval ? 88 : 0),
              left: 12,
              right: 12,
              child: InboxBanner(
                title: inbox.bannerTitle!,
                body: inbox.bannerBody!,
                onDismiss: () => ref.read(clientInboxProvider.notifier).dismissBanner(),
                onTap: () {
                  ref.read(clientInboxProvider.notifier).dismissBanner();
                  if (inbox.bannerType == 'chat') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ChatScreen()),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ClientNotificationsScreen()),
                    );
                  }
                },
              ),
            ),
        ],
      ),
      bottomNavigationBar: _FloatingNavbar(currentIndex: currentIndex, lockPaidFeatures: pendingApproval),
    ),
    );
  }
}

class _FloatingNavbar extends ConsumerWidget {
  final int currentIndex;
  final bool lockPaidFeatures;
  const _FloatingNavbar({required this.currentIndex, this.lockPaidFeatures = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(authProvider).awaitingAdminApproval;
    return PfFloatingTabBar(
      index: currentIndex,
      items: [
        const PfNavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Accueil'),
        const PfNavItem(icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view_rounded, label: 'Catalogue'),
        const PfNavItem(icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet_rounded, label: 'Payer'),
        const PfNavItem(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_month_rounded, label: 'Suivi'),
        PfNavItem(icon: Icons.history_rounded, activeIcon: Icons.history_rounded, label: 'Historique', badge: pending),
      ],
      onTap: (index) {
        if (lockPaidFeatures && index == 2) {
          showRegistrationFeatureLockedSnackBar(context, 'Paiement');
          return;
        }
        if (lockPaidFeatures && (index == 3 || index == 4)) {
          showRegistrationFeatureLockedSnackBar(context, index == 3 ? 'Suivi' : 'Historique');
          return;
        }
        if (index == 4 && !lockPaidFeatures) {
          ref.read(financeProvider.notifier).reload();
        }
        ref.read(navigationIndexProvider.notifier).setIndex(index);
      },
    );
  }
}
