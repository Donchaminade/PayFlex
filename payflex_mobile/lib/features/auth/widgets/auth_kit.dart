import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design/pf_motion.dart';
import '../../../core/design/pf_tokens.dart';
import 'payflex_logo.dart';

/// Kit visuel des écrans d'authentification (réf. DcOUIemTImO + Dc7xjbKTa7h + DZPqMZ2T1PA).

// ───────────────────────── Fond animé : orbes floutés qui dérivent (15 s)
class PfAuroraBackground extends StatefulWidget {
  const PfAuroraBackground({super.key, this.dark = false});
  final bool dark;
  @override
  State<PfAuroraBackground> createState() => _PfAuroraBackgroundState();
}

class _PfAuroraBackgroundState extends State<PfAuroraBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 15));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (PfMotion.reduced(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) => CustomPaint(painter: _AuroraPainter(_c.value, widget.dark), size: Size.infinite),
        ),
      );
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter(this.t, this.dark);
  final double t;
  final bool dark;
  @override
  void paint(Canvas canvas, Size s) {
    final bg = Rect.fromLTWH(0, 0, s.width, s.height);
    canvas.drawRect(
      bg,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dark ? const [Pf.inkDeep, Pf.ink] : const [Color(0xFFFFFBF2), Pf.canvas],
        ).createShader(bg),
    );
    final a = t * 2 * math.pi;
    void orb(Offset c, double r, Color col) {
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(colors: [col, col.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }

    final w = s.width, h = s.height;
    orb(Offset(w * (.15 + .12 * math.sin(a)), h * (.12 + .05 * math.cos(a))), w * .75, Pf.gold.withValues(alpha: dark ? .30 : .28));
    orb(Offset(w * (.95 + .08 * math.cos(a + 1)), h * (.38 + .06 * math.sin(a + 1))), w * .7, (dark ? const Color(0xFF1C6E9E) : Pf.ink).withValues(alpha: dark ? .45 : .12));
    orb(Offset(w * (.2 + .1 * math.cos(a + 2.4)), h * (.88 + .04 * math.sin(a + 2.4))), w * .8, Pf.goldSoft.withValues(alpha: dark ? .18 : .16));
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter o) => o.t != t || o.dark != dark;
}

// ───────────────────────── Logo : intro (scale + anneau doré) + bouclier cadenas → déverrouillé
enum PfLockState { locked, checking, unlocked, error }

class PfAuthLogo extends StatefulWidget {
  const PfAuthLogo({super.key, this.size = 108, this.lock, this.onLongPress});
  final double size;
  final PfLockState? lock;
  final VoidCallback? onLongPress;
  @override
  State<PfAuthLogo> createState() => _PfAuthLogoState();
}

class _PfAuthLogoState extends State<PfAuthLogo> with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  late final AnimationController _spin = AnimationController(vsync: this, duration: const Duration(seconds: 6));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (PfMotion.reduced(context)) {
      _intro.value = 1;
      _spin.stop();
    } else {
      if (_intro.value == 0) _intro.forward();
      if (!_spin.isAnimating) _spin.repeat();
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final lock = widget.lock;
    final ringColor = switch (lock) {
      PfLockState.unlocked => Pf.success,
      PfLockState.error => Pf.danger,
      _ => Pf.gold,
    };
    return GestureDetector(
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: Listenable.merge([_intro, _spin]),
        builder: (_, __) {
          final k = Curves.easeOutBack.transform(_intro.value.clamp(0, 1));
          final ring = Curves.easeOutCubic.transform(((_intro.value - .25) / .75).clamp(0, 1));
          return SizedBox(
            width: s + 28,
            height: s + 28,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // halo
                Container(
                  width: s + 28,
                  height: s + 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: ringColor.withValues(alpha: .28 * ring), blurRadius: 40, spreadRadius: 2)],
                  ),
                ),
                Transform.rotate(
                  angle: _spin.value * 2 * math.pi,
                  child: CustomPaint(size: Size(s + 24, s + 24), painter: _RingPainter(ring, ringColor, lock == PfLockState.checking)),
                ),
                Transform.scale(
                  scale: .6 + .4 * k,
                  child: Opacity(
                    opacity: _intro.value.clamp(0, 1),
                    child: Container(
                      width: s,
                      height: s,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: Pf.shadowLift),
                      child: Transform.scale(scale: 1.35, child: PayFlexLogo(size: s)),
                    ),
                  ),
                ),
                if (lock != null)
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: _ShieldBadge(state: lock),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.t, this.color, this.busy);
  final double t;
  final Color color;
  final bool busy;
  @override
  void paint(Canvas canvas, Size s) {
    final r = Rect.fromLTWH(1.5, 1.5, s.width - 3, s.height - 3);
    canvas.drawArc(r, 0, 2 * math.pi, false, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = color.withValues(alpha: .18 * t));
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(colors: [color.withValues(alpha: 0), color]).createShader(r);
    canvas.drawArc(r, 0, (busy ? 1.6 : 1.1) * math.pi * t, false, p);
  }

  @override
  bool shouldRepaint(covariant _RingPainter o) => o.t != t || o.color != color || o.busy != busy;
}

