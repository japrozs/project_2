import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'bigfoot_trail_alerts',
    'Trail Safety Alerts',
    description: 'Notifications about trail conditions and safety updates.',
    importance: Importance.high,
  );

  static FlutterLocalNotificationsPlugin? _localNotifications;

  static Future<void> initialize(FlutterLocalNotificationsPlugin plugin) async {
    _localNotifications = plugin;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    await plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    // Only on mobile — web doesn't support FCM the same way
    if (!kIsWeb) {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // getToken() is a slow network call — don't block app startup
      FirebaseMessaging.instance.getToken().then(
            (token) => debugPrint('FCM Token: $token'),
          );
    }
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    if (_localNotifications == null) return;

    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications!.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  static Future<String?> getFCMToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  static Future<void> subscribeToTrail(String trailId) async {
    await FirebaseMessaging.instance.subscribeToTopic('trail_$trailId');
  }

  static Future<void> unsubscribeFromTrail(String trailId) async {
    await FirebaseMessaging.instance.unsubscribeFromTopic('trail_$trailId');
  }
}
