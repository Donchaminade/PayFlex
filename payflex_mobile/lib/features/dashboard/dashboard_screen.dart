import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/client_inbox_provider.dart';
import '../../core/providers/client_notifications_provider.dart';
import '../../core/widgets/count_badge.dart';
import '../../core/widgets/offline_banner.dart';
import '../../core/widgets/payflex_profile_avatar.dart';
import '../auth/widgets/registration_feature_guard.dart';
import '../../core/providers/finance_provider.dart';
import '../../core/providers/navigation_provider.dart';
import '../../core/utils/money_format.dart';
import '../chat/chat_screen.dart';
import '../notifications/client_notifications_screen.dart';
import '../payment/adhesion_payment_screen.dart';
import 'dashboard_project_detail_screen.dart';
import '../profile/profile_screen.dart';
import '../support/client_report_screen.dart';
import '../vitrine/job_offers_screen.dart';
import '../../core/widgets/client_bonus_savings_card.dart';
import '../../core/widgets/payflex_quick_access_row.dart';
import '../../core/design/pf_components.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final financeState = ref.watch(financeProvider);
    final notifState = auth.role == 'client' ? ref.watch(clientNotificationsProvider) : null;
    final inboxState = auth.role == 'client' ? ref.watch(clientInboxProvider) : null;

    if (auth.role == 'client') {
      ref.listen<ClientNotificationsState>(clientNotificationsProvider, (prev, next) {
        final msg = next.lastSnackMessage;
        if (msg != null && msg != prev?.lastSnackMessage) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg, style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF38A169),
            ),
          );
          ref.read(clientNotificationsProvider.notifier).clearSnack();
        }
      });
    }

    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12 ? 'Bonjour' : hour < 18 ? 'Bon après-midi' : 'Bonsoir';

    return Scaffold(
      backgroundColor: Pf.canvas,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // === EN-TÊTE « EXPLORE » ===
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(Pf.gutter, Pf.s16, Pf.gutter, 0),
                        child: Row(
                          children: [
                            PfPressable(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ProfileScreen()),
                              ),
                              semanticLabel: 'Mon profil',
                              child: PayflexProfileAvatar(
                                letter: auth.avatarLetter,
                                imageUrl: auth.profilePhotoUrl,
                                awaitingAdminApproval: auth.awaitingAdminApproval,
                                radius: 20,
                                letterFontSize: 16,
                              ),
                            ),
                            const SizedBox(width: Pf.s12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    auth.name?.trim().isNotEmpty == true ? auth.name!.trim() : 'Mon espace PayFlex',
                                    style: Pf.label(size: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    auth.assignedAgentName != null && auth.assignedAgentName!.trim().isNotEmpty
                                        ? '${auth.statusLabelFr()} · Agent ${auth.assignedAgentName!.trim()}'
                                        : '${auth.statusLabelFr()} · ${auth.roleLabelFr()}',
                                    style: Pf.body(size: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            PfCircleButton(
                              icon: Icons.notifications_none_rounded,
                              semanticLabel: 'Notifications',
                              dot: inboxState != null && inboxState.notificationsUnread > 0,
                              onTap: auth.role == 'client'
                                  ? () => Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => const ClientNotificationsScreen()),
                                      )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      PfReveal(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(Pf.gutter, Pf.s24, Pf.gutter, Pf.s20),
                          child: Text('$greeting,\n${auth.greetingFirstName}', style: Pf.display()),
                        ),
                      ),
                      PfReveal(
                        index: 1,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: Pf.gutter),
                          child: PfSearchBar(
                            hint: 'Rechercher un équipement',
                            readOnly: true,
                            onTap: () => ref.read(navigationIndexProvider.notifier).setIndex(1),
                            onFilter: () => ref.read(navigationIndexProvider.notifier).setIndex(1),
                          ),
                        ),
                      ),
                      const SizedBox(height: Pf.s8),
                      PfReveal(
                        index: 2,
                        child: PfCategoryTabs(
                          selected: 0,
                          items: const [
                            PfTabItem('Aperçu', Icons.space_dashboard_rounded),
                            PfTabItem('Catalogue', Icons.storefront_rounded),
                            PfTabItem('Cotiser', Icons.payments_rounded),
                            PfTabItem('Suivi', Icons.calendar_month_rounded),
                            PfTabItem('Opportunités', Icons.work_outline_rounded),
                          ],
                          onSelected: (i) {
                            if (i == 0) return;
                            if (i == 4) {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const JobOffersScreen()));
                              return;
                            }
                            final tab = i == 1 ? 1 : (i == 2 ? 2 : 3);
                            if (!auth.canUseAppFeatures && tab != 1) {
                              showRegistrationFeatureLockedSnackBar(context, tab == 2 ? 'Paiement' : 'Suivi');
                              return;
                            }
                            ref.read(navigationIndexProvider.notifier).setIndex(tab);
                          },
                        ),
                      ),
                      const SizedBox(height: Pf.s24),
                      // Carte vedette : solde épargné
                      PfReveal(
                        index: 3,
                        scale: true,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: Pf.gutter),
                          child: _BalanceFeaturedCard(
                            balance: financeState.balance,
                            projects: financeState.projects,
                            locked: auth.awaitingAdminApproval,
                            onPay: () {
                              if (!auth.canUseAppFeatures) {
                                showRegistrationFeatureLockedSnackBar(context, 'Paiement');
                                return;
                              }
                              ref.read(navigationIndexProvider.notifier).setIndex(2);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (auth.role == 'client' && financeState.isOffline)
                const SliverToBoxAdapter(
                  child: OfflineBanner(
                    margin: EdgeInsets.fromLTRB(24, 16, 24, 0),
                  ),
                ),

              if (auth.awaitingAdminApproval)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Material(
                      elevation: 0,
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.amber.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.hourglass_top_rounded, color: Colors.amber.shade900),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Validation PayFlex en cours',
                                    style: GoogleFonts.manrope(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: Colors.amber.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Votre dossier a été transmis. Catalogue, paiements et cotisations seront actifs après approbation par l’équipe.',
                              style: GoogleFonts.inter(fontSize: 13, color: Colors.amber.shade900, height: 1.4),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: auth.isLoading
                                    ? null
                                    : () async {
                                        final ok = await ref.read(authProvider.notifier).tryActivateApprovedAccount();
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              ok
                                                  ? 'Compte activé — toutes les fonctions sont disponibles.'
                                                  : 'Pas encore validé. Réessayez dans quelques instants.',
                                            ),
                                          ),
                                        );
                                      },
                                icon: const Icon(Icons.refresh_rounded, size: 18),
                                label: const Text('Vérifier mon activation'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // === CHIFFRES CLÉS ===
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(Pf.gutter, Pf.s16, Pf.gutter, 0),
                  child: Row(
                    children: [
                      _statCard(
                        index: 0,
                        icon: Icons.trending_up_rounded,
                        label: 'Projets actifs',
                        value: auth.awaitingAdminApproval ? '—' : '${financeState.projects.length}',
                        color: Pf.gold,
                      ),
                      const SizedBox(width: Pf.s12),
                      _statCard(
                        index: 1,
                        icon: Icons.receipt_long_rounded,
                        label: 'Transactions',
                        value: '${financeState.transactions.length}',
                        color: Pf.ink,
                      ),
                      const SizedBox(width: Pf.s12),
                      _statCard(
                        index: 2,
                        icon: Icons.history_toggle_off_rounded,
                        label: 'Rattrapages',
                        value: '${financeState.catchUpOrangeDaysCount}',
                        color: const Color(0xFFD97706),
                      ),
                    ],
                  ),
                ),
              ),

              if (!auth.awaitingAdminApproval &&
                  auth.role == 'client' &&
                  financeState.bonusSavings.hasData)
                SliverToBoxAdapter(
                  child: ColoredBox(
                    color: const Color(0xFFF8FAFC),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                      child: ClientBonusSavingsCard(summary: financeState.bonusSavings),
                    ),
                  ).animate().fadeIn(delay: 320.ms).slideY(begin: 0.08),
                ),

              SliverToBoxAdapter(
                child: ColoredBox(
                  color: const Color(0xFFF8FAFC),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: PayflexQuickAccessRow(
                      onReportTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ClientReportScreen()),
                      ),
                      onOpportunitiesTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const JobOffersScreen()),
                      ),
                    ),
                  ),
                ),
              ),

              if (!auth.awaitingAdminApproval &&
                  auth.role == 'client' &&
                  (auth.deliveryCycleActive ||
                      financeState.projects.any((p) => p.progress >= 0.999)))
                SliverToBoxAdapter(
                  child: ColoredBox(
                    color: const Color(0xFFF8FAFC),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.success.withValues(alpha: 0.15), Colors.white],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              auth.deliveryReadyForPickup
                                  ? 'Prêt pour la livraison'
                                  : 'Objectif atteint !',
                              style: GoogleFonts.manrope(fontWeight: FontWeight.w900, color: AppColors.secondary),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              auth.deliveryReadyForPickup
                                  ? 'Le centre a validé votre clôture${auth.deliveryProductName != null ? ' pour « ${auth.deliveryProductName} »' : ''}. Votre équipement sera remis prochainement — vous serez notifié.'
                                  : auth.deliveryStatus == 'awaiting_closure'
                                      ? 'Votre solde est complet. Le centre valide votre carnet avant la remise de l’équipement.'
                                      : 'Votre objectif est atteint${auth.deliveryProductName != null ? ' pour « ${auth.deliveryProductName} »' : ''}. Le centre finalise la clôture puis la livraison.',
                              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade700),
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: () => ref.read(navigationIndexProvider.notifier).setIndex(3),
                              child: Text(
                                auth.deliveryReadyForPickup ? 'Suivre ma livraison' : 'Voir mon suivi',
                                style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              if (auth.role == 'client' && auth.needsAdhesionPayment)
                SliverToBoxAdapter(
                  child: ColoredBox(
                    color: const Color(0xFFF8FAFC),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                      child: Material(
                        elevation: 0,
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.orange.shade50,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () async {
                            final ok = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(builder: (_) => const AdhesionPaymentScreen()),
                            );
                            if (ok == true && context.mounted) {
                              await ref.read(authProvider.notifier).refreshProfile();
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.payments_outlined, color: Colors.orange.shade800, size: 26),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Adhésion ${auth.adhesionFeeFcfa} FCFA',
                                        style: GoogleFonts.manrope(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.orange.shade900,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        auth.assignedAgentName != null &&
                                                auth.assignedAgentName!.trim().isNotEmpty
                                            ? 'Espèces chez ${auth.assignedAgentName!.trim()} ou mobile money (PayDunya).'
                                            : 'Paiement mobile money (PayDunya). Appuyez pour payer.',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          height: 1.35,
                                          color: Colors.orange.shade900.withValues(alpha: 0.85),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right_rounded, color: Colors.orange.shade800),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.06),
                  ),
                ),

              SliverToBoxAdapter(
                child: ColoredBox(
                  color: const Color(0xFFF8FAFC),
                  child: SizedBox(height: auth.role == 'client' && auth.needsAdhesionPayment ? 22 : 28),
                ),
              ),

              // === DISCUSSION ===
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Pf.gutter),
                  child: PfReveal(
                    index: 4,
                    child: PfCard(
                      onTap: () {
                        if (!auth.canUseAppFeatures) {
                          showRegistrationFeatureLockedSnackBar(context, 'Discussion support');
                          return;
                        }
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen()));
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(color: Pf.gold.withValues(alpha: 0.16), borderRadius: Pf.br(Pf.rSm)),
                            child: Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                const Icon(Icons.chat_bubble_outline_rounded, color: Pf.ink, size: 22),
                                if (inboxState != null && inboxState.chatUnread > 0)
                                  CountBadge(count: inboxState.chatUnread, top: -6, right: -6),
                              ],
                            ),
                          ),
                          const SizedBox(width: Pf.s12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Message / Discussion', style: Pf.label()),
                                Text('Votre agent et le support PayFlex', style: Pf.body(size: 12)),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Pf.faint),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: Pf.s32)),

              // === MES PROJETS ===
              if (financeState.projects.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: PfSectionHeader(
                    title: 'Mes projets',
                    action: 'Voir tout',
                    onAction: () => ref.read(navigationIndexProvider.notifier).setIndex(3),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: Pf.s12)),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 196,
                    child: ListView.builder(
                      clipBehavior: Clip.none,
                      padding: const EdgeInsets.symmetric(horizontal: Pf.gutter),
                      scrollDirection: Axis.horizontal,
                      itemCount: financeState.projects.length,
                      itemBuilder: (context, index) {
                        final project = financeState.projects[index];
                        return PfReveal(
                          index: index,
                          scale: true,
                          child: PfPressable(
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => DashboardProjectDetailScreen(projectId: project.id),
                              ),
                            );
                            if (context.mounted) {
                              await ref.read(financeProvider.notifier).reload();
                            }
                          },
                          child: ProjectCard(
                            title: project.title,
                            saved: formatFcfa(project.saved, withSuffix: false),
                            total: formatFcfa(project.total, withSuffix: false),
                            progress: project.progress,
                            color: AppColors.primary,
                          ),
                        ),
                        );
                      },
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 28)),
              ],

              // === ACTIVITÉS RÉCENTES ===
              SliverToBoxAdapter(
                child: PfSectionHeader(
                  title: 'Activités récentes',
                  action: 'Tout voir',
                  onAction: () => ref.read(navigationIndexProvider.notifier).setIndex(3),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: Pf.s8)),

              if (financeState.transactions.isEmpty)
                SliverToBoxAdapter(
                  child: PfEmptyState(
                    icon: Icons.receipt_long_rounded,
                    title: 'Aucune transaction',
                    message: 'Commencez une épargne depuis le catalogue !',
                    action: 'Explorer le catalogue',
                    onAction: () => ref.read(navigationIndexProvider.notifier).setIndex(1),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final transaction = financeState.transactions[index];
                      return PfReveal(index: index, child: TransactionTile(transaction: transaction));
                    },
                    childCount: financeState.transactions.length,
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard({required int index, required IconData icon, required String label, required String value, required Color color}) {
    return Expanded(
      child: PfReveal(
        index: index + 4,
        child: Container(
          padding: const EdgeInsets.all(Pf.s16),
          decoration: BoxDecoration(color: Pf.surface, borderRadius: Pf.br(Pf.rLg), boxShadow: Pf.shadowSoft),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: Pf.br(10)),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: Pf.s12),
              Text(value, style: Pf.num(size: 22)),
              const SizedBox(height: 2),
              Text(label, style: Pf.body(size: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

/// Carte vedette « solde épargné » (style featured card) avec compteur animé et anneau.
class _BalanceFeaturedCard extends StatelessWidget {
  const _BalanceFeaturedCard({required this.balance, required this.projects, required this.locked, required this.onPay});
  final double balance;
  final List<ProjectModel> projects;
  final bool locked;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final saved = projects.fold<double>(0, (s, p) => s + p.saved);
    final total = projects.fold<double>(0, (s, p) => s + p.total);
    final progress = total > 0 ? saved / total : 0.0;
    return PfFeaturedCard(
      height: 200,
      badge: 'SOLDE ÉPARGNÉ',
      title: formatFcfaLong(balance),
      titleWidget: FittedBox(
        alignment: Alignment.centerLeft,
        fit: BoxFit.scaleDown,
        child: PfAnimatedAmount(value: balance, format: formatFcfaLong, style: Pf.amount(color: Colors.white, size: 30)),
      ),
      subtitle: projects.isEmpty
          ? 'Aucun projet en cours'
          : '${projects.length} projet${projects.length > 1 ? 's' : ''} · objectif ${formatFcfa(total)}',
      cta: locked ? 'Activation en attente' : 'Cotiser maintenant',
      onCta: onPay,
      trailing: projects.isEmpty
          ? null
          : PfRing(
              value: progress,
              size: 96,
              stroke: 9,
              track: Colors.white.withValues(alpha: 0.12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${(progress * 100).round()}%', style: Pf.num(size: 20, color: Colors.white)),
                  Text('atteint', style: Pf.body(size: 10, color: Colors.white60)),
                ],
              ),
            ),
    );
  }
}

class ProjectCard extends StatelessWidget {
  final String title;
  final String saved;
  final String total;
  final double progress;
  final Color color;

  const ProjectCard({
    super.key,
    required this.title,
    required this.saved,
    required this.total,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 176,
      margin: const EdgeInsets.only(right: Pf.s12, bottom: Pf.s16),
      padding: const EdgeInsets.all(Pf.s16),
      decoration: BoxDecoration(color: Pf.surface, borderRadius: Pf.br(Pf.rXl), boxShadow: Pf.shadowSoft),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PfRing(
                value: progress,
                size: 48,
                stroke: 5,
                color: color,
                child: Text('${(progress * 100).toInt()}%', style: Pf.num(size: 11)),
              ),
              const Spacer(),
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(color: Pf.fill, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_outward_rounded, size: 16, color: Pf.ink),
              ),
            ],
          ),
          const Spacer(),
          Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: Pf.label(size: 14)),
          const SizedBox(height: Pf.s4),
          Text.rich(
            TextSpan(children: [
              TextSpan(text: saved, style: Pf.num(size: 12)),
              TextSpan(text: ' / $total FCFA', style: Pf.body(size: 11)),
            ]),
            maxLines: 1,
          ),
          const SizedBox(height: Pf.s8),
          ClipRRect(
            borderRadius: Pf.br(4),
            child: LinearProgressIndicator(value: progress.clamp(0, 1), minHeight: 4, color: color, backgroundColor: Pf.fill),
          ),
        ],
      ),
    );
  }
}

class TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  const TransactionTile({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final (tone, statusLabel, color) = switch (transaction.status) {
      'validated' => (PfChipTone.success, 'VALIDÉ', Pf.success),
      'rejected' => (PfChipTone.danger, 'REJETÉ', Pf.danger),
      _ => (PfChipTone.warn, 'EN ATTENTE', const Color(0xFFD97706)),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Pf.gutter, vertical: 6),
      child: PfCard(
        padding: const EdgeInsets.symmetric(horizontal: Pf.s16, vertical: Pf.s12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: Pf.br(Pf.rSm)),
              child: Icon(Icons.south_west_rounded, color: color, size: 20),
            ),
            const SizedBox(width: Pf.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(transaction.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Pf.label()),
                  const SizedBox(height: 2),
                  Text('${transaction.date} · Cotisation', style: Pf.body(size: 12)),
                ],
              ),
            ),
            const SizedBox(width: Pf.s8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('+${formatFcfaLong(transaction.amount)}', style: Pf.num(size: 14)),
                const SizedBox(height: Pf.s4),
                PfPillChip(label: statusLabel, tone: tone),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
