import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'payment_checkout_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/design/pf_components.dart';
import '../../core/constants/app_colors.dart';
import '../../core/database/database_service.dart';
import '../../core/models/allocation_result.dart';
import '../../core/providers/finance_provider.dart';
import '../../core/providers/navigation_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/network/mobile_api_service.dart';
import '../../core/utils/money_format.dart';
import '../../core/widgets/payflex_phone_field.dart';
import '../../core/utils/phone_input_utils.dart';
import 'contribution_receipt_screen.dart';
import 'payment_success_screen.dart';
import 'widgets/payment_flow_stage.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  final TextEditingController _amountController = TextEditingController();
  String _selectedMethod = 'mobile_money';
  String _selectedMobileProvider = 'Flooz';
  String? _selectedProjectId;
  bool _isProcessing = false;
  /// Garde la scène visible entre la fin du traitement et l'écran de succès.
  bool _handingOff = false;
  /// Morphing du bouton (réf. Checkout v3) : 0 normal, 1 « Traitement… », 2 réduit en carré.
  int _morph = 0;
  bool _useAlternatePayerPhone = false;
  // PayDunya = passerelle mobile money unique. Masquée si le backend ne l'a pas configurée.
  bool _paydunyaAvailable = false;
  final TextEditingController _payerPhoneController = TextEditingController();
  final GlobalKey<FormState> _payerPhoneFormKey = GlobalKey<FormState>();

  final List<String> _presetsExtra = ['1000', '2500', '5000', '10000', '25000'];
  final _mobileApi = MobileApiService();

  @override
  void initState() {
    super.initState();
    _loadPaymentProviders();
  }

  /// Repli gracieux : on masque le mobile money si PayDunya n'est pas configuré (clés absentes)
  /// → il ne reste que la déclaration classique / espèces.
  Future<void> _loadPaymentProviders() async {
    final providers = await _mobileApi.fetchPaymentProviders();
    if (!mounted) return;
    setState(() {
      _paydunyaAvailable = providers.paydunyaEnabled;
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _payerPhoneController.dispose();
    super.dispose();
  }

  double get _dailyRate {
    final fin = ref.read(financeProvider);
    if (_selectedProjectId == null) return 0;
    try {
      return fin.projects.firstWhere((p) => p.id == _selectedProjectId).dailySuggested;
    } catch (_) {
      return fin.projects.isNotEmpty ? fin.projects.first.dailySuggested : 0;
    }
  }

  int get _casesCount {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final dailyRate = _dailyRate;
    if (dailyRate <= 0 || amount <= 0) return 0;
    return (amount / dailyRate).floor();
  }

  bool _isGoalReached(ProjectModel p) {
    return p.total > 0 && p.saved >= p.total;
  }

  List<String> _presetAmounts(double daily) {
    final base = <String>{..._presetsExtra};
    if (daily > 0) {
      base.add(daily.ceil().toString());
      base.add((daily * 7).ceil().toString());
      base.add((daily * 30).ceil().toString());
    }
    final sorted = base.map((s) => int.tryParse(s) ?? 0).where((n) => n > 0).toSet().toList()..sort();
    return sorted.take(9).map((n) => n.toString()).toList();
  }

  @override
  Widget build(BuildContext context) {
    final financeState = ref.watch(financeProvider);
    final auth = ref.watch(authProvider);
    final projects = financeState.projects;
    final goalReachedIds = projects.where(_isGoalReached).map((p) => p.id).toSet();
    final selectableProjects = projects.where((p) => !goalReachedIds.contains(p.id)).toList();
    final hasSelectable = selectableProjects.isNotEmpty;
    final projectLocked = _selectedProjectId != null && goalReachedIds.contains(_selectedProjectId);
    final ids = selectableProjects.map((p) => p.id).toList();
    if (_selectedProjectId == null || (_selectedProjectId != null && !ids.contains(_selectedProjectId))) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _selectedProjectId = ids.isNotEmpty ? ids.first : null);
      });
    }
    final daily = _dailyRate;
    final presets = _presetAmounts(daily);

    return Scaffold(
      backgroundColor: Pf.canvas,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        automaticallyImplyLeading: false, // PAS de flèche retour automatique
        toolbarHeight: 96,
        titleSpacing: Pf.gutter,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Valider une cotisation', style: Pf.body(size: 13, w: FontWeight.w600)),
            const SizedBox(height: Pf.s4),
            Text('Cotiser', style: Pf.display()),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Contenu scrollable
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (projects.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Text(
                        'Aucun projet d’épargne.\nChoisissez un produit dans le catalogue pour cotiser.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: AppColors.secondary.withOpacity(0.7)),
                      ),
                    ),
                  )
                else ...[
                // === CARTE CLIENT ===
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: Pf.featuredGradient,
                    borderRadius: Pf.br(Pf.rXxl),
                    boxShadow: Pf.shadowLift,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.primary.withOpacity(0.25),
                        child: Text(
                          (auth.name != null && auth.name!.trim().isNotEmpty)
                              ? auth.name!.trim()[0].toUpperCase()
                              : 'P',
                          style: GoogleFonts.manrope(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(auth.name ?? 'Client PayFlex',
                              style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                            Text(
                              auth.uniqueCode != null && auth.uniqueCode!.trim().isNotEmpty
                                  ? 'Code : ${auth.uniqueCode}'
                                  : (auth.phone ?? '—'),
                              style: GoogleFonts.inter(color: Colors.white.withOpacity(0.5), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      // Badge solde
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                        ),
                        child: Text(
                          formatFcfaLong(financeState.balance),
                          style: GoogleFonts.manrope(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: 0.1),

                const SizedBox(height: 28),

                // === SÉLECTION PROJET ===
                _sectionTitle('PROJET CIBLE'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Pf.surface,
                    borderRadius: Pf.br(Pf.rLg),
                    border: Border.all(color: Pf.line),
                    boxShadow: Pf.shadowSoft,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedProjectId != null && ids.contains(_selectedProjectId) ? _selectedProjectId : null,
                      isExpanded: true,
                      dropdownColor: Pf.surface,
                      borderRadius: Pf.br(Pf.rLg),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Pf.ink),
                      style: Pf.label(),
                      hint: Text('Choisir un projet', style: Pf.body()),
                      items: projects
                          .map(
                            (p) {
                              final disabled = goalReachedIds.contains(p.id);
                              return DropdownMenuItem<String>(
                                value: p.id,
                                enabled: !disabled,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        p.title,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: disabled ? Pf.faint : Pf.ink,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    if (disabled)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        margin: const EdgeInsets.only(left: 8),
                                        decoration: BoxDecoration(
                                          color: Pf.fill,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          'Objectif atteint',
                                          style: GoogleFonts.inter(
                                            color: Pf.muted,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ).toList(),
                      onChanged: (v) async {
                        if (v != null && goalReachedIds.contains(v)) return;
                        setState(() => _selectedProjectId = v);
                        final uid = ref.read(authProvider).userId;
                        if (v != null && uid != null) {
                          await DatabaseService().setUserCurrentProject(uid, v);
                          await ref.read(financeProvider.notifier).reload();
                        }
                      },
                    ),
                  ),
                ).animate().fadeIn(delay: 100.ms),
                if (daily > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Référence plan : ~${formatFcfaLong(daily)} / jour pour ce projet.',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.secondary.withOpacity(0.45)),
                  ),
                ],
                if (projects.isNotEmpty && selectableProjects.isEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Objectif déjà atteint pour vos projets. Ajoutez un nouvel article dans le catalogue pour continuer à épargner.',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.secondary.withOpacity(0.6)),
                  ),
                ] else if (goalReachedIds.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Les projets en gris sont verrouillés car leur objectif est atteint.',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.secondary.withOpacity(0.55)),
                  ),
                ],

                const SizedBox(height: 24),

                // === SAISIE MONTANT ===
                _sectionTitle('MONTANT DE LA COTISATION'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))],
                    border: Border.all(color: AppColors.secondary.withOpacity(0.05)),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        onChanged: (_) => setState(() {}),
                        style: Pf.amount(size: 48, color: Pf.ink),
                        decoration: InputDecoration(
                          hintText: '0',
                          hintStyle: TextStyle(color: AppColors.secondary.withOpacity(0.1)),
                          filled: false,
                          suffixText: 'FCFA',
                          suffixStyle: GoogleFonts.manrope(
                            fontWeight: FontWeight.w900, color: AppColors.secondary.withOpacity(0.3), fontSize: 14,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Presets
                      Wrap(
                        spacing: 10, runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: presets.map((p) {
                          final isSelected = _amountController.text == p;
                          return GestureDetector(
                            onTap: () => setState(() => _amountController.text = p),
                            child: AnimatedContainer(
                              duration: 200.ms,
                              constraints: const BoxConstraints(minWidth: 64, minHeight: 48),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? Pf.ink : Pf.fill,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: isSelected ? AppColors.primary : Colors.transparent),
                              ),
                              child: Text(
                                formatFcfa(int.parse(p)),
                                style: GoogleFonts.manrope(
                                  fontWeight: FontWeight.w800,
                                  color: isSelected ? Pf.gold : Pf.ink,
                                  fontSize: 15,
                                ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms),

                // Indicateur de cases cochées
                if (_casesCount > 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FFF4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF38A169).withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF38A169), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.manrope(color: const Color(0xFF38A169), fontSize: 13),
                              children: [
                                TextSpan(
                                  text: '$_casesCount case${_casesCount > 1 ? "s" : ""} ',
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                                ),
                                const TextSpan(text: 'seront cochées dans votre carnet'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),
                ],

                const SizedBox(height: 24),

                // === MODE DE PAIEMENT ===
                _sectionTitle('MODE DE PAIEMENT'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _paymentMethodCard(
                      'mobile_money',
                      Icons.phone_android_rounded,
                      'Mobile Money',
                      'Orange / MTN',
                    ),
                    const SizedBox(width: 12),
                    _paymentMethodCard(
                      'cash',
                      Icons.payments_rounded,
                      'Espèces',
                      'Via Agent',
                    ),
                  ],
                ).animate().fadeIn(delay: 300.ms),
                if (_selectedMethod == 'mobile_money') ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.secondary.withOpacity(0.08)),
                    ),
                    child: Row(
                      children: [
                        _providerChip('Flooz'),
                        const SizedBox(width: 8),
                        _providerChip('Mix by Yas'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _payerPhoneSection(),
                ],

                const SizedBox(height: 36),

                // === BOUTON CONFIRMER (morph « Traitement… » → carré, réf. Checkout v3) ===
                Center(
                  child: LayoutBuilder(builder: (context, c) {
                    final collapsed = _isProcessing && _morph >= 2;
                    final enabled = !(projects.isEmpty || _amountController.text.isEmpty || _isProcessing || !hasSelectable || projectLocked);
                    return AnimatedContainer(
                      duration: PfMotion.reduced(context) ? Duration.zero : const Duration(milliseconds: 420),
                      curve: Curves.easeInOutCubic,
                      width: collapsed ? 60 : c.maxWidth,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: enabled ? () => _processPayment(context) : (_isProcessing ? () {} : null),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.secondary,
                          disabledBackgroundColor: Pf.fill,
                          minimumSize: const Size(60, 60),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(collapsed ? 18 : 30)),
                          elevation: 0,
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: !_isProcessing
                              ? Row(
                                  key: const ValueKey('idle'),
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.lock_rounded, size: 18),
                                    const SizedBox(width: Pf.s8),
                                    Text('Confirmer le paiement', style: Pf.label(size: 16, w: FontWeight.w800)),
                                  ],
                                )
                              : collapsed
                                  ? const SizedBox(key: ValueKey('sq'), width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.secondary))
                                  : Row(
                                      key: const ValueKey('proc'),
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.secondary)),
                                        const SizedBox(width: Pf.s12),
                                        Text('Traitement…', style: Pf.label(size: 16, w: FontWeight.w800)),
                                      ],
                                    ),
                        ),
                      ),
                    );
                  }),
                ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
              ],
            ],
          ),
          ),
          // Anneau de progression pendant le traitement → écran de succès
          // Scène de vérification (anneaux dorés) après le morphing du bouton
          if ((_isProcessing && _morph >= 3) || _handingOff)
            const Positioned.fill(child: PaymentVerifyingOverlay()),
        ],
      ),
    );
  }

  Widget _paymentMethodCard(String id, IconData icon, String title, String subtitle) {
    final isSelected = _selectedMethod == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMethod = id),
        child: AnimatedContainer(
          duration: 200.ms,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: isSelected ? Pf.featuredGradient : null,
            color: isSelected ? null : Pf.surface,
            borderRadius: Pf.br(Pf.rLg),
            border: Border.all(color: isSelected ? Pf.ink : Pf.line, width: 1.5),
            boxShadow: isSelected ? Pf.shadowLift : Pf.shadowSoft,
          ),
          child: Column(
            children: [
              Icon(icon, size: 30, color: isSelected ? AppColors.primary : AppColors.secondary.withOpacity(0.5)),
              const SizedBox(height: 8),
              Text(title, style: GoogleFonts.manrope(
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : AppColors.secondary,
                fontSize: 13,
              )),
              Text(subtitle, style: GoogleFonts.inter(
                color: isSelected ? Colors.white.withOpacity(0.6) : Colors.grey,
                fontSize: 10,
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    final t = title.toLowerCase();
    return Text(t[0].toUpperCase() + t.substring(1), style: Pf.title(size: 17));
  }

  /// Timing du morph : 0,5 s « Traitement… », 0,45 s réduction, puis scène.
  Future<void> _runButtonMorph() async {
    final reduced = PfMotion.reduced(context);
    await Future.delayed(Duration(milliseconds: reduced ? 0 : 500));
    if (!mounted || !_isProcessing) return;
    setState(() => _morph = 2);
    await Future.delayed(Duration(milliseconds: reduced ? 0 : 450));
    if (!mounted || !_isProcessing) return;
    setState(() => _morph = 3);
  }

  Future<void> _processPayment(BuildContext context) async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return;

    final paymentMode = _selectedMethod == 'mobile_money' ? 'mobile_money' : 'cash';
    final financeState = ref.read(financeProvider);
    ProjectModel? selectedProject;
    try {
      selectedProject = financeState.projects.firstWhere((p) => p.id == _selectedProjectId);
    } catch (_) {
      selectedProject = null;
    }
    if (selectedProject == null) {
      _showErrorSnack(context, 'Sélectionnez d’abord un projet actif.');
      return;
    }
    if (_isGoalReached(selectedProject)) {
      _showErrorSnack(context, 'Objectif atteint pour ce projet. Choisissez un autre produit.');
      return;
    }

    String? payerPhone;
    if (paymentMode == 'mobile_money' && _useAlternatePayerPhone) {
      if (!(_payerPhoneFormKey.currentState?.validate() ?? false)) {
        return;
      }
      final entered = _payerPhoneController.text.trim();
      if (entered.isNotEmpty) payerPhone = entered;
    }

    setState(() {
      _isProcessing = true;
      _morph = 1;
    });
    _runButtonMorph();

    final auth = ref.read(authProvider);
    final authPhone = auth.phone?.trim() ?? '';
    final authPin = auth.pin?.trim() ?? '';
    final productIdApi = _selectedProjectId != null
        ? int.tryParse(_selectedProjectId!.replaceAll(RegExp(r'[^0-9]'), ''))
        : null;
    String? serverContributionId;
    var gatewayValidated = false;
    AllocationResult? allocation;

    if (auth.userId != null && paymentMode == 'mobile_money') {
      if (authPhone.isEmpty || authPin.isEmpty) {
        setState(() => _isProcessing = false);
        _showErrorSnack(context, 'Session invalide. Reconnectez-vous.');
        return;
      }
      final gatewayInit = await _mobileApi.initPaydunyaContribution(
        userId: auth.userId!,
        phone: authPhone,
        pin: authPin,
        amount: amount,
        productId: productIdApi,
        payerPhone: payerPhone,
      );
      if (gatewayInit == null) {
        setState(() => _isProcessing = false);
        _showErrorSnack(context, 'Impossible de joindre le serveur. Réessayez.');
        return;
      }
      if (gatewayInit['error'] != null) {
        setState(() => _isProcessing = false);
        _showErrorSnack(context, gatewayInit['error'].toString());
        return;
      }
      final gatewayOn = gatewayInit['paydunyaEnabled'] == true;
      final paymentUrl = gatewayInit['paymentUrl']?.toString() ?? '';
      final contributionId = (gatewayInit['contributionId'] as num?)?.toInt();
      final callbackUrl = gatewayInit['callbackUrl']?.toString() ?? '';
      if (mounted && gatewayOn && !_paydunyaAvailable) {
        // Si la détection initiale a échoué (réseau), on réactive PayDunya pour la session.
        setState(() => _paydunyaAvailable = true);
      }
      if (gatewayOn && paymentUrl.isNotEmpty && contributionId != null && context.mounted) {
        serverContributionId = contributionId.toString();
        setState(() => _isProcessing = false);
        final checkout = await Navigator.of(context).push<PaymentCheckoutResult>(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => PaymentCheckoutScreen(
              paymentUrl: paymentUrl,
              contributionId: contributionId,
              userId: auth.userId!,
              phone: authPhone,
              pin: authPin,
              amountFcfa: amount.round(),
              callbackUrl: callbackUrl,
            ),
          ),
        );
        if (!context.mounted) return;
        if (checkout == null || checkout.outcome == PaymentCheckoutOutcome.cancelled) {
          _showErrorSnack(context, 'Paiement annulé. Vous pouvez réessayer quand vous voulez.');
          return;
        }
        if (checkout.outcome == PaymentCheckoutOutcome.rejected) {
          _showErrorSnack(context, 'Paiement non confirmé par PayDunya.');
          return;
        }
        gatewayValidated = checkout.outcome == PaymentCheckoutOutcome.validated;
        allocation = checkout.allocation;
      } else {
        if (gatewayOn && paymentUrl.isEmpty && context.mounted) {
          _showErrorSnack(context, 'Lien PayDunya indisponible. Cotisation enregistrée pour validation manuelle.');
        } else if (!gatewayOn && gatewayInit['message'] != null && context.mounted) {
          _showErrorSnack(
            context,
            gatewayInit['message']?.toString() ??
                'PayDunya indisponible. Cotisation enregistrée pour validation manuelle.',
          );
        }
        // PayDunya non configuré, indisponible ou sans URL → déclaration classique
        final apiRes = await _mobileApi.sendContribution(
          userId: auth.userId!,
          phone: authPhone,
          pin: authPin,
          amount: amount,
          paymentMode: paymentMode,
          productId: productIdApi,
        );
        final errorMessage = apiRes?['error']?.toString();
        if (errorMessage != null) {
          setState(() => _isProcessing = false);
          _showErrorSnack(context, errorMessage);
          return;
        }
        if (apiRes == null) {
          setState(() => _isProcessing = false);
          _showErrorSnack(context, 'Cotisation non enregistrée. Vérifiez votre connexion.');
          return;
        }
        serverContributionId = apiRes['id']?.toString();
      }
    } else {
      // Déclaration classique (espèces)
      if (auth.userId != null) {
        if (authPhone.isEmpty || authPin.isEmpty) {
          setState(() => _isProcessing = false);
          _showErrorSnack(context, 'Session invalide. Reconnectez-vous.');
          return;
        }
        final apiRes = await _mobileApi.sendContribution(
          userId: auth.userId!,
          phone: authPhone,
          pin: authPin,
          amount: amount,
          paymentMode: paymentMode,
          productId: productIdApi,
        );
        final errorMessage = apiRes?['error']?.toString();
        if (errorMessage != null) {
          setState(() => _isProcessing = false);
          _showErrorSnack(context, errorMessage);
          return;
        }
        if (apiRes == null) {
          setState(() => _isProcessing = false);
          _showErrorSnack(context, 'Cotisation non enregistrée. Vérifiez votre connexion.');
          return;
        }
        serverContributionId = apiRes['id']?.toString();
      } else {
        await Future.delayed(const Duration(milliseconds: 400));
      }
    }

    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _handingOff = true;
    });
    final recorded = await ref.read(financeProvider.notifier).addContribution(
      amount,
      paymentMode: paymentMode,
      contributorUserId: auth.userId,
      transactionId: serverContributionId,
    );
    if (!recorded && mounted) setState(() => _handingOff = false);
    if (!recorded && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Aucun projet d’épargne actif. Choisissez d’abord un produit dans le catalogue.',
            style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (!context.mounted) return;
    _showSuccessDialog(
      context,
      amount,
      awaitingAgentValidation: paymentMode == 'mobile_money' && !gatewayValidated,
      gatewayConfirmed: gatewayValidated,
      allocation: allocation,
    );
  }

  void _showErrorSnack(BuildContext context, String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessDialog(
    BuildContext context,
    double amount, {
    required bool awaitingAgentValidation,
    bool gatewayConfirmed = false,
    AllocationResult? allocation,
  }) {
    final fin = ref.read(financeProvider);
    double rate = 0;
    String? productName;
    if (_selectedProjectId != null) {
      try {
        final p = fin.projects.firstWhere((p) => p.id == _selectedProjectId);
        rate = p.dailySuggested;
        productName = p.title;
      } catch (_) {
        rate = fin.projects.isNotEmpty ? fin.projects.first.dailySuggested : 0;
        productName = fin.projects.isNotEmpty ? fin.projects.first.title : null;
      }
    }
    final slotsApprox = rate > 0 ? (amount / rate).floor() : _casesCount;
    final slotsLabel = slotsApprox > 0 ? slotsApprox : _casesCount;

    final refTx = 'PF-${DateTime.now().millisecondsSinceEpoch}';
    final paidAt = DateTime.now();
    final paymentModeLabel =
        _selectedMethod == 'mobile_money' ? 'Payé via $_selectedMobileProvider' : 'Payé en espèces (Agent)';

    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
        pageBuilder: (screenContext, _, __) => PaymentSuccessScreen(
          amount: amount,
          awaitingAgentValidation: awaitingAgentValidation,
          gatewayConfirmed: gatewayConfirmed,
          paymentModeLabel: paymentModeLabel,
          slotsCount: slotsLabel,
          productName: productName,
          allocation: allocation,
          onDone: () {
            ref.read(navigationIndexProvider.notifier).setIndex(0);
            Navigator.of(screenContext).pop();
          },
          onViewReceipt: () {
            Navigator.of(screenContext).pop();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ContributionReceiptScreen(
                  amount: amount,
                  reference: refTx,
                  paidAt: paidAt,
                  paymentModeLabel: paymentModeLabel,
                  slotsCount: slotsLabel,
                  awaitingValidation: awaitingAgentValidation,
                ),
              ),
            );
          },
        ),
      ),
    ).then((_) {
      if (mounted) setState(() => _handingOff = false);
    });
  }

  Widget _payerPhoneSection() {
    final auth = ref.watch(authProvider);
    final accountPhone = (auth.phone != null && auth.phone!.trim().isNotEmpty)
        ? auth.phone!.trim()
        : 'Numéro du compte';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.smartphone_rounded, size: 18, color: AppColors.secondary.withOpacity(0.6)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Numéro de paiement',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: AppColors.secondary,
                      ),
                    ),
                    Text(
                      _useAlternatePayerPhone ? 'Autre numéro Mobile Money' : accountPhone,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.secondary.withOpacity(0.55),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _useAlternatePayerPhone = !_useAlternatePayerPhone),
            child: Row(
              children: [
                Icon(
                  _useAlternatePayerPhone
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Utiliser un autre numéro',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_useAlternatePayerPhone) ...[
            const SizedBox(height: 12),
            Form(
              key: _payerPhoneFormKey,
              child: PayflexPhoneField(
                completeNumberController: _payerPhoneController,
                hint: 'Numéro du payeur (Flooz / Mixx by Yas)',
                validator: (v) => PayflexPhoneValidator.validate(v),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Le paiement Mobile Money sera demandé sur ce numéro.',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.secondary.withOpacity(0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _providerChip(String label) {
    final isSelected = _selectedMobileProvider == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMobileProvider = label),
        child: AnimatedContainer(
          duration: 200.ms,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.secondary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isSelected ? AppColors.secondary : AppColors.secondary.withOpacity(0.7),
            ),
          ),
        ),
      ),
    );
  }
}
