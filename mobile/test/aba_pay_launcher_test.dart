import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itc_events/modules/tickets/aba_pay_launcher.dart';

void main() {
  const deeplink =
      'abamobilebank://ababank.com?type=payway&qrcode=000201PAYWAY';

  test('iOS opens Simulator UAT with the PayWay URL when ABA Mobile is offloaded', () async {
    final opened = <Uri>[];
    final launcher = AbaPayLauncher(
      isInstalled: (bundleId) async => bundleId == AbaPayLauncher.uatBundleId,
      launch: (uri) async {
        opened.add(uri);
        return true;
      },
    );

    expect(
      await launcher.open(deeplink, platform: TargetPlatform.iOS),
      isTrue,
    );
    expect(opened, [Uri.parse(deeplink)]);
  });

  test('does not open ABA Mobile', () async {
    final opened = <Uri>[];
    final launcher = AbaPayLauncher(
      isInstalled: (bundleId) async =>
          bundleId == AbaPayLauncher.abaMobileBundleId ||
          bundleId == AbaPayLauncher.uatBundleId,
      launch: (uri) async {
        opened.add(uri);
        return true;
      },
    );

    expect(
      await launcher.open(deeplink, platform: TargetPlatform.iOS),
      isFalse,
    );
    expect(opened, isEmpty);
  });

  test('never opens TestFlight', () async {
    final opened = <Uri>[];
    final launcher = AbaPayLauncher(
      isInstalled: (_) async => false,
      launch: (uri) async {
        opened.add(uri);
        return true;
      },
    );

    await launcher.open(deeplink, platform: TargetPlatform.iOS);
    expect(opened.every((uri) => !uri.host.contains('testflight')), isTrue);
  });

  test('does not open on Android', () async {
    final opened = <Uri>[];
    final launcher = AbaPayLauncher(
      isInstalled: (_) async => fail('must not probe apps on Android'),
      launch: (uri) async {
        opened.add(uri);
        return true;
      },
    );

    expect(
      await launcher.open(deeplink, platform: TargetPlatform.android),
      isFalse,
    );
    expect(opened, isEmpty);
  });
}
