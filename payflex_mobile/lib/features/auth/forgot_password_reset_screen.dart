import '../../core/design/pf_motion.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/mobile_api_service.dart';
import '../../core/utils/user_visible_message.dart';
import 'login_screen.dart';
import 'widgets/auth_kit.dart';
import 'widgets/auth_wave_background.dart';

/// Étape 2 — Nouveau code PIN PayFlex (connexion + cotisations).
class ForgotPasswordResetScreen extends StatefulWidget {
  const ForgotPasswordResetScreen({super.key, required this.resetToken});

  final String resetToken;

  @override
  State<ForgotPasswordResetScreen> createState() => _ForgotPasswordResetScreenState();
}

class _ForgotPasswordResetScreenState extends State<ForgotPasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pin = TextEditingController();
  final _pin2 = TextEditingController();
  final _api = MobileApiService();
  bool _loading = false;
  PfLiquidState _btn = PfLiquidState.idle;
  bool _obscurePin = true;

  @override
  void dispose() {
    _pin.dispose();
    _pin2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthWaveBackground(
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
                    lock: switch (_btn) {
                      PfLiquidState.loading => PfLockState.checking,
                      PfLiquidState.success => PfLockState.unlocked,
                      PfLiquidState.error => PfLockState.error,
                      _ => PfLockState.locked,
                    },
                  ),
                ),
                const SizedBox(height: 12),
                PfSecuritySteps(step: _btn == PfLiquidState.success ? 2 : 1, failed: _btn == PfLiquidState.error, labels: const ['Identité', 'Nouveau PIN', 'Connexion']),
                const SizedBox(height: 16),
                Text(
                  'Nouveau code PIN',
                  style: GoogleFonts.manrope(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choisissez un code PIN (4 à 12 chiffres) ou un mot de passe (8 caractères minimum). '
                  'Il sert à vous connecter et à valider vos cotisations.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 24),
                _pinField('Nouveau code PIN', _pin, _obscurePin, (v) => setState(() => _obscurePin = v)),
                const SizedBox(height: 12),
                _pinField('Confirmer le code PIN', _pin2, _obscurePin, (v) => setState(() => _obscurePin = v)),
                const SizedBox(height: 28),
                PfLiquidButton(
                  label: 'Enregistrer',
                  icon: Icons.lock_reset_rounded,
                  loadingLabel: 'Mise à jour…',
                  successLabel: 'PIN mis à jour',
                  state: _btn,
                  onPressed: _loading ? null : _submit,
                ),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pinField(
    String hint,
    TextEditingController c,
    bool obscure,
    void Function(bool) setVis,
  ) {
    return TextFormField(
      controller: c,
      obscureText: obscure,
      keyboardType: TextInputType.number,
      validator: (v) {
        final t = v?.trim() ?? '';
        if (t.isEmpty) return 'Requis';
        final isPin = RegExp(r'^[0-9]+$').hasMatch(t) && t.length >= 4 && t.length <= 12;
        final isPassword = t.length >= 8 && t.length <= 64;
        if (!isPin && !isPassword) {
          return 'PIN (4-12 chiffres) ou mot de passe (8-64 car.)';
        }
        return null;
      },
      style: GoogleFonts.inter(color: Colors.black87, fontSize: 16),
      decoration: pfAuthDecoration(hint, obscure ? Icons.lock_rounded : Icons.lock_open_rounded, suffix: PfEyeToggle(visible: !obscure, onChanged: (v) => setVis(!v))),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pin.text.trim() != _pin2.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Les deux codes PIN ne correspondent pas.')),
      );
      return;
    }
    setState(() {
      _loading = true;
      _btn = PfLiquidState.loading;
    });
    final pinTrim = _pin.text.trim();
    final err = await _api.resetAccountCredentials(
      resetToken: widget.resetToken,
      newPin: pinTrim,
      newSecretCode: pinTrim,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _btn = err == null ? PfLiquidState.success : PfLiquidState.error;
    });
    if (err == null && !PfMotion.reduced(context)) await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    if (err != null) {
      Future<void>.delayed(const Duration(milliseconds: 2500), () {
        if (mounted && _btn == PfLiquidState.error) setState(() => _btn = PfLiquidState.idle);
      });
    }
    if (err == null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => const LoginScreen(
            recoverySuccessMessage: 'Votre code PIN a été mis à jour. Connectez-vous avec votre nouveau PIN.',
          ),
        ),
        (route) => false,
      );
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
}
