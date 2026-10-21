import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/design/pf_components.dart';
import '../../core/design/pf_motion.dart';
import '../../core/design/pf_tokens.dart';
import '../auth/widgets/payflex_logo.dart';
import 'receipt/receipt_data.dart';
import 'receipt/receipt_pdf.dart';

/// Reçu de cotisation consultable + téléchargeable (PDF).
class ContributionReceiptScreen extends StatefulWidget {
  final double amount;
  final String reference;
  final DateTime paidAt;
  final String paymentModeLabel;
  final int slotsCount;
  final bool awaitingValidation;
  final String? clientName;
  final String? projectName;
  final String? agentName;
  final double? projectSaved;
  final double? projectTotal;

  const ContributionReceiptScreen({
    super.key,
    required this.amount,
    required this.reference,
    required this.paidAt,
    required this.paymentModeLabel,
    required this.slotsCount,
    this.awaitingValidation = false,
    this.clientName,
    this.projectName,
    this.agentName,
    this.projectSaved,
    this.projectTotal,
  });

  ReceiptData get data => ReceiptData(
        amount: amount,
        reference: reference,
        paidAt: paidAt,
        paymentModeLabel: paymentModeLabel,
        slotsCount: slotsCount,
        awaitingValidation: awaitingValidation,
        clientName: clientName,
        projectName: projectName,
        agentName: agentName,
        projectSaved: projectSaved,
        projectTotal: projectTotal,
      );

  @override
  State<ContributionReceiptScreen> createState() => _ContributionReceiptScreenState();
}

enum _DlState { idle, busy, done }

Future<ReceiptPdfAssets> loadReceiptPdfAssets() async {
  Future<Uint8List> b(String p) async => (await rootBundle.load(p)).buffer.asUint8List();
  return ReceiptPdfAssets(
    logo: await b(PayFlexLogo.assetPath),
    manrope700: await b('assets/fonts/manrope-700.ttf'),
    manrope800: await b('assets/fonts/manrope-800.ttf'),
    inter400: await b('assets/fonts/inter-400.ttf'),
    inter600: await b('assets/fonts/inter-600.ttf'),
  );
}

