import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../payment/widgets/payment_flow_stage.dart';
import '../../core/network/mobile_api_service.dart';
import '../../core/utils/user_visible_message.dart';
import 'forgot_password_reset_screen.dart';
import '../../core/widgets/payflex_phone_field.dart';
import '../../core/utils/phone_input_utils.dart';
import 'widgets/auth_kit.dart';
import 'widgets/auth_wave_background.dart';

/// Étape 1 — Vérification d’identité pour « mot de passe oublié ».
class ForgotPasswordVerifyScreen extends StatefulWidget {
  const ForgotPasswordVerifyScreen({super.key});

  @override
  State<ForgotPasswordVerifyScreen> createState() => _ForgotPasswordVerifyScreenState();
}

class _ForgotPasswordVerifyScreenState extends State<ForgotPasswordVerifyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _fullName = TextEditingController();
  final _uniqueCode = TextEditingController();
  final _api = MobileApiService();
  bool _loading = false;
  /// Scène de vérification d'identité (réf. Checkout v3).
  bool _verifying = false;
  VerificationResult _stage = VerificationResult.pending;
  bool _stageVisible = false;
  Completer<void>? _stageDone;

  @override
  void dispose() {
    _phone.dispose();
    _fullName.dispose();
    _uniqueCode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AuthWaveBackground(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: pfStagger([
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: AppColors.secondary,
                    ),
                  ],
                ),
                Center(
                  child: PfAuthLogo(
                    size: 72,
                    lock: _verifying ? PfLockState.checking : (_liqErr ? PfLockState.error : PfLockState.locked),
                  ),
                ),
                const SizedBox(height: 12),
                PfSecuritySteps(step: 0, failed: _liqErr, labels: const ['Identité', 'Nouveau PIN', 'Connexion']),
                const SizedBox(height: 16),
                Text(
                  'Récupération du compte',
                  style: GoogleFonts.manrope(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Indiquez les mêmes informations que lors de votre inscription PayFlex. '
                  'Sélectionnez votre pays et saisissez votre numéro (Togo +228 par défaut).',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 28),
                PayflexPhoneField(
                  completeNumberController: _phone,
                  hint: 'Numéro de téléphone',
                  validator: (v) => PayflexPhoneValidator.validate(v),
                ),
                const SizedBox(height: 16),
                _field(
                  Icons.badge_outlined,
                  'Nom et prénom (identique à l’inscription)',
                  _fullName,
                  (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                ),
                const SizedBox(height: 16),
                _field(
                  Icons.qr_code_2_rounded,
                  'Code unique PayFlex',
                  _uniqueCode,
                  (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                ),
                const SizedBox(height: 28),
                if (_loading && !_verifying)
                  const Center(child: CircularProgressIndicator(color: AppColors.primary))
                else ...[
                  PfLiquidButton(label: 'Vérifier mes informations', state: _liq, onPressed: _verifying ? null : _submit, loadingLabel: 'Vérification…', successLabel: 'Identité vérifiée', icon: Icons.verified_user_rounded),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: _requestCallback,
                    child: Text(
                      'J’ai tout oublié — demander un rappel PayFlex',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ),
      ),
    ),
        if (_stageVisible)
          Positioned.fill(
            child: CodeVerificationOverlay(
              result: _stage,
              pendingLabel: 'Vérification de votre identité',
              successLabel: 'Identité confirmée',
              failureLabel: 'Informations non reconnues',
              onFinished: () {
                final c = _stageDone;
                if (c != null && !c.isCompleted) c.complete();
              },
            ),
          ),
      ],
    );
  }

  bool _liqErr = false;
  PfLiquidState get _liq => _verifying
      ? (_stage == VerificationResult.success ? PfLiquidState.success : PfLiquidState.loading)
      : (_liqErr ? PfLiquidState.error : PfLiquidState.idle);

  /// La vague du bouton remplit ~650 ms, puis la scène de vérification prend le relais
  /// (elle attend la vraie réponse du serveur).
  void _showStageSoon() {
    Future<void>.delayed(const Duration(milliseconds: 650), () {
      if (mounted && _verifying && !_stageVisible) {
        setState(() {
          _stageVisible = true;
          _stage = VerificationResult.pending;
        });
      }
    });
  }

  void _flashError() {
    setState(() => _liqErr = true);
    Future<void>.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _liqErr = false);
    });
  }

  Future<void> _endStage(VerificationResult r) async {
    if (!_stageVisible) {
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
  }

  Widget _field(
    IconData icon,
    String hint,
    TextEditingController c,
    String? Function(String?)? validator, {
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: c,
      validator: validator,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(color: Colors.black87, fontSize: 16),
      decoration: pfAuthDecoration(hint, icon),
    );
  }

  Future<void> _requestCallback() async {
    if (_phone.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indiquez au minimum votre numéro de téléphone.')),
      );
      return;
    }
    setState(() => _loading = true);
    final err = await _api.requestRecoveryCallback(
      phone: _phone.text,
      fullName: _fullName.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (err == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Demande enregistrée. Un conseiller PayFlex vous rappellera.',
            style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFF38A169),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            UserVisibleMessage.apiOrFallback(err, UserVisibleMessage.unexpected),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _verifying = true;
      _liqErr = false;
    });
    _showStageSoon();
    final outcome = await _api.requestAccountRecovery(
      phone: _phone.text,
      fullName: _fullName.text,
      uniqueCode: _uniqueCode.text,
    );
    if (!mounted) return;
    final ok = outcome.ok && outcome.resetToken != null;
    await _endStage(ok ? VerificationResult.success : VerificationResult.failure);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _verifying = false;
      if (!ok) _stageVisible = false;
    });
    if (!ok) _flashError();
    if (ok) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ForgotPasswordResetScreen(resetToken: outcome.resetToken!),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            UserVisibleMessage.apiOrFallback(outcome.message, 'Vérification impossible. Vérifiez vos informations.'),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
