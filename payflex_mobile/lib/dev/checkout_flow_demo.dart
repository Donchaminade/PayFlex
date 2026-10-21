import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/design/pf_components.dart';
import '../core/utils/money_format.dart';
import '../features/payment/payment_success_screen.dart';
import '../features/payment/widgets/payment_flow_stage.dart';

/// Démo du tunnel (vitrine) : reproduit le bouton de PaymentScreen
/// (même morph et mêmes durées), puis la vraie scène de vérification et le
/// vrai écran de succès. Le serveur est simulé par un délai de 2,4 s.
class CheckoutFlowDemo extends StatefulWidget {
  const CheckoutFlowDemo({super.key, this.autoplay = true});
  final bool autoplay;
  @override
  State<CheckoutFlowDemo> createState() => _CheckoutFlowDemoState();
}

class _CheckoutFlowDemoState extends State<CheckoutFlowDemo> {
  bool _processing = false;
  int _morph = 0;

  @override
  void initState() {
    super.initState();
    if (widget.autoplay) Future.delayed(const Duration(milliseconds: 1500), _pay);
  }

  Future<void> _pay() async {
    if (!mounted) return;
    setState(() {
      _processing = true;
      _morph = 1;
    });
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _morph = 2);
    await Future.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    setState(() => _morph = 3);
    await Future.delayed(const Duration(milliseconds: 2400)); // « serveur »
    if (!mounted) return;
    await Navigator.of(context).push(PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 220),
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
      pageBuilder: (c, _, __) => PaymentSuccessScreen(
        amount: 1300,
        awaitingAgentValidation: false,
        gatewayConfirmed: true,
        paymentModeLabel: 'Payé via T-Money',
        slotsCount: 2,
        productName: 'Machine à coudre Juki Pro',
        onViewReceipt: () {},
        onDone: () => Navigator.of(c).pop(),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final collapsed = _processing && _morph >= 2;
    return Scaffold(
      backgroundColor: Pf.canvas,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Pf.gutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: Pf.s16),
                  Text('Valider une cotisation', style: Pf.body(size: 13, w: FontWeight.w600)),
                  const SizedBox(height: Pf.s4),
                  Text('Cotiser', style: Pf.display()),
                  const SizedBox(height: Pf.s24),
                  PfFeaturedCard(
                    badge: 'MOBILE MONEY',
                    title: 'T-Money · +228 90 •• •• 56',
                    subtitle: 'Machine à coudre Juki Pro',
                    height: 160,
                  ),
                  const SizedBox(height: Pf.s24),
                  Text('Montant', style: Pf.body()),
                  Text(formatFcfaLong(1300), style: Pf.amount(size: 40)),
                  const SizedBox(height: Pf.s24),
                  PfCard(
                    child: Column(children: [
                      _row('Cotisation', formatFcfa(1300)),
                      const SizedBox(height: Pf.s8),
                      _row('Jours de plan', '2'),
                      const Divider(height: Pf.s24),
                      _row('Total', formatFcfaLong(1300), bold: true),
                    ]),
                  ),
                  const Spacer(),
                  Center(
                    child: LayoutBuilder(builder: (context, c) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 420),
                        curve: Curves.easeInOutCubic,
                        width: collapsed ? 60 : c.maxWidth,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: _processing ? () {} : _pay,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.secondary,
                            minimumSize: const Size(60, 60),
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(collapsed ? 18 : 30)),
                            elevation: 0,
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: !_processing
                                ? Row(key: const ValueKey('i'), mainAxisAlignment: MainAxisAlignment.center, children: [
                                    const Icon(Icons.lock_rounded, size: 18),
                                    const SizedBox(width: Pf.s8),
                                    Text('Confirmer le paiement', style: Pf.label(size: 16, w: FontWeight.w800)),
                                  ])
                                : collapsed
                                    ? const SizedBox(key: ValueKey('s'), width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.secondary))
                                    : Row(key: const ValueKey('p'), mainAxisAlignment: MainAxisAlignment.center, children: [
                                        const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.secondary)),
                                        const SizedBox(width: Pf.s12),
                                        Text('Traitement…', style: Pf.label(size: 16, w: FontWeight.w800)),
                                      ]),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: Pf.s24),
                ],
              ),
            ),
          ),
          if (_processing && _morph >= 3) const Positioned.fill(child: PaymentVerifyingOverlay()),
        ],
      ),
    );
  }

  Widget _row(String a, String b, {bool bold = false}) => Row(children: [
        Text(a, style: bold ? Pf.label() : Pf.body()),
        const Spacer(),
        Text(b, style: Pf.num(size: bold ? 16 : 14)),
      ]);
}
