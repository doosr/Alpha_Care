import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Configuration de l'initialisation des notifications locales pour Android
    const InitializationSettings initializationSettings =
    InitializationSettings(
      android: AndroidInitializationSettings(
          'app_icon'), // icône de l'application pour les notifications Android
    );

    // Initialisation du plugin des notifications locales
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> showNotification(String title, String body) async {
    // Configuration de la notification pour Android
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'your_channel_id', // ID du canal de notification
      'your_channel_name', // Nom du canal de notification
      channelDescription: 'your_channel_description',
      // Description du canal de notification
      importance: Importance.max,
      priority: Priority.high,
    );

    // NotificationDetails pour Android seulement
    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    // Affichage de la notification
    await flutterLocalNotificationsPlugin.show(
      0, // ID de la notification
      title, // Titre de la notification
      body, // Corps de la notification
      platformChannelSpecifics,
    );
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
