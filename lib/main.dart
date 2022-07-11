import 'dart:convert';
import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:message/ui/navigator_app.dart';
import 'package:message/utilities/payload.dart';

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'com.zero.message.push',
  'Push Notifications',
  importance: Importance.high,
);

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _backgroundMessageHandler(RemoteMessage message) async {
  log('Background message: ${message.data}', name: '_backgroundMessage');
  Payload payload = Payload.fromJson(message.data);
  flutterLocalNotificationsPlugin.cancel(
    payload.senderId.hashCode,
  );
  flutterLocalNotificationsPlugin.show(
    payload.senderId.hashCode,
    payload.senderName,
    payload.body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        icon: '@mipmap/ic_launcher',
        groupKey: payload.senderId,
      ),
    ),
    payload: jsonEncode(message.data),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  runApp(NavigarorApp());
}

