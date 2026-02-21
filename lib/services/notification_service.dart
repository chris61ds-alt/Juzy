import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io'; // Wichtig für Platform Check
import '../models/item.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('ic_launcher');
    
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, 
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    
    try {
      await _notifications.initialize(
        const InitializationSettings(android: androidSettings, iOS: iosSettings)
      );
    } catch (e) {
      print("Fehler Init Notifications: $e");
    }
  }

  // --- Diese Methoden haben gefehlt: ---

  Future<bool> requestPermissions() async {
    if (Platform.isIOS) {
      final bool? result = await _notifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return result ?? false;
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final bool? granted = await androidImplementation?.requestNotificationsPermission();
      return granted ?? false;
    }
    return false;
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  // -------------------------------------

  Future<void> checkAndNudge(List<Item> items) async {
    // Platzhalter Logik
  }

  Future<void> showNotification(String title, String body) async {
    const NotificationDetails platformDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'juzy_channel', 
        'Juzy',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    try {
      await _notifications.show(0, title, body, platformDetails);
    } catch (e) {
       print("Fehler beim Senden: $e");
    }
  }
}