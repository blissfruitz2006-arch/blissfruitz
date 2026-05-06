import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/supabase_config.dart';

final notificationServiceProvider = Provider((ref) => NotificationService(SupabaseConfig.client));

/// Top-level function for background message handling.
@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
}

/// Service for handling push and local notifications.
class NotificationService {
  final SupabaseClient _supabase;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  NotificationService(this._supabase);

  /// Initializes FCM and local notifications.
  /// 
  /// Saves the device token to the `riders` table.
  Future<void> initialize(String riderId) async {
    // 1. Request permissions (iOS/Android 13+)
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Setup background handler
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // 3. Setup local notifications
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Notification clicked: ${details.payload}');
      },
    );

    // 4. Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        showLocalNotification(notification.title ?? '', notification.body ?? '');
      }
    });

    // 5. Get and save token
    final token = await _fcm.getToken();
    if (token != null) {
      await _saveToken(riderId, token);
    }

    _fcm.onTokenRefresh.listen((newToken) {
      _saveToken(riderId, newToken);
    });
  }

  /// Saves the FCM token to the rider's record in Supabase.
  Future<void> _saveToken(String riderId, String token) async {
    try {
      await _supabase.from('riders').update({
        'fcm_token': token,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', riderId);
      debugPrint('FCM Token saved for rider $riderId');
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// Shows a local notification in the foreground.
  Future<void> showLocalNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'delivery_channel',
      'Delivery Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.show(
      id: DateTime.now().millisecond,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  /// Sends a notification to a specific rider via Supabase Edge Function.
  /// 
  /// Calls the 'send-fcm' function with payload.
  Future<void> sendOrderNotificationToRider({
    required String riderId,
    required String orderId,
    required String customerName,
    required String address,
  }) async {
    try {
      await _supabase.functions.invoke('send-fcm', body: {
        'rider_id': riderId,
        'order_id': orderId,
        'title': 'New Delivery Assigned!',
        'body': 'Deliver to $customerName at $address',
        'data': {
          'type': 'new_assignment',
          'order_id': orderId,
        }
      });
      debugPrint('Notification trigger sent to Edge Function for rider $riderId');
    } catch (e) {
      debugPrint('Error triggering notification: $e');
      throw Exception('Failed to send notification: $e');
    }
  }
}
