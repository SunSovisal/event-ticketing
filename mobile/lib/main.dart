import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/services/api_client.dart';
import 'package:itc_events/app/services/push_notification_service.dart';
import 'package:itc_events/app/locale/app_translations.dart';
import 'package:itc_events/app/locale/locale_controller.dart';
import 'package:itc_events/app/theme/app_theme.dart';
import 'package:itc_events/modules/auth/auth_binding.dart';
import 'package:itc_events/app/theme/them_controller_page.dart';
import 'package:itc_events/modules/shell/splash_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  const disablePhoneVerification = bool.fromEnvironment(
    'DISABLE_PHONE_APP_VERIFICATION',
  );

  if (disablePhoneVerification) {
    await FirebaseAuth.instance.setSettings(
      appVerificationDisabledForTesting: true,
    );
  }

  // ApiClient lives for the whole app
  final apiClient = ApiClient();

  Get.put<ApiClient>(apiClient, permanent: true);
  Get.put(await ThemeController.load(), permanent: true);
  Get.put(await LocaleController.load(), permanent: true);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PushNotificationService.register();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeCtrl = Get.find<ThemeController>();
    final localeCtrl = Get.find<LocaleController>();

    return GetMaterialApp(
      title: 'GoITC',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeCtrl.themeMode.value,
      translations: AppTranslations(),
      locale: localeCtrl.locale.value,
      fallbackLocale: const Locale('en', 'US'),
      initialBinding: AuthBinding(),
      builder: (context, child) {
        final content = child ?? const SizedBox.shrink();
        if (!LocaleController.isKhmer(Get.locale)) {
          return DefaultTextStyle.merge(
            style: const TextStyle(fontFamily: AppTheme.englishFontFamily),
            child: content,
          );
        }
        return Theme(
          data: AppTheme.applyKhmerFont(Theme.of(context)),
          child: DefaultTextStyle.merge(
            style: AppTheme.khmerStyle(const TextStyle()),
            child: content,
          ),
        );
      },
      home: const SplashPage(),
    );
  }
}
