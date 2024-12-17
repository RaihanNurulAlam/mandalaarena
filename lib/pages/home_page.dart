// lib/pages/home_page.dart

// ignore_for_file: use_key_in_widget_constructors, deprecated_member_use, prefer_typing_uninitialized_variables

import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandalaarenaapp/pages/checkout_page.dart';
import 'package:mandalaarenaapp/pages/detail_page.dart';
import 'package:mandalaarenaapp/pages/galery_page.dart';
import 'package:mandalaarenaapp/pages/models/lapang.dart';
import 'package:mandalaarenaapp/pages/search_page.dart';
import 'package:mandalaarenaapp/provider/cart.dart';
import 'package:provider/provider.dart';
import '../cubit/navigation_cubit.dart';
import '../widgets/drawer_widget.dart';
import '../pages/booking_page.dart';
import '../pages/information_page.dart';
import '../pages/about_page.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Lapang> lapangs = [];

  Future<void> getLapangs() async {
    String dataLapangJson =
        await rootBundle.loadString('assets/json/lapang.json');
    List<dynamic> jsonMap = json.decode(dataLapangJson);

    setState(() {
      lapangs = jsonMap.map((e) => Lapang.fromJson(e)).toList();
    });

    debugPrint(lapangs[0].name);
  }

  void goToDetailLapang(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailPage(
          lapang: lapangs[index],
        ),
      ),
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
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Mandala Arena',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 28),
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
            Consumer<Cart>(
              builder: (context, value, child) {
                return Padding(
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
                          visible: value.cart.isNotEmpty ? true : false,
                          child: CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.yellow,
                            child: Center(
                              child: Text(
                                value.cart.length.toString(),
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
                );
              },
            )
          ],
        ),
        drawer: DrawerWidget(),
        body: BlocBuilder<NavigationCubit, NavigationState>(
          builder: (context, state) {
            switch (state) {
              case NavigationState.booking:
                return BookingPage();
              case NavigationState.gallery:
                return GalleryPage();
              case NavigationState.information:
                return InformationPage();
              case NavigationState.about:
                return AboutPage();
              case NavigationState.checkout:
                return CheckoutPage(totalPayment: "");
              default:
                return _buildHomeContent(context);
            }
          },
        ),
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildDiscountBanner(context), // Banner Diskon
          bestSellerWidget(context), // Best Seller
          SizedBox(height: 20),

          // Menampilkan lapang-lapang yang bisa dipilih
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Pilih Lapang',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          // Daftar lapang dalam horizontal list
          SizedBox(
            height: 200, // Mengatur tinggi kontainer lapang
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount:
                  lapangs.length, // Menggunakan data lapang yang sudah dimuat
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    goToDetailLapang(index); // Arahkan ke detail lapang
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: 16),
                    width: 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      image: DecorationImage(
                        image: AssetImage(lapangs[index].imagePath ??
                            'assets/default_image.jpg'),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          Colors.black.withOpacity(0.2),
                          BlendMode.darken,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ListTile(
                          title: Text(
                            lapangs[index].name ?? 'Lapang Tanpa Nama',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '${lapangs[index].price} IDR',
                            style: TextStyle(
                              color: Colors.yellowAccent,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
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
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              'Untuk Booking Lapang di Hari Jumat',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
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
                      lapangs[1].name.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '${lapangs[2].price} IDR',
                      style: TextStyle(
                        color: Colors.yellowAccent,
                        fontSize: 18,
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
}