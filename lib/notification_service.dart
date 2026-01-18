import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// INIT NOTIFICATION
  static Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
        InitializationSettings(android: androidSettings);

    await _flutterLocalNotificationsPlugin.initialize(settings);
  }

  /// 🎟️ NOTIFIKASI TIKET BERHASIL
  static Future<void> showTicketSuccess({
    required String eventName,
    required String ticketCode,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'ticket_channel',
      'Ticket Notification',
      channelDescription: 'Notifikasi pembelian tiket',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    await _flutterLocalNotificationsPlugin.show(
      1,
      'Pembelian Berhasil 🎉',
      'Tiket $eventName berhasil dibeli\nKode: $ticketCode',
      notificationDetails,
    );
  }
}