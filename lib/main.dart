import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/splash_screen.dart';
import 'services/revenue_cat_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _sendLocationToServer() async {
  try {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 10)),
    );

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;

    await http.post(
      Uri.parse('https://alivecheck.app/api/location/update'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'latitude': position.latitude, 'longitude': position.longitude}),
    ).timeout(const Duration(seconds: 10));
  } catch (e) {
    // silent fail
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  final type = message.data['type'];

  if (type == 'location_request') {
    await _sendLocationToServer();
    return;
  }

  if (type == 'ring' || type == 'alert') {
    final isAlert = type == 'alert';
    final userName = isAlert
        ? (message.data['user_name'] ?? 'Someone')
        : (message.data['guardian_name'] ?? 'Your guardian');
    final title = isAlert
        ? '$userName missed their check-in!'
        : '$userName is calling you!';
    final body = isAlert
        ? '$userName has not checked in on time.'
        : 'Your guardian is sending you an urgent alert.';

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'ring_channel',
      'Ring Alerts',
      channelDescription: 'Urgent ring alerts from guardians',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.alarm,
    );

    const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
    );

    await flutterLocalNotificationsPlugin.show(
      isAlert ? 1 : 0,
      title,
      body,
      notificationDetails,
    );

    FlutterRingtonePlayer().playAlarm(looping: false);

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

  // Request location permission
  LocationPermission locPerm = await Geolocator.checkPermission();
  if (locPerm == LocationPermission.denied) {
    locPerm = await Geolocator.requestPermission();
  }
  if (locPerm == LocationPermission.whileInUse) {
    await Geolocator.requestPermission();
  }

  // Foreground FCM handler
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final type = message.data['type'];
    if (type == 'location_request') {
      _sendLocationToServer();
      return;
    }
    if (type == 'ring' || type == 'alert') {
      final isAlert = type == 'alert';
      final userName = isAlert
          ? (message.data['user_name'] ?? 'Someone')
          : (message.data['guardian_name'] ?? 'Your guardian');
      final title = isAlert
          ? '$userName missed their check-in!'
          : '$userName is calling you!';
      final body = isAlert
          ? '$userName has not checked in on time.'
          : 'Your guardian is sending you an urgent alert.';

      flutterLocalNotificationsPlugin.show(
        isAlert ? 1 : 0,
        title,
        body,
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
