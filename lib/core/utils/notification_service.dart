import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
    );
    
    // ⭐ Request permissions for Android 13+
    await requestPermissions();
  }

  Future<void> requestPermissions() async {
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
        
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'market_reminder_channel',
      'Market Reminders',
      channelDescription: 'Notifications for market proximity reminders',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  Future<void> showTetReminder({
    required int daysLeft,
    required int itemsLeft,
  }) async {
    String title = "🧧 Sắm Tết thôi nào!";
    String body = "Còn $daysLeft ngày nữa là đến Tết. Bạn vẫn còn $itemsLeft món chưa sắm đâu nhé!";

    if (daysLeft == 0) {
      title = "🧧 Chúc mừng năm mới!";
      body = "Tết đã đến rồi! Chúc bạn và gia đình một năm mới an khang thịnh vượng.";
    } else if (itemsLeft == 0) {
      title = "✨ Tuyệt vời!";
      body = "Chỉ còn $daysLeft ngày nữa đến Tết và bạn đã sắm đủ đồ chưa vậy hả. Về quê ăn Tết cùng gia đình thôi!";
    }

    await showNotification(
      id: 999, // Unique ID for Tet reminder
      title: title,
      body: body,
    );
  }
}
