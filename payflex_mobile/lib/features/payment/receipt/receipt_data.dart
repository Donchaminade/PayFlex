/// Données d'un reçu de cotisation (uniquement des données déjà présentes dans l'app).
class ReceiptData {
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

  const ReceiptData({
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

  double? get progress =>
      (projectSaved != null && projectTotal != null && projectTotal! > 0) ? (projectSaved! / projectTotal!).clamp(0.0, 1.0) : null;

  String get statusLabel => awaitingValidation ? 'En attente' : 'Payé';

  static String two(int v) => v.toString().padLeft(2, '0');
  String get dateLabel => '${two(paidAt.day)}/${two(paidAt.month)}/${paidAt.year}';
  String get timeLabel => '${two(paidAt.hour)}:${two(paidAt.minute)}';

  static String fcfa(double v) {
    final s = v.round().abs().toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('\u00A0');
      b.write(s[i]);
    }
    return '${v < 0 ? '-' : ''}$b FCFA';
  }

  String get fileName => 'recu-payflex-${reference.replaceAll(RegExp(r'[^A-Za-z0-9-]'), '')}.pdf';
}
