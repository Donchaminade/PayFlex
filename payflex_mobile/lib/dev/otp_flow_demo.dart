import 'dart:async';

import 'package:flutter/material.dart';

import '../core/design/pf_code_input.dart';
import '../core/design/pf_components.dart';
import '../features/payment/widgets/payment_flow_stage.dart';

/// Démo vitrine du parcours code (mêmes widgets que l'écran PIN) :
/// saisie case par case → mauvais code (scène → croix rouge → secousse)
/// → collage du bon code → scène → coche verte. Serveur simulé (1,8 s).
class OtpFlowDemo extends StatefulWidget {
  const OtpFlowDemo({super.key});
  @override
  State<OtpFlowDemo> createState() => _OtpFlowDemoState();
}

class _OtpFlowDemoState extends State<OtpFlowDemo> {
  final _code = TextEditingController();
  final _key = GlobalKey<PfCodeInputState>();
  final _focus = FocusNode();
  bool _busy = false, _error = false, _stageVisible = false;
  VerificationResult _stage = VerificationResult.pending;
  Completer<void>? _done;

  @override
  void initState() {
    super.initState();
    _script();
  }

  Future<void> _wait(int ms) => Future.delayed(Duration(milliseconds: ms));

  Future<void> _script() async {
    await _wait(1400);
    _focus.requestFocus();
    for (final d in ['4', '8', '1', '9']) {
      await _wait(380);
      if (!mounted) return;
      _code.text += d;
    }
    await _wait(500);
    await _submit(correct: false);
    await _wait(1200);
    _code.clear();
    _focus.requestFocus();
    await _wait(600);
    _code.text = '2580'; // collage
    setState(() => _error = false);
    await _wait(700);
    await _submit(correct: true);
  }

  Future<void> _submit({required bool correct}) async {
    setState(() {
      _busy = true;
      _error = false;
    });
    await _wait(950 + 1800); // morph + « serveur »
    if (!mounted) return;
    _done = Completer<void>();
    setState(() => _stage = correct ? VerificationResult.success : VerificationResult.failure);
    await _done!.future;
    if (!mounted || correct) return;
    setState(() {
      _stageVisible = false;
      _stage = VerificationResult.pending;
      _busy = false;
      _error = true;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  const PfCircleButton(icon: Icons.arrow_back_rounded),
                  const SizedBox(height: Pf.s32),
                  Text('Sécurité du compte', style: Pf.body(size: 13, w: FontWeight.w600)),
                  const SizedBox(height: Pf.s4),
                  Text('Créer votre\ncode PIN', style: Pf.display()),
                  const SizedBox(height: Pf.s12),
                  Text('4 chiffres, demandés pour valider vos cotisations et vos opérations avec un agent.', style: Pf.body(size: 14)),
                  const SizedBox(height: Pf.s40),
                  PfCodeInput(key: _key, controller: _code, focusNode: _focus, obscure: false, error: _error, enabled: !_busy),
                  const SizedBox(height: Pf.s16),
                  Center(
                    child: AnimatedSwitcher(
                      duration: PfMotion.quick,
                      child: _error
                          ? Text('Code refusé — réessayez', key: const ValueKey('e'), style: Pf.label(size: 13, color: Pf.danger))
                          : Text('Collez ou saisissez le code', key: const ValueKey('n'), style: Pf.body(size: 13)),
                    ),
                  ),
                  const Spacer(),
                  PfMorphButton(
                    label: 'Valider le code',
                    busy: _busy,
                    onPressed: () {},
                    onCollapsed: () => setState(() => _stageVisible = true),
                  ),
                  const SizedBox(height: Pf.s24),
                ],
              ),
            ),
          ),
          if (_stageVisible)
            Positioned.fill(
              child: CodeVerificationOverlay(
                result: _stage,
                pendingLabel: 'Vérification du code',
                successLabel: 'Code vérifié',
                failureLabel: 'Code incorrect',
                onFinished: () => _done?.complete(),
              ),
            ),
        ],
      ),
    );
  }
}
