import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import '../models/credit_card.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle notification click if needed
      },
    );

    // Request permissions for Android 13+
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> showDuePaymentNotification({
    required CreditCard card,
    String? customMessage,
  }) async {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dueFormatted = currencyFormat.format(card.dueAmount);
    final dateFormatted = DateFormat('MMM dd, yyyy').format(card.dueDate);

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'card_due_channel',
      'Credit Card Due Reminders',
      channelDescription: 'Alerts for upcoming and overdue credit card payments',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    final title = card.isOverdue
        ? '⚠️ Overdue Alert: ${card.cardName}'
        : '💳 Payment Reminder: ${card.cardName}';

    final body = customMessage ??
        'Due Amount: $dueFormatted is due on $dateFormatted. Tap to pay now!';

    await flutterLocalNotificationsPlugin.show(
      card.id ?? 100,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'general_alerts',
      'General Alerts',
      channelDescription: 'SpendWise General Alerts',
      importance: Importance.high,
      priority: Priority.high,
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);
    await flutterLocalNotificationsPlugin.show(0, title, body, details);
  }

  Future<void> checkAndAlertUpcomingDues(List<CreditCard> cards) async {
    for (final card in cards) {
      if (card.dueAmount > 0) {
        if (card.isOverdue) {
          await showDuePaymentNotification(
            card: card,
            customMessage:
                'URGENT: Your payment of \$${card.dueAmount.toStringAsFixed(2)} was due on ${DateFormat('MMM dd').format(card.dueDate)}!',
          );
        } else if (card.daysUntilDue <= 3 && card.daysUntilDue >= 0) {
          final dayText = card.daysUntilDue == 0 ? 'TODAY' : 'in ${card.daysUntilDue} days';
          await showDuePaymentNotification(
            card: card,
            customMessage:
                'Reminder: \$${card.dueAmount.toStringAsFixed(2)} due $dayText (${DateFormat('MMM dd').format(card.dueDate)}). Avoid late fees!',
          );
        }
      }
    }
  }
}
