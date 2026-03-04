import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:log_o_logu/core/router/app_router.dart';
import 'package:log_o_logu/core/theme/app_theme.dart';
import 'package:log_o_logu/core/notifications/notification_service.dart';
import 'package:log_o_logu/features/auth/domain/auth_service.dart';
import 'package:log_o_logu/features/invite/domain/invite_service.dart';
import 'package:log_o_logu/features/admin/data/admin_repository.dart';
import 'package:log_o_logu/features/admin/domain/admin_service.dart';
import 'package:log_o_logu/firebase_options.dart';

/// Top-level handler for background/terminated FCM messages.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('[FCM Background] ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Optimize Firestore for better responsiveness
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    if (!kIsWeb) {
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }

    // Register background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Configure iOS foreground notification display
    await NotificationService.configureForegroundPresentation();
  } catch (e) {
    debugPrint('[main] Firebase init error: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => InviteService()),
        Provider(create: (_) => AdminRepository()),
        ChangeNotifierProxyProvider<AdminRepository, AdminService>(
          create: (_) => AdminService(repository: AdminRepository()),
          update: (_, repo, service) =>
              service ?? AdminService(repository: repo),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

/// MyApp creates the GoRouter once (tied to the AuthService instance) and
/// passes it to MaterialApp.router. The router's [refreshListenable] points
/// to AuthService, so GoRouter re-evaluates its redirect on every auth change
/// without rebuilding the entire widget tree.
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final _router = createAppRouter(context.read<AuthService>());
  NotificationService? _notificationService;

  @override
  void initState() {
    super.initState();
    // Initialize notifications once auth state stabilises
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initNotifications();
    });
  }

  Future<void> _initNotifications() async {
    final authService = context.read<AuthService>();
    _notificationService = NotificationService(authService: authService);

    // Listen for auth changes – initialise FCM when user logs in
    authService.addListener(_onAuthChanged);

    // If user is already logged in at launch
    if (authService.currentUser != null) {
      await _notificationService!.initialize();
    }
  }

  void _onAuthChanged() {
    final user = context.read<AuthService>().currentUser;
    if (user != null && _notificationService != null) {
      _notificationService!.initialize();
    }
  }

  @override
  void dispose() {
    context.read<AuthService>().removeListener(_onAuthChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Log-O-Logu',
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}
