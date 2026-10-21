import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'pf_motion.dart';
import 'pf_tokens.dart';

/// Saisie de code en cases (PIN / code de vérification) :
/// cases arrondies, case active dorée, avance automatique, collage d'un code
/// complet, état erreur rouge + secousse, masquage optionnel.
/// Un seul TextField invisible pilote les cases (clavier numérique, collage
/// et effacement natifs).
class PfCodeInput extends StatefulWidget {
  const PfCodeInput({
    super.key,
    required this.controller,
    this.length = 4,
    this.obscure = true,
    this.enabled = true,
    this.error = false,
    this.onCompleted,
    this.onChanged,
    this.focusNode,
    this.boxSize = 64,
  });

  final TextEditingController controller;
  final int length;
  final bool obscure;
  final bool enabled;
  final bool error;
  final ValueChanged<String>? onCompleted;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final double boxSize;

  @override
  State<PfCodeInput> createState() => PfCodeInputState();
}

class PfCodeInputState extends State<PfCodeInput> with SingleTickerProviderStateMixin {
  late final FocusNode _focus = widget.focusNode ?? FocusNode();
  late final AnimationController _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 480));

  /// Secousse (erreur). Ignorée si « réduire les animations ».
  void shake() {
    HapticFeedback.mediumImpact();
    if (PfMotion.reduced(context)) return;
    _shake.forward(from: 0);
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onText);
    _focus.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(PfCodeInput old) {
    super.didUpdateWidget(old);
    if (!old.error && widget.error) shake();
  }

  void _onText() => setState(() {});

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    if (widget.focusNode == null) _focus.dispose();
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text;
    final active = _focus.hasFocus ? math.min(text.length, widget.length - 1) : -1;
    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) {
        final t = _shake.value;
        final dx = math.sin(t * math.pi * 6) * 10 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Champ réel (invisible) : clavier, collage, effacement
          Opacity(
            opacity: 0,
            child: SizedBox(
              height: widget.boxSize,
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                enabled: widget.enabled,
                autofocus: false,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                maxLength: widget.length,
                showCursor: false,
                enableInteractiveSelection: true,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(widget.length)],
                decoration: const InputDecoration(counterText: '', border: InputBorder.none, filled: false),
                onChanged: (v) {
                  widget.onChanged?.call(v);
                  if (v.length == widget.length) widget.onCompleted?.call(v);
                },
              ),
            ),
          ),
          IgnorePointer(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.length; i++) ...[
                  if (i > 0) const SizedBox(width: Pf.s12),
                  _Box(
                    size: widget.boxSize,
                    char: i < text.length ? (widget.obscure ? '•' : text[i]) : '',
                    filled: i < text.length,
                    active: i == active && widget.enabled,
                    error: widget.error,
                  ),
                ],
              ],
            ),
          ),
          // Zone de tap pour ouvrir le clavier
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: widget.enabled ? () => _focus.requestFocus() : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.size, required this.char, required this.filled, required this.active, required this.error});
  final double size;
  final String char;
  final bool filled, active, error;

  @override
  Widget build(BuildContext context) {
    final border = error ? Pf.danger : (active ? Pf.gold : (filled ? Pf.ink.withValues(alpha: 0.35) : Pf.line));
    return AnimatedContainer(
      duration: PfMotion.quick,
      curve: Curves.easeOut,
      width: size,
      height: size * 1.12,
      decoration: BoxDecoration(
        color: error ? Pf.danger.withValues(alpha: 0.06) : Pf.surface,
        borderRadius: Pf.br(Pf.rMd),
        border: Border.all(color: border, width: active || error ? 2 : 1.2),
        boxShadow: active ? [BoxShadow(color: Pf.gold.withValues(alpha: 0.28), blurRadius: 16)] : Pf.shadowSoft,
      ),
      alignment: Alignment.center,
      child: AnimatedSwitcher(
        duration: PfMotion.quick,
        transitionBuilder: (c, a) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack), child: c),
        child: char.isEmpty
            ? (active ? _Caret(key: const ValueKey('caret')) : const SizedBox(key: ValueKey('e')))
            : Text(char, key: ValueKey(char), style: Pf.num(size: 28, color: error ? Pf.danger : Pf.ink)),
      ),
    );
  }
}

class _Caret extends StatefulWidget {
  const _Caret({super.key});
  @override
  State<_Caret> createState() => _CaretState();
}

class _CaretState extends State<_Caret> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _c,
        child: Container(width: 2, height: 26, color: Pf.gold),
      );
}
