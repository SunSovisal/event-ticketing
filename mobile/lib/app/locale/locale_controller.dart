import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/locale/app_translations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController extends GetxController {
  LocaleController({
    SharedPreferences? prefs,
    Locale initialLocale = const Locale('en', 'US'),
  }) : _prefs = prefs,
       locale = initialLocale.obs;

  static const languageKey = 'app_language';

  final SharedPreferences? _prefs;
  final Rx<Locale> locale;

  static Future<LocaleController> load() async {
    final prefs = await SharedPreferences.getInstance();
    return LocaleController(
      prefs: prefs,
      initialLocale: localeFromCode(prefs.getString(languageKey)),
    );
  }

  static Locale localeFromCode(String? code) {
    return switch (code) {
      'kh' || 'km' => const Locale('km', 'KH'),
      _ => const Locale('en', 'US'),
    };
  }

  static String codeFromLocale(Locale locale) {
    return locale.languageCode == 'km' || locale.languageCode == 'kh'
        ? 'kh'
        : 'en';
  }

  @override
  void onInit() {
    super.onInit();
    syncAppTranslations();
    Get.updateLocale(locale.value);
  }

  static bool isKhmer(Locale? locale) {
    final code = locale?.languageCode;
    return code == 'km' || code == 'kh';
  }

  String get languageCode => codeFromLocale(locale.value);

  String get currentLanguageLabel {
    return switch (languageCode) {
      'kh' => 'language_khmer'.tr,
      _ => 'language_english'.tr,
    };
  }

  void setLanguage(String code) {
    final next = localeFromCode(code);
    locale.value = next;
    syncAppTranslations();
    Get.updateLocale(next);
    _prefs?.setString(languageKey, code);
  }
}
