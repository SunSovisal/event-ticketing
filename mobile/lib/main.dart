import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/instance_manager.dart';
import 'package:get/route_manager.dart';
import 'package:itc_events/app/services/api_client.dart';
import 'package:itc_events/app/services/push_notification_service.dart';
import 'package:itc_events/app/theme/app_theme.dart';
import 'package:itc_events/modules/auth/auth_binding.dart';
import 'package:itc_events/modules/auth/them_controller_page.dart';
import 'package:itc_events/modules/events/splash_page.dart';

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
  Get.put(ThemeController());

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
    return GetMaterialApp(
      title: 'GoITC',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: Get.find<ThemeController>().themeMode.value,
      initialBinding: AuthBinding(),
      home: const SplashPage(),
    );
  }
}
