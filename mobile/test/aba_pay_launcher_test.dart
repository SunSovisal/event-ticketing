import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itc_events/modules/tickets/aba_pay_launcher.dart';

void main() {
  const deeplink =
      'abamobilebank://ababank.com?type=payway&qrcode=000201PAYWAY';

  test('sandbox keeps ABA’s registered scheme casing on the payment URL', () {
    expect(
      AbaPayLauncher.paymentUrlForSimulatorUat(deeplink),
      'abaMobileBank://ababank.com?type=payway&qrcode=000201PAYWAY',
    );
  });

  test(
    'sandbox on iOS opens Simulator UAT by app id with the PayWay transaction',
    () async {
      final opened = <(String, String)>[];
      final launcher = AbaPayLauncher(
        openInstalledApp: (bundleId, url) async {
          opened.add((bundleId, url));
          return true;
        },
        launch: (_) async => fail('sandbox must not use the shared ABA scheme'),
      );

      expect(
        await launcher.open(
          deeplink,
          sandbox: true,
          platform: TargetPlatform.iOS,
        ),
        isTrue,
      );
      expect(opened, [
        (
          'com.ababank.abamobile-simulator',
          'abaMobileBank://ababank.com?type=payway&qrcode=000201PAYWAY',
        ),
      ]);
    },
  );

  test('sandbox never opens live ABA or TestFlight', () async {
    final launched = <Uri>[];
    final launcher = AbaPayLauncher(
      openInstalledApp: (bundleId, url) async {
        expect(bundleId, 'com.ababank.abamobile-simulator');
        expect(
          url,
          'abaMobileBank://ababank.com?type=payway&qrcode=000201PAYWAY',
        );
        return true;
      },
      launch: (uri) async {
        launched.add(uri);
        return true;
      },
    );

    expect(
      await launcher.open(
        deeplink,
        sandbox: true,
        platform: TargetPlatform.iOS,
      ),
      isTrue,
    );
    expect(launched, isEmpty);
  });

  test('sandbox on Android does not open live ABA', () async {
    final opened = <Uri>[];
    final launcher = AbaPayLauncher(
      openInstalledApp: (_, __) async => fail('Android sandbox must not launch'),
      launch: (uri) async {
        opened.add(uri);
        return true;
      },
    );

    expect(
      await launcher.open(
        deeplink,
        sandbox: true,
        platform: TargetPlatform.android,
      ),
      isFalse,
    );
    expect(opened, isEmpty);
  });

  test('live iOS payments still open the PayWay deeplink', () async {
    final opened = <Uri>[];
    final launcher = AbaPayLauncher(
      openInstalledApp: (_, __) async => fail('live payments use the ABA scheme'),
      launch: (uri) async {
        opened.add(uri);
        return true;
      },
    );

    expect(await launcher.open(deeplink, platform: TargetPlatform.iOS), isTrue);
    expect(opened, [Uri.parse(deeplink)]);
  });
}
