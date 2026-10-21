import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'pf_motion.dart';
import 'pf_tokens.dart';

export 'pf_motion.dart';
export 'pf_tokens.dart';

/// En-tête « Explore » : gros titre + sous-titre + bouton rond (cloche…).
class PfHeader extends StatelessWidget {
  const PfHeader({super.key, required this.title, this.eyebrow, this.trailing = const []});
  final String title;
  final String? eyebrow;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Pf.gutter, Pf.s16, Pf.gutter, Pf.s16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null) ...[
                  Text(eyebrow!, style: Pf.body(size: 13, w: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: Pf.s4),
                ],
                Text(title, style: Pf.display(), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          for (final t in trailing) ...[const SizedBox(width: Pf.s8), t],
        ],
      ),
    );
  }
}

/// Bouton rond contouré (cloche, panier…) avec pastille dorée optionnelle.
class PfCircleButton extends StatelessWidget {
  const PfCircleButton({super.key, required this.icon, this.onTap, this.badge = 0, this.dot = false, this.semanticLabel, this.dark = false});
  final IconData icon;
  final VoidCallback? onTap;
  final int badge;
  final bool dot;
  final bool dark;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return PfPressable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: dark ? Colors.white.withValues(alpha: 0.10) : Pf.surface,
              shape: BoxShape.circle,
              border: Border.all(color: dark ? Colors.white24 : Pf.line),
              boxShadow: dark ? null : Pf.shadowSoft,
            ),
            child: Icon(icon, size: 22, color: dark ? Colors.white : Pf.ink),
          ),
          if (badge > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                constraints: const BoxConstraints(minWidth: 20),
                height: 20,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Pf.gold,
                  borderRadius: Pf.br(10),
                  border: Border.all(color: Pf.surface, width: 2),
                ),
                child: Text(badge > 99 ? '99+' : '$badge', style: Pf.num(size: 10, color: Pf.ink)),
              ),
            )
          else if (dot)
            Positioned(
              top: 10,
              right: 12,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(color: Pf.gold, shape: BoxShape.circle, border: Border.all(color: Pf.surface, width: 1.5)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Barre de recherche arrondie + bouton filtre.
class PfSearchBar extends StatelessWidget {
  const PfSearchBar({
    super.key,
    this.controller,
    this.hint = 'Rechercher',
    this.onChanged,
    this.onTap,
    this.onFilter,
    this.onClear,
    this.readOnly = false,
  });
  final TextEditingController? controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final VoidCallback? onFilter;
  final VoidCallback? onClear;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.only(left: Pf.s16, right: Pf.s8),
      decoration: BoxDecoration(color: Pf.fill, borderRadius: Pf.br(Pf.rLg)),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Pf.muted, size: 22),
          const SizedBox(width: Pf.s12),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onTap: onTap,
              readOnly: readOnly,
              style: Pf.label(w: FontWeight.w600),
              cursorColor: Pf.ink,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: Pf.body(color: Pf.faint, size: 14),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (onClear != null && (controller?.text.isNotEmpty ?? false))
            IconButton(onPressed: onClear, icon: const Icon(Icons.close_rounded, size: 20, color: Pf.muted)),
          if (onFilter != null)
            PfPressable(
              onTap: onFilter,
              semanticLabel: 'Filtres',
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: Pf.surface, borderRadius: Pf.br(Pf.rSm), boxShadow: Pf.shadowSoft),
                child: const Icon(Icons.tune_rounded, size: 20, color: Pf.ink),
              ),
            ),
        ],
      ),
    );
  }
}

