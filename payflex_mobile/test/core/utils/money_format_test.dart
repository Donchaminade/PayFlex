import 'package:flutter_test/flutter_test.dart';
import 'package:payflex_mobile/core/utils/money_format.dart';

const _nbsp = '\u202F';

void main() {
  group('formatFcfa', () {
    test('formats a small amount without thousands separator', () {
      expect(formatFcfa(500), '500${_nbsp}F');
    });

    test('groups thousands using the thin non-breaking space', () {
      expect(formatFcfa(25000), '25${_nbsp}000${_nbsp}F');
    });

    test('groups millions with two separators', () {
      expect(formatFcfa(1500000), '1${_nbsp}500${_nbsp}000${_nbsp}F');
    });

    test('formats zero', () {
      expect(formatFcfa(0), '0${_nbsp}F');
    });

    test('formats a negative amount with a leading minus sign', () {
      expect(formatFcfa(-5000), '-5${_nbsp}000${_nbsp}F');
    });

    test('formats a negative amount smaller than 1000', () {
      expect(formatFcfa(-42), '-42${_nbsp}F');
    });

    test('rounds a fractional amount to the nearest integer (round half up)', () {
      expect(formatFcfa(1500.6), '1${_nbsp}501${_nbsp}F');
      expect(formatFcfa(1500.4), '1${_nbsp}500${_nbsp}F');
    });

    test('formats a very large amount with multiple separators', () {
      expect(formatFcfa(123456789), '123${_nbsp}456${_nbsp}789${_nbsp}F');
    });

    test('omits the suffix when withSuffix is false', () {
      expect(formatFcfa(25000, withSuffix: false), '25${_nbsp}000');
    });

    test('omits the suffix for a negative amount when withSuffix is false', () {
      expect(formatFcfa(-25000, withSuffix: false), '-25${_nbsp}000');
    });

    test('supports a custom suffix', () {
      expect(formatFcfa(25000, suffix: 'FCFA'), '25${_nbsp}000${_nbsp}FCFA');
    });

    test('exactly on a thousands boundary (1000) gets one separator', () {
      expect(formatFcfa(1000), '1${_nbsp}000${_nbsp}F');
    });

    test('999 stays ungrouped (below the first boundary)', () {
      expect(formatFcfa(999), '999${_nbsp}F');
    });
  });

  group('formatFcfaLong', () {
    test('uses the FCFA suffix', () {
      expect(formatFcfaLong(25000), '25${_nbsp}000${_nbsp}FCFA');
    });

    test('formats zero with the long suffix', () {
      expect(formatFcfaLong(0), '0${_nbsp}FCFA');
    });

    test('formats a negative amount with the long suffix', () {
      expect(formatFcfaLong(-1000), '-1${_nbsp}000${_nbsp}FCFA');
    });
  });
}
