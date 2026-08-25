import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/theme/app_theme.dart';

abstract final class AppSnackbar {
  static void success(String message, {String title = 'Success'}) {
    _show(
      title: title,
      message: message,
      background: AppTheme.success,
      icon: Icons.check_circle_outline,
    );
  }

  static void error(String message, {String title = 'Error'}) {
    _show(
      title: title,
      message: message,
      background: AppTheme.error,
      icon: Icons.error_outline,
    );
  }

  static void warning(String message, {String title = 'Notice'}) {
    _show(
      title: title,
      message: message,
      background: AppTheme.warning,
      icon: Icons.info_outline,
    );
  }

  static void _show({
    required String title,
    required String message,
    required Color background,
    required IconData icon,
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: background,
      colorText: Colors.white,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
      isDismissible: true,
      snackStyle: SnackStyle.FLOATING,
      icon: Icon(icon, color: Colors.white),
      shouldIconPulse: false,
    );
  }
}
