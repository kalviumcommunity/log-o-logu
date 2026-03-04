// lib/core/notifications/notification_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:log_o_logu/features/auth/domain/auth_service.dart';

/// Handles FCM token storage, local notifications for visitor arrivals,
/// and Firestore-stream-based push (works without Blaze plan).
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final AuthService _authService;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Tracks the latest log entryTime we've already notified about,
  /// so we don't re-fire when the stream re-emits.
  DateTime? _lastNotifiedLogTime;

  NotificationService({required AuthService authService})
      : _authService = authService;

  // ─── Android notification channel ───
  static const _androidChannel = AndroidNotificationChannel(
    'visitor_alerts',
    'Visitor Alerts',
    description: 'Notifications when a visitor enters the gate',
    importance: Importance.high,
  );

  /// Requests permissions, stores the FCM token, and initialises
  /// the local notification plugin.
  Future<void> initialize() async {
    try {
      // 1. Request permission (iOS / macOS / web)
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('[NotificationService] Permission denied by user.');
        return;
      }

      debugPrint(
          '[NotificationService] Permission status: ${settings.authorizationStatus}');

      // 2. Get and store FCM token (still useful for later Blaze upgrade)
      await _refreshAndStoreToken();

      _messaging.onTokenRefresh.listen((newToken) async {
        debugPrint('[NotificationService] Token refreshed.');
        await _storeFcmToken(newToken);
      });

      // 3. Initialise local notifications plugin
      await _initLocalNotifications();

      // 4. Start listening for new visitor logs
      _startLogListener();

      // 5. Handle FCM foreground / tap (ready for when Blaze is enabled)
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      debugPrint('[NotificationService] Initialized successfully.');
    } catch (e) {
      debugPrint('[NotificationService] Initialization error: $e');
    }
  }

  // ─── Local notifications setup ───

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
    );

    await _localNotifications.initialize(settings: initSettings);

    // Create the Android notification channel
    if (!kIsWeb) {
      final androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(_androidChannel);
    }
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'visitor_alerts',
      'Visitor Alerts',
      channelDescription: 'Notifications when a visitor enters the gate',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const darwinDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  // ─── Firestore log listener (replaces Cloud Function) ───

  void _startLogListener() {
    final uid = _authService.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;

    // Mark current time so we only notify about logs created AFTER init
    _lastNotifiedLogTime = DateTime.now();

    FirebaseFirestore.instance
        .collection('logs')
        .where('residentUid', isEqualTo: uid)
        .orderBy('entryTime', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docChanges.isEmpty) return;

      for (final change in snapshot.docChanges) {
        if (change.type != DocumentChangeType.added) continue;

        final data = change.doc.data();
        if (data == null) continue;

        final entryTime = (data['entryTime'] as Timestamp?)?.toDate();
        if (entryTime == null) continue;

        // Skip logs that existed before we started listening
        if (_lastNotifiedLogTime != null &&
            entryTime.isBefore(_lastNotifiedLogTime!)) {
          continue;
        }

        final guestName = data['guestName'] as String? ?? 'A visitor';
        _lastNotifiedLogTime = entryTime;

        _showLocalNotification(
          title: 'Visitor Arrived',
          body: '$guestName has entered the gate.',
        );

        debugPrint(
            '[NotificationService] Local notification: $guestName arrived.');
      }
    }, onError: (e) {
      debugPrint('[NotificationService] Log listener error: $e');
    });
  }

  // ─── FCM token management ───

  Future<void> _refreshAndStoreToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _storeFcmToken(token);
      }
    } catch (e) {
      debugPrint('[NotificationService] Failed to get FCM token: $e');
    }
  }

  Future<void> _storeFcmToken(String token) async {
    final uid = _authService.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      try {
        await _authService.updateFcmToken(token);
        debugPrint('[NotificationService] FCM token stored for user $uid.');
      } catch (e) {
        debugPrint('[NotificationService] Failed to store FCM token: $e');
      }
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint(
        '[NotificationService] Foreground message: ${message.notification?.title}');
  }

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint(
        '[NotificationService] Notification tapped: ${message.data}');
  }

  /// Call this in main() before runApp to configure iOS foreground display.
  static Future<void> configureForegroundPresentation() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }
}
