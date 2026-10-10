import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool firebaseInitialized = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseInitialized = true;
  } catch (e) {
    debugPrint(
      'Firebase initialization warning: $e\n'
      'Make sure you configure your Firebase project credentials in firebase_options.dart '
      'or by running `flutterfire configure`.',
    );
  }

  runApp(CampusSosApp(firebaseInitialized: firebaseInitialized));
}

class CampusSosApp extends StatelessWidget {
  final bool firebaseInitialized;

  const CampusSosApp({super.key, required this.firebaseInitialized});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: 'CampusSOS — Safe Campus Companion',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
