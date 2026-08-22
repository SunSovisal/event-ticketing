import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/instance_manager.dart';
import 'package:get/route_manager.dart';
import 'package:itc_events/app/services/api_client.dart';
import 'package:itc_events/app/theme/app_theme.dart';
import 'package:itc_events/modules/auth/auth_binding.dart';
import 'package:itc_events/modules/events/splash_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

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

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'GoITC',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialBinding: AuthBinding(),
      home: const SplashPage(),
    );
  }
}
