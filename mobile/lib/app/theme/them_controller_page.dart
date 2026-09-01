import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  ThemeController({
    SharedPreferences? prefs,
    ThemeMode initialMode = ThemeMode.system,
  }) : _prefs = prefs,
       themeMode = initialMode.obs;

  static const _themeModeKey = 'theme_mode';

  final SharedPreferences? _prefs;
  final Rx<ThemeMode> themeMode;

  static Future<ThemeController> load() async {
    final prefs = await SharedPreferences.getInstance();
    return ThemeController(
      prefs: prefs,
      initialMode: themeModeFromName(prefs.getString(_themeModeKey)),
    );
  }

  static ThemeMode themeModeFromName(String? name) {
    return switch (name) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  @override
  void onInit() {
    super.onInit();
    Get.changeThemeMode(themeMode.value);
  }

  void setThemeMode(ThemeMode mode) {
    themeMode.value = mode;
    Get.changeThemeMode(mode);
    _prefs?.setString(_themeModeKey, mode.name);
  }

  String get currentThemeLabel {
    switch (themeMode.value) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System auto';
    }
  }

  IconData get currentThemeIcon {
    switch (themeMode.value) {
      case ThemeMode.light:
        return Icons.light_mode_outlined;
      case ThemeMode.dark:
        return Icons.dark_mode_outlined;
      case ThemeMode.system:
        return Icons.brightness_auto_outlined;
    }
  }
}