class _ShieldBadge extends StatelessWidget {
  const _ShieldBadge({required this.state});
  final PfLockState state;
  @override
  Widget build(BuildContext context) {
    final (icon, bg) = switch (state) {
      PfLockState.locked => (Icons.lock_rounded, Pf.ink),
      PfLockState.checking => (Icons.shield_rounded, Pf.gold),
      PfLockState.unlocked => (Icons.lock_open_rounded, Pf.success),
      PfLockState.error => (Icons.gpp_bad_rounded, Pf.danger),
    };
    return AnimatedContainer(
      duration: PfMotion.quick,
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [BoxShadow(color: bg.withValues(alpha: .4), blurRadius: 12)],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 380),
        transitionBuilder: (c, a) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack), child: RotationTransition(turns: Tween(begin: -.15, end: 0.0).animate(a), child: c)),
        child: Icon(icon, key: ValueKey(state), size: 16, color: Colors.white),
      ),
    );
  }
}

// ───────────────────────── Champ : label flottant, halo doré au focus, œil qui se transforme
InputDecoration pfAuthDecoration(String label, IconData icon, {Widget? suffix, String? hint}) => InputDecoration(
      labelText: label,
      hintText: hint,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      labelStyle: Pf.body(size: 14.5),
      floatingLabelStyle: Pf.label(size: 13, color: const Color(0xFFB7791F)),
      hintStyle: Pf.body(size: 14, color: Pf.faint),
      prefixIcon: Icon(icon, size: 20),
      prefixIconColor: WidgetStateColor.resolveWith((s) => s.contains(WidgetState.error)
          ? Pf.danger
          : s.contains(WidgetState.focused)
              ? Pf.gold
              : Pf.faint),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Pf.line)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Pf.line)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Pf.gold, width: 1.8)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Pf.danger)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Pf.danger, width: 1.8)),
      errorStyle: Pf.body(size: 11.5, color: Pf.danger),
    );

/// Halo doré doux autour d'un champ quand il a le focus.
class PfFocusGlow extends StatefulWidget {
  const PfFocusGlow({super.key, required this.child});
  final Widget child;
  @override
  State<PfFocusGlow> createState() => _PfFocusGlowState();
}

class _PfFocusGlowState extends State<PfFocusGlow> {
  bool _f = false;
  @override
  Widget build(BuildContext context) => Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onFocusChange: (v) => setState(() => _f = v),
        child: AnimatedContainer(
          duration: PfMotion.quick,
          curve: PfMotion.ease,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: (_f ? Pf.gold : Pf.ink).withValues(alpha: _f ? .22 : .04), blurRadius: _f ? 22 : 12, offset: const Offset(0, 6)),
            ],
          ),
          child: widget.child,
        ),
      );
}

/// Bouton œil : morph œil ouvert ↔ barré (rotation + échelle).
class PfEyeToggle extends StatelessWidget {
  const PfEyeToggle({super.key, required this.visible, required this.onChanged});
  final bool visible;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: visible ? 'Masquer' : 'Afficher',
        onPressed: () {
          HapticFeedback.selectionClick();
          onChanged(!visible);
        },
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          transitionBuilder: (c, a) => RotationTransition(
            turns: Tween(begin: .5, end: 1.0).animate(a),
            child: ScaleTransition(scale: a, child: c),
          ),
          child: Icon(
            visible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            key: ValueKey(visible),
            color: visible ? Pf.gold : Pf.faint,
            size: 21,
          ),
        ),
      );
}

// ───────────────────────── Secousse d'erreur
class PfShake extends StatefulWidget {
  const PfShake({super.key, required this.child});
  final Widget child;
  @override
  State<PfShake> createState() => PfShakeState();
}

