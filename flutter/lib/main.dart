import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:log_o_logu/features/auth/domain/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Web requires `flutterfire configure` to emit firebase_options.dart.
    // Android uses google-services.json automatically.
    if (!kIsWeb) {
      await Firebase.initializeApp();

      // Forward all Flutter framework errors to Crashlytics.
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

      // Forward uncaught async errors (Zone errors) to Crashlytics.
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    } else {
      debugPrint('[main] Web platform — Firebase Web setup required.');
    }
  } catch (e) {
    debugPrint('[main] Firebase init error: $e');
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthService(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Log-O-Logu',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD0BCFF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      // TODO(routing): replace with GoRouter that reacts to AuthService.status
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            const Hero(
              tag: 'logo',
              child: Icon(
                Icons.domain_verification_rounded,
                size: 100,
                color: Color(0xFF6750A4),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Log-O-Logu',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Digitalizing Security. Simplifying Access.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                    letterSpacing: 1.2,
                  ),
            ),
            const Spacer(),
            const CircularProgressIndicator(),
            const SizedBox(height: 48),
            const Text(
              'Firebase Connected',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
