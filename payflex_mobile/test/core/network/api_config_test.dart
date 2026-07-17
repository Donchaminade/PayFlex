import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:payflex_mobile/core/network/api_config.dart';
import 'package:payflex_mobile/core/network/api_config_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ApiConfigStore.clearOverride();
  });

  tearDown(() async {
    await ApiConfigStore.clearOverride();
  });

  group('baseUrl priority', () {
    test('falls back to localhost on the default backend port when nothing is configured', () {
      // `flutter test` runs on the host desktop platform (no dart-define
      // overrides, no persisted SharedPreferences override), so ApiConfig
      // falls through to the desktop/debug default.
      expect(ApiConfigStore.hasOverride, isFalse);
      expect(ApiConfig.baseUrl, 'http://localhost:8088');
    });

    test('a persisted SharedPreferences override takes priority over the default', () async {
      await ApiConfigStore.setOverride('http://192.168.1.20:8088');

      expect(ApiConfig.baseUrl, 'http://192.168.1.20:8088');
    });

    test('the override is re-normalized (trailing slash stripped) when read back through baseUrl', () async {
      await ApiConfigStore.setOverride('http://192.168.1.20:8088');
      // Sanity: ApiConfigStore itself already normalizes, but baseUrl must
      // not reintroduce a trailing slash or otherwise mangle the value.
      expect(ApiConfig.baseUrl, isNot(endsWith('/')));
      expect(ApiConfig.baseUrl, 'http://192.168.1.20:8088');
    });

    test('clearing the override falls back to the default again', () async {
      await ApiConfigStore.setOverride('http://192.168.1.20:8088');
      expect(ApiConfig.baseUrl, 'http://192.168.1.20:8088');

      await ApiConfigStore.clearOverride();

      expect(ApiConfig.baseUrl, 'http://localhost:8088');
    });
  });

  group('resolveMediaUrl', () {
    test('returns an empty string for null or empty input', () {
      expect(ApiConfig.resolveMediaUrl(null), '');
      expect(ApiConfig.resolveMediaUrl(''), '');
      expect(ApiConfig.resolveMediaUrl('   '), '');
    });

    test('passes through an already-absolute URL untouched', () {
      expect(
        ApiConfig.resolveMediaUrl('https://cdn.example.com/x.png'),
        'https://cdn.example.com/x.png',
      );
      expect(
        ApiConfig.resolveMediaUrl('http://cdn.example.com/x.png'),
        'http://cdn.example.com/x.png',
      );
    });

    test('prefixes a relative path with the current baseUrl', () {
      expect(
        ApiConfig.resolveMediaUrl('uploads/receipt_1.jpg'),
        '${ApiConfig.baseUrl}/uploads/receipt_1.jpg',
      );
    });

    test('strips a leading slash before joining with baseUrl (no double slash)', () {
      expect(
        ApiConfig.resolveMediaUrl('/uploads/receipt_1.jpg'),
        '${ApiConfig.baseUrl}/uploads/receipt_1.jpg',
      );
    });
  });

  group('local tunnel detection', () {
    test('urlNeedsLocalTunnelBypass is true for loca.lt and localtunnel.me domains', () {
      expect(ApiConfig.urlNeedsLocalTunnelBypass('https://payflex-app.loca.lt'), isTrue);
      expect(ApiConfig.urlNeedsLocalTunnelBypass('https://foo.localtunnel.me'), isTrue);
    });

    test('urlNeedsLocalTunnelBypass is false for a regular LAN/host URL', () {
      expect(ApiConfig.urlNeedsLocalTunnelBypass('http://192.168.1.20:8088'), isFalse);
      expect(ApiConfig.urlNeedsLocalTunnelBypass('http://localhost:8088'), isFalse);
    });

    test('usesLocalTunnel reflects the current baseUrl', () async {
      expect(ApiConfig.usesLocalTunnel, isFalse);

      await ApiConfigStore.setOverride('https://payflex-app.loca.lt');
      expect(ApiConfig.usesLocalTunnel, isTrue);
    });
  });
}