class PfShakeState extends State<PfShake> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 460));
  void shake() {
    HapticFeedback.mediumImpact();
    if (PfMotion.reduced(context)) return;
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, child) => Transform.translate(offset: Offset(math.sin(_c.value * math.pi * 6) * 10 * (1 - _c.value), 0), child: child),
        child: widget.child,
      );
}

// ───────────────────────── Bouton liquide (Dc7xjbKTa7h) : idle → vague → check / erreur
enum PfLiquidState { idle, loading, success, error }

class PfLiquidButton extends StatefulWidget {
  const PfLiquidButton({super.key, required this.label, required this.onPressed, this.state = PfLiquidState.idle, this.icon, this.loadingLabel, this.successLabel = 'Connecté', this.errorLabel = 'Réessayez', this.gold = false});
  /// Variante dorée (texte navy) pour les CTA d'accueil.
  final bool gold;
  final String label;
  final String? loadingLabel;
  final String successLabel;
  final String errorLabel;
  final IconData? icon;
  final VoidCallback? onPressed;
  final PfLiquidState state;
  @override
  State<PfLiquidButton> createState() => _PfLiquidButtonState();
}

class _PfLiquidButtonState extends State<PfLiquidButton> with TickerProviderStateMixin {
  late final AnimationController _wave = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
  late final AnimationController _fill = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));
  late final AnimationController _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 460));
  bool _down = false;

  @override
  void didUpdateWidget(covariant PfLiquidButton old) {
    super.didUpdateWidget(old);
    if (old.state == widget.state) return;
    final reduced = PfMotion.reduced(context);
    switch (widget.state) {
      case PfLiquidState.loading:
        if (!reduced) _wave.repeat();
        // Remplissage asymptotique : n'atteint jamais 100 % tant que le serveur n'a pas répondu.
        _fill.animateTo(.85, curve: Curves.easeOutCubic);
      case PfLiquidState.success:
        _fill.animateTo(1, duration: const Duration(milliseconds: 260));
        HapticFeedback.lightImpact();
      case PfLiquidState.error:
        _wave.stop();
        _fill.animateTo(0, duration: const Duration(milliseconds: 300));
        if (!reduced) _shake.forward(from: 0);
        HapticFeedback.heavyImpact();
      case PfLiquidState.idle:
        _wave.stop();
        _fill.animateTo(0, duration: const Duration(milliseconds: 300));
    }
  }

  @override
  void dispose() {
    _wave.dispose();
    _fill.dispose();
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = widget.state;
    final enabled = widget.onPressed != null && st == PfLiquidState.idle || st == PfLiquidState.error && widget.onPressed != null;
    final (label, icon) = switch (st) {
      PfLiquidState.idle => (widget.label, widget.icon ?? Icons.arrow_forward_rounded),
      PfLiquidState.loading => (widget.loadingLabel ?? 'Vérification…', null),
      PfLiquidState.success => (widget.successLabel, Icons.check_rounded),
      PfLiquidState.error => (widget.errorLabel, Icons.refresh_rounded),
    };
    final base = st == PfLiquidState.error ? Pf.danger : (widget.gold ? Pf.gold : Pf.ink);
    final fg = widget.gold && st == PfLiquidState.idle ? Pf.ink : Colors.white;
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: enabled
            ? (_) {
                setState(() => _down = false);
                HapticFeedback.selectionClick();
                widget.onPressed?.call();
              }
            : null,
        child: AnimatedBuilder(
          animation: Listenable.merge([_wave, _fill, _shake]),
          builder: (_, __) {
            final dx = math.sin(_shake.value * math.pi * 6) * 8 * (1 - _shake.value);
            return Transform.translate(
              offset: Offset(dx, 0),
              child: AnimatedOpacity(
                duration: PfMotion.quick,
                opacity: widget.onPressed == null && st == PfLiquidState.idle ? .45 : 1,
                child: AnimatedScale(
                scale: _down ? .96 : 1,
                duration: PfMotion.quick,
                child: AnimatedContainer(
                  duration: PfMotion.quick,
                  height: 58,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: st == PfLiquidState.success ? Pf.success : base,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(color: (st == PfLiquidState.success ? Pf.success : base).withValues(alpha: .35), blurRadius: 22, offset: const Offset(0, 10))],
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (st != PfLiquidState.error)
                        CustomPaint(painter: _WavePainter(_fill.value, _wave.value, st == PfLiquidState.success ? Pf.success : (widget.gold ? Pf.ink : Pf.gold))),
                      // reflet « glass »
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        height: 26,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white.withValues(alpha: .16), Colors.white.withValues(alpha: 0)]),
                          ),
                        ),
                      ),
                      Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          transitionBuilder: (c, a) => FadeTransition(opacity: a, child: SlideTransition(position: Tween(begin: const Offset(0, .4), end: Offset.zero).animate(a), child: c)),
                          child: Row(
                            key: ValueKey(st),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (st == PfLiquidState.loading)
                                const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white)),
                              if (st == PfLiquidState.loading) const SizedBox(width: 10),
                              Text(label, style: Pf.label(size: 15.5, color: fg, w: FontWeight.w800).copyWith(letterSpacing: .2)),
                              if (icon != null) ...[
                                const SizedBox(width: 10),
                                Icon(icon, color: st == PfLiquidState.idle ? (widget.gold ? Pf.ink : Pf.gold) : Colors.white, size: 20),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter(this.fill, this.phase, this.color);
  final double fill, phase;
  final Color color;
  @override
  void paint(Canvas canvas, Size s) {
    if (fill <= 0) return;
    final level = s.height * (1 - fill);
    final p = Path()..moveTo(0, s.height);
    for (double x = 0; x <= s.width; x += 4) {
      p.lineTo(x, level + math.sin((x / s.width * 2 * math.pi) + phase * 2 * math.pi) * 5 * (1 - fill * .6));
    }
    p
      ..lineTo(s.width, s.height)
      ..close();
    canvas.drawPath(p, Paint()..color = color.withValues(alpha: .9));
  }

  @override
  bool shouldRepaint(covariant _WavePainter o) => o.fill != fill || o.phase != phase || o.color != color;
}

