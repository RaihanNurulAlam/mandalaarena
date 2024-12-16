// ignore_for_file: use_key_in_widget_constructors, deprecated_member_use

import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandalaarenaapp/pages/about_page.dart';
import 'package:mandalaarenaapp/pages/booking_page.dart';
import 'package:mandalaarenaapp/pages/checkout_page.dart';
import 'package:mandalaarenaapp/pages/galery_page.dart';
import 'package:mandalaarenaapp/pages/information_page.dart';
import 'package:mandalaarenaapp/pages/models/lapang.dart';
import 'package:mandalaarenaapp/pages/search_page.dart';

// BLoC State
enum NavigationState { home, booking, gallery, information, about, checkout }

class NavigationCubit extends Cubit<NavigationState> {
  NavigationCubit() : super(NavigationState.home);

  void navigateTo(NavigationState state) => emit(state);
}

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Lapang> lapangs = [];

  Future<void> getLapangs() async {
    String dataLapangJson = await rootBundle.loadString('assets/json/lapang.json');
    List<dynamic> jsonMap = json.decode(dataLapangJson);

    setState(() {
      lapangs = jsonMap.map((e) => Lapang.fromJson(e)).toList();
    });

    debugPrint(lapangs[0].name);
  }

  void goToDetailLapang(int index) {
    Navigator.pushNamed(
      context,
      '/detail', // Menyebutkan nama rute yang sudah didefinisikan
      arguments: lapangs[index], // Anda bisa mengirim data jika perlu
    );
  }

  void goToCart() {
    Navigator.pushNamed(context, '/cart');
  }

  @override
  void initState() {
    getLapangs();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NavigationCubit(),
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 80,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Raihan Nurul Alam',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 30,
                ),
              ),
              Row(
                children: [
                  Icon(
                    CupertinoIcons.map_pin,
                    size: 14,
                    color: Colors.grey,
                  ),
                  SizedBox(width: 1),
                  Text(
                    'Garut, Indonesia',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => SearchPage()));
              },
              icon: Icon(
                CupertinoIcons.search,
                size: 30,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 14, left: 10),
              child: Stack(
                children: [
                  IconButton(
                    onPressed: () {
                      goToCart();
                    },
                    icon: Icon(
                      CupertinoIcons.bag,
                      size: 30,
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Visibility(
                      visible: lapangs.isNotEmpty, // Replace with actual cart length if necessary
                      child: CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.yellow,
                        child: Center(
                          child: Text(
                            lapangs.length.toString(),
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
        drawer: _buildDrawer(context),
        body: BlocBuilder<NavigationCubit, NavigationState>(
          builder: (context, state) {
            Widget currentPage;

            switch (state) {
              case NavigationState.booking:
                currentPage = BookingPage();
                break;
              case NavigationState.gallery:
                currentPage = GalleryPage();
                break;
              case NavigationState.information:
                currentPage = InformationPage();
                break;
              case NavigationState.about:
                currentPage = AboutPage();
                break;
              case NavigationState.checkout:
                currentPage = CheckoutPage();
                break;
              default:
                currentPage = _buildHomePage(context);
            }

            return SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: currentPage,
            );
          },
        ),
      ),
    );
  }

  Widget _buildHomePage(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildDiscountBanner(context),
          bestSellerWidget(context),
        ],
      ),
    );
  }

  Widget _buildDiscountBanner(BuildContext context) {
    return Container(
      height: 200,
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      width: MediaQuery.sizeOf(context).width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: AssetImage('assets/lapangan_a.jpg'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.5),
            BlendMode.darken,
          ),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: const [
          ListTile(
            title: Text(
              'Dapatkan Diskon 10%',
              style: TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              'Untuk Booking Lapang di Hari Jumat',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
              ),
            ),
            trailing: Icon(
              CupertinoIcons.arrow_right,
              size: 40,
              color: Colors.white,
            ),
          )
        ],
      ),
    );
  }

  bestSellerWidget(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Best Seller',
            style: TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              goToDetailLapang(1);
            },
            child: Container(
              height: 200,
              width: MediaQuery.sizeOf(context).width,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(
                  image: AssetImage(lapangs[1].imagePath.toString()),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.2),
                    BlendMode.darken,
                  ),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ListTile(
                    title: Text(
                      lapangs[2].name.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '${lapangs[2].price} IDR',
                      style: TextStyle(
                        color: Colors.yellowAccent,
                        fontSize: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
  return Drawer(
    child: ListView(
      children: [
        DrawerHeader(
          decoration: BoxDecoration(color: Colors.blue),
          child: Text('Navigation', style: TextStyle(color: Colors.white, fontSize: 24)),
        ),
        ListTile(
          leading: Icon(Icons.home),
          title: Text('Home'),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/');
          },
        ),
        ListTile(
          leading: Icon(Icons.calendar_today),
          title: Text('Jadwal Booking'),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/booking');
          },
        ),
        ListTile(
          leading: Icon(Icons.photo_library),
          title: Text('Galeri Aktivitas'),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/gallery');
          },
        ),
        ListTile(
          leading: Icon(Icons.article),
          title: Text('Informasi Terkini'),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/information');
          },
        ),
        ListTile(
          leading: Icon(Icons.info),
          title: Text('Tentang Aplikasi'),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/about');
          },
        ),
        ListTile(
          leading: Icon(Icons.payment),
          title: Text('Checkout'),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/checkout');
          },
        ),
      ],
    ),
  );
}
}
