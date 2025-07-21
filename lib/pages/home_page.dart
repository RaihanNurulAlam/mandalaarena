// ignore_for_file: use_key_in_widget_constructors, deprecated_member_use, prefer_typing_uninitialized_variables, unreachable_switch_case, avoid_print, prefer_interpolation_to_compose_strings, use_build_context_synchronously, use_super_parameters, unused_local_variable

import 'dart:convert';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandalaarenaapp/Login%20Signup/Screen/login.dart';
import 'package:mandalaarenaapp/pages/alamat_page.dart';
import 'package:mandalaarenaapp/pages/booking_summary_page.dart';
import 'package:mandalaarenaapp/pages/detailpage.dart';
// import 'package:mandalaarenaapp/pages/galery_page.dart';
import 'package:mandalaarenaapp/pages/models/lapang.dart';
import 'package:mandalaarenaapp/pages/points_page.dart';
import 'package:mandalaarenaapp/pages/profile_navigation.dart';
// import 'package:mandalaarenaapp/pages/payment_page.dart';
// import 'package:mandalaarenaapp/pages/search_page.dart';
import 'package:mandalaarenaapp/pages/sparring_team_page.dart';
import 'package:mandalaarenaapp/provider/cart.dart';
import 'package:mandalaarenaapp/provider/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../cubit/navigation_cubit.dart';
// import '../widgets/drawer_widget.dart';
// import '../pages/information_page.dart';
// import '../pages/about_page.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Lapang> lapangs = [];
  // String adminWhatsApp = "";
  bool isExpanded = false;
  bool isHoveredToggle = false;

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
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => BookingSummaryPage()));
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
    final user = FirebaseAuth.instance.currentUser;
    return BlocProvider(
      create: (context) => NavigationCubit(),
      child: Builder(builder: (BuildContext newContext) {
        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 80,
            title: Padding(
              padding: const EdgeInsets.only(left: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Mandala Arena',
                    style: TextStyle(color: Colors.black, fontSize: 20),
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
            ),
            actions: [
              TextButton.icon(
                onPressed: user != null
                    ? () {
                        // 2. Gunakan 'newContext' dari Builder untuk memanggil Cubit
                        newContext.read<NavigationCubit>().navigateToIndex(3);
                      }
                    : null,
                icon: const Icon(Icons.star, color: Colors.orange, size: 22),
                label: Text(
                  userProvider.points.toString(),
                  style: const TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => AlamatPage()));
                },
                icon: const Icon(Icons.location_on, size: 30),
              ),
              // Search button
              // IconButton(
              //   onPressed: () {
              //     Navigator.push(context,
              //         MaterialPageRoute(builder: (context) => SearchPage()));
              //   },
              //   icon: Icon(
              //     CupertinoIcons.search,
              //     size: 30,
              //   ),
              // ),
              Consumer<Cart>(
                builder: (context, value, child) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 14, left: 5),
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
              ),
              // Tombol Login atau Avatar Profil (Posisi Paling Kanan)
              if (user == null)
                // --- AWAL PERUBAHAN ---
                // Jika user BELUM login
                Padding(
                  // Padding di kanan (14px) agar sejajar dengan cart
                  padding: const EdgeInsets.fromLTRB(4, 18, 16, 18),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginScreen()),
                      );
                    },
                    icon:
                        const Icon(Icons.login, size: 18, color: Colors.white),
                    label: const Text("Login"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                )
              // --- AKHIR PERUBAHAN ---
              else
                // Jika SUDAH login
                Consumer<UserProvider>(
                  builder: (context, provider, child) {
                    return GestureDetector(
                      onTap: () {
                        // 2. Gunakan 'newContext' juga di sini
                        newContext.read<NavigationCubit>().navigateToIndex(2);
                      },
                      child: Padding(
                        // Padding di kanan (14px) agar sejajar
                        padding: const EdgeInsets.only(right: 16.0, left: 4.0),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundImage: NetworkImage(
                            userProvider.profileImageUrl.isNotEmpty
                                ? userProvider.profileImageUrl
                                : "https://via.placeholder.com/150",
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
          // drawer: DrawerWidget(),
          body: Stack(
            children: [
              BlocBuilder<NavigationCubit, NavigationState>(
                builder: (context, state) {
                  switch (state) {
                    // case NavigationState.gallery:
                    //   return GalleryPage();
                    // case NavigationState.information:
                    //   return InformationPage();
                    // case NavigationState.about:
                    //   return AboutPage();
                    // case NavigationState.payment:
                    //   return PaymentPage();
                    case NavigationState.sparring:
                      return SparringTeamPage();
                    case NavigationState.profile:
                      return ProfilePageNavigation();
                    case NavigationState.points:
                      return PointsPage();
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
                              _launchURL('https://wa.me/6281111122525'),
                          backgroundColor: Colors.green,
                          child: Image.network(
                            "https://img.icons8.com/?size=100&id=16733&format=png&color=FFFFFF",
                            width: 25, // Sesuaikan ukuran
                            height: 25,
                          ),
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
                          child:
                              const Icon(Icons.facebook, color: Colors.white),
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
                            child: Image.network(
                              "https://img.icons8.com/?size=100&id=59813&format=png&color=FFFFFF",
                              width: 25, // Sesuaikan ukuran
                              height: 25,
                            )),
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
                          child: Image.network(
                            "https://img.icons8.com/?size=100&id=ptAjLogGbrSi&format=png&color=FFFFFF",
                            width: 25, // Sesuaikan ukuran
                            height: 25,
                          ),
                        ),
                      ),
                    ),

                    // Tombol Utama (Menu)
                    MouseRegion(
                      onEnter: (_) => setState(() {
                        isHoveredToggle = true;
                      }),
                      onExit: (_) => setState(() {
                        isHoveredToggle = false;
                      }),
                      child: FloatingActionButton(
                        heroTag: "toggle",
                        onPressed: _toggleMenu,
                        backgroundColor: Colors.black.withOpacity(
                            isHoveredToggle
                                ? 1.0
                                : 0.5), // Transparansi di sini
                        child: Icon(
                          isExpanded ? Icons.close : Icons.add_comment,
                          color: Colors.white,
                        ),
                      ),
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
                  // BottomNavigationBarItem(
                  //   icon: Icon(Icons.photo_library),
                  //   label: 'Galeri',
                  // ),
                  // BottomNavigationBarItem(
                  //   icon: Icon(Icons.article),
                  //   label: 'Informasi',
                  // ),
                  // BottomNavigationBarItem(
                  //   icon: Icon(Icons.info),
                  //   label: 'Tentang',
                  // ),
                  // BottomNavigationBarItem(
                  //   icon: Icon(Icons.payment),
                  //   label: 'Checkout',
                  // ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.group),
                    label: 'Sparring',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person),
                    label: 'Profile',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.star),
                    label: 'Points',
                  ),
                ],
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildHomeContent(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildDiscountBanner(context),
          // bestSellerWidget(context),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Pilih Lapang',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          _buildGridLapangs(context),
          // _buildFAQSection(),
        ],
      ),
    );
  }

  // Widget _buildFAQSection() {
  //   List<Map<String, String>> faqs = [
  //     {
  //       'question':
  //           'Apa kelebihan sewa lapangan yang tersedia di Mandala Arena?',
  //       'answer':
  //           'Lapangan kami memiliki fasilitas lengkap dan lokasi strategis.'
  //     },
  //     {
  //       'question': 'Bagaimana cara memesan lapangan di Mandala Arena?',
  //       'answer':
  //           'Anda dapat memesan melalui aplikasi atau menghubungi kami langsung.'
  //     },
  //     {
  //       'question':
  //           'Berapa biaya sewa lapangan yang tersedia di Mandala Arena?',
  //       'answer':
  //           'Biaya sewa bervariasi tergantung jenis lapangan dan waktu pemakaian.'
  //     },
  //     {
  //       'question': 'Apakah ada diskon atau promo khusus?',
  //       'answer':
  //           'Kami menawarkan diskon setiap hari Jumat dan event-event tertentu.'
  //     },
  //   ];

  //   return Padding(
  //     padding: const EdgeInsets.all(16.0),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //     //     Text(
  //     //       'FAQ',
  //     //       style: TextStyle(
  //     //         fontSize: 24,
  //     //         fontWeight: FontWeight.bold,
  //     //       ),
  //     //     ),
  //     //     SizedBox(height: 16),
  //     //     ...faqs.map((faq) => ExpansionTile(
  //     //           title: Text(
  //     //             faq['question']!,
  //     //             style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  //     //           ),
  //     //           children: [
  //     //             Padding(
  //     //               padding: const EdgeInsets.symmetric(horizontal: 16.0),
  //     //               child: Text(faq['answer']!),
  //     //             ),
  //     //           ],
  //     //         )),
  //     //   ],
  //     // ),
  //   );
  // }

  Widget _buildGridLapangs(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
          horizontal: 20, vertical: 10), // Padding di sekeliling GridView
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 1650
            ? 5
            : MediaQuery.of(context).size.width > 1200
                ? 4
                : MediaQuery.of(context).size.width > 750
                    ? 3
                    : 2,
        mainAxisSpacing: 20, // Sedikit perbesar jarak
        crossAxisSpacing: 20, // Sedikit perbesar jarak
        childAspectRatio: 4 / 5,
      ),
      itemCount: lapangs.length,
      itemBuilder: (context, index) {
        // Panggil widget item yang sudah kita buat
        return LapangGridItem(
          lapang: lapangs[index],
          onTap: () => goToDetailLapang(index),
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
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: CarouselSlider.builder(
        itemCount: discountBanners.length,
        options: CarouselOptions(
          height: 300,
          autoPlay: true,
          autoPlayInterval: const Duration(seconds: 20),
          autoPlayAnimationDuration: const Duration(milliseconds: 800),
          enlargeCenterPage: true,
          viewportFraction: 1.0,
        ),
        itemBuilder: (context, index, realIndex) {
          final discount = discountBanners[index];
          return Container(
            margin: const EdgeInsets.symmetric(
                horizontal: 5.0), // Beri sedikit jarak antar banner
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand, // Pastikan Stack memenuhi seluruh area
                children: [
                  // Gambar Latar Belakang
                  Image.asset(
                    discount["image"]!,
                    fit: BoxFit.cover,
                  ),
                  // Lapisan Gradasi untuk Teks
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.center,
                        colors: [
                          Colors.black.withOpacity(0.8),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  // Konten Teks
                  Positioned(
                    bottom: 20.0,
                    left: 20.0,
                    right: 20.0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          discount["title"]!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              // Tambahkan shadow agar teks lebih terbaca
                              Shadow(
                                blurRadius: 10.0,
                                color: Colors.black54,
                                offset: Offset(2.0, 2.0),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          discount["description"]!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

//   Widget bestSellerWidget(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const SizedBox(height: 10),
//           if (lapangs.isNotEmpty && lapangs.length > 1)
//             GestureDetector(
//               onTap: () {
//                 goToDetailLapang(1);
//               },
//               child: Stack(
//                 children: [
//                   // Gambar dengan deskripsi
//                   Container(
//                     height: 250,
//                     width: MediaQuery.sizeOf(context).width,
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(20),
//                       image: DecorationImage(
//                         image: AssetImage(lapangs[1].imagePath.toString()),
//                         fit: BoxFit.cover,
//                         colorFilter: ColorFilter.mode(
//                           Colors.black.withOpacity(0.2),
//                           BlendMode.darken,
//                         ),
//                       ),
//                     ),
//                     child: Align(
//                       alignment: Alignment.bottomCenter,
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 16, vertical: 10),
//                         decoration: const BoxDecoration(
//                           color: Colors.white60,
//                           borderRadius: BorderRadius.vertical(
//                             bottom: Radius.circular(20),
//                           ),
//                         ),
//                         child: ListTile(
//                           title: Text(
//                             lapangs[1].name.toString(),
//                             style: const TextStyle(
//                               color: Colors.black,
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           subtitle: Text(
//                             'Rp. ${lapangs[1].price}',
//                             style: const TextStyle(
//                               color: Colors.black,
//                               fontSize: 14,
//                             ),
//                           ),
//                           trailing: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               const Icon(
//                                 CupertinoIcons.star_fill,
//                                 size: 20,
//                                 color: Colors.yellow,
//                               ),
//                               const SizedBox(
//                                   width: 6), // Jarak antara ikon dan teks
//                               Text(
//                                 '${lapangs[1].rating ?? 0.0}', // Menampilkan rating
//                                 style: const TextStyle(
//                                   color: Colors.black,
//                                   fontSize: 14,
//                                   // fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                   // Banner di pojok kiri atas
//                   Positioned(
//                     top: 10,
//                     left: 10,
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 10, vertical: 5),
//                       decoration: BoxDecoration(
//                         color: Colors.black,
//                         borderRadius: BorderRadius.circular(10),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.2),
//                             blurRadius: 4,
//                             offset: const Offset(2, 2),
//                           ),
//                         ],
//                       ),
//                       child: const Text(
//                         'Best Seller',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 14,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             )
//           else
//             Center(
//               child: Text(
//                 "Belum ada best seller tersedia",
//                 style: TextStyle(color: Colors.grey, fontSize: 16),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
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

class LapangGridItem extends StatefulWidget {
  final Lapang lapang; // Ganti 'Lapang' dengan nama model Anda
  final VoidCallback onTap;

  const LapangGridItem({
    Key? key,
    required this.lapang,
    required this.onTap,
  }) : super(key: key);

  @override
  _LapangGridItemState createState() => _LapangGridItemState();
}

class _LapangGridItemState extends State<LapangGridItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          // --- Animasi saat hover ---
          transform: _isHovered
              ? (Matrix4.identity()..scale(1.05))
              : Matrix4.identity(),
          transformAlignment: FractionalOffset.center,
          child: Card(
            // --- Efek shadow dan corner radius ---
            elevation: _isHovered ? 10 : 5,
            shadowColor: Colors.black.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            clipBehavior:
                Clip.antiAlias, // Penting agar gambar mengikuti corner radius
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Gambar Latar
                Image.asset(
                  widget.lapang.imagePath ?? 'assets/default_image.jpg',
                  fit: BoxFit.cover,
                ),

                // --- Efek Gradien ---
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.1),
                        Colors.black.withOpacity(0.7),
                      ],
                      stops: const [0.5, 0.7, 1.0],
                    ),
                  ),
                ),

                // Konten Teks
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.lapang.name ?? 'Lapang Tanpa Nama',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                blurRadius: 4.0,
                                color: Colors.black54,
                                offset: Offset(1.0, 1.0),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Mulai dari Rp. ${widget.lapang.price}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BannerModel {
  final String imageUrl;
  final String title;
  final String description;

  BannerModel({
    required this.imageUrl,
    required this.title,
    required this.description,
  });

  // Factory constructor untuk membuat instance dari Firestore document
  factory BannerModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return BannerModel(
      imageUrl: data['imageUrl'] ?? '',
      title: data['title'] ?? 'Judul Tidak Tersedia',
      description: data['description'] ?? 'Deskripsi tidak tersedia.',
    );
  }
}

// 2. Buat Widget yang dinamis
class DiscountBanner extends StatefulWidget {
  const DiscountBanner({super.key});

  @override
  State<DiscountBanner> createState() => _DiscountBannerState();
}

class _DiscountBannerState extends State<DiscountBanner> {
  // Fungsi untuk mengambil data dari koleksi 'banners' di Firestore
  Future<List<BannerModel>> _fetchBanners() async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('banners').get();

    // Filter dokumen yang aktif saja (opsional)
    // QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('banners').where('isActive', isEqualTo: true).get();

    return snapshot.docs.map((doc) => BannerModel.fromFirestore(doc)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BannerModel>>(
      future: _fetchBanners(),
      builder: (context, snapshot) {
        // Saat data sedang dimuat
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Jika terjadi error
        if (snapshot.hasError) {
          return const Center(child: Text("Gagal memuat banner promo."));
        }

        // Jika tidak ada data atau data kosong
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink(); // Tidak menampilkan apa-apa
        }

        // Jika data berhasil dimuat
        final banners = snapshot.data!;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          child: CarouselSlider.builder(
            itemCount: banners.length,
            options: CarouselOptions(
              height: 220, // Sesuaikan tinggi
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 5),
              enlargeCenterPage: true,
              viewportFraction: 0.9, // Menampilkan sedikit banner di samping
              aspectRatio: 16 / 9,
            ),
            itemBuilder: (context, index, realIndex) {
              final banner = banners[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 5.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Ganti Image.asset menjadi Image.network
                      Image.network(
                        banner.imageUrl,
                        fit: BoxFit.cover,
                        // Loading builder untuk menampilkan progress saat gambar di-load
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                              child: CircularProgressIndicator());
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.error, color: Colors.red);
                        },
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.center,
                            colors: [
                              Colors.black.withOpacity(0.8),
                              Colors.transparent
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 20.0,
                        left: 20.0,
                        right: 20.0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              banner.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                      blurRadius: 10.0, color: Colors.black54)
                                ],
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              banner.description,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