// ───────────────────────── Étapes de sécurité (réf. DcOUIemTImO)
class PfSecuritySteps extends StatelessWidget {
  const PfSecuritySteps({super.key, required this.step, this.failed = false, this.labels = const ['Identifiants', 'Vérification', 'Authentification']});
  final List<String> labels;
  /// 0 = rien, 1 = identifiants validés, 2 = vérification, 3 = authentifié.
  final int step;
  final bool failed;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 3; i++) ...[
          Flexible(flex: 2, child: _dot(i + 1 <= step, failed && i + 1 == step + 1, i + 1 == step + 1 && step > 0 && !failed, labels[i])),
          if (i < 2)
            Expanded(
              flex: 1,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                height: 2,
                margin: const EdgeInsets.only(bottom: 18),
                color: i + 2 <= step ? Pf.success : Pf.line,
              ),
            ),
        ],
      ],
    );
  }

  Widget _dot(bool done, bool fail, bool active, String label) {
    final col = fail
        ? Pf.danger
        : done
            ? Pf.success
            : active
                ? Pf.gold
                : Pf.faint;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? Pf.success : Colors.white,
            border: Border.all(color: col, width: 2),
            boxShadow: active ? [BoxShadow(color: Pf.gold.withValues(alpha: .4), blurRadius: 10)] : null,
          ),
          child: done ? const Icon(Icons.check_rounded, size: 13, color: Colors.white) : null,
        ),
        const SizedBox(height: 6),
        FittedBox(fit: BoxFit.scaleDown, child: Text(label, maxLines: 1, style: Pf.body(size: 10.5, color: col == Pf.faint ? Pf.muted : col, w: FontWeight.w700))),
      ],
    );
  }
}

/// Transition « fondu + zoom léger » vers l'accueil après connexion.
Route<T> pfAuthSuccessRoute<T>(Widget page) => PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 650),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (ctx, a, __, child) {
        if (PfMotion.reduced(ctx)) return FadeTransition(opacity: a, child: child);
        final c = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
        return FadeTransition(opacity: c, child: ScaleTransition(scale: Tween(begin: 1.06, end: 1.0).animate(c), child: child));
      },
    );

/// Entrée en cascade (fade + montée, 80 ms entre éléments) d'une liste d'enfants.
List<Widget> pfStagger(List<Widget> children) => [
      for (var i = 0; i < children.length; i++)
        children[i] is SizedBox || children[i] is Spacer ? children[i] : PfReveal(index: i, dy: 20, child: children[i]),
    ];
