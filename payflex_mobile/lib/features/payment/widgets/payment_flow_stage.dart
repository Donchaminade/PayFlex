import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/design/pf_components.dart';

/// Scène du tunnel de paiement (référence « Interactive Payment Checkout v3 ») :
/// fond marine, anneaux concentriques dorés qui pulsent, carré central
/// (cadenas → coche), arc de progression et pourcentage.
class PaymentPulseStage extends StatefulWidget {
  const PaymentPulseStage({
    super.key,
    required this.progress,
    required this.label,
    this.done = false,
    this.doneIcon = Icons.check_rounded,
    this.doneColor = Pf.success,
    this.ripple = 0,
    this.showPercent = true,
    this.size = 300,
  });

  /// 0..1 — progression affichée (arc + pourcentage).
  final double progress;
  final String label;

  /// true : le cadenas devient la coche, l'arc passe en vert.
  final bool done;
  final IconData doneIcon;
  final Color doneColor;

  /// 0..1 — onde finale : les anneaux s'éloignent et s'effacent.
  final double ripple;
  final bool showPercent;
  final double size;

  @override
  State<PaymentPulseStage> createState() => _PaymentPulseStageState();
}

class _PaymentPulseStageState extends State<PaymentPulseStage> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!PfMotion.reduced(context) && !_pulse.isAnimating) _pulse.repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.done ? widget.doneColor : Pf.gold;
    final s = widget.size;
    return SizedBox(
      width: s,
      height: s + (widget.showPercent ? 64 : 0),
      child: Column(
        children: [
          SizedBox(
            width: s,
            height: s,
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) {
                final t = _pulse.value;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Anneaux concentriques (3 couches) qui respirent, puis onde de sortie
                    for (var i = 3; i >= 1; i--)
                      Opacity(
                        opacity: ((1 - widget.ripple) * (0.10 + 0.07 * (4 - i)) * (0.85 + 0.15 * math.sin((t + i / 3) * math.pi * 2))).clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: (0.42 + 0.19 * i) * (1 + 0.025 * math.sin((t + i * 0.2) * math.pi * 2)) * (1 + 0.6 * widget.ripple),
                          child: Container(
                            width: s,
                            height: s,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(colors: [accent.withValues(alpha: 0.0), accent.withValues(alpha: 0.55)], stops: const [0.55, 1]),
                              border: Border.all(color: accent.withValues(alpha: 0.5), width: 1),
                            ),
                          ),
                        ),
                      ),
                    // Halo central
                    Container(
                      width: s * 0.44,
                      height: s * 0.44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Pf.inkDeep,
                        boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.45), blurRadius: 36, spreadRadius: 2)],
                      ),
                    ),
                    // Arc de progression
                    SizedBox(
                      width: s * 0.44,
                      height: s * 0.44,
                      child: CustomPaint(painter: _ArcPainter(widget.progress, accent)),
                    ),
                    // Carré central : cadenas → coche
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeOutBack,
                      width: widget.done ? s * 0.2 : s * 0.17,
                      height: widget.done ? s * 0.2 : s * 0.17,
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(widget.done ? s : 14),
                        boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.6), blurRadius: 24)],
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 320),
                        transitionBuilder: (c, a) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack), child: FadeTransition(opacity: a, child: c)),
                        child: Icon(
                          widget.done ? widget.doneIcon : Icons.lock_rounded,
                          key: ValueKey(widget.done),
                          color: widget.done ? Colors.white : Pf.ink,
                          size: s * (widget.done ? 0.11 : 0.085),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          if (widget.showPercent) ...[
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(widget.label, key: ValueKey(widget.label), style: Pf.body(color: Colors.white70, size: 13, w: FontWeight.w600)),
            ),
            const SizedBox(height: Pf.s4),
            Text('${(widget.progress * 100).round()}%', style: Pf.num(size: 22, color: Colors.white)),
          ],
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter(this.v, this.color);
  final double v;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 4.0;
    final r = Rect.fromLTWH(stroke, stroke, size.width - stroke * 2, size.height - stroke * 2);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(r, 0, math.pi * 2, false, p..color = Colors.white.withValues(alpha: 0.08));
    canvas.drawArc(r, -math.pi / 2, math.pi * 2 * v.clamp(0, 1), false, p..color = color);
  }

  @override
  bool shouldRepaint(_ArcPainter o) => o.v != v || o.color != color;
}

