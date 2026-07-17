import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:payflex_mobile/core/services/session_timeout_service.dart';

const _kLastActiveAtMs = 'payflex_last_active_at_ms';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final service = SessionTimeoutService.instance;

  setUp(() async {
    // Fresh mock prefs store for every test, and reset the service's
    // in-memory cache + pending-message flag so tests don't leak state
    // into one another (the service is a process-wide singleton).
    SharedPreferences.setMockInitialValues({});
    await service.clear();
  });

  group('lastActiveAt', () {
    test('is null when no activity has ever been recorded', () async {
      expect(await service.lastActiveAt(), isNull);
    });

    test('reflects the timestamp written by recordActivity', () async {
      final before = DateTime.now();
      await service.recordActivity();
      final after = DateTime.now();

      final last = await service.lastActiveAt();
      expect(last, isNotNull);
      expect(
        last!.millisecondsSinceEpoch,
        inInclusiveRange(before.millisecondsSinceEpoch, after.millisecondsSinceEpoch),
      );
    });

    test('is persisted to SharedPreferences, not just kept in memory', () async {
      await service.recordActivity();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(_kLastActiveAtMs), isNotNull);
    });
  });

  group('isExpired', () {
    test('is false when no activity was ever recorded (no baseline to expire from)', () async {
      expect(await service.isExpired(), isFalse);
    });

    test('is false right after recording activity', () async {
      await service.recordActivity();
      expect(await service.isExpired(), isFalse);
    });

    test('is false just before the 30 minute limit', () async {
      final justInside = DateTime.now().subtract(
        SessionTimeoutService.inactivityLimit - const Duration(seconds: 1),
      );
      SharedPreferences.setMockInitialValues({
        _kLastActiveAtMs: justInside.millisecondsSinceEpoch,
      });

      expect(await service.isExpired(), isFalse);
    });

    test('is true once the 30 minute limit is reached exactly', () async {
      final exactLimit = DateTime.now().subtract(SessionTimeoutService.inactivityLimit);
      SharedPreferences.setMockInitialValues({
        _kLastActiveAtMs: exactLimit.millisecondsSinceEpoch,
      });

      expect(await service.isExpired(), isTrue);
    });

    test('is true well past the 30 minute limit', () async {
      final wayPast = DateTime.now().subtract(const Duration(hours: 2));
      SharedPreferences.setMockInitialValues({
        _kLastActiveAtMs: wayPast.millisecondsSinceEpoch,
      });

      expect(await service.isExpired(), isTrue);
    });

    test('recordActivity resets an expired session back to valid', () async {
      final wayPast = DateTime.now().subtract(const Duration(hours: 2));
      SharedPreferences.setMockInitialValues({
        _kLastActiveAtMs: wayPast.millisecondsSinceEpoch,
      });
      expect(await service.isExpired(), isTrue);

      await service.recordActivity();

      expect(await service.isExpired(), isFalse);
    });
  });

  group('clear', () {
    test('removes the stored activity timestamp and the in-memory cache', () async {
      await service.recordActivity();
      expect(await service.lastActiveAt(), isNotNull);

      await service.clear();

      expect(await service.lastActiveAt(), isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(_kLastActiveAtMs), isNull);
    });

    test('also resets the pending expired message flag', () async {
      service.markExpiredForMessage();
      await service.clear();
      expect(service.consumeExpiredMessage(), isFalse);
    });
  });

  group('expired message flag', () {
    test('markExpiredForMessage then consumeExpiredMessage returns true exactly once', () async {
      expect(service.consumeExpiredMessage(), isFalse);

      service.markExpiredForMessage();

      expect(service.consumeExpiredMessage(), isTrue);
      expect(service.consumeExpiredMessage(), isFalse);
    });
  });
}
