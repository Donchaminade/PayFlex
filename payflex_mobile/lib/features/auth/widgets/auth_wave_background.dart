import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/design/pf_tokens.dart';
import 'auth_kit.dart';

/// Fond commun des écrans d'authentification : aurore animée or/navy (orbes qui dérivent),
/// champs à label flottant + halo doré (thème local).
class AuthWaveBackground extends StatelessWidget {
  final Widget child;
  final bool dark;
  const AuthWaveBackground({super.key, required this.child, this.dark = false});

  static const double decorHeight = 110;

  @override
  Widget build(BuildContext context) {
    final keyboardBottom = MediaQuery.viewInsetsOf(context).bottom;
    final base = Theme.of(context);
    OutlineInputBorder ob(Color c, [double w = 1]) =>
        OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c, width: w));
    return Theme(
      data: base.copyWith(
        inputDecorationTheme: base.inputDecorationTheme.copyWith(
          filled: true,
          fillColor: Colors.white,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          floatingLabelStyle: const TextStyle(color: Color(0xFFB7791F), fontWeight: FontWeight.w700),
          border: ob(Pf.line),
          enabledBorder: ob(Pf.line),
          focusedBorder: ob(Pf.gold, 1.8),
          errorBorder: ob(Pf.danger),
          focusedErrorBorder: ob(Pf.danger, 1.8),
        ),
      ),
      child: Scaffold(
        backgroundColor: Pf.canvas,
        resizeToAvoidBottomInset: false,
        body: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(child: PfAuroraBackground(dark: dark)),
            Padding(
              padding: EdgeInsets.only(bottom: keyboardBottom),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

/// Bandeau décoratif bas : une seule courbe supérieure lisse, sans « pointe » verticale.
class FintechCurvesPainter extends CustomPainter {
  const FintechCurvesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Bleu nuit (arrière-plan)
    final pathBlue = Path()
      ..moveTo(0, h)
      ..lineTo(w, h)
      ..lineTo(w, h - 36)
      ..quadraticBezierTo(w * 0.72, h - 8, w * 0.28, h - 32)
      ..quadraticBezierTo(w * 0.06, h - 48, 0, h - 28)
      ..close();

    canvas.drawPath(
      pathBlue,
      Paint()
        ..color = AppColors.secondary
        ..style = PaintingStyle.fill,
    );

    // Orange (devant) — bord supérieur = une courbe, pas de trait vertical à gauche
    final pathYellow = Path()
      ..moveTo(0, h)
      ..lineTo(w, h)
      ..lineTo(w, h - 48)
      ..quadraticBezierTo(w * 0.58, h - 62, w * 0.14, h - 40)
      ..quadraticBezierTo(0, h - 44, 0, h - 24)
      ..close();

    canvas.drawPath(
      pathYellow,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
