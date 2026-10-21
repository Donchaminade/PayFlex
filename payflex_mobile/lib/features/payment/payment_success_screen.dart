import 'package:flutter/material.dart';
import '../../core/design/pf_components.dart';
import 'widgets/payment_flow_stage.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/allocation_result.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/money_format.dart';

/// Écran de confirmation de paiement volontairement grand et simple.
///
/// Objectif accessibilité : une grande coche verte, le montant lisible
/// (« 25 000 F »), un message court et un seul gros bouton « OK ». Un lien
/// discret « Voir le reçu » reste disponible sans surcharger l'écran.
class PaymentSuccessScreen extends StatefulWidget {
  const PaymentSuccessScreen({
    super.key,
    required this.amount,
    required this.awaitingAgentValidation,
    required this.paymentModeLabel,
    required this.slotsCount,
    this.gatewayConfirmed = false,
    this.productName,
    this.allocation,
    this.onViewReceipt,
    required this.onDone,
  });

  final double amount;
  final bool awaitingAgentValidation;
  final bool gatewayConfirmed;
  final String paymentModeLabel;
  final int slotsCount;
  final String? productName;

  /// Détail de la répartition automatique si le paiement a dépassé le reste à
  /// payer du produit visé et a été scindé entre plusieurs produits actifs.
  final AllocationResult? allocation;
  final VoidCallback? onViewReceipt;
  final VoidCallback onDone;

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

/// Séquence (référence Checkout v3) — 3,2 s :
/// 0–19 % progression 88 → 100 %, puis cadenas → coche verte,
/// 28–50 % onde de sortie des anneaux, 42–68 % la coche remonte,
/// 58–92 % particules, 60 %+ textes en cascade, 85 %+ boutons.
class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.status == AnimationStatus.dismissed) {
      if (PfMotion.reduced(context)) {
        _c.value = 1;
      } else {
        _c.forward();
      }
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _seg(double v, double a, double b, [Curve curve = Curves.easeOutCubic]) =>
      curve.transform(((v - a) / (b - a)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final awaiting = w.awaitingAgentValidation;
    final Color accent = awaiting ? Pf.gold : Pf.success;
    final IconData icon = awaiting ? Icons.hourglass_top_rounded : Icons.check_rounded;

    final String title = awaiting
        ? 'Demande envoyée'
        : (w.gatewayConfirmed ? 'Paiement confirmé' : 'Cotisation validée');

    final splitNow = w.allocation != null && w.allocation!.wasSplit;
    final String message = awaiting
        ? 'Votre cotisation sera ajoutée à votre carnet après validation par votre agent.'
        : splitNow
            ? w.allocation!.toFrenchMessage()
            : 'C\'est fait ! Votre carnet est à jour.';

    final slots = w.slotsCount > 0 ? w.slotsCount : 1;
    final split = splitNow;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Pf.inkDeep,
        body: PaymentStageBackground(
          child: SafeArea(
            child: LayoutBuilder(builder: (context, box) {
              return AnimatedBuilder(
                animation: _c,
                builder: (context, _) {
                  final v = _c.value;
                  final progress = PaymentVerifyingOverlay.handoffProgress +
                      (1 - PaymentVerifyingOverlay.handoffProgress) * _seg(v, 0, 0.19);
                  final done = v >= 0.19;
                  final ripple = _seg(v, 0.28, 0.50);
                  final move = _seg(v, 0.42, 0.68, Curves.easeInOutCubic);
                  const stageSize = 300.0;
                  final startY = box.maxHeight * 0.46;
                  const endY = 104.0;
                  final cy = startY + (endY - startY) * move;
                  final scale = 1 - 0.26 * move;
                  double txt(int i) => _seg(v, 0.60 + i * 0.035, 0.78 + i * 0.035);
                  Widget rise(int i, Widget child) {
                    final t = txt(i);
                    return Opacity(opacity: t, child: Transform.translate(offset: Offset(0, 16 * (1 - t)), child: child));
                  }

                  final buttons = _seg(v, 0.85, 1);
                  return Stack(
                    children: [
                      // Contenu final
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Column(
                          children: [
                            const SizedBox(height: 228),
                            rise(0, Text(title, textAlign: TextAlign.center, style: Pf.title(color: Colors.white, size: 24))),
                            const SizedBox(height: Pf.s12),
                            rise(1, Text(formatFcfa(w.amount), textAlign: TextAlign.center, style: Pf.amount(size: 46, color: accent))),
                            const SizedBox(height: Pf.s8),
                            if (!split && w.productName != null && w.productName!.trim().isNotEmpty) ...[
                              rise(2, Text(w.productName!.trim(), textAlign: TextAlign.center, style: Pf.label(size: 16, color: Colors.white))),
                              const SizedBox(height: Pf.s8),
                            ],
                            rise(3, Text(message, textAlign: TextAlign.center, style: Pf.body(size: 14, color: Colors.white60))),
                            if (split) ...[
                              const SizedBox(height: Pf.s16),
                              rise(4, _AllocationBreakdownCard(allocation: w.allocation!)),
                            ],
                            const SizedBox(height: Pf.s16),
                            rise(4, Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                              ),
                              child: Text(
                                '$slots jour${slots > 1 ? 's' : ''} de plan · ${w.paymentModeLabel}',
                                textAlign: TextAlign.center,
                                style: Pf.label(size: 13, color: Colors.white),
                              ),
                            )),
                            const Spacer(),
                            Opacity(
                              opacity: buttons,
                              child: Transform.translate(
                                offset: Offset(0, 24 * (1 - buttons)),
                                child: Column(
                                  children: [
                                    SizedBox(
                                      width: double.infinity,
                                      height: 60,
                                      child: ElevatedButton(
                                        onPressed: buttons > 0.5 ? w.onDone : null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: AppColors.secondary,
                                          shape: const StadiumBorder(),
                                        ),
                                        child: Text('OK', style: Pf.label(size: 18, w: FontWeight.w900, color: AppColors.secondary)),
                                      ),
                                    ),
                                    if (w.onViewReceipt != null)
                                      TextButton.icon(
                                        onPressed: buttons > 0.5 ? w.onViewReceipt : null,
                                        icon: const Icon(Icons.receipt_long_rounded, size: 18, color: Colors.white70),
                                        label: Text('Voir le reçu', style: Pf.label(color: Colors.white70)),
                                      ),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Scène : anneaux → coche qui remonte
                      Positioned(
                        left: 0,
                        right: 0,
                        top: cy - stageSize / 2,
                        child: Center(
                          child: Transform.scale(
                            scale: scale,
                            child: SizedBox(
                              width: stageSize,
                              height: stageSize,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  PaymentSparkles(t: _seg(v, 0.58, 0.92, Curves.linear), radius: 120, color: accent),
                                  PaymentPulseStage(
                                    progress: progress,
                                    label: '',
                                    showPercent: false,
                                    done: done,
                                    doneIcon: icon,
                                    doneColor: accent,
                                    ripple: ripple,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Libellé + pourcentage pendant la fin de vérification
                      Positioned(
                        left: 0,
                        right: 0,
                        top: startY + stageSize / 2,
                        child: Opacity(
                          opacity: 1 - _seg(v, 0.30, 0.45),
                          child: Column(
                            children: [
                              Text(done ? 'Transaction sécurisée' : 'Vérification du paiement', style: Pf.body(color: Colors.white70, size: 13, w: FontWeight.w600)),
                              const SizedBox(height: Pf.s4),
                              Text('${(progress * 100).round()}%', style: Pf.num(size: 22, color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// Carte récapitulant la répartition automatique d'un paiement scindé entre
/// plusieurs produits (ex. « 200 F → Produit A · objectif atteint, 300 F → Produit B »).
class _AllocationBreakdownCard extends StatelessWidget {
  const _AllocationBreakdownCard({required this.allocation});

  final AllocationResult allocation;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.call_split_rounded, size: 16, color: Colors.white60),
              const SizedBox(width: 6),
              Text(
                'RÉPARTITION AUTOMATIQUE',
                style: AppTypography.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final line in allocation.lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      line.productName,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.manrope(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
                    ),
                  ),
                  if (line.goalReachedNow)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(Icons.check_circle_rounded, size: 15, color: const Color(0xFF38A169).withValues(alpha: 0.8)),
                    ),
                  Text(
                    formatFcfa(line.amountFcfa),
                    style: AppTypography.manrope(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.white),
                  ),
                ],
              ),
            ),
          if (allocation.unallocatedSurplusFcfa > 0) ...[
            const SizedBox(height: 4),
            Text(
              '${formatFcfa(allocation.unallocatedSurplusFcfa)} en attente d’affectation — contactez votre agent.',
              style: AppTypography.inter(fontSize: 11, color: Colors.orange.shade800, height: 1.3),
            ),
          ],
        ],
      ),
    );
  }
}
