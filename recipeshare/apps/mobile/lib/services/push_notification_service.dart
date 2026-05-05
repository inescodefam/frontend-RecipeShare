import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared/shared.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class PushNotificationService {
  PushNotificationService({
    required DeviceTokenService deviceTokenService,
  }) : _deviceTokenService = deviceTokenService;

  final DeviceTokenService _deviceTokenService;
  FirebaseMessaging? _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<RemoteMessage>? _onMessageSubscription;
  StreamSubscription<String>? _onTokenRefreshSubscription;

  bool _initialized = false;
  String? _lastKnownToken;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await Firebase.initializeApp();
    _messaging = FirebaseMessaging.instance;
    debugPrint('Push: Firebase initialized');
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _initializeLocalNotifications();
    await _requestPermission();
    await _messaging!.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    _onMessageSubscription = FirebaseMessaging.onMessage.listen(_showForeground);
    _onTokenRefreshSubscription = _messaging!.onTokenRefresh.listen((token) async {
      _lastKnownToken = token;
      debugPrint('Push: token refreshed $token');
      try {
        await _deviceTokenService.registerDeviceToken(token);
        debugPrint('Push: refreshed token registered in backend');
      } catch (e) {
        debugPrint('Push: failed to register refreshed token: $e');
      }
    });

    final initialToken = await _messaging!.getToken();
    _lastKnownToken = initialToken;
    debugPrint('Push: initial token ${initialToken ?? 'null'}');
  }

  Future<void> registerCurrentToken() async {
    final messaging = _messaging;
    if (messaging == null) return;
    final token = await messaging.getToken();
    if (token == null || token.isEmpty) return;
    _lastKnownToken = token;
    debugPrint('Push: registering token $token');
    try {
      await _deviceTokenService.registerDeviceToken(token);
      debugPrint('Push: token registered in backend');
    } catch (e) {
      debugPrint('Push: failed to register token: $e');
    }
  }

  Future<void> unregisterCurrentToken() async {
    final messaging = _messaging;
    if (messaging == null) return;
    final token = _lastKnownToken ?? await messaging.getToken();
    if (token == null || token.isEmpty) return;
    debugPrint('Push: unregistering token $token');
    try {
      await _deviceTokenService.unregisterDeviceToken(token);
      debugPrint('Push: token unregistered in backend');
    } catch (e) {
      debugPrint('Push: failed to unregister token: $e');
    }
  }

  Future<void> dispose() async {
    await _onMessageSubscription?.cancel();
    await _onTokenRefreshSubscription?.cancel();
  }

  Future<void> _requestPermission() async {
    if (kIsWeb) return;
    await _messaging!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(settings: settings);

    const channel = AndroidNotificationChannel(
      'recipeshare_notifications',
      'RecipeShare Notifications',
      description: 'Notification channel for social activity',
      importance: Importance.high,
    );

    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(channel);
  }

  Future<void> _showForeground(RemoteMessage message) async {
    debugPrint(
      'Push: foreground message title=${message.notification?.title} body=${message.notification?.body}',
    );
    final notification = message.notification;
    if (notification == null) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'recipeshare_notifications',
        'RecipeShare Notifications',
        channelDescription: 'Notification channel for social activity',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: details,
    );
  }
}
