// ignore_for_file: use_key_in_widget_constructors, avoid_print, unused_local_variable

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mandalaarenaapp/Login%20Signup/Screen/home_screen.dart';
import 'package:mandalaarenaapp/Login%20Signup/Screen/login.dart';
import 'package:mandalaarenaapp/Login%20Signup/Screen/signup.dart';
import 'package:mandalaarenaapp/firebase_options.dart';
import 'package:mandalaarenaapp/pages/about_page.dart';
import 'package:mandalaarenaapp/pages/cart_page.dart';
import 'package:mandalaarenaapp/pages/galery_page.dart';
import 'package:mandalaarenaapp/pages/information_page.dart';
import 'package:mandalaarenaapp/pages/welcome_page.dart';
import 'package:mandalaarenaapp/provider/cart.dart';
import 'package:mandalaarenaapp/provider/love_provider.dart';
import 'package:mandalaarenaapp/provider/user_provider.dart';
import 'package:provider/provider.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (context) => Cart()), // Provider untuk Cart
        ChangeNotifierProvider(
            create: (context) => UserProvider()),
        ChangeNotifierProvider(
            create: (_) => LoveProvider()),
      ],
      child: MandalaArenaApp(), // Mengganti MandalaArenaApp menjadi MyApp
    ),
  );
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void setupNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Minta izin untuk menerima notifikasi
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Token FCM (untuk debug)
  String? token = await messaging.getToken();
  print('FCM Token: $token');

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            importance: Importance.high,
          ),
        ),
      );
    }
  });
}

class MandalaArenaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    setupNotifications();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mandala Arena',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => WelcomePage(),
        '/homescreen': (context) => HomeScreen(),
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
        '/gallery': (context) => GalleryPage(),
        '/information': (context) => InformationPage(),
        '/about': (context) => AboutPage(),
        '/cart': (context) => CartPage(),
      },
    );
  }
}