class PfTabItem {
  const PfTabItem(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Onglets catégories à icônes, onglet actif souligné en doré (glisse).
class PfCategoryTabs extends StatelessWidget {
  const PfCategoryTabs({super.key, required this.items, required this.selected, required this.onSelected});
  final List<PfTabItem> items;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 68,
      child: Stack(
        children: [
          Positioned(left: 0, right: 0, bottom: 0, child: Container(height: 1, color: Pf.line)),
          ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Pf.gutter),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: Pf.s24),
            itemBuilder: (context, i) {
              final active = i == selected;
              final it = items[i];
              return PfPressable(
                onTap: () => onSelected(i),
                semanticLabel: it.label,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AnimatedScale(
                      scale: active ? 1.06 : 1,
                      duration: PfMotion.quick,
                      child: Icon(it.icon, size: 24, color: active ? Pf.ink : Pf.faint),
                    ),
                    const SizedBox(height: Pf.s8),
                    AnimatedDefaultTextStyle(
                      duration: PfMotion.quick,
                      style: Pf.label(size: 12, color: active ? Pf.ink : Pf.faint, w: active ? FontWeight.w800 : FontWeight.w600),
                      child: Text(it.label),
                    ),
                    const SizedBox(height: Pf.s8),
                    AnimatedContainer(
                      duration: PfMotion.slide,
                      curve: PfMotion.ease,
                      height: 3,
                      width: active ? 28 : 0,
                      decoration: BoxDecoration(color: Pf.gold, borderRadius: Pf.br(2)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Pastille (badge doré « NOUVEAU », chip blanche sur photo, CTA).
class PfPillChip extends StatelessWidget {
  const PfPillChip({super.key, required this.label, this.icon, this.tone = PfChipTone.gold, this.onTap, this.large = false});
  final String label;
  final IconData? icon;
  final PfChipTone tone;
  final VoidCallback? onTap;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      PfChipTone.gold => (Pf.gold, Pf.ink),
      PfChipTone.white => (Colors.white, Pf.ink),
      PfChipTone.glass => (Colors.white.withValues(alpha: 0.14), Colors.white),
      PfChipTone.ink => (Pf.ink, Colors.white),
      PfChipTone.success => (Pf.success.withValues(alpha: 0.12), Pf.success),
      PfChipTone.warn => (Pf.gold.withValues(alpha: 0.16), const Color(0xFF8A5A00)),
      PfChipTone.danger => (Pf.danger.withValues(alpha: 0.10), Pf.danger),
    };
    final chip = Container(
      padding: EdgeInsets.symmetric(horizontal: large ? Pf.s20 : Pf.s12, vertical: large ? Pf.s12 : 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: Pf.br(999),
        boxShadow: tone == PfChipTone.white ? Pf.shadowSoft : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: large ? 18 : 13, color: tone == PfChipTone.white ? Pf.gold : fg), const SizedBox(width: 6)],
          Text(label, style: large ? Pf.label(size: 14, color: fg, w: FontWeight.w800) : Pf.overline(color: fg).copyWith(letterSpacing: 0.6, fontSize: 11)),
        ],
      ),
    );
    return onTap == null ? chip : PfPressable(onTap: onTap, child: chip);
  }
}

enum PfChipTone { gold, white, glass, ink, success, warn, danger }

/// Carte vedette marine (dégradé + verre) : badge, titre, sous-titre, CTA, visuel à droite.
class PfFeaturedCard extends StatelessWidget {
  const PfFeaturedCard({
    super.key,
    required this.badge,
    required this.title,
    this.subtitle,
    this.cta,
    this.onCta,
    this.onTap,
    this.image,
    this.trailing,
    this.height = 184,
    this.titleWidget,
  });
  final String badge;
  final String title;
  final Widget? titleWidget;
  final String? subtitle;
  final String? cta;
  final VoidCallback? onCta;
  final VoidCallback? onTap;
  final ImageProvider? image;
  final Widget? trailing;
  final double height;

  @override
  Widget build(BuildContext context) {
    return PfPressable(
      onTap: onTap,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(borderRadius: Pf.br(Pf.rXxl), gradient: Pf.featuredGradient, boxShadow: Pf.shadowLift),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // halo doré doux
            Positioned(
              left: -60,
              bottom: -90,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [Pf.gold.withValues(alpha: 0.22), Pf.gold.withValues(alpha: 0)]),
                ),
              ),
            ),
            if (image != null)
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                width: 150,
                child: ShaderMask(
                  shaderCallback: (r) => const LinearGradient(colors: [Colors.transparent, Colors.black], stops: [0, 0.35]).createShader(r),
                  blendMode: BlendMode.dstIn,
                  child: Image(image: image!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()),
                ),
              ),
            if (trailing != null) Positioned(top: 0, bottom: 0, right: Pf.s20, child: Center(child: trailing!)),
            // filet verre
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: Pf.br(Pf.rXxl),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Pf.s20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PfPillChip(label: badge),
                  const Spacer(),
                  SizedBox(
                    width: (image != null || trailing != null) ? 180 : double.infinity,
                    child: titleWidget ?? Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: Pf.title(color: Colors.white, size: 22)),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: Pf.s4),
                    SizedBox(
                      width: 200,
                      child: Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: Pf.body(color: Colors.white.withValues(alpha: 0.7))),
                    ),
                  ],
                  if (cta != null) ...[
                    const SizedBox(height: Pf.s16),
                    PfPillChip(label: cta!, tone: PfChipTone.white, onTap: onCta, large: false),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// En-tête de section « Titre » + lien « Voir tout ».
class PfSectionHeader extends StatelessWidget {
  const PfSectionHeader({super.key, required this.title, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Pf.gutter),
      child: Row(
        children: [
          Expanded(child: Text(title, style: Pf.title(size: 19))),
          if (action != null)
            PfPressable(
              onTap: onAction,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Pf.s8),
                child: Text(action!, style: Pf.label(size: 13, color: Pf.muted).copyWith(decoration: TextDecoration.underline, decorationColor: Pf.faint)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Carte photo arrondie (carrousel) : chip blanche + bouton cœur + légende.
class PfPhotoCard extends StatefulWidget {
  const PfPhotoCard({super.key, required this.image, required this.title, this.subtitle, this.chip, this.chipIcon = Icons.bolt_rounded, this.onTap, this.width = 232, this.height = 276, this.heroTag, this.price});
  final ImageProvider image;
  final String title;
  final String? subtitle;
  final String? price;
  final String? chip;
  final IconData chipIcon;
  final VoidCallback? onTap;
  final double width;
  final double height;
  final Object? heroTag;

  @override
  State<PfPhotoCard> createState() => _PfPhotoCardState();
}

class _PfPhotoCardState extends State<PfPhotoCard> {
  bool _liked = false;

  @override
  Widget build(BuildContext context) {
    Widget img = Image(
      image: widget.image,
      fit: BoxFit.cover,
      frameBuilder: (c, child, frame, sync) => frame == null && !sync ? const PfShimmer() : child,
      errorBuilder: (_, __, ___) => const _ImageFallback(),
    );
    if (widget.heroTag != null) img = Hero(tag: widget.heroTag!, child: img);
    return PfPressable(
      onTap: widget.onTap,
      child: SizedBox(
        width: widget.width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: widget.height - 64,
              decoration: BoxDecoration(borderRadius: Pf.br(Pf.rXl), boxShadow: Pf.shadowSoft),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  img,
                  if (widget.chip != null)
                    Positioned(left: Pf.s12, top: Pf.s12, child: PfPillChip(label: widget.chip!, icon: widget.chipIcon, tone: PfChipTone.white)),
                  Positioned(
                    right: Pf.s12,
                    top: Pf.s12,
                    child: PfPressable(
                      onTap: () => setState(() => _liked = !_liked),
                      semanticLabel: 'Favori',
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: AnimatedSwitcher(
                          duration: PfMotion.quick,
                          transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                          child: Icon(_liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              key: ValueKey(_liked), size: 18, color: _liked ? Pf.gold : Pf.ink),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Pf.s12),
            Row(
              children: [
                Expanded(child: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Pf.label(size: 15))),
                if (widget.price != null) Text(widget.price!, style: Pf.num(size: 13)),
              ],
            ),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 2),
              Text(widget.subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: Pf.body(size: 12)),
            ],
          ],
        ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();
  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFE9EEF3), Color(0xFFDCE3EA)])),
        child: const Center(child: Icon(Icons.inventory_2_rounded, color: Pf.faint, size: 36)),
      );
}

/// Squelette « shimmer ».
class PfShimmer extends StatefulWidget {
  const PfShimmer({super.key, this.radius = 0, this.width, this.height});
  final double radius;
  final double? width;
  final double? height;
  @override
  State<PfShimmer> createState() => _PfShimmerState();
}

class _PfShimmerState extends State<PfShimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!PfMotion.reduced(context) && !_c.isAnimating) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final x = -1.5 + 3 * _c.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: Pf.br(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(x - 1, 0),
              end: Alignment(x + 1, 0),
              colors: const [Color(0xFFEAEFF4), Color(0xFFF6F8FA), Color(0xFFEAEFF4)],
            ),
          ),
        );
      },
    );
  }
}

