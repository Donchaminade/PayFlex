import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../main_navigation_screen.dart';
import 'role_selection_screen.dart';
import 'widgets/auth_wave_background.dart';
import 'widgets/auth_kit.dart';
import 'package:flutter/services.dart';
import '../../core/design/pf_motion.dart';
import '../../core/design/pf_tokens.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_config.dart';
import '../../core/network/payflex_api_logger.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/notification_permission_flow.dart';
import '../../core/utils/user_visible_message.dart';
import '../../core/utils/phone_input_utils.dart';
import '../../core/widgets/dev_api_settings_sheet.dart';
import '../../core/widgets/payflex_phone_field.dart';
import '../agent/agent_main_navigation_screen.dart';
import '../../core/providers/navigation_provider.dart';
import '../../core/services/biometric_auth_service.dart';
import 'forgot_password_verify_screen.dart';

enum _LoginMethod { phone, name, email }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.recoverySuccessMessage, this.registrationSuccessMessage});

  /// Affiché une fois au chargement après réinitialisation PIN / code secret.
  final String? recoverySuccessMessage;

  /// Affiché une fois après envoi réussi de la demande d'inscription.
  final String? registrationSuccessMessage;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _pinController = TextEditingController();
  _LoginMethod _method = _LoginMethod.phone;
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _biometricAvailable = false;
  PfLiquidState _btn = PfLiquidState.idle;
  PfLockState _lock = PfLockState.locked;
  int _step = 0;
  final _shakeKey = GlobalKey<PfShakeState>();

  void _visual(PfLiquidState b, PfLockState l, int step) {
    if (!mounted) return;
    setState(() {
      _btn = b;
      _lock = l;
      _step = step;
    });
  }

  Future<void> _failed() async {
    _visual(PfLiquidState.error, PfLockState.error, 1);
    _shakeKey.currentState?.shake();
    await Future<void>.delayed(const Duration(milliseconds: 2500));
    if (mounted && _btn == PfLiquidState.error) _visual(PfLiquidState.idle, PfLockState.locked, 0);
  }

  Future<void> _succeeded(BuildContext context, WidgetRef ref) async {
    _visual(PfLiquidState.success, PfLockState.unlocked, 3);
    if (!PfMotion.reduced(context)) await Future<void>.delayed(const Duration(milliseconds: 750));
    if (!context.mounted) return;
    _navigateAfterLogin(context, ref);
  }

  TextStyle get _fieldStyle => GoogleFonts.inter(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w500);

  @override
  void initState() {
    super.initState();
    final msg = widget.registrationSuccessMessage ?? widget.recoverySuccessMessage;
    if (msg != null && msg.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final enabled = await BiometricAuthService.isEnabled();
    final supported = await BiometricAuthService.isDeviceSupported();
    if (mounted) setState(() => _biometricAvailable = enabled && supported);
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _pinController.dispose();
    super.dispose();
  }

  String _loginModeParam() {
    switch (_method) {
      case _LoginMethod.phone:
        return 'phone';
      case _LoginMethod.name:
        return 'name';
      case _LoginMethod.email:
        return 'email';
    }
  }

  String _buildIdentifier() {
    switch (_method) {
      case _LoginMethod.phone:
        return _phoneCtrl.text.trim();
      case _LoginMethod.name:
        return _nameCtrl.text.trim();
      case _LoginMethod.email:
        return _emailCtrl.text.trim();
    }
  }

  Widget _buildLogo() {
    return PfAuthLogo(
      size: 96,
      lock: _lock,
      onLongPress: kDebugMode ? () => showDevApiSettingsSheet(context) : null,
    );
  }

  int _i = 0;
  Widget _in(Widget w) => PfReveal(index: _i++, dy: 24, child: w);

  @override
  Widget build(BuildContext context) {
    _i = 0;
    return AuthWaveBackground(
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(Pf.gutter, 24, Pf.gutter, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Center(child: _buildLogo()),
                const SizedBox(height: 24),
                _in(Text('ESPACE SÉCURISÉ', textAlign: TextAlign.center, style: Pf.overline().copyWith(letterSpacing: 2))),
                const SizedBox(height: 8),
                _in(Text('Bon retour 👋', textAlign: TextAlign.center, style: Pf.display(size: 32))),
                const SizedBox(height: 6),
                _in(Text('Connectez-vous pour gérer vos cotisations.', textAlign: TextAlign.center, style: Pf.body(size: 14))),
                const SizedBox(height: 28),
                _in(
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .86),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white),
                      boxShadow: Pf.shadowLift,
                    ),
                    child: PfShake(
                      key: _shakeKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildMethodSelector(),
                          const SizedBox(height: 18),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 280),
                            transitionBuilder: (c, a) => FadeTransition(
                              opacity: a,
                              child: SlideTransition(position: Tween(begin: const Offset(.06, 0), end: Offset.zero).animate(a), child: c),
                            ),
                            child: KeyedSubtree(key: ValueKey(_method), child: PfFocusGlow(child: _buildIdentifierField())),
                          ),
                          const SizedBox(height: 14),
                          PfFocusGlow(
                            child: _buildPasswordField(
                              'Mot de passe ou code PIN',
                              _isPasswordVisible,
                              _pinController,
                              (v) => setState(() => _isPasswordVisible = v),
                              validator: (v) => (v == null || v.isEmpty) ? 'Veuillez entrer votre mot de passe ou code PIN' : null,
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(builder: (_) => const ForgotPasswordVerifyScreen()),
                                );
                              },
                              child: Text('PIN oublié ?', style: Pf.label(size: 13, color: const Color(0xFFB7791F))),
                            ),
                          ),
                          const SizedBox(height: 6),
                          PfLiquidButton(
                            label: 'Se connecter',
                            loadingLabel: 'Vérification sécurisée…',
                            successLabel: 'Bienvenue !',
                            errorLabel: 'Réessayer',
                            state: _btn,
                            onPressed: _isLoading ? null : _onLogin,
                          ),
                          const SizedBox(height: 18),
                          PfSecuritySteps(step: _step, failed: _btn == PfLiquidState.error),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_biometricAvailable) ...[
                  const SizedBox(height: 16),
                  _in(
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _onBiometricLogin,
                      icon: const Icon(Icons.fingerprint_rounded, color: Pf.ink),
                      label: Text('Connexion biométrique', style: Pf.label(size: 14)),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 54),
                        backgroundColor: Colors.white.withValues(alpha: .7),
                        side: const BorderSide(color: Pf.line, width: 1.4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                _in(
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
                        );
                      },
                      child: RichText(
                        text: TextSpan(
                          text: 'Nouveau sur PayFlex ? ',
                          style: Pf.body(size: 13.5),
                          children: [TextSpan(text: 'Créer un compte', style: Pf.label(size: 13.5, color: Pf.ink).copyWith(decoration: TextDecoration.underline, decorationColor: Pf.gold, decorationThickness: 2))],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMethodSelector() {
    const items = [
      (_LoginMethod.phone, Icons.phone_iphone_rounded, 'Téléphone'),
      (_LoginMethod.name, Icons.badge_rounded, 'Nom'),
      (_LoginMethod.email, Icons.alternate_email_rounded, 'E-mail'),
    ];
    final idx = items.indexWhere((e) => e.$1 == _method);
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Pf.fill, borderRadius: BorderRadius.circular(16)),
      child: LayoutBuilder(
        builder: (_, c) {
          final w = c.maxWidth / items.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: PfMotion.slide,
                curve: PfMotion.spring,
                left: w * idx,
                top: 0,
                bottom: 0,
                width: w,
                child: Container(decoration: BoxDecoration(color: Pf.ink, borderRadius: BorderRadius.circular(12), boxShadow: Pf.shadowSoft)),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final it in items)
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: it.$1 == _method,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _method = it.$1);
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(it.$2, size: 16, color: it.$1 == _method ? Pf.gold : Pf.muted),
                              const SizedBox(width: 6),
                              AnimatedDefaultTextStyle(
                                duration: PfMotion.quick,
                                style: Pf.label(size: 12.5, color: it.$1 == _method ? Colors.white : Pf.muted),
                                child: Text(it.$3),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildIdentifierField() {
    switch (_method) {
      case _LoginMethod.phone:
        return PayflexPhoneField(
          completeNumberController: _phoneCtrl,
          hint: 'Ex. 90000000',
          textStyle: _fieldStyle,
          validator: (v) => PayflexPhoneValidator.validate(v),
        );
      case _LoginMethod.name:
        return _buildField(
          Icons.badge_outlined,
          'Prénom, nom ou les deux',
          controller: _nameCtrl,
          keyboardType: TextInputType.name,
          textCapitalization: TextCapitalization.words,
          validator: (v) {
            final t = v?.trim() ?? '';
            if (t.length < 2) return 'Saisissez au moins 2 caractères';
            return null;
          },
        );
      case _LoginMethod.email:
        return _buildField(
          Icons.email_outlined,
          'Adresse e-mail',
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            final t = v?.trim() ?? '';
            if (t.isEmpty) return 'E-mail requis';
            if (!t.contains('@') || !t.contains('.')) return 'Adresse e-mail invalide';
            return null;
          },
        );
    }
  }

  Future<void> _onBiometricLogin() async {
    final ok = await BiometricAuthService.authenticate(reason: 'Connectez-vous à PayFlex');
    if (!ok || !mounted) return;
    final creds = await BiometricAuthService.storedCredentials();
    if (creds == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session biométrique introuvable. Connectez-vous manuellement.')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final phone = creds['phone']?.toString() ?? '';
      final pin = creds['pin']?.toString() ?? '';
      _phoneCtrl.text = phone;
      _pinController.text = pin;
      _method = _LoginMethod.phone;
      final outcome = await ref.read(authProvider.notifier).login(phone, pin, loginMode: 'phone');
      if (!mounted) return;
      if (outcome.success && ref.read(authProvider).isAuthenticated) {
        _navigateAfterLogin(context, ref);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              UserVisibleMessage.apiOrFallback(
                outcome.errorMessage,
                'Connexion biométrique échouée.',
              ),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) {
      _shakeKey.currentState?.shake();
      return;
    }
    {
      final String identifier = _buildIdentifier();
      final String pin = _pinController.text.trim();
      final String mode = _loginModeParam();
      PayflexApiLogger.info(
        'Écran login → mode=$mode identifier=${PayflexApiLogger.maskPhone(identifier)} '
        'api=${ApiConfig.baseUrl}',
      );
      setState(() => _isLoading = true);
      _visual(PfLiquidState.loading, PfLockState.checking, 1);
      Future<void>.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _btn == PfLiquidState.loading) setState(() => _step = 2);
      });
      try {
        final outcome = await ref.read(authProvider.notifier).login(identifier, pin, loginMode: mode);
        if (!context.mounted) return;
        if (outcome.success && ref.read(authProvider).isAuthenticated) {
          await _succeeded(context, ref);
          return;
        }
        _failed();
        if (outcome.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Connexion incomplète. Réessayez.'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                UserVisibleMessage.apiOrFallback(
                  outcome.errorMessage,
                  'Connexion impossible. Réessayez.',
                ),
              ),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _navigateAfterLogin(BuildContext context, WidgetRef ref) {
    final role = ref.read(authProvider).role;
    ref.read(navigationIndexProvider.notifier).setIndex(0);
    if (role == 'agent') {
      ref.read(agentNavigationIndexProvider.notifier).setIndex(0);
    }
    final Widget nextScreen = role == 'agent'
        ? const AgentMainNavigationScreen()
        : const MainNavigationScreen();
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      pfAuthSuccessRoute<void>(nextScreen),
      (_) => false,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      requestPayflexNotificationsIfNeeded();
    });
  }

  Widget _buildField(
    IconData icon,
    String hint, {
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      autocorrect: false,
      style: _fieldStyle,
      decoration: pfAuthDecoration(hint, icon),
    );
  }

  Widget _buildPasswordField(String hint, bool isVisible, TextEditingController controller, Function(bool) toggle, {String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      validator: validator,
      style: _fieldStyle,
      decoration: pfAuthDecoration(
        hint,
        isVisible ? Icons.lock_open_rounded : Icons.lock_rounded,
        suffix: PfEyeToggle(visible: isVisible, onChanged: (v) => toggle(v)),
      ),
    );
  }
}
