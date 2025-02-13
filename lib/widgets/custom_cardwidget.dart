// lib/pages/home_page.dart

// ignore_for_file: use_key_in_widget_constructors, deprecated_member_use, prefer_typing_uninitialized_variables, unreachable_switch_case, avoid_print, prefer_interpolation_to_compose_strings, use_build_context_synchronously, use_super_parameters, unused_local_variable

import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandalaarenaapp/pages/alamat_page.dart';
import 'package:mandalaarenaapp/pages/detailpage.dart';
import 'package:mandalaarenaapp/pages/galery_page.dart';
import 'package:mandalaarenaapp/pages/models/lapang.dart';
import 'package:mandalaarenaapp/pages/payment_page.dart';
import 'package:mandalaarenaapp/pages/search_page.dart';
import 'package:mandalaarenaapp/pages/sparring_team_page.dart';
import 'package:mandalaarenaapp/provider/cart.dart';
import 'package:mandalaarenaapp/provider/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../cubit/navigation_cubit.dart';
import '../widgets/drawer_widget.dart';
import '../pages/information_page.dart';
import '../pages/about_page.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Lapang> lapangs = [];
  String adminWhatsApp = "";

  Future<void> getLapangs() async {
    String dataLapangJson =
        await rootBundle.loadString('assets/json/lapang.json');
    List<dynamic> jsonMap = json.decode(dataLapangJson);

    setState(() {
      lapangs = jsonMap.map((e) => Lapang.fromJson(e)).toList();
    });

    debugPrint(lapangs[0].name);
  }

  Future<void> fetchAdminContact() async {
    final databaseReference =
        FirebaseDatabase.instance.ref("admin_contact/whatsapp");
    try {
      final snapshot = await databaseReference.get();
      if (snapshot.exists && snapshot.value != null) {
        setState(() {
          adminWhatsApp = snapshot.value.toString();
        });
      } else {
        setState(() {
          adminWhatsApp = "";
        });
        print("Nomor WhatsApp belum tersedia di database.");
      }
    } catch (e) {
      print("Error fetching WhatsApp number: $e");
    }
  }

  String formatWhatsAppNumber(String number) {
    String formattedNumber = number.replaceAll(RegExp(r'[^0-9]'), '');

    if (formattedNumber.startsWith('0')) {
      formattedNumber = '62' + formattedNumber.substring(1);
    }

    return formattedNumber;
  }

  void openWhatsApp() async {
    final defaultNumber = "082117556907";
    final numberToUse =
        adminWhatsApp.isNotEmpty ? adminWhatsApp : defaultNumber;

    final formattedNumber = formatWhatsAppNumber(numberToUse);
    final url = Uri.parse("https://wa.me/$formattedNumber");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Tidak dapat membuka WhatsApp.")));
    }
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
    super.initState();
    getLapangs();
    fetchAdminContact();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
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
                style: TextStyle(color: Colors.black, fontSize: 28),
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
                    MaterialPageRoute(builder: (context) => AlamatPage()));
              },
              icon: Icon(
                Icons.location_on,
                size: 30,
              ),
            ),
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
        body: Stack(
          children: [
            BlocBuilder<NavigationCubit, NavigationState>(
              builder: (context, state) {
                switch (state) {
                  case NavigationState.gallery:
                    return GalleryPage();
                  case NavigationState.information:
                    return InformationPage();
                  case NavigationState.about:
                    return AboutPage();
                  case NavigationState.payment:
                    return PaymentPage();
                  case NavigationState.sparring:
                    return SparringTeamPage();
                  default:
                    return _buildHomeContent(context);
                }
              },
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                onPressed: openWhatsApp,
                backgroundColor: Colors.black,
                child: Icon(Icons.message, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildDiscountBanner(context),
          bestSellerWidget(context),
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
          SizedBox(height: 20),
          _buildGridLapangs(context),
          SizedBox(height: 20),
          _buildFAQSection(),
          SizedBox(height: 20),
          _buildNewWidgetSection(), // Tambahkan widget baru di sini
        ],
      ),
    );
  }

  Widget _buildFAQSection() {
    List<Map<String, String>> faqs = [
      {
        'question':
            'Apa kelebihan sewa lapangan yang tersedia di Mandala Arena?',
        'answer':
            'Lapangan kami memiliki fasilitas lengkap dan lokasi strategis.'
      },
      {
        'question': 'Bagaimana cara memesan lapangan di Mandala Arena?',
        'answer':
            'Anda dapat memesan melalui aplikasi atau menghubungi kami langsung.'
      },
      {
        'question':
            'Berapa biaya sewa lapangan yang tersedia di Mandala Arena?',
        'answer':
            'Biaya sewa bervariasi tergantung jenis lapangan dan waktu pemakaian.'
      },
      {
        'question': 'Apakah ada diskon atau promo khusus?',
        'answer':
            'Kami menawarkan diskon setiap hari Jumat dan event-event tertentu.'
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FAQ',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          ...faqs.map((faq) => ExpansionTile(
                title: Text(
                  faq['question']!,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(faq['answer']!),
                  ),
                ],
              )),
        ],
      ),
    );
  }

  Widget _buildGridLapangs(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 4 / 5,
      ),
      itemCount: lapangs.length,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            goToDetailLapang(index);
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: DecorationImage(
                image: AssetImage(
                    lapangs[index].imagePath ?? 'assets/default_image.jpg'),
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
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    lapangs[index].name ?? 'Lapang Tanpa Nama',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Rp. ${lapangs[index].price}',
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
          image: AssetImage('assets/mini.jpg'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.2),
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
                      'Rp. ${lapangs[1].price}',
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

  Widget _buildNewWidgetSection() {
    // Contoh widget baru yang ditambahkan di bagian bawah halaman
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Widget Baru',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                'Ini adalah widget baru',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
