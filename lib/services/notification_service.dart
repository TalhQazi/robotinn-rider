import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifs = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    try {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);
      await _localNotifs.initialize(initSettings);

      final token = await _messaging.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
      }

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notif = message.notification;
        if (notif != null) {
          _localNotifs.show(
            DateTime.now().millisecond,
            notif.title,
            notif.body,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'robotinn_rider_channel',
                'RobotInn Rider Notifications',
                importance: Importance.max,
                priority: Priority.high,
              ),
            ),
          );
        }
      });
    } catch (_) {}
  }
}