/// Fond marine de la scène.
class PaymentStageBackground extends StatelessWidget {
  const PaymentStageBackground({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(center: Alignment(0, -0.2), radius: 1.1, colors: [Color(0xFF0A4468), Pf.ink, Pf.inkDeep], stops: [0, 0.5, 1]),
        ),
        child: child,
      );
}

/// Pendant l'appel serveur : la scène apparaît (petit anneau qui grandit),
/// la progression avance de façon asymptotique vers ~88 % sans jamais
/// prétendre avoir fini avant la réponse réelle.
class PaymentVerifyingOverlay extends StatefulWidget {
  const PaymentVerifyingOverlay({super.key});
  /// Valeur à laquelle l'écran de succès reprend l'animation.
  static const double handoffProgress = 0.88;

  @override
  State<PaymentVerifyingOverlay> createState() => _PaymentVerifyingOverlayState();
}

class _PaymentVerifyingOverlayState extends State<PaymentVerifyingOverlay> with TickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  late final AnimationController _clock = AnimationController(vsync: this, duration: const Duration(seconds: 30));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_enter.status == AnimationStatus.dismissed) {
      if (PfMotion.reduced(context)) {
        _enter.value = 1;
      } else {
        _enter.forward();
      }
      _clock.forward();
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_enter, _clock]),
      builder: (context, _) {
        final e = Curves.easeOutCubic.transform(_enter.value);
        final grow = Curves.easeOutBack.transform(_enter.value);
        final secs = _clock.value * 30;
        final progress = PaymentVerifyingOverlay.handoffProgress * (1 - math.exp(-secs / 1.6));
        return Opacity(
          opacity: e,
          child: PaymentStageBackground(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: 0.3 + 0.7 * grow,
                    child: PaymentPulseStage(progress: progress, label: 'Vérification du paiement'),
                  ),
                  const SizedBox(height: Pf.s24),
                  Opacity(
                    opacity: e,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_user_rounded, size: 14, color: Colors.white38),
                        const SizedBox(width: 6),
                        Text('Connexion chiffrée · ne fermez pas l’application', style: Pf.body(color: Colors.white38, size: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Particules qui jaillissent autour de la coche (succès).
class PaymentSparkles extends StatelessWidget {
  const PaymentSparkles({super.key, required this.t, this.radius = 90, this.color = Pf.success});
  final double t; // 0..1
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (t <= 0 || t >= 1) return const SizedBox.shrink();
    return IgnorePointer(child: CustomPaint(size: Size.square(radius * 2.6), painter: _SparklePainter(t, radius, color)));
  }
}

class _SparklePainter extends CustomPainter {
  _SparklePainter(this.t, this.r, this.color);
  final double t, r;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final rnd = math.Random(7);
    final ease = Curves.easeOutCubic.transform(t);
    for (var i = 0; i < 26; i++) {
      final a = (i / 26) * math.pi * 2 + rnd.nextDouble() * 0.3;
      final dist = r * (0.55 + rnd.nextDouble() * 0.75) * ease;
      final pos = c + Offset(math.cos(a), math.sin(a)) * dist;
      final col = i % 3 == 0 ? Pf.gold : color;
      final alpha = (1 - t) * (0.6 + rnd.nextDouble() * 0.4);
      canvas.drawCircle(pos, 1.2 + rnd.nextDouble() * 2.2, Paint()..color = col.withValues(alpha: alpha));
    }
  }

  @override
  bool shouldRepaint(_SparklePainter o) => o.t != t;
}

/// Résultat de vérification pour [CodeVerificationOverlay].
enum VerificationResult { pending, success, failure }

/// Scène de vérification générique (PIN, code, identité) :
/// - pending : progression asymptotique (≤ 88 %) tant que le serveur n'a pas répondu ;
/// - success : 100 % puis cadenas → coche verte, puis [onFinished] ;
/// - failure : arc rouge + croix, fondu de sortie puis [onFinished]
///   (l'écran revient à la saisie et secoue les cases).
class CodeVerificationOverlay extends StatefulWidget {
  const CodeVerificationOverlay({
    super.key,
    required this.result,
    this.pendingLabel = 'Vérification du code',
    this.successLabel = 'Code vérifié',
    this.failureLabel = 'Vérification refusée',
    this.onFinished,
  });

  final VerificationResult result;
  final String pendingLabel;
  final String successLabel;
  final String failureLabel;
  final VoidCallback? onFinished;

  @override
  State<CodeVerificationOverlay> createState() => _CodeVerificationOverlayState();
}

class _CodeVerificationOverlayState extends State<CodeVerificationOverlay> with TickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  late final AnimationController _clock = AnimationController(vsync: this, duration: const Duration(seconds: 60));
  late final AnimationController _finish = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  double _frozen = 0;

  bool get _reduced => PfMotion.reduced(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_enter.status == AnimationStatus.dismissed) {
      _reduced ? _enter.value = 1 : _enter.forward();
      _clock.forward();
    }
  }

  @override
  void didUpdateWidget(CodeVerificationOverlay old) {
    super.didUpdateWidget(old);
    if (old.result == VerificationResult.pending && widget.result != VerificationResult.pending) {
      _frozen = _pendingProgress;
      _clock.stop();
      if (_reduced) {
        _finish.value = 1;
        Future.delayed(const Duration(milliseconds: 400), () => widget.onFinished?.call());
      } else {
        _finish.forward(from: 0).whenComplete(() => widget.onFinished?.call());
      }
    }
  }

  double get _pendingProgress => PaymentVerifyingOverlay.handoffProgress * (1 - math.exp(-(_clock.value * 60) / 1.6));

  @override
  void dispose() {
    _enter.dispose();
    _clock.dispose();
    _finish.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_enter, _clock, _finish]),
      builder: (context, _) {
        final e = Curves.easeOutCubic.transform(_enter.value);
        final grow = Curves.easeOutBack.transform(_enter.value);
        final f = _finish.value;
        final r = widget.result;
        double progress;
        String label;
        var done = false;
        var opacity = e;
        var ripple = 0.0;
        Color doneColor = Pf.success;
        IconData doneIcon = Icons.check_rounded;
        switch (r) {
          case VerificationResult.pending:
            progress = _pendingProgress;
            label = widget.pendingLabel;
          case VerificationResult.success:
            final k = Curves.easeOutCubic.transform((f / 0.4).clamp(0, 1));
            progress = _frozen + (1 - _frozen) * k;
            done = f >= 0.4;
            ripple = ((f - 0.55) / 0.45).clamp(0.0, 1.0);
            label = done ? widget.successLabel : widget.pendingLabel;
          case VerificationResult.failure:
            progress = _frozen;
            done = f >= 0.15;
            doneColor = Pf.danger;
            doneIcon = Icons.close_rounded;
            label = widget.failureLabel;
            opacity = e * (1 - ((f - 0.6) / 0.4).clamp(0.0, 1.0));
        }
        return Opacity(
          opacity: opacity,
          child: PaymentStageBackground(
            child: Center(
              child: Transform.scale(
                scale: 0.3 + 0.7 * grow,
                child: PaymentPulseStage(
                  progress: progress,
                  label: label,
                  done: done,
                  doneColor: doneColor,
                  doneIcon: doneIcon,
                  ripple: ripple,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
