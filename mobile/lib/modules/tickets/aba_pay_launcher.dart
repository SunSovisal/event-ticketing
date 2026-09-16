import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens ABA to finish a PayWay transaction.
///
/// Live ABA and Simulator UAT both register `abaMobileBank`. Sandbox therefore
/// opens Simulator UAT by bundle id and passes it the PayWay URL. Dart's [Uri]
/// lowercases schemes, so the native payload keeps ABA's registered casing.
class AbaPayLauncher {
  AbaPayLauncher({
    Future<bool> Function(Uri uri)? launch,
    Future<bool> Function(String bundleId, String url)? openInstalledApp,
  }) : _launch = launch ?? _launchExternal,
       _openInstalledApp = openInstalledApp ?? _openInstalledAppNative;

  static const uatBundleId = 'com.ababank.abamobile-simulator';
  static const uatScheme = 'abaMobileBank';
  static const _channel = MethodChannel('goitc.aba_pay_launcher');

  final Future<bool> Function(Uri uri) _launch;
  final Future<bool> Function(String bundleId, String url) _openInstalledApp;

  static Future<bool> _launchExternal(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<bool> _openInstalledAppNative(
    String bundleId,
    String url,
  ) async {
    try {
      final opened = await _channel.invokeMethod<bool>('openInstalledApp', {
        'bundleId': bundleId,
        'url': url,
      });
      return opened == true;
    } on MissingPluginException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// PayWay sends `abamobilebank://…`. Simulator UAT registers `abaMobileBank`.
  static String paymentUrlForSimulatorUat(String deeplink) {
    final trimmed = deeplink.trim();
    final colon = trimmed.indexOf(':');
    if (colon <= 0) {
      return trimmed;
    }
    return '$uatScheme${trimmed.substring(colon)}';
  }

  Future<bool> open(
    String? deeplink, {
    bool sandbox = false,
    TargetPlatform? platform,
  }) async {
    final target = platform ?? defaultTargetPlatform;
    final raw = deeplink?.trim() ?? '';
    final uri = Uri.tryParse(raw);

    if (sandbox) {
      if (target != TargetPlatform.iOS || raw.isEmpty || uri == null) {
        return false;
      }
      if (!uri.hasScheme) {
        return false;
      }
      return _openInstalledApp(
        uatBundleId,
        paymentUrlForSimulatorUat(raw),
      );
    }

    if (uri != null && uri.scheme.toLowerCase() == 'abamobilebank') {
      if (await _tryLaunch(uri)) {
        return true;
      }
    }

    return false;
  }

  Future<bool> _tryLaunch(Uri uri) async {
    try {
      return await _launch(uri);
    } catch (_) {
      return false;
    }
  }
}
