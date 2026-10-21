import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/design/pf_code_input.dart';
import '../../core/design/pf_components.dart';
import '../payment/widgets/payment_flow_stage.dart';
import 'widgets/auth_wave_background.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_config.dart';
import '../../core/network/payflex_api_logger.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/utils/user_visible_message.dart';
import '../../core/widgets/payflex_sweet_alert.dart';
import '../agent/agent_main_navigation_screen.dart';
import '../main_navigation_screen.dart';
import '../../core/providers/navigation_provider.dart';
import '../../core/services/notification_permission_flow.dart';

class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  final TextEditingController _code = TextEditingController();
  final GlobalKey<PfCodeInputState> _codeKey = GlobalKey<PfCodeInputState>();
  bool _submitting = false;
  /// Scène de vérification (réf. Checkout v3) : null = masquée.
  VerificationResult? _stage;
  bool _stageVisible = false;
  bool _codeError = false;
  Completer<void>? _stageDone;
  bool _pinVisible = false;
  Map<String, dynamic>? _cachedRegistrationData;

  static const Duration _submitTimeout = Duration(seconds: 35);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cacheRegistrationData());
  }

  void _cacheRegistrationData() {
    final fromProvider = ref.read(tempRegistrationDataProvider);
    if (fromProvider.isNotEmpty) {
      setState(() => _cachedRegistrationData = Map<String, dynamic>.from(fromProvider));
    }
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  String get _pin => _code.text;

  Map<String, dynamic> _registrationData() {
    if (_cachedRegistrationData != null && _cachedRegistrationData!.isNotEmpty) {
      return _cachedRegistrationData!;
    }
    final fromProvider = ref.read(tempRegistrationDataProvider);
    if (fromProvider.isNotEmpty) {
      _cachedRegistrationData = Map<String, dynamic>.from(fromProvider);
      return _cachedRegistrationData!;
    }
    return const {};
  }

  Future<void> _goToClientHome({bool showSuccessDialog = true}) async {
    ref.read(navigationIndexProvider.notifier).setIndex(0);
    const home = MainNavigationScreen();
    if (!mounted) return;
    if (showSuccessDialog) {
      await PayflexSweetAlert.showSuccess(
        context: context,
        title: 'Inscription réussie',
      text:
          'Votre compte PayFlex est actif.\n\n'
          'Finalisez votre adhésion (250 FCFA) pour activer les cotisations et les paiements : '
          'mobile money dans l’app ou espèces auprès de votre agent parrain.',
        confirmText: 'Découvrir l’application',
      );
      if (!mounted) return;
    }
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => home),
      (_) => false,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      requestPayflexNotificationsIfNeeded();
    });
    ref.read(tempRegistrationDataProvider.notifier).clear();
    ref.read(tempRoleProvider.notifier).setRole(null);
    ref.read(tempClientProfileProvider.notifier).setProfile(null);
    _cachedRegistrationData = null;
  }

  Future<void> _finishRegistrationSuccess({
    required String role,
    required String pin,
    required Map<String, dynamic> data,
    int? registrationId,
  }) async {
    final phone = (data['phone'] ?? '').toString().trim();
    PayflexApiLogger.info(
      'PIN terminé → login auto phone=${PayflexApiLogger.maskPhone(phone)} '
      'registrationId=$registrationId api=${ApiConfig.baseUrl}',
    );
    final loginOutcome = await ref.read(authProvider.notifier).login(phone, pin, loginMode: 'phone');
    if (!loginOutcome.success) {
      PayflexApiLogger.warn(
        'Login post-inscription échoué: ${loginOutcome.errorMessage} — session pending locale',
      );
      await ref.read(authProvider.notifier).establishPendingRegistrationSession(
            role: role,
            pin: pin,
            data: data,
            registrationId: registrationId,
          );
    } else {
      PayflexApiLogger.info('Login post-inscription OK');
    }

    if (!mounted) return;
    setState(() => _submitting = false);

    if (role == 'agent') {
      ref.read(agentNavigationIndexProvider.notifier).setIndex(0);
      if (!mounted) return;
      await PayflexSweetAlert.showSuccess(
        context: context,
        title: 'Inscription réussie',
        text: 'Vos informations ont bien été enregistrées.',
        confirmText: 'Continuer',
      );
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const AgentMainNavigationScreen()),
        (_) => false,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        requestPayflexNotificationsIfNeeded();
      });
      ref.read(tempRegistrationDataProvider.notifier).clear();
      ref.read(tempRoleProvider.notifier).setRole(null);
      _cachedRegistrationData = null;
      return;
    }

    await _goToClientHome();
  }

  Future<bool> _tryRecoverAfterFailedSubmit({
    required String role,
    required String pin,
    required Map<String, dynamic> data,
    String? serverMessage,
  }) async {
    final phone = (data['phone'] ?? '').toString().trim();
    if (phone.isEmpty) return false;

    final recoveredId = await ref.read(authProvider.notifier).findPendingRegistrationIdForPhone(phone);
    if (recoveredId != null) {
      await _finishRegistrationSuccess(
        role: role,
        pin: pin,
        data: data,
        registrationId: recoveredId,
      );
      return true;
    }

    final loginOutcome = await ref.read(authProvider.notifier).login(phone, pin, loginMode: 'phone');
    if (loginOutcome.success) {
      await _finishRegistrationSuccess(role: role, pin: pin, data: data);
      return true;
    }

    final msg = (serverMessage ?? '').toLowerCase();
    if (msg.contains('déjà utilisé') || msg.contains('deja utilise')) {
      await ref.read(authProvider.notifier).establishPendingRegistrationSession(
            role: role,
            pin: pin,
            data: data,
          );
      await _goToClientHome();
      return true;
    }

    return false;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final pin = _pin;
    if (pin.length != 4) {
      setState(() => _codeError = true);
      _codeKey.currentState?.shake();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer 4 chiffres')),
      );
      return;
    }

    final auth = ref.read(authProvider);
    if (auth.isAuthenticated && auth.role == 'client') {
      await _goToClientHome(showSuccessDialog: false);
      return;
    }

    const role = 'client';
    final data = _registrationData();
    if (data.isEmpty) {
      if (auth.isAuthenticated) {
        await _goToClientHome(showSuccessDialog: false);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Données d’inscription manquantes. Si vous venez de vous inscrire, connectez-vous avec votre numéro et votre code PIN.',
          ),
          duration: Duration(seconds: 6),
        ),
      );
      return;
    }

    setState(() {
      _submitting = true;
      _codeError = false;
    });
    // La scène s'affiche quand le bouton a fini son morph (voir PfMorphButton.onCollapsed).

    try {
      final result = await ref
          .read(authProvider.notifier)
          .submitPendingRegistration(role: role, pin: pin, data: data)
          .timeout(_submitTimeout);

      if (!mounted) return;

      if (!result.success) {
        final recovered = await _tryRecoverAfterFailedSubmit(
          role: role,
          pin: pin,
          data: data,
          serverMessage: result.message,
        );
        if (recovered) return;
        if (!mounted) return;
        await _endStage(VerificationResult.failure);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              UserVisibleMessage.apiOrFallback(
                result.message,
                'Impossible de finaliser l’inscription. Vérifiez votre connexion ou contactez le support.',
              ),
            ),
            duration: const Duration(seconds: 5),
          ),
        );
        return;
      }

      await _endStage(VerificationResult.success);
      if (!mounted) return;
      await _finishRegistrationSuccess(role: role, pin: pin, data: data, registrationId: result.registrationId);
    } on TimeoutException {
      if (!mounted) return;

      final recovered = await _tryRecoverAfterFailedSubmit(role: role, pin: pin, data: data);
      if (recovered) return;

      if (!mounted) return;
      await _endStage(VerificationResult.failure);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connexion lente : réessayez. Évitez d’appuyer plusieurs fois sur le bouton.'),
          duration: Duration(seconds: 6),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      final recovered = await _tryRecoverAfterFailedSubmit(
        role: role,
        pin: pin,
        data: data,
        serverMessage: UserVisibleMessage.forException(e),
      );
      if (recovered) return;

      if (!mounted) return;
      await _endStage(VerificationResult.failure);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UserVisibleMessage.forException(e))),
      );
    }
  }

  /// Termine la scène : succès (coche) ou échec (croix rouge → retour à la
  /// saisie, cases rouges + secousse). N'influe pas sur la logique serveur.
  Future<void> _endStage(VerificationResult r) async {
    if (!_stageVisible) {
      // Réponse plus rapide que le morph du bouton : afficher la scène d'abord.
      setState(() {
        _stageVisible = true;
        _stage = VerificationResult.pending;
      });
      await Future.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
    }
    final done = Completer<void>();
    setState(() {
      _stage = r;
      _stageDone = done;
    });
    await done.future.timeout(const Duration(seconds: 3), onTimeout: () {});
    if (!mounted) return;
    if (r == VerificationResult.failure) {
      setState(() {
        _stageVisible = false;
        _stage = null;
        _submitting = false;
        _codeError = true;
      });
      _codeKey.currentState?.shake();
    }
  }

  void _handleBack() {
    if (_submitting) return;
    final auth = ref.read(authProvider);
    if (auth.isAuthenticated && auth.role == 'client') {
      unawaited(_goToClientHome(showSuccessDialog: false));
      return;
    }
    Navigator.maybePop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _submitting) return;
        _handleBack();
      },
      child: Stack(
        children: [
          AuthWaveBackground(
        child: SafeArea(
          child: AbsorbPointer(
            absorbing: _submitting,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: _submitting ? null : _handleBack,
                    icon: const Icon(Icons.arrow_back),
                    color: AppColors.secondary,
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Créer votre code PIN',
                          style: GoogleFonts.manrope(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Entrez un code à 4 chiffres',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 600.ms),
                  const SizedBox(height: 48),
                  Center(
                    child: Container(
                      width: 100,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.lock_rounded, color: AppColors.secondary, size: 50),
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms).scale(),
                  const SizedBox(height: 40),
                  Center(
                    child: Text(
                      'Ce code PIN vous sera demandé pour :',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 24),
                  _buildFeatureTile(Icons.calendar_today_rounded, 'Valider vos cotisations'),
                  const SizedBox(height: 12),
                  _buildFeatureTile(Icons.people_alt_rounded, 'Valider vos opérations\navec un agent'),
                  const SizedBox(height: 48),
                  PfReveal(
                    index: 6,
                    child: PfCodeInput(
                      key: _codeKey,
                      controller: _code,
                      length: 4,
                      obscure: !_pinVisible,
                      enabled: !_submitting,
                      error: _codeError,
                      onChanged: (_) {
                        if (_codeError) setState(() => _codeError = false);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton.icon(
                      onPressed: _submitting ? null : () => setState(() => _pinVisible = !_pinVisible),
                      icon: Icon(
                        _pinVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 20,
                        color: AppColors.secondary,
                      ),
                      label: Text(
                        _pinVisible ? 'Masquer le code' : 'Afficher le code saisi',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  PfMorphButton(
                    label: 'Terminer l\'inscription',
                    busy: _submitting,
                    onPressed: _submit,
                    onCollapsed: () {
                      if (mounted && _submitting && !_stageVisible) {
                        setState(() {
                          _stageVisible = true;
                          _stage ??= VerificationResult.pending;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ),
      ),
          if (_stageVisible && _stage != null)
            Positioned.fill(
              child: CodeVerificationOverlay(
                result: _stage!,
                pendingLabel: 'Création de votre compte',
                successLabel: 'Code PIN enregistré',
                failureLabel: 'Échec de l’enregistrement',
                onFinished: () {
                  final c = _stageDone;
                  if (c != null && !c.isCompleted) c.complete();
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeatureTile(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.secondary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.secondary,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.05);
  }
}