/// Anneau de progression (paiement, projets).
class PfRing extends StatelessWidget {
  const PfRing({super.key, required this.value, this.size = 56, this.stroke = 6, this.color = Pf.gold, this.track, this.child});
  final double value;
  final double size;
  final double stroke;
  final Color color;
  final Color? track;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    final reduced = PfMotion.reduced(context);
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: reduced ? v : 0, end: v),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (_, t, __) => CustomPaint(
          painter: _RingPainter(t, stroke, color, track ?? color.withValues(alpha: 0.16)),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.v, this.stroke, this.color, this.track);
  final double v, stroke;
  final Color color, track;
  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(r, 0, math.pi * 2, false, p..color = track);
    if (v > 0) canvas.drawArc(r, -math.pi / 2, math.pi * 2 * v, false, p..color = color);
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.v != v || o.color != color;
}

/// État vide / erreur illustré.
class PfEmptyState extends StatelessWidget {
  const PfEmptyState({super.key, required this.icon, required this.title, this.message, this.action, this.onAction});
  final IconData icon;
  final String title;
  final String? message;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Pf.s40, vertical: Pf.s32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [Pf.gold.withValues(alpha: 0.18), Pf.gold.withValues(alpha: 0.04)]),
            ),
            child: Icon(icon, size: 36, color: Pf.ink),
          ),
          const SizedBox(height: Pf.s16),
          Text(title, textAlign: TextAlign.center, style: Pf.title(size: 17)),
          if (message != null) ...[
            const SizedBox(height: Pf.s8),
            Text(message!, textAlign: TextAlign.center, style: Pf.body()),
          ],
          if (action != null) ...[
            const SizedBox(height: Pf.s20),
            PfPillChip(label: action!, tone: PfChipTone.ink, large: true, onTap: onAction),
          ],
        ],
      ),
    );
  }
}

