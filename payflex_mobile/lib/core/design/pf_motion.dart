import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Spécifications d'animation par défaut :
/// fade + rise 0.5 s easeOut, cartes en cascade 80 ms, scale .95→1,
/// pression .96, respect de « réduire les animations ».
class PfMotion {
  PfMotion._();
  static const Duration enter = Duration(milliseconds: 500);
  static const Duration stagger = Duration(milliseconds: 80);
  static const Duration quick = Duration(milliseconds: 180);
  static const Duration slide = Duration(milliseconds: 380);
  static const Curve ease = Curves.easeOutCubic;
  static const Curve spring = Curves.easeOutBack;

  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}

/// Apparition fade + rise (+ scale optionnel) avec délai de cascade.
class PfReveal extends StatefulWidget {
  const PfReveal({super.key, required this.child, this.index = 0, this.delay = Duration.zero, this.scale = false, this.dy = 16});
  final Widget child;
  final int index;
  final Duration delay;
  final bool scale;
  final double dy;

  @override
  State<PfReveal> createState() => _PfRevealState();
}

class _PfRevealState extends State<PfReveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: PfMotion.enter);
  late final Animation<double> _t = CurvedAnimation(parent: _c, curve: PfMotion.ease);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.status != AnimationStatus.dismissed) return;
    if (PfMotion.reduced(context)) {
      _c.value = 1;
      return;
    }
    final wait = widget.delay + PfMotion.stagger * widget.index.clamp(0, 10);
    Future.delayed(wait, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (context, child) {
        final v = _t.value;
        Widget w = Transform.translate(offset: Offset(0, (1 - v) * widget.dy), child: child);
        if (widget.scale) w = Transform.scale(scale: 0.95 + 0.05 * v, child: w);
        return Opacity(opacity: v, child: w);
      },
    );
  }
}

/// Pression : scale .96 + retour haptique léger.
class PfPressable extends StatefulWidget {
  const PfPressable({super.key, required this.child, this.onTap, this.haptic = true, this.semanticLabel});
  final Widget child;
  final VoidCallback? onTap;
  final bool haptic;
  final String? semanticLabel;

  @override
  State<PfPressable> createState() => _PfPressableState();
}

class _PfPressableState extends State<PfPressable> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap == null) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final reduced = PfMotion.reduced(context);
    return Semantics(
      button: widget.onTap != null,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapCancel: () => _set(false),
        onTapUp: (_) => _set(false),
        onTap: widget.onTap == null
            ? null
            : () {
                if (widget.haptic) HapticFeedback.selectionClick();
                widget.onTap!();
              },
        child: AnimatedScale(
          scale: _down && !reduced ? 0.96 : 1,
          duration: PfMotion.quick,
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Montant animé (compteur) — chiffres tabulaires via le style passé.
class PfAnimatedAmount extends StatelessWidget {
  const PfAnimatedAmount({super.key, required this.value, required this.format, required this.style});
  final double value;
  final String Function(double) format;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    if (PfMotion.reduced(context)) return Text(format(value), style: style);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text(format(v), style: style, maxLines: 1),
    );
  }
}

/// Transition de page douce (fade + léger glissement), utilisée par le thème.
class PfPageTransitionsBuilder extends PageTransitionsBuilder {
  const PfPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(PageRoute<T> route, BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    if (PfMotion.reduced(context)) return child;
    final a = CurvedAnimation(parent: animation, curve: PfMotion.ease);
    return FadeTransition(
      opacity: a,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(a),
        child: child,
      ),
    );
  }
}
