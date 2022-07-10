import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:message/ui/contacts_page.dart';
import 'package:message/ui/message_page.dart';
import 'package:message/ui/profile_page.dart';
import 'package:message/ui/signup_page.dart';
import 'package:message/utilities/app_data.dart';
import 'package:message/utilities/payload.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';

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

class NavigarorApp extends StatelessWidget {
  NavigarorApp({Key? key}) : super(key: key);
  final navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppData()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        onGenerateRoute: (settings) {
          switch(settings.name) {
            case '/':
              return MaterialPageRoute(
                builder: (context) => HomeApp(navigatorKey: navigatorKey),
              );
            case MessagePage.routeName:
              return PageTransition(
                type: PageTransitionType.rightToLeft,
                child: MessagePage(
                  contactItem: settings.arguments as ContactItem,
                ),
              );
            case ProfilePage.routeName:
              return PageTransition(
                type: PageTransitionType.rightToLeft,
                child: const ProfilePage(),
              );
          default:
            return MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: AppBar(
                  title: const Text('Error'),
                ),
                body: const Center(
                  child: Text('Page not found'),
                ),
              ),
            );
          }
        },
        initialRoute: '/',
        theme: ThemeData(
          colorSchemeSeed: Colors.green,
          useMaterial3: true,
        ),
      ),
    );
  }
}

class HomeApp extends StatefulWidget {
  const HomeApp({Key? key, required this.navigatorKey}) : super(key: key);
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  State<HomeApp> createState() => _HomeAppState();
}

class _HomeAppState extends State<HomeApp> {
  void _saveToken(String? token) async {
    log(
      'Saving token: $token',
      name: runtimeType.toString(),
    );
    if (token == null) return;
  }

  @override
  void initState() {
    super.initState();
    flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails().then(
      (details) {
        if (details == null ||
            !details.didNotificationLaunchApp ||
            details.payload == null) {
          log(
            'didNotificationLaunchApp: false',
            name: runtimeType.toString(),
          );
          return;
        }
        log(
          'notification launch payload: ${details.payload}',
          name: runtimeType.toString(),
        );
        var payload = Payload.fromJson(jsonDecode(details.payload!));
        flutterLocalNotificationsPlugin.cancel(
          payload.senderId.hashCode,
        );
        Navigator.pushNamed(
          context,
          MessagePage.routeName,
          arguments: ContactItem(
            name: payload.senderName,
            phoneNumber: payload.senderPhoneNumber,
            uid: payload.senderId,
          ),
        );
      },
    );
    FirebaseMessaging.instance.onTokenRefresh.listen(_saveToken);
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      log('message: ' + message.toString(), name: 'getInitialMessage');
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      Payload payload = Payload.fromJson(message.data);
      var _number = context.read<AppData>().userNumber;
      log(
        _number.toString(),
        name: 'user opened',
      );
      if (_number == payload.senderPhoneNumber) {
        return;
      }
      flutterLocalNotificationsPlugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
        onSelectNotification: ((_) async {
          log(
            'notification payload: ${payload.body}',
            name: 'onSelectNotification',
          );
          var user = await FirebaseFirestore.instance
              .collection('users')
              .doc(payload.senderPhoneNumber)
              .get();
          if (context.read<AppData>().userNumber == payload.senderPhoneNumber) {
            return;
          } else if (context.read<AppData>().userNumber != null &&
              (widget.navigatorKey.currentState?.canPop() ?? false)) {
            widget.navigatorKey.currentState!.pop();
          }
          var data = user.data()!;
          log('forwarding to ${data['name']}', name: 'onSelectNotification');
          flutterLocalNotificationsPlugin.cancel(
            payload.senderId.hashCode,
          );
          Navigator.pushNamed(
            context,
            MessagePage.routeName,
            arguments: ContactItem(
              name: payload.senderName,
              phoneNumber: payload.senderPhoneNumber,
              uid: payload.senderId,
            ),
          );
        }),
      );
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
            groupKey: payload.senderId,
            category: '',
          ),
        ),
        payload: jsonEncode(message.data),
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log('' + message.toString(), name: 'onMessageOpenedApp');
    });
  }

  @override
  Widget build(BuildContext context) {
    return FirebaseAuth.instance.currentUser != null
        ? const ContactsPage()
        : const SignUpPage();
  }
}
