// ignore_for_file: use_key_in_widget_constructors, deprecated_member_use, prefer_typing_uninitialized_variables, unreachable_switch_case, avoid_print, prefer_interpolation_to_compose_strings, use_build_context_synchronously, use_super_parameters, unused_local_variable

import 'dart:convert';

import 'package:carousel_slider/carousel_slider.dart';
// import 'package:firebase_database/firebase_database.dart';
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
  // String adminWhatsApp = "";
  bool isExpanded = false;

  Future<void> getLapangs() async {
    String dataLapangJson =
        await rootBundle.loadString('assets/json/lapang.json');
    List<dynamic> jsonMap = json.decode(dataLapangJson);

    setState(() {
      lapangs = jsonMap.map((e) => Lapang.fromJson(e)).toList();
    });

    debugPrint(lapangs[0].name);
  }

  // Future<void> fetchAdminContact() async {
  //   final databaseReference =
  //       FirebaseDatabase.instance.ref("admin_contact/whatsapp");
  //   try {
  //     final snapshot = await databaseReference.get();
  //     if (snapshot.exists && snapshot.value != null) {
  //       setState(() {
  //         adminWhatsApp = snapshot.value.toString();
  //       });
  //     } else {
  //       setState(() {
  //         adminWhatsApp = "";
  //       });
  //       print("Nomor WhatsApp belum tersedia di database.");
  //     }
  //   } catch (e) {
  //     print("Error fetching WhatsApp number: $e");
  //   }
  // }

  // String formatWhatsAppNumber(String number) {
  //   String formattedNumber = number.replaceAll(RegExp(r'[^0-9]'), '');

  //   if (formattedNumber.startsWith('0')) {
  //     formattedNumber = '62' + formattedNumber.substring(1);
  //   }

  //   return formattedNumber;
  // }

  // void openWhatsApp() async {
  //   final defaultNumber = "082117556907";
  //   final numberToUse =
  //       adminWhatsApp.isNotEmpty ? adminWhatsApp : defaultNumber;

  //   final formattedNumber = formatWhatsAppNumber(numberToUse);
  //   final url = Uri.parse("https://wa.me/$formattedNumber");

  //   if (await canLaunchUrl(url)) {
  //     await launchUrl(url, mode: LaunchMode.externalApplication);
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text("Tidak dapat membuka WhatsApp.")));
  //   }
  // }

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

  void _toggleMenu() {
    setState(() {
      isExpanded = !isExpanded;
    });
  }

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  @override
  void initState() {
    super.initState();
    getLapangs();
    // fetchAdminContact();
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
                      ),
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
                  default:
                    return _buildHomeContent(context);
                }
              },
            ),
            // Floating Social Media Button
            Positioned(
              bottom: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // WhatsApp
                  Visibility(
                    visible: isExpanded,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(bottom: 10),
                      child: FloatingActionButton(
                        heroTag: "whatsapp",
                        onPressed: () =>
                            _launchURL('https://wa.me/6282117556907'),
                        backgroundColor: Colors.green,
                        child: const Icon(Icons.phone, color: Colors.white),
                      ),
                    ),
                  ),

                  // Facebook
                  Visibility(
                    visible: isExpanded,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(bottom: 10),
                      child: FloatingActionButton(
                        heroTag: "facebook",
                        onPressed: () => _launchURL(
                            'https://www.facebook.com/mandala.arena'),
                        backgroundColor: Colors.blue,
                        child: const Icon(Icons.facebook, color: Colors.white),
                      ),
                    ),
                  ),

                  // Instagram
                  Visibility(
                    visible: isExpanded,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(bottom: 10),
                      child: FloatingActionButton(
                        heroTag: "instagram",
                        onPressed: () => _launchURL(
                            'https://www.instagram.com/mandalaarena'),
                        backgroundColor: Colors.purple,
                        child:
                            const Icon(Icons.camera_alt, color: Colors.white),
                      ),
                    ),
                  ),

                  // Email
                  Visibility(
                    visible: isExpanded,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(bottom: 10),
                      child: FloatingActionButton(
                        heroTag: "email",
                        onPressed: () =>
                            _launchURL('mailto:mandalaarena@gmail.com'),
                        backgroundColor: Colors.red,
                        child: const Icon(Icons.email, color: Colors.white),
                      ),
                    ),
                  ),

                  // Tombol Utama (Menu)
                  FloatingActionButton(
                    heroTag: "toggle",
                    onPressed: _toggleMenu,
                    backgroundColor: Colors.black,
                    child: Icon(isExpanded ? Icons.close : Icons.add_comment,
                        color: Colors.white),
                  ),
                ],
              ),
            ),
            // Positioned(
            //   bottom: 16,
            //   right: 16,
            //   child: FloatingActionButton(
            //     onPressed: openWhatsApp,
            //     backgroundColor: Colors.black,
            //     child: Icon(Icons.message, color: Colors.white),
            //   ),
            // ),
          ],
        ),
        bottomNavigationBar: BlocBuilder<NavigationCubit, NavigationState>(
          builder: (context, state) {
            return BottomNavigationBar(
              currentIndex: state.index,
              selectedItemColor: Colors.black,
              unselectedItemColor: Colors.black,
              onTap: (index) {
                context.read<NavigationCubit>().navigateToIndex(index);
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Beranda',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.photo_library),
                  label: 'Galeri Aktivitas',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.article),
                  label: 'Informasi Terkini',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.info),
                  label: 'Tentang Aplikasi',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.payment),
                  label: 'Checkout',
                ),
              ],
            );
          },
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
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  color: Colors.white60,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lapangs[index].name ?? 'Lapang Tanpa Nama',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Rp. ${lapangs[index].price}',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.yellow, size: 16),
                        SizedBox(width: 4),
                        Text(
                          '${lapangs[index].rating ?? 0.0}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDiscountBanner(BuildContext context) {
    final List<Map<String, String>> discountBanners = [
      {
        "image": "assets/mini.JPG",
        "title": "Dapatkan Diskon 10%",
        "description": "Untuk Booking Lapang di Hari Jumat",
      },
      {
        "image": "assets/rubber.JPG",
        "title": "Diskon 15% Untuk Member",
        "description": "Nikmati promo eksklusif untuk pengguna setia",
      },
      {
        "image": "assets/vynil.JPG",
        "title": "Promo Spesial Weekend!",
        "description": "Diskon 20% untuk pemesanan di Sabtu & Minggu",
      },
    ];

    return Container(
      height: 250,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: CarouselSlider.builder(
        itemCount: discountBanners.length,
        options: CarouselOptions(
          height: 250,
          autoPlay: true,
          autoPlayInterval: const Duration(seconds: 20),
          autoPlayAnimationDuration: const Duration(milliseconds: 800),
          enlargeCenterPage: true,
          viewportFraction: 1.0,
        ),
        itemBuilder: (context, index, realIndex) {
          final discount = discountBanners[index];
          return ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Gambar sebagai latar belakang
                Positioned.fill(
                  child: Image.asset(
                    discount["image"]!,
                    fit: BoxFit.cover,
                    color: Colors.black.withOpacity(0.3),
                    colorBlendMode: BlendMode.darken,
                  ),
                ),
                // Lapisan putih untuk deskripsi
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: const BoxDecoration(
                      color: Colors.white60,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(20),
                      ),
                    ),
                    child: ListTile(
                      title: Text(
                        discount["title"]!,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        discount["description"]!,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                        ),
                      ),
                      trailing: const Icon(
                        CupertinoIcons.arrow_right,
                        size: 28,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget bestSellerWidget(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          if (lapangs.isNotEmpty && lapangs.length > 1)
            GestureDetector(
              onTap: () {
                goToDetailLapang(1);
              },
              child: Stack(
                children: [
                  // Gambar dengan deskripsi
                  Container(
                    height: 250,
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
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: const BoxDecoration(
                          color: Colors.white60,
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(20),
                          ),
                        ),
                        child: ListTile(
                          title: Text(
                            lapangs[1].name.toString(),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'Rp. ${lapangs[1].price}',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                CupertinoIcons.star_fill,
                                size: 20,
                                color: Colors.yellow,
                              ),
                              const SizedBox(
                                  width: 6), // Jarak antara ikon dan teks
                              Text(
                                '${lapangs[1].rating ?? 0.0}', // Menampilkan rating
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                  // fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Banner di pojok kiri atas
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Best Seller',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Center(
              child: Text(
                "Belum ada best seller tersedia",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
        ],
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String profileImageUrl;

  const ProfilePage({
    Key? key,
    required this.userName,
    required this.userEmail,
    required this.profileImageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Halaman Profil"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(profileImageUrl),
            ),
            const SizedBox(height: 20),
            Text(
              userName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              userEmail,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Kembali ke beranda"),
            ),
          ],
        ),
      ),
    );
  }
}
