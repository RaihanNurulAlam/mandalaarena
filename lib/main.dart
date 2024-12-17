// ignore_for_file: use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mandalaarenaapp/pages/about_page.dart';
import 'package:mandalaarenaapp/pages/booking_page.dart';
import 'package:mandalaarenaapp/pages/cart_page.dart';
import 'package:mandalaarenaapp/pages/checkout_page.dart';
import 'package:mandalaarenaapp/pages/galery_page.dart';
import 'package:mandalaarenaapp/pages/home_page.dart';
import 'package:mandalaarenaapp/pages/information_page.dart';
import 'package:mandalaarenaapp/pages/welcome_page.dart';
import 'package:mandalaarenaapp/provider/cart.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp( 
    options: FirebaseOptions(
      apiKey: "AIzaSyAlNhiLGmW_kgVYQEYZ8KDI0k9t551pP34",
      authDomain: "mandalaarenaapp-95d0d.firebaseapp.com",
      databaseURL: "https://mandalaarenaapp-95d0d-default-rtdb.asia-southeast1.firebasedatabase.app",
      projectId: "mandalaarenaapp-95d0d",
      storageBucket: "mandalaarenaapp-95d0d.firebasestorage.app",
      messagingSenderId: "824515157247",
      appId: "1:824515157247:web:e5917ff217cf1cd02300ca",
      measurementId: "G-PLDEDBNW67"
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (context) => Cart()), // Tambahkan Cart provider
      ],
      child: MandalaArenaApp(),
    ),
  );
}

class MandalaArenaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mandala Arena',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => WelcomePage(),
        '/home': (context) => HomePage(),
        '/booking': (context) => BookingPage(),
        '/gallery': (context) => GalleryPage(),
        '/information': (context) => InformationPage(),
        '/about': (context) => AboutPage(),
        '/checkout': (context) => CheckoutPage(
              totalPayment: '',
            ),
        '/cart': (context) => CartPage(),
      },
    );
  }
}
