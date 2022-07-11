import 'package:flutter/material.dart';
import 'package:message/model/contact_item.dart';
import 'package:message/ui/home_app.dart';
import 'package:message/ui/message_page.dart';
import 'package:message/ui/profile_page.dart';
import 'package:message/utilities/app_data.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';

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