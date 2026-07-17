import 'package:flutter_test/flutter_test.dart';
import 'package:payflex_mobile/core/models/allocation_result.dart';

void main() {
  group('AllocationLine.fromJson', () {
    test('parses a well-formed line', () {
      final line = AllocationLine.fromJson({
        'contributionId': 42,
        'productId': 7,
        'productName': 'Frigo Premium',
        'amountFcfa': 12345.0,
        'goalReachedNow': true,
      });

      expect(line.contributionId, 42);
      expect(line.productId, 7);
      expect(line.productName, 'Frigo Premium');
      expect(line.amountFcfa, 12345.0);
      expect(line.goalReachedNow, isTrue);
    });

    test('defaults goalReachedNow to false when absent', () {
      final line = AllocationLine.fromJson({
        'contributionId': 1,
        'productId': 1,
        'productName': 'X',
        'amountFcfa': 100,
      });
      expect(line.goalReachedNow, isFalse);
    });

    test('falls back to "Produit" when productName is missing or blank', () {
      expect(
        AllocationLine.fromJson({'contributionId': 1, 'productId': 1, 'amountFcfa': 100}).productName,
        'Produit',
      );
      expect(
        AllocationLine.fromJson({
          'contributionId': 1,
          'productId': 1,
          'productName': '   ',
          'amountFcfa': 100,
        }).productName,
        'Produit',
      );
    });

    test('defaults numeric fields to 0 when missing or null', () {
      final line = AllocationLine.fromJson({'productName': 'Y'});
      expect(line.contributionId, 0);
      expect(line.productId, 0);
      expect(line.amountFcfa, 0);
    });
  });

  group('AllocationResult.tryParse', () {
    test('returns null for a null payload', () {
      expect(AllocationResult.tryParse(null), isNull);
    });

    test('returns null when the allocations list is missing', () {
      expect(AllocationResult.tryParse({'sourceAmountFcfa': 100}), isNull);
    });

    test('returns null when the allocations list is empty', () {
      expect(
        AllocationResult.tryParse({
          'sourceAmountFcfa': 500,
          'allocations': <Map<String, dynamic>>[],
          'unallocatedSurplusFcfa': 0,
        }),
        isNull,
      );
    });

    test('returns null for a single line with no surplus (no real split occurred)', () {
      final result = AllocationResult.tryParse({
        'sourceAmountFcfa': 500,
        'allocations': [
          {
            'contributionId': 1,
            'productId': 10,
            'productName': 'Produit A',
            'amountFcfa': 500,
            'goalReachedNow': false,
          },
        ],
        'unallocatedSurplusFcfa': 0,
      });

      expect(result, isNull);
    });

    test('returns a result for a single line when an unallocated surplus remains', () {
      final result = AllocationResult.tryParse({
        'sourceAmountFcfa': 500,
        'allocations': [
          {
            'contributionId': 1,
            'productId': 10,
            'productName': 'Produit A',
            'amountFcfa': 300,
            'goalReachedNow': true,
          },
        ],
        'unallocatedSurplusFcfa': 200,
      });

      expect(result, isNotNull);
      expect(result!.wasSplit, isTrue);
      expect(result.lines, hasLength(1));
      expect(result.unallocatedSurplusFcfa, 200);
    });

    test('parses a multi-product split with the backend payload shape (contributions/allocation-group)', () {
      final json = {
        'sourceAmountFcfa': 5000.0,
        'allocations': [
          {
            'contributionId': 101,
            'productId': 10,
            'productName': 'Produit A',
            'amountFcfa': 2000.0,
            'goalReachedNow': true,
          },
          {
            'contributionId': 102,
            'productId': 20,
            'productName': 'Produit B',
            'amountFcfa': 3000.0,
            'goalReachedNow': false,
          },
        ],
        'unallocatedSurplusFcfa': 0.0,
      };

      final result = AllocationResult.tryParse(json);

      expect(result, isNotNull);
      expect(result!.sourceAmountFcfa, 5000.0);
      expect(result.lines, hasLength(2));
      expect(result.lines[0].productName, 'Produit A');
      expect(result.lines[0].goalReachedNow, isTrue);
      expect(result.lines[1].productName, 'Produit B');
      expect(result.lines[1].goalReachedNow, isFalse);
      expect(result.unallocatedSurplusFcfa, 0.0);
      expect(result.wasSplit, isTrue);
    });

    test('parses a multi-product split with a leftover unallocated surplus', () {
      final json = {
        'sourceAmountFcfa': 10000.0,
        'allocations': [
          {
            'contributionId': 201,
            'productId': 10,
            'productName': 'Produit A',
            'amountFcfa': 4000.0,
            'goalReachedNow': true,
          },
          {
            'contributionId': 202,
            'productId': 20,
            'productName': 'Produit B',
            'amountFcfa': 4000.0,
            'goalReachedNow': true,
          },
        ],
        'unallocatedSurplusFcfa': 2000.0,
      };

      final result = AllocationResult.tryParse(json);

      expect(result, isNotNull);
      expect(result!.unallocatedSurplusFcfa, 2000.0);
      expect(result.wasSplit, isTrue);
    });

    test('computes sourceAmountFcfa from lines + surplus when absent from the payload', () {
      final json = {
        'allocations': [
          {'contributionId': 1, 'productId': 1, 'productName': 'A', 'amountFcfa': 700.0, 'goalReachedNow': false},
          {'contributionId': 2, 'productId': 2, 'productName': 'B', 'amountFcfa': 300.0, 'goalReachedNow': false},
        ],
        'unallocatedSurplusFcfa': 100.0,
      };

      final result = AllocationResult.tryParse(json);

      expect(result, isNotNull);
      expect(result!.sourceAmountFcfa, 1100.0);
    });

    test('ignores non-map entries within the allocations list', () {
      final json = {
        'sourceAmountFcfa': 100.0,
        'allocations': [
          'not a map',
          {'contributionId': 1, 'productId': 1, 'productName': 'A', 'amountFcfa': 50.0, 'goalReachedNow': false},
          {'contributionId': 2, 'productId': 2, 'productName': 'B', 'amountFcfa': 50.0, 'goalReachedNow': false},
        ],
      };

      final result = AllocationResult.tryParse(json);

      expect(result, isNotNull);
      expect(result!.lines, hasLength(2));
    });
  });

  group('AllocationResult.toFrenchMessage', () {
    test('single line without split mentions only the total amount', () {
      const result = AllocationResult(
        sourceAmountFcfa: 500,
        lines: [
          AllocationLine(
            contributionId: 1,
            productId: 1,
            productName: 'Produit A',
            amountFcfa: 500,
            goalReachedNow: false,
          ),
        ],
        unallocatedSurplusFcfa: 0,
      );

      final msg = result.toFrenchMessage();
      expect(msg, contains('500'));
      expect(msg, contains('enregistré'));
      expect(msg, isNot(contains('réparti')));
    });

    test('multi-line split lists every product and tags the reached goal', () {
      const result = AllocationResult(
        sourceAmountFcfa: 500,
        lines: [
          AllocationLine(
            contributionId: 1,
            productId: 1,
            productName: 'Produit A',
            amountFcfa: 200,
            goalReachedNow: true,
          ),
          AllocationLine(
            contributionId: 2,
            productId: 2,
            productName: 'Produit B',
            amountFcfa: 300,
            goalReachedNow: false,
          ),
        ],
        unallocatedSurplusFcfa: 0,
      );

      final msg = result.toFrenchMessage();
      expect(msg, contains('réparti'));
      expect(msg, contains('Produit A'));
      expect(msg, contains('(objectif atteint)'));
      expect(msg, contains('Produit B'));
      expect(msg, isNot(contains('restent en attente')));
    });

    test('mentions the unallocated surplus when present', () {
      const result = AllocationResult(
        sourceAmountFcfa: 700,
        lines: [
          AllocationLine(
            contributionId: 1,
            productId: 1,
            productName: 'Produit A',
            amountFcfa: 500,
            goalReachedNow: true,
          ),
        ],
        unallocatedSurplusFcfa: 200,
      );

      final msg = result.toFrenchMessage();
      expect(msg, contains('restent en attente'));
      expect(msg, contains('200'));
    });
  });
}
