import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

// Offline Aba Mobile to use Simulator UAT
class AbaPayLauncher {
  AbaPayLauncher({
    Future<bool> Function(Uri uri)? launch,
    Future<bool> Function(String bundleId)? isInstalled,
  }) : _launch = launch ?? _launchExternal,
       _isInstalled = isInstalled ?? _isInstalledNative;

  static const abaMobileBundleId = 'com.paygo24.ababank';
  static const uatBundleId = 'com.ababank.abamobile-simulator';
  static const _channel = MethodChannel('goitc.aba_pay_launcher');

  final Future<bool> Function(Uri uri) _launch;
  final Future<bool> Function(String bundleId) _isInstalled;

  static Future<bool> _launchExternal(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<bool> _isInstalledNative(String bundleId) async {
    try {
      final installed = await _channel.invokeMethod<bool>(
        'isAppInstalled',
        bundleId,
      );
      return installed == true;
    } on MissingPluginException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> open(String? deeplink, {TargetPlatform? platform}) async {
    final target = platform ?? defaultTargetPlatform;
    if (target != TargetPlatform.iOS) {
      return false;
    }

    final uri = Uri.tryParse(deeplink?.trim() ?? '');
    if (uri == null || !uri.hasScheme) {
      return false;
    }
    if (uri.scheme.toLowerCase() != 'abamobilebank') {
      return false;
    }
    if (await _isInstalled(abaMobileBundleId)) {
      return false;
    }
    return _tryLaunch(uri);
  }

  Future<bool> _tryLaunch(Uri uri) async {
    try {
      return await _launch(uri);
    } catch (_) {
      return false;
    }
  }
}
