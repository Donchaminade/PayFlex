import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'receipt_data.dart';

/// Polices + logo nécessaires au PDF (chargés depuis les assets par l'appelant).
class ReceiptPdfAssets {
  final Uint8List logo;
  final Uint8List manrope700, manrope800, inter400, inter600;
  const ReceiptPdfAssets({required this.logo, required this.manrope700, required this.manrope800, required this.inter400, required this.inter600});
}

const _ink = PdfColor.fromInt(0xFF00314F);
const _inkDeep = PdfColor.fromInt(0xFF001F33);
const _gold = PdfColor.fromInt(0xFFF9A825);
const _green = PdfColor.fromInt(0xFF38A169);
const _muted = PdfColor.fromInt(0xFF64748B);
const _line = PdfColor.fromInt(0xFFE3E8EE);
const _canvas = PdfColor.fromInt(0xFFF8FAFC);

/// Génère le PDF du reçu (format A5 portrait, style ticket PayFlex).
Future<Uint8List> buildReceiptPdf(ReceiptData d, ReceiptPdfAssets a) async {
  final m7 = pw.Font.ttf(a.manrope700.buffer.asByteData());
  final m8 = pw.Font.ttf(a.manrope800.buffer.asByteData());
  final i4 = pw.Font.ttf(a.inter400.buffer.asByteData());
  final i6 = pw.Font.ttf(a.inter600.buffer.asByteData());
  final logo = pw.MemoryImage(a.logo);
  final doc = pw.Document(title: 'Reçu PayFlex ${d.reference}', author: 'PayFlex', theme: pw.ThemeData.withFont(base: i4, bold: i6));

  pw.Widget row(String k, String v, {bool strong = false}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 5),
        child: pw.Row(children: [
          pw.Text(k, style: pw.TextStyle(font: i4, fontSize: 9, color: _muted)),
          pw.Spacer(),
          pw.Text(v, style: pw.TextStyle(font: strong ? m8 : m7, fontSize: strong ? 11 : 9.5, color: _ink)),
        ]),
      );

  final rows = <pw.Widget>[
    row('Référence', d.reference),
    row('Date', d.dateLabel),
    row('Heure', d.timeLabel),
    if (d.clientName != null) row('Client', d.clientName!),
    if (d.projectName != null) row('Projet', d.projectName!),
    if (d.agentName != null) row('Agent', d.agentName!),
    row('Mode de paiement', d.paymentModeLabel),
    row('Jours de plan couverts', '${d.slotsCount > 0 ? d.slotsCount : 1}'),
    pw.Divider(color: _line, thickness: 0.6),
    row('Montant', ReceiptData.fcfa(d.amount), strong: true),
  ];

  doc.addPage(pw.Page(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.symmetric(horizontal: 90, vertical: 60),
    build: (ctx) => pw.Stack(children: [
      // Filigrane : motif du logo, très discret.
      pw.Positioned.fill(
        child: pw.Opacity(
          opacity: 0.045,
          child: pw.Wrap(
            spacing: 34,
            runSpacing: 34,
            children: List.generate(48, (_) => pw.Image(logo, width: 44, height: 44)),
          ),
        ),
      ),
      pw.Column(children: [
        pw.Container(
          padding: const pw.EdgeInsets.fromLTRB(20, 18, 20, 18),
          decoration: const pw.BoxDecoration(
            gradient: pw.LinearGradient(colors: [_ink, _inkDeep], begin: pw.Alignment.topLeft, end: pw.Alignment.bottomRight),
            borderRadius: pw.BorderRadius.vertical(top: pw.Radius.circular(16)),
          ),
          child: pw.Row(children: [
            pw.Container(
              width: 38, height: 38, padding: const pw.EdgeInsets.all(5),
              decoration: const pw.BoxDecoration(color: PdfColors.white, borderRadius: pw.BorderRadius.all(pw.Radius.circular(10))),
              child: pw.Image(logo),
            ),
            pw.SizedBox(width: 12),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('PayFlex', style: pw.TextStyle(font: m8, fontSize: 16, color: PdfColors.white)),
              pw.Text('REÇU DE COTISATION', style: pw.TextStyle(font: i6, fontSize: 7.5, color: _gold, letterSpacing: 1.4)),
            ]),
            pw.Spacer(),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: pw.BoxDecoration(color: d.awaitingValidation ? _gold : _green, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(9))),
              child: pw.Text(d.statusLabel, style: pw.TextStyle(font: m8, fontSize: 9, color: PdfColors.white)),
            ),
          ]),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.fromLTRB(20, 18, 20, 18),
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            border: pw.Border.all(color: _line, width: 0.8),
            borderRadius: pw.BorderRadius.vertical(bottom: pw.Radius.circular(16)),
          ),
          child: pw.Column(children: [
            pw.Text('Montant cotisé', style: pw.TextStyle(font: i4, fontSize: 9, color: _muted)),
            pw.SizedBox(height: 4),
            pw.Text(ReceiptData.fcfa(d.amount), style: pw.TextStyle(font: m8, fontSize: 26, color: _green)),
            pw.SizedBox(height: 12),
            // Perforation du ticket
            pw.Row(children: List.generate(46, (i) => pw.Expanded(child: pw.Container(height: 1, color: i.isEven ? _line : PdfColors.white)))),
            pw.SizedBox(height: 10),
            ...rows,
            if (d.progress != null) ...[
              pw.SizedBox(height: 10),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: const pw.BoxDecoration(color: _canvas, borderRadius: pw.BorderRadius.all(pw.Radius.circular(10))),
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Row(children: [
                    pw.Text('Progression du projet', style: pw.TextStyle(font: i6, fontSize: 8.5, color: _ink)),
                    pw.Spacer(),
                    pw.Text('${(d.progress! * 100).round()} %', style: pw.TextStyle(font: m8, fontSize: 9, color: _gold)),
                  ]),
                  pw.SizedBox(height: 6),
                  pw.Stack(children: [
                    pw.Container(height: 5, decoration: const pw.BoxDecoration(color: _line, borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)))),
                    pw.Container(
                        width: 351 * d.progress!, height: 5,
                        decoration: const pw.BoxDecoration(color: _gold, borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)))),
                  ]),
                  pw.SizedBox(height: 5),
                  pw.Text('${ReceiptData.fcfa(d.projectSaved!)} sur ${ReceiptData.fcfa(d.projectTotal!)}',
                      style: pw.TextStyle(font: i4, fontSize: 8, color: _muted)),
                ]),
              ),
            ],
            pw.SizedBox(height: 14),
            pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
              pw.BarcodeWidget(barcode: pw.Barcode.qrCode(), data: d.reference, width: 62, height: 62, color: _ink),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: pw.Text(
                  d.awaitingValidation
                      ? 'Paiement enregistré, en attente de validation par votre agent PayFlex.'
                      : 'Paiement confirmé. Conservez ce reçu : le QR code contient la référence de la transaction.',
                  style: pw.TextStyle(font: i4, fontSize: 8, color: _muted, lineSpacing: 2),
                ),
              ),
            ]),
          ]),
        ),
        pw.SizedBox(height: 18),
        pw.Text('PayFlex — Épargnez à votre rythme', style: pw.TextStyle(font: i6, fontSize: 8, color: _muted)),
      ]),
    ]),
  ));
  return doc.save();
}
