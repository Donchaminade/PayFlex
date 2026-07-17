import 'package:flutter_test/flutter_test.dart';
import 'package:payflex_mobile/core/calendar/calendar_plan_logic.dart';

void main() {
  group('estimateDaysRemaining', () {
    test('returns 0 when there is no daily contribution configured', () {
      expect(
        CalendarPlanLogic.estimateDaysRemaining(targetAmount: 10000, savedAmount: 0, dailySuggested: 0),
        0,
      );
    });

    test('returns 0 when the target is already reached', () {
      expect(
        CalendarPlanLogic.estimateDaysRemaining(targetAmount: 10000, savedAmount: 10000, dailySuggested: 500),
        0,
      );
    });

    test('returns 0 when the saved amount exceeds the target', () {
      expect(
        CalendarPlanLogic.estimateDaysRemaining(targetAmount: 10000, savedAmount: 12000, dailySuggested: 500),
        0,
      );
    });

    test('rounds up a partial remaining day (ceil, never underestimates)', () {
      // remaining = 4900, daily = 500 -> 9.8 -> ceil -> 10
      expect(
        CalendarPlanLogic.estimateDaysRemaining(targetAmount: 10000, savedAmount: 5100, dailySuggested: 500),
        10,
      );
    });

    test('divides evenly when the remainder is exact', () {
      expect(
        CalendarPlanLogic.estimateDaysRemaining(targetAmount: 10000, savedAmount: 5000, dailySuggested: 500),
        10,
      );
    });
  });

  group('estimateEndDate', () {
    test('returns null when there is nothing left to save', () {
      expect(
        CalendarPlanLogic.estimateEndDate(targetAmount: 10000, savedAmount: 10000, dailySuggested: 500),
        isNull,
      );
    });

    test('returns null when the daily contribution is 0', () {
      expect(
        CalendarPlanLogic.estimateEndDate(targetAmount: 10000, savedAmount: 0, dailySuggested: 0),
        isNull,
      );
    });

    test('adds the estimated remaining days to the "from" date', () {
      final from = DateTime(2026, 1, 1);
      final end = CalendarPlanLogic.estimateEndDate(
        targetAmount: 10000,
        savedAmount: 5000,
        dailySuggested: 500,
        from: from,
      );
      expect(end, DateTime(2026, 1, 11));
    });
  });

  group('countGaps / countOrange', () {
    test('countGaps counts both gris (missed) and orange (pending catch-up) days', () {
      final statuses = {1: 'vert', 2: 'gris', 3: 'orange', 4: 'bleu', 5: 'gris'};
      expect(CalendarPlanLogic.countGaps(statuses), 3);
    });

    test('countOrange only counts orange days', () {
      final statuses = {1: 'vert', 2: 'gris', 3: 'orange', 4: 'orange'};
      expect(CalendarPlanLogic.countOrange(statuses), 2);
    });

    test('both return 0 for an empty map', () {
      expect(CalendarPlanLogic.countGaps(const {}), 0);
      expect(CalendarPlanLogic.countOrange(const {}), 0);
    });
  });

  group('buildDayStatuses', () {
    test('marks past days as vert while enough paid slots remain', () {
      final now = DateTime.now();
      final statuses = CalendarPlanLogic.buildDayStatuses(
        savedAmount: 3000,
        dailySuggested: 500,
        validatedCatchUpDaysInMonth: const {},
        year: now.year,
        month: now.month,
      );
      // 3000 / 500 = 6 paid slots consumed starting from day 1.
      expect(statuses[1], 'vert');
    });

    test('marks days beyond the paid slots as gris (unpaid)', () {
      final now = DateTime.now();
      final lastDay = DateTime(now.year, now.month + 1, 0).day;
      final statuses = CalendarPlanLogic.buildDayStatuses(
        savedAmount: 0,
        dailySuggested: 500,
        validatedCatchUpDaysInMonth: const {},
        year: now.year,
        month: now.month,
      );
      expect(statuses.length, lastDay);
      expect(statuses.values.every((s) => s == 'gris'), isTrue);
    });

    test('a pending catch-up day flips an otherwise-gris day to orange', () {
      final now = DateTime.now();
      final statuses = CalendarPlanLogic.buildDayStatuses(
        savedAmount: 0,
        dailySuggested: 500,
        validatedCatchUpDaysInMonth: const {},
        year: now.year,
        month: now.month,
        pendingCatchUpDays: {1},
      );
      expect(statuses[1], 'orange');
    });

    test('a validated catch-up day is vert (past) or bleu (future) regardless of remaining slots', () {
      final now = DateTime.now();
      final statuses = CalendarPlanLogic.buildDayStatuses(
        savedAmount: 0,
        dailySuggested: 500,
        validatedCatchUpDaysInMonth: {1},
        year: now.year,
        month: now.month,
      );
      final cellDate = DateTime(now.year, now.month, 1);
      final today = DateTime(now.year, now.month, now.day);
      final expected = cellDate.isAfter(today) ? 'bleu' : 'vert';
      expect(statuses[1], expected);
    });

    test('pending catch-up on a day that is not gris (e.g. already vert) leaves it untouched', () {
      final now = DateTime.now();
      final statuses = CalendarPlanLogic.buildDayStatuses(
        savedAmount: 3000,
        dailySuggested: 500,
        validatedCatchUpDaysInMonth: const {},
        year: now.year,
        month: now.month,
        pendingCatchUpDays: {1},
      );
      // Day 1 is already vert thanks to the paid slots, so it must stay vert.
      expect(statuses[1], 'vert');
    });
  });
}