class _ContributionReceiptScreenState extends State<ContributionReceiptScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
  _DlState _dl = _DlState.idle;
  bool _sharing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (PfMotion.reduced(context)) {
      _c.value = 1;
    } else if (!_c.isAnimating && _c.value == 0) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<Uint8List> _pdf() async => buildReceiptPdf(widget.data, await loadReceiptPdfAssets());

  Future<void> _download() async {
    if (_dl == _DlState.busy) return;
    HapticFeedback.lightImpact();
    setState(() => _dl = _DlState.busy);
    try {
      final bytes = await _pdf();
      if (kIsWeb) {
        // Sur le web, sharePdf déclenche le téléchargement du fichier.
        await Printing.sharePdf(bytes: bytes, filename: widget.data.fileName);
      } else {
        // Android / iOS : feuille système « Enregistrer en PDF / Imprimer ».
        await Printing.layoutPdf(onLayout: (_) async => bytes, name: widget.data.fileName);
      }
      if (!mounted) return;
      setState(() => _dl = _DlState.done);
      await Future<void>.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _dl = _DlState.idle);
    } catch (e) {
      if (!mounted) return;
      setState(() => _dl = _DlState.idle);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible de générer le reçu. Réessayez.')));
    }
  }

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      await Printing.sharePdf(bytes: await _pdf(), filename: widget.data.fileName);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Partage indisponible pour le moment.')));
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Animation<double> _iv(double a, double b, [Curve c = Curves.easeOutCubic]) =>
      CurvedAnimation(parent: _c, curve: Interval(a, b, curve: c));

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final slide = _iv(0, .55);
    return Scaffold(
      backgroundColor: Pf.canvas,
      appBar: PfAppBar(title: 'Reçu de cotisation'),
      body: Stack(
        children: [
          const Positioned.fill(child: _LogoWatermark()),
          SafeArea(
            top: false,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(Pf.gutter, 8, Pf.gutter, 24),
                    child: AnimatedBuilder(
                      animation: slide,
                      builder: (_, child) => Opacity(
                        opacity: slide.value,
                        child: Transform.translate(offset: Offset(0, 60 * (1 - slide.value)), child: child),
                      ),
                      child: _ticket(d),
                    ),
                  ),
                ),
                _actions(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ticket(ReceiptData d) {
    final ok = !d.awaitingValidation;
    return PhysicalShape(
      clipper: const _TicketClipper(notchY: 236, notchR: 12),
      color: Pf.surface,
      elevation: 10,
      shadowColor: Pf.ink.withValues(alpha: .18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // En-tête navy
          Container(
            height: 236,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Pf.ink, Pf.inkDeep], begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -40,
                  bottom: -50,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Pf.gold.withValues(alpha: .14), width: 26)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                            child: Transform.scale(scale: 1.9, child: const PayFlexLogo(size: 36)),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('PayFlex', style: Pf.title(color: Colors.white, size: 16)),
                              Text('REÇU DE COTISATION', style: Pf.overline().copyWith(fontSize: 9, letterSpacing: 1.4)),
                            ],
                          ),
                          const Spacer(),
                          _StatusChip(label: d.statusLabel, ok: ok),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: 56,
                        height: 56,
                        child: AnimatedBuilder(
                          animation: _iv(.35, .8),
                          builder: (_, __) => CustomPaint(
                            painter: _CheckPainter(t: _iv(.35, .8).value, ok: ok),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text('Montant cotisé', style: Pf.body(color: Colors.white70, size: 12)),
                      const SizedBox(height: 2),
                      PfAnimatedAmount(
                        value: d.amount,
                        format: ReceiptData.fcfa,
                        style: Pf.amount(color: ok ? const Color(0xFF5EE29A) : Pf.gold, size: 32),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Perforation
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            child: _Perforation(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              children: [
                _row(Icons.tag_rounded, 'Référence', d.reference, 0),
                _row(Icons.event_rounded, 'Date', d.dateLabel, 1),
                _row(Icons.schedule_rounded, 'Heure', d.timeLabel, 2),
                if (d.clientName != null) _row(Icons.person_rounded, 'Client', d.clientName!, 3),
                if (d.projectName != null) _row(Icons.workspaces_rounded, 'Projet', d.projectName!, 4),
                if (d.agentName != null) _row(Icons.badge_rounded, 'Agent', d.agentName!, 5),
                _row(Icons.account_balance_wallet_rounded, 'Mode de paiement', d.paymentModeLabel, 6),
                _row(Icons.calendar_view_week_rounded, 'Jours couverts', '${d.slotsCount > 0 ? d.slotsCount : 1}', 7),
                const Divider(height: 20, color: Pf.line),
                _row(Icons.payments_rounded, 'Montant', ReceiptData.fcfa(d.amount), 8, strong: true),
                if (d.progress != null) ...[const SizedBox(height: 14), _progress(d)],
                const SizedBox(height: 16),
                _qr(d),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String k, String v, int i, {bool strong = false}) => PfReveal(
        index: i,
        delay: const Duration(milliseconds: 450),
        dy: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: Pf.gold.withValues(alpha: .12), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 15, color: const Color(0xFFB7791F)),
              ),
              const SizedBox(width: 10),
              Text(k, style: Pf.body(size: 12.5)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  v,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: strong ? Pf.num(size: 16, color: Pf.success) : Pf.label(size: 13),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _progress(ReceiptData d) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Pf.canvas, borderRadius: BorderRadius.circular(16), border: Border.all(color: Pf.line)),
        child: Row(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: d.progress!),
              duration: PfMotion.reduced(context) ? Duration.zero : const Duration(milliseconds: 1400),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => SizedBox(
                width: 54,
                height: 54,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(value: v, strokeWidth: 5, strokeCap: StrokeCap.round, backgroundColor: Pf.line, color: Pf.gold),
                    Text('${(v * 100).round()}%', style: Pf.num(size: 12)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Progression du projet', style: Pf.label(size: 13)),
                  const SizedBox(height: 4),
                  Text('${ReceiptData.fcfa(d.projectSaved!)} / ${ReceiptData.fcfa(d.projectTotal!)}', style: Pf.num(size: 12, color: Pf.muted, w: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _qr(ReceiptData d) => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Pf.line)),
            child: QrImageView(
              data: d.reference,
              size: 76,
              padding: EdgeInsets.zero,
              eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.circle, color: Pf.ink),
              dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: Pf.ink),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              d.awaitingValidation
                  ? 'Paiement enregistré, en attente de validation par votre agent PayFlex.'
                  : 'Paiement confirmé. Le QR code contient la référence de la transaction.',
              style: Pf.body(size: 12),
            ),
          ),
        ],
      );

  Widget _actions() {
    final busy = _dl == _DlState.busy, done = _dl == _DlState.done;
    return Container(
      padding: const EdgeInsets.fromLTRB(Pf.gutter, 12, Pf.gutter, 16),
      decoration: BoxDecoration(color: Pf.surface, boxShadow: Pf.shadowSoft),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PfPressable(
            onTap: _download,
            child: AnimatedContainer(
              duration: PfMotion.quick,
              height: 54,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: done ? [Pf.success, Pf.success] : [Pf.gold, Pf.goldSoft]),
                borderRadius: BorderRadius.circular(Pf.s16),
                boxShadow: [BoxShadow(color: (done ? Pf.success : Pf.gold).withValues(alpha: .35), blurRadius: 18, offset: const Offset(0, 8))],
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: PfMotion.quick,
                  child: Row(
                    key: ValueKey(_dl),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (busy)
                        const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.4, color: Pf.ink))
                      else
                        Icon(done ? Icons.check_circle_rounded : Icons.download_rounded, color: done ? Colors.white : Pf.ink),
                      const SizedBox(width: 10),
                      Text(
                        busy ? 'Génération du PDF…' : done ? 'Reçu prêt' : 'Télécharger le reçu',
                        style: Pf.label(size: 15, color: done ? Colors.white : Pf.ink, w: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          PfPressable(
            onTap: _share,
            child: Container(
              height: 48,
              width: double.infinity,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(Pf.s16), border: Border.all(color: Pf.line, width: 1.4)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _sharing
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Pf.ink))
                      : const Icon(Icons.ios_share_rounded, size: 18, color: Pf.ink),
                  const SizedBox(width: 8),
                  Text('Partager', style: Pf.label(size: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.ok});
  final String label;
  final bool ok;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: (ok ? Pf.success : Pf.gold).withValues(alpha: .18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: (ok ? const Color(0xFF5EE29A) : Pf.gold).withValues(alpha: .6)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(ok ? Icons.verified_rounded : Icons.hourglass_top_rounded, size: 13, color: ok ? const Color(0xFF5EE29A) : Pf.gold),
          const SizedBox(width: 4),
          Text(label, style: Pf.label(size: 11.5, color: Colors.white)),
        ]),
      );
}

/// Motif très discret du logo en fond d'écran.
class _LogoWatermark extends StatelessWidget {
  const _LogoWatermark();
  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Opacity(
          opacity: .035,
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.topLeft,
              maxWidth: double.infinity,
              maxHeight: double.infinity,
              child: Transform.rotate(
                angle: -math.pi / 12,
                child: Wrap(
                  spacing: 42,
                  runSpacing: 42,
                  children: List.generate(90, (_) => Image.asset(PayFlexLogo.assetPath, width: 46, height: 46)),
                ).sized(700),
              ),
            ),
          ),
        ),
      );
}

extension on Widget {
  Widget sized(double w) => SizedBox(width: w, child: this);
}

class _Perforation extends StatelessWidget {
  const _Perforation();
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 1,
        child: LayoutBuilder(
          builder: (_, c) => Row(
            children: List.generate((c.maxWidth / 10).floor(), (i) => Expanded(child: Container(height: 1.4, color: i.isEven ? Pf.line : Colors.transparent))),
          ),
        ),
      );
}