class PfNavItem {
  const PfNavItem({required this.icon, required this.activeIcon, required this.label, this.badge = false});
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool badge;
}

/// Barre d'onglets flottante marine : onglet actif = pilule blanche icône + libellé (glisse).
class PfFloatingTabBar extends StatelessWidget {
  const PfFloatingTabBar({super.key, required this.items, required this.index, required this.onTap});
  final List<PfNavItem> items;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final reduced = PfMotion.reduced(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(Pf.s16, 0, Pf.s16, math.max(bottom, Pf.s16)),
      child: Container(
        height: 68,
        decoration: BoxDecoration(borderRadius: Pf.br(34), boxShadow: Pf.shadowLift),
        child: ClipRRect(
          borderRadius: Pf.br(34),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.all(Pf.s8),
              decoration: BoxDecoration(
                color: Pf.ink.withValues(alpha: 0.96),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                borderRadius: Pf.br(34),
              ),
              child: LayoutBuilder(builder: (context, c) {
                // l'actif prend 2 parts, les autres 1
                final unit = c.maxWidth / (items.length + 1.4);
                final activeW = unit * 2.4;
                return Stack(
                  children: [
                    AnimatedPositioned(
                      duration: reduced ? Duration.zero : PfMotion.slide,
                      curve: PfMotion.ease,
                      left: unit * index,
                      top: 0,
                      bottom: 0,
                      width: activeW,
                      child: DecoratedBox(decoration: BoxDecoration(color: Colors.white, borderRadius: Pf.br(26))),
                    ),
                    Row(
                      children: [
                        for (var i = 0; i < items.length; i++)
                          AnimatedContainer(
                            duration: reduced ? Duration.zero : PfMotion.slide,
                            curve: PfMotion.ease,
                            width: i == index ? activeW : unit,
                            child: PfPressable(
                              onTap: () => onTap(i),
                              semanticLabel: items[i].label,
                              child: SizedBox.expand(child: _TabContent(item: items[i], active: i == index)),
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabContent extends StatelessWidget {
  const _TabContent({required this.item, required this.active});
  final PfNavItem item;
  final bool active;
  @override
  Widget build(BuildContext context) {
    final icon = Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(active ? item.activeIcon : item.icon, size: 22, color: active ? Pf.ink : Colors.white.withValues(alpha: 0.62)),
        if (item.badge)
          Positioned(
            right: -3,
            top: -3,
            child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Pf.gold, shape: BoxShape.circle)),
          ),
      ],
    );
    if (!active) return Center(child: icon);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        icon,
        const SizedBox(width: Pf.s8),
        Flexible(
          child: Text(item.label, maxLines: 1, overflow: TextOverflow.fade, softWrap: false, style: Pf.label(size: 13, w: FontWeight.w800)),
        ),
      ],
    );
  }
}

/// Carte surface blanche standard.
class PfCard extends StatelessWidget {
  const PfCard({super.key, required this.child, this.padding = const EdgeInsets.all(Pf.s16), this.onTap, this.color = Pf.surface});
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color color;
  @override
  Widget build(BuildContext context) {
    final c = Container(
      padding: padding,
      decoration: BoxDecoration(color: color, borderRadius: Pf.br(Pf.rLg), boxShadow: Pf.shadowSoft, border: Border.all(color: Pf.line.withValues(alpha: 0.6))),
      child: child,
    );
    return onTap == null ? c : PfPressable(onTap: onTap, child: c);
  }
}
