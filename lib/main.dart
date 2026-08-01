import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'firebase_options.dart';
import 'theme/theme.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize notification service
  if (!kIsWeb) {
    // Must be registered before runApp so notifications that arrive while
    // the app is terminated are still handled.
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final notificationService = NotificationService();
    await notificationService.initialize();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'HeyTeacher!',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        home: const SplashScreen(),
      ),
    );
  }
}
