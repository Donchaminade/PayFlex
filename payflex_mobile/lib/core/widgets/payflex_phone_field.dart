import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';

import '../design/pf_tokens.dart';
import '../utils/phone_input_utils.dart';

/// Champ téléphone international : drapeau + indicatif pays, **Togo (+228)** par défaut.
///
/// [completeNumberController] reçoit le numéro complet (ex. `+22890123456`) à chaque saisie.
class PayflexPhoneField extends StatefulWidget {
  const PayflexPhoneField({
    super.key,
    required this.completeNumberController,
    this.hint = 'Numéro de téléphone',
    this.label = 'Téléphone',
    this.validator,
    this.required = true,
    this.initialCountryCode = 'TG',
    this.textStyle,
  });

  final TextEditingController completeNumberController;
  final String hint;
  final String label;
  final String? Function(String?)? validator;
  final bool required;
  final String initialCountryCode;
  final TextStyle? textStyle;

  @override
  State<PayflexPhoneField> createState() => _PayflexPhoneFieldState();
}

class _PayflexPhoneFieldState extends State<PayflexPhoneField> {
  late final TextEditingController _nationalController;
  String _countryCode = 'TG';
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _countryCode = widget.initialCountryCode;
    _nationalController = TextEditingController();
    _applyStoredCompleteNumber(widget.completeNumberController.text);
    widget.completeNumberController.addListener(_onExternalControllerChanged);
  }

  @override
  void dispose() {
    widget.completeNumberController.removeListener(_onExternalControllerChanged);
    _nationalController.dispose();
    super.dispose();
  }

  void _onExternalControllerChanged() {
    final stored = widget.completeNumberController.text;
    if (stored.isEmpty) {
      if (_nationalController.text.isNotEmpty) {
        _nationalController.clear();
      }
      return;
    }
    final currentComplete = _buildCompleteFromParts();
    if (stored != currentComplete) {
      _applyStoredCompleteNumber(stored);
    }
  }

  void _applyStoredCompleteNumber(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return;

    try {
      final parsed = PhoneNumber.fromCompleteNumber(completeNumber: trimmed);
      if (!mounted) return;
      setState(() {
        _countryCode = parsed.countryISOCode;
        _nationalController.text = parsed.number;
      });
    } catch (_) {
      final digits = PayflexPhoneValidator.digitsOnly(trimmed);
      final country = countries.firstWhere(
        (c) => c.code == widget.initialCountryCode,
        orElse: () => countries.first,
      );
      String national = digits;
      final dialDigits = country.dialCode;
      if (national.startsWith(dialDigits)) {
        national = national.substring(dialDigits.length);
      }
      if (!mounted) return;
      setState(() {
        _countryCode = country.code;
        _nationalController.text = national;
      });
      widget.completeNumberController.text = '+$dialDigits$national';
    }
  }

  String _buildCompleteFromParts() {
    final country = countries.firstWhere(
      (c) => c.code == _countryCode,
      orElse: () => countries.firstWhere((c) => c.code == 'TG'),
    );
    final national = _nationalController.text.replaceAll(RegExp(r'\D'), '');
    if (national.isEmpty) return '';
    return '+${country.dialCode}$national';
  }

  void _syncCompleteNumber(String nationalDigits) {
    final country = countries.firstWhere(
      (c) => c.code == _countryCode,
      orElse: () => countries.firstWhere((c) => c.code == 'TG'),
    );
    final digits = nationalDigits.replaceAll(RegExp(r'\D'), '');
    final complete = digits.isEmpty ? '' : '+${country.dialCode}$digits';
    if (widget.completeNumberController.text != complete) {
      widget.completeNumberController.text = complete;
    }
  }

  InputDecoration _decoration() {
    OutlineInputBorder ob(Color c, [double w = 1]) =>
        OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c, width: w));
    return InputDecoration(
      labelText: widget.label,
      hintText: widget.hint,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      labelStyle: GoogleFonts.inter(color: Pf.muted, fontSize: 14.5, fontWeight: FontWeight.w500),
      floatingLabelStyle: GoogleFonts.manrope(color: const Color(0xFFB7791F), fontSize: 13, fontWeight: FontWeight.w700),
      hintStyle: GoogleFonts.inter(color: Pf.faint, fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      border: ob(Pf.line),
      enabledBorder: ob(Pf.line),
      focusedBorder: ob(Pf.gold, 1.8),
      errorBorder: ob(Pf.danger),
      focusedErrorBorder: ob(Pf.danger, 1.8),
      errorStyle: GoogleFonts.inter(fontSize: 11.5, color: Pf.danger),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.textStyle ??
        GoogleFonts.inter(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w500);

    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (v) => setState(() => _focused = v),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (_focused ? Pf.gold : Pf.ink).withValues(alpha: _focused ? .22 : .04),
              blurRadius: _focused ? 22 : 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: IntlPhoneField(
      controller: _nationalController,
      initialCountryCode: _countryCode,
      languageCode: 'fr',
      invalidNumberMessage: 'Numéro invalide',
      disableLengthCheck: true,
      decoration: _decoration(),
      style: style,
      dropdownTextStyle: style.copyWith(fontSize: 14),
      flagsButtonPadding: const EdgeInsets.only(left: 4, right: 4),
      dropdownIcon: const Icon(Icons.expand_more_rounded, color: Pf.gold, size: 20),
      onCountryChanged: (country) {
        setState(() => _countryCode = country.code);
        _syncCompleteNumber(_nationalController.text);
      },
      onChanged: (phone) {
        widget.completeNumberController.text = phone.completeNumber;
      },
      validator: (value) {
        final fromField = value == null ? '' : value.toString().trim();
        final complete = widget.completeNumberController.text.trim().isNotEmpty
            ? widget.completeNumberController.text.trim()
            : fromField;
        if (widget.validator != null) {
          return widget.validator!(complete);
        }
        return PayflexPhoneValidator.validate(complete, required: widget.required);
      },
        ),
      ),
    );
  }
}
