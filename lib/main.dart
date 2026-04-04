import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'screens/splash_screen.dart';
import 'services/revenue_cat_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  if (message.data['type'] == 'ring') {
    final guardianName = message.data['guardian_name'] ?? 'Your guardian';

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'ring_channel',
      'Ring Alerts',
      channelDescription: 'Urgent ring alerts from guardians',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      playSound: true,
      enableVibration: true,
      sound: RawResourceAndroidNotificationSound('alarm'),
      category: AndroidNotificationCategory.alarm,
    );

    const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      '$guardianName is calling you!',
      'Your guardian is sending you an urgent alert.',
      notificationDetails,
    );

    FlutterRingtonePlayer().playAlarm(looping: false);

    // Stop alarm after 20 seconds
    Timer(const Duration(seconds: 20), () {
      FlutterRingtonePlayer().stop();
    });
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await RevenueCatService.init();

  // Setup local notifications channel
  const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  await flutterLocalNotificationsPlugin.initialize(const InitializationSettings(android: androidInit));

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(const AndroidNotificationChannel(
        'ring_channel',
        'Ring Alerts',
        description: 'Urgent ring alerts from guardians',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ));

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await FirebaseMessaging.instance.requestPermission();

  // Foreground FCM handler
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final type = message.data['type'];
    if (type == 'ring') {
      final guardianName = message.data['guardian_name'] ?? 'Your guardian';

      flutterLocalNotificationsPlugin.show(
        0,
        '$guardianName is calling you!',
        'Your guardian is sending you an urgent alert.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'ring_channel',
            'Ring Alerts',
            importance: Importance.max,
            priority: Priority.max,
            fullScreenIntent: true,
            playSound: true,
            enableVibration: true,
          ),
        ),
      );

      FlutterRingtonePlayer().playAlarm(looping: false);
      Timer(const Duration(seconds: 20), () {
        FlutterRingtonePlayer().stop();
      });
    }
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}
