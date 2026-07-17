import 'package:flutter_test/flutter_test.dart';
import 'package:payflex_mobile/core/finance/client_bonus_savings_logic.dart';

void main() {
  group('officialDaysInMonth', () {
    test('is the number of days in the month minus one', () {
      // January has 31 days.
      expect(ClientBonusSavingsLogic.officialDaysInMonth(2026, 1), 30);
      // February 2026 (not a leap year) has 28 days.
      expect(ClientBonusSavingsLogic.officialDaysInMonth(2026, 2), 27);
      // February 2028 (leap year) has 29 days.
      expect(ClientBonusSavingsLogic.officialDaysInMonth(2028, 2), 28);
    });
  });

  group('monthlyClientBonus', () {
    test('is half of the daily contribution', () {
      expect(ClientBonusSavingsLogic.monthlyClientBonus(1000), 500);
    });

    test('is 0 for a zero or negative daily contribution', () {
      expect(ClientBonusSavingsLogic.monthlyClientBonus(0), 0);
      expect(ClientBonusSavingsLogic.monthlyClientBonus(-100), 0);
    });
  });

  group('monthlyLineBonus', () {
    test('is half of (unit daily min * quantity)', () {
      expect(
        ClientBonusSavingsLogic.monthlyLineBonus(unitDailyMin: 300, quantity: 2),
        300,
      );
    });

    test('is 0 when unitDailyMin is not positive', () {
      expect(ClientBonusSavingsLogic.monthlyLineBonus(unitDailyMin: 0, quantity: 3), 0);
      expect(ClientBonusSavingsLogic.monthlyLineBonus(unitDailyMin: -50, quantity: 3), 0);
    });

    test('is 0 when quantity is not positive', () {
      expect(ClientBonusSavingsLogic.monthlyLineBonus(unitDailyMin: 300, quantity: 0), 0);
      expect(ClientBonusSavingsLogic.monthlyLineBonus(unitDailyMin: 300, quantity: -1), 0);
    });
  });

  group('activeMonthsFromTransactions', () {
    test('counts distinct year-month pairs among validated transactions', () {
      final txs = [
        {'status': 'validated', 'date': '2026-01-05T00:00:00.000'},
        {'status': 'validated', 'date': '2026-01-20T00:00:00.000'},
        {'status': 'validated', 'date': '2026-02-01T00:00:00.000'},
      ];
      expect(ClientBonusSavingsLogic.activeMonthsFromTransactions(txs), 2);
    });

    test('ignores non-validated transactions', () {
      final txs = [
        {'status': 'pending', 'date': '2026-01-05T00:00:00.000'},
        {'status': 'rejected', 'date': '2026-02-05T00:00:00.000'},
      ];
      expect(ClientBonusSavingsLogic.activeMonthsFromTransactions(txs), 0);
    });

    test('ignores entries with an unparsable or missing date', () {
      final txs = [
        {'status': 'validated', 'date': 'not-a-date'},
        {'status': 'validated'},
      ];
      expect(ClientBonusSavingsLogic.activeMonthsFromTransactions(txs), 0);
    });

    test('returns 0 for an empty list', () {
      expect(ClientBonusSavingsLogic.activeMonthsFromTransactions(const []), 0);
    });
  });

  group('accruedBonus', () {
    test('multiplies the monthly bonus by the number of active months', () {
      expect(
        ClientBonusSavingsLogic.accruedBonus(dailyContribution: 1000, activeMonths: 3),
        1500, // 500/month * 3
      );
    });

    test('is 0 when there are no active months', () {
      expect(
        ClientBonusSavingsLogic.accruedBonus(dailyContribution: 1000, activeMonths: 0),
        0,
      );
    });
  });

  group('BonusSavingsLine.fromMap', () {
    test('parses a well-formed line', () {
      final line = BonusSavingsLine.fromMap({
        'productName': 'Frigo',
        'quantity': 2,
        'unitDailyMinFcfa': 300.0,
        'monthlyBonusFcfa': 300.0,
      });
      expect(line.productName, 'Frigo');
      expect(line.quantity, 2);
      expect(line.unitDailyMin, 300.0);
      expect(line.monthlyBonus, 300.0);
    });

    test('applies sensible defaults for missing fields', () {
      final line = BonusSavingsLine.fromMap(const {});
      expect(line.productName, 'Article');
      expect(line.quantity, 1);
      expect(line.unitDailyMin, 0);
      expect(line.monthlyBonus, 0);
    });
  });

  group('BonusSavingsSummary.fromMap', () {
    test('parses a full backend payload including nested bonus lines', () {
      final summary = BonusSavingsSummary.fromMap({
        'bonusSavingsFcfa': 4500.0,
        'bonusSavingsMonthlyFcfa': 500.0,
        'activeMonthsCount': 9,
        'officialDaysThisMonth': 30,
        'dailyContributionFcfa': 1000.0,
        'bonusLines': [
          {
            'productName': 'Frigo',
            'quantity': 1,
            'unitDailyMinFcfa': 500.0,
            'monthlyBonusFcfa': 250.0,
          },
        ],
        'ruleLabel': '50/50',
        'lastCreditedYearMonth': '2026-06',
        'currentMonthCredited': true,
        'creditedInDatabase': true,
      });

      expect(summary.accruedFcfa, 4500.0);
      expect(summary.monthlyFcfa, 500.0);
      expect(summary.activeMonths, 9);
      expect(summary.officialDaysThisMonth, 30);
      expect(summary.dailyContribution, 1000.0);
      expect(summary.lines, hasLength(1));
      expect(summary.lines.single.productName, 'Frigo');
      expect(summary.ruleLabel, '50/50');
      expect(summary.currentMonthCredited, isTrue);
      expect(summary.creditedInDatabase, isTrue);
      expect(summary.hasData, isTrue);
    });

    test('defaults to an empty line list when bonusLines is absent or malformed', () {
      final summary = BonusSavingsSummary.fromMap(const {});
      expect(summary.lines, isEmpty);
      expect(summary.hasData, isFalse);
    });

    test('hasData is true when only the daily contribution is set', () {
      final summary = BonusSavingsSummary.fromMap({'dailyContributionFcfa': 200.0});
      expect(summary.hasData, isTrue);
    });
  });
}
