import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';

final notificationServiceProvider = Provider((ref) => NotificationService());

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const initializationSettingsAndroid = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initializationSettingsIOS = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await _notificationsPlugin.initialize(initializationSettings);
  }

  Future<void> showPaymentNotification({
    required String clientName,
    required double amount,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'payments_channel',
      'Pagamentos',
      channelDescription: 'Notificações de pagamentos recebidos',
      importance: Importance.max,
      priority: Priority.high,
      color: Color(0xFF1976D2),
    );
    const iosDetails = DarwinNotificationDetails();
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      DateTime.now().millisecond,
      '💰 Pagamento Recebido!',
      'O cliente $clientName pagou o orçamento de R\$ ${amount.toStringAsFixed(2)}.',
      notificationDetails,
    );
  }
}
