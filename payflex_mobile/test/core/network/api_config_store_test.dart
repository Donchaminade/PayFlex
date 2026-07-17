import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:payflex_mobile/core/network/api_config_store.dart';

const _prefsKey = 'payflex_dev_api_base_url';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // `ApiConfigStore.init()` is guarded by a static "already initialized"
  // flag that only ever fires once per process. Since a single `flutter
  // test` run keeps one Dart VM per test *file*, this must be the very
  // first test to exercise the real (non-early-return) seeding path.
  test('init() seeds an override from seedLanHost when nothing was saved yet', () async {
    SharedPreferences.setMockInitialValues({});

    await ApiConfigStore.init(seedLanHost: '192.168.1.50');

    expect(ApiConfigStore.hasOverride, isTrue);
    expect(ApiConfigStore.overrideUrl, 'http://192.168.1.50:8088');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(_prefsKey), 'http://192.168.1.50:8088');
  });

  group('setOverride / overrideUrl / hasOverride', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() async {
      await ApiConfigStore.clearOverride();
    });

    test('hasOverride is false and overrideUrl is null when nothing is set', () async {
      await ApiConfigStore.clearOverride();
      expect(ApiConfigStore.hasOverride, isFalse);
      expect(ApiConfigStore.overrideUrl, isNull);
    });

    test('setOverride persists the value and makes it readable back', () async {
      await ApiConfigStore.setOverride('http://10.0.0.5:8088');

      expect(ApiConfigStore.hasOverride, isTrue);
      expect(ApiConfigStore.overrideUrl, 'http://10.0.0.5:8088');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(_prefsKey), 'http://10.0.0.5:8088');
    });

    test('setOverride strips a trailing slash', () async {
      await ApiConfigStore.setOverride('http://10.0.0.5:8088/');
      expect(ApiConfigStore.overrideUrl, 'http://10.0.0.5:8088');
    });

    test('setOverride with an empty/blank value clears the override instead', () async {
      await ApiConfigStore.setOverride('http://10.0.0.5:8088');
      expect(ApiConfigStore.hasOverride, isTrue);

      await ApiConfigStore.setOverride('   ');

      expect(ApiConfigStore.hasOverride, isFalse);
      expect(ApiConfigStore.overrideUrl, isNull);
    });

    test('clearOverride removes both the in-memory value and the persisted one', () async {
      await ApiConfigStore.setOverride('http://10.0.0.5:8088');
      await ApiConfigStore.clearOverride();

      expect(ApiConfigStore.hasOverride, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(_prefsKey), isNull);
    });
  });

  group('setFromUserInput', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() async {
      await ApiConfigStore.clearOverride();
    });

    test('bare IP is rebuilt into a full URL with the default backend port', () async {
      await ApiConfigStore.setFromUserInput('192.168.0.42');
      expect(ApiConfigStore.overrideUrl, 'http://192.168.0.42:8088');
    });

    test('a full https URL is kept as-is (only normalized)', () async {
      await ApiConfigStore.setFromUserInput('https://payflex-app.loca.lt/');
      expect(ApiConfigStore.overrideUrl, 'https://payflex-app.loca.lt');
    });

    test('a full http URL is kept as-is', () async {
      await ApiConfigStore.setFromUserInput('http://192.168.0.42:9090');
      expect(ApiConfigStore.overrideUrl, 'http://192.168.0.42:9090');
    });

    test('an "ip:port" shorthand (no scheme) drops the typed port and reuses the default backend port', () async {
      // Documents current behaviour: setFromUserInput's non-URL branch only
      // keeps the host part (`raw.split('/').first.split(':').first`) and
      // always rebuilds the URL with the fixed `_backendPort` default. Only
      // a bare IP or a full "http(s)://" URL are the two officially
      // supported input shapes per the class doc comment.
      await ApiConfigStore.setFromUserInput('192.168.0.42:9090');
      expect(ApiConfigStore.overrideUrl, 'http://192.168.0.42:8088');
    });

    test('blank input clears the override', () async {
      await ApiConfigStore.setOverride('http://192.168.0.42:8088');
      await ApiConfigStore.setFromUserInput('   ');
      expect(ApiConfigStore.hasOverride, isFalse);
    });
  });

  group('setUsbReverseDefault', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() async {
      await ApiConfigStore.clearOverride();
    });

    test('points the override at 127.0.0.1 on the default backend port', () async {
      await ApiConfigStore.setUsbReverseDefault();
      expect(ApiConfigStore.overrideUrl, 'http://127.0.0.1:8088');
    });
  });
}