/// Ticket aux encoches latérales au niveau de la perforation, coins arrondis.
class _TicketClipper extends CustomClipper<Path> {
  const _TicketClipper({required this.notchY, required this.notchR});
  final double notchY, notchR;
  @override
  Path getClip(Size s) {
    const r = 22.0;
    final w = s.width, h = s.height, y = notchY, n = notchR;
    return Path()
      ..moveTo(r, 0)
      ..lineTo(w - r, 0)
      ..arcToPoint(Offset(w, r), radius: const Radius.circular(r))
      ..lineTo(w, y - n)
      ..arcToPoint(Offset(w, y + n), radius: Radius.circular(n), clockwise: false)
      ..lineTo(w, h - r)
      ..arcToPoint(Offset(w - r, h), radius: const Radius.circular(r))
      ..lineTo(r, h)
      ..arcToPoint(Offset(0, h - r), radius: const Radius.circular(r))
      ..lineTo(0, y + n)
      ..arcToPoint(Offset(0, y - n), radius: Radius.circular(n), clockwise: false)
      ..lineTo(0, r)
      ..arcToPoint(const Offset(r, 0), radius: const Radius.circular(r))
      ..close();
  }

  @override
  bool shouldReclip(covariant _TicketClipper o) => o.notchY != notchY || o.notchR != notchR;
}

/// Cercle + coche qui se dessinent.
class _CheckPainter extends CustomPainter {
  _CheckPainter({required this.t, required this.ok});
  final double t;
  final bool ok;
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final col = ok ? const Color(0xFF5EE29A) : Pf.gold;
    canvas.drawCircle(c, size.width / 2, Paint()..color = col.withValues(alpha: .14 * t));
    final ring = Paint()
      ..color = col
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: c, radius: size.width / 2 - 2), -math.pi / 2, 2 * math.pi * (t * 1.6).clamp(0, 1), false, ring);
    final k = ((t - .45) / .55).clamp(0.0, 1.0);
    if (k <= 0) return;
    final w = size.width;
    final path = ok
        ? (Path()
          ..moveTo(w * .3, w * .52)
          ..lineTo(w * .45, w * .66)
          ..lineTo(w * .72, w * .38))
        : (Path()
          ..moveTo(w * .5, w * .3)
          ..lineTo(w * .5, w * .52)
          ..lineTo(w * .64, w * .62));
    for (final m in path.computeMetrics()) {
      canvas.drawPath(m.extractPath(0, m.length * k), ring..strokeWidth = 3.6);
    }
  }

  @override
  bool shouldRepaint(covariant _CheckPainter o) => o.t != t || o.ok != ok;
}
