import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../theme/app_typography.dart';

/// Design tokens « Explore » appliqués à la charte PayFlex
/// (jaune doré #F9A825 + bleu marine #00314F, Manrope / Inter).
/// Grille 8 pt : toutes les marges sont des multiples de 4/8.
class Pf {
  Pf._();

  // Couleurs (charte PayFlex existante uniquement)
  static const Color ink = AppColors.secondary; // #00314F
  static const Color inkDeep = Color(0xFF001F33); // dégradé secondaire existant
  static const Color gold = AppColors.primary; // #F9A825
  static const Color goldSoft = Color(0xFFFFB300); // dégradé primaire existant
  static const Color canvas = Color(0xFFF8FAFC); // fond clair existant des écrans
  static const Color surface = Colors.white;
  static const Color fill = Color(0xFFEEF2F6); // champs / recherche
  static const Color line = Color(0xFFE3E8EE);
  static const Color muted = Color(0xFF64748B);
  static const Color faint = Color(0xFF94A3B8);
  static const Color success = Color(0xFF38A169);
  static const Color danger = AppColors.error;

  // Espacements (8 pt)
  static const double s4 = 4, s8 = 8, s12 = 12, s16 = 16, s20 = 20, s24 = 24, s32 = 32, s40 = 40, s48 = 48;
  static const double gutter = 24;

  // Rayons
  static const double rSm = 12, rMd = 16, rLg = 20, rXl = 24, rXxl = 28;
  static BorderRadius br(double r) => BorderRadius.circular(r);

  // Ombres en couches (douces)
  static List<BoxShadow> get shadowSoft => [
        BoxShadow(color: ink.withValues(alpha: 0.04), blurRadius: 2, offset: const Offset(0, 1)),
        BoxShadow(color: ink.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 8)),
      ];
  static List<BoxShadow> get shadowLift => [
        BoxShadow(color: ink.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 2)),
        BoxShadow(color: ink.withValues(alpha: 0.18), blurRadius: 32, offset: const Offset(0, 16)),
      ];

  static const LinearGradient featuredGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A4468), ink, inkDeep],
    stops: [0, 0.55, 1],
  );

  // Typographie
  static const _tab = [FontFeature.tabularFigures()];

  static TextStyle display({Color color = ink, double size = 34}) => AppTypography.manrope(
        fontSize: size, fontWeight: FontWeight.w800, color: color, height: 1.08, letterSpacing: -1.1);
  static TextStyle title({Color color = ink, double size = 20}) => AppTypography.manrope(
        fontSize: size, fontWeight: FontWeight.w800, color: color, height: 1.2, letterSpacing: -0.4);
  static TextStyle label({Color color = ink, double size = 14, FontWeight w = FontWeight.w700}) =>
      AppTypography.manrope(fontSize: size, fontWeight: w, color: color, letterSpacing: -0.1);
  static TextStyle body({Color color = muted, double size = 13, FontWeight w = FontWeight.w500}) =>
      AppTypography.inter(fontSize: size, fontWeight: w, color: color, height: 1.4);
  static TextStyle overline({Color color = gold}) =>
      AppTypography.manrope(fontSize: 10, fontWeight: FontWeight.w800, color: color, letterSpacing: 1.4);
  static TextStyle amount({Color color = ink, double size = 32}) => AppTypography.manrope(
        fontSize: size, fontWeight: FontWeight.w800, color: color, letterSpacing: -1, height: 1.05)
      .copyWith(fontFeatures: _tab);
  static TextStyle num({Color color = ink, double size = 14, FontWeight w = FontWeight.w800}) =>
      AppTypography.manrope(fontSize: size, fontWeight: w, color: color).copyWith(fontFeatures: _tab);
}
