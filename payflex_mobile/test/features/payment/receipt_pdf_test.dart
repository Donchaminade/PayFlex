import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:payflex_mobile/features/payment/receipt/receipt_data.dart';
import 'package:payflex_mobile/features/payment/receipt/receipt_pdf.dart';

void main() {
  final d = ReceiptData(
    amount: 1300,
    reference: 'PF-1761036000',
    paidAt: DateTime(2026, 10, 21, 9, 12),
    paymentModeLabel: 'T-Money',
    slotsCount: 2,
    clientName: 'Ama Kossiwa Mensah',
    projectName: 'Machine à coudre Juki Pro',
    agentName: 'Kodjo Agbeko',
    projectSaved: 96500,
    projectTotal: 185000,
  );

  test('format FCFA et libellés', () {
    expect(ReceiptData.fcfa(185000), '185\u00A0000 FCFA');
    expect(d.statusLabel, 'Payé');
    expect(d.dateLabel, '21/10/2026');
    expect(d.timeLabel, '09:12');
    expect(d.progress, closeTo(.52, .01));
    expect(d.fileName, 'recu-payflex-PF-1761036000.pdf');
  });

  test('génère un PDF valide', () async {
    final assets = ReceiptPdfAssets(
      logo: File('assets/icons/logo.png').readAsBytesSync(),
      manrope700: File('assets/fonts/manrope-700.ttf').readAsBytesSync(),
      manrope800: File('assets/fonts/manrope-800.ttf').readAsBytesSync(),
      inter400: File('assets/fonts/inter-400.ttf').readAsBytesSync(),
      inter600: File('assets/fonts/inter-600.ttf').readAsBytesSync(),
    );
    final bytes = await buildReceiptPdf(d, assets);
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    final out = Platform.environment['RECEIPT_PDF_OUT'];
    if (out != null) File(out).writeAsBytesSync(bytes);
  });
}
