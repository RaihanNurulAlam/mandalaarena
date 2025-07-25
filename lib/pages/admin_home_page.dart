// ignore_for_file: use_build_context_synchronously, unused_element, deprecated_member_use, use_super_parameters, unused_field, use_key_in_widget_constructors, prefer_const_constructors, avoid_print, prefer_interpolation_to_compose_strings, sized_box_for_whitespace

import 'dart:convert';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mandalaarenaapp/Login%20Signup/Screen/login.dart';
import 'package:mandalaarenaapp/cubit/navigation_cubit.dart';
import 'package:mandalaarenaapp/pages/about_page.dart';
import 'package:mandalaarenaapp/pages/alamat_page.dart';
import 'package:mandalaarenaapp/pages/banner_form_page.dart';
import 'package:mandalaarenaapp/pages/booking_summary_page.dart';
import 'package:mandalaarenaapp/pages/detailpage.dart';
import 'package:mandalaarenaapp/pages/edit_profile_page.dart';
import 'package:mandalaarenaapp/pages/galery_page.dart';
import 'package:mandalaarenaapp/pages/information_page.dart';
import 'package:mandalaarenaapp/pages/manage_booking_page.dart';
import 'package:mandalaarenaapp/pages/membership_page.dart';
import 'package:mandalaarenaapp/pages/models/lapang.dart';
import 'package:mandalaarenaapp/pages/points_page.dart';
import 'package:mandalaarenaapp/pages/welcome_page.dart';
import 'package:mandalaarenaapp/provider/cart.dart';
import 'package:mandalaarenaapp/provider/user_provider.dart';
import 'package:mandalaarenaapp/pages/sparring_team_page.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import 'models/banner_model.dart';

class AdminHomePage extends StatefulWidget {
  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>(); // 1. Deklarasikan GlobalKey
  List<Lapang> lapangs = [];
  bool isExpanded = false;
  bool isHoveredToggle = false;
  YoutubePlayerController? _controller;

  @override
  void initState() {
    super.initState();
    getLapangs();
    Intl.defaultLocale = 'id_ID';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      const videoUrl = 'https://www.youtube.com/watch?v=Ke-n-g-3P2U';
      final videoId = YoutubePlayer.convertUrlToId(videoUrl);

      if (mounted) {
        setState(() {
          _controller = YoutubePlayerController(
            initialVideoId: videoId ?? '',
            flags: const YoutubePlayerFlags(
              autoPlay: false,
              mute: false,
            ),
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> getLapangs() async {
    String dataLapangJson =
        await rootBundle.loadString('assets/json/lapang.json');
    List<dynamic> jsonMap = json.decode(dataLapangJson);

    setState(() {
      lapangs = jsonMap.map((e) => Lapang.fromJson(e)).toList();
    });
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

  void _navigateToBannerForm({BannerModel? banner}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BannerFormPage(banner: banner),
      ),
    );
  }

  void _deleteBanner(
      BuildContext context, String bannerId, String imageUrl) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: const Text('Apakah Anda yakin ingin menghapus banner ini?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('banners')
            .doc(bannerId)
            .delete();

        if (imageUrl.isNotEmpty) {
          await FirebaseStorage.instance.refFromURL(imageUrl).delete();
        }

        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Banner berhasil dihapus!')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus banner: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userProvider = Provider.of<UserProvider>(context);
    return BlocProvider(
      create: (context) => NavigationCubit(),
      child: Scaffold(
        // 4. Hapus Builder yang membungkus Scaffold
        key: _scaffoldKey, // 2. Gunakan GlobalKey pada Scaffold
        endDrawer: const ProfileSlider(),
        appBar: AppBar(
          toolbarHeight: 80,
          title: Padding(
            padding: const EdgeInsets.only(left: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Mandala Arena (Admin)',
                  style: TextStyle(color: Colors.black, fontSize: 16),
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
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => PointsPage()));
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
            Consumer<Cart>(
              builder: (context, value, child) {
                return Padding(
                  padding: const EdgeInsets.only(right: 14, left: 5),
                  child: Stack(
                    children: [
                      IconButton(
                        onPressed: goToCart,
                        icon: const Icon(
                          CupertinoIcons.bag,
                          size: 30,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Visibility(
                          visible: value.cart.isNotEmpty,
                          child: CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.yellow,
                            child: Center(
                              child: Text(
                                value.cart.length.toString(),
                                style: const TextStyle(
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
            if (user == null)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 18, 16, 18),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()),
                    );
                  },
                  icon: const Icon(Icons.login, size: 18),
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
            else
              Consumer<UserProvider>(
                builder: (context, provider, child) {
                  return GestureDetector(
                    onTap: () {
                      _scaffoldKey.currentState
                          ?.openEndDrawer(); // 3. Panggil openEndDrawer melalui key
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16.0, left: 4.0),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundImage: NetworkImage(
                          provider.profileImageUrl.isNotEmpty
                              ? provider.profileImageUrl
                              : "https://via.placeholder.com/150",
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
        body: Stack(
          children: [
            BlocBuilder<NavigationCubit, NavigationState>(
              builder: (context, state) {
                switch (state) {
                  case NavigationState.sparring:
                    return SparringTeamPage();
                  case NavigationState.information:
                    return InformationPage();
                  case NavigationState.about:
                    return AboutPage();
                  default:
                    return _buildHomeContent(context);
                }
              },
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
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
                          width: 25,
                          height: 25,
                        ),
                      ),
                    ),
                  ),
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
                            width: 25,
                            height: 25,
                          )),
                    ),
                  ),
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
                          width: 25,
                          height: 25,
                        ),
                      ),
                    ),
                  ),
                  MouseRegion(
                    onEnter: (_) => setState(() => isHoveredToggle = true),
                    onExit: (_) => setState(() => isHoveredToggle = false),
                    child: FloatingActionButton(
                      heroTag: "toggle",
                      onPressed: _toggleMenu,
                      backgroundColor:
                          Colors.black.withOpacity(isHoveredToggle ? 1.0 : 0.5),
                      child: Icon(
                        isExpanded ? Icons.close : Icons.add_comment,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
                  icon: Icon(Icons.group),
                  label: 'Sparring',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.article_rounded),
                  label: 'Artikel',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.question_answer_rounded),
                  label: 'Ulasan',
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = FirebaseAuth.instance.currentUser;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- BLOK MEMBER DIPINDAHKAN KE ATAS ---
          if (user != null)
            if (userProvider.isMembershipActive)
              _buildMemberStatusCard(context, userProvider)
            else
              _buildMembershipBanner(context),

          _buildDiscountBanner(context),
          // _buildYoutubePlayer(),
          _buildGalleryPreview(context),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Text(
              'Pilih Lapang',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildGridLapangs(context),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Widget _buildYoutubePlayer() {
  //   if (_controller == null) {
  //     return const SizedBox(
  //       height: 200,
  //       child: Center(
  //         child: CircularProgressIndicator(),
  //       ),
  //     );
  //   }
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
  //     child: Card(
  //       elevation: 4,
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
  //       clipBehavior: Clip.antiAlias,
  //       child: YoutubePlayer(
  //         controller: _controller!,
  //         showVideoProgressIndicator: true,
  //         progressIndicatorColor: Colors.amber,
  //         progressColors: const ProgressBarColors(
  //           playedColor: Colors.amber,
  //           handleColor: Colors.amberAccent,
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildGalleryPreview(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Galeri Aktivitas',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => GalleryPage()),
                  );
                },
                child: const Text(
                  'Lihat Lainnya >',
                  style: TextStyle(
                      color: Colors.black54, fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('gallery')
              .orderBy('timestamp', descending: true)
              .limit(3)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 220, // Disesuaikan dari 200 menjadi 220
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const SizedBox.shrink();
            }

            final galleryDocs = snapshot.data!.docs;

            return CarouselSlider.builder(
              itemCount: galleryDocs.length,
              options: CarouselOptions(
                height: 220, // Disesuaikan dari 200 menjadi 220
                autoPlay: galleryDocs.length > 1,
                autoPlayInterval: const Duration(seconds: 5),
                enlargeCenterPage: true,
                viewportFraction: 0.9, // Disesuaikan dari 0.85 menjadi 0.9
                aspectRatio: 16 / 9, // Ditambahkan agar sesuai
              ),
              itemBuilder: (context, index, realIndex) {
                final doc = galleryDocs[index];
                final imageUrl = doc['imageUrl'];

                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 5.0, vertical: 4.0),
                  elevation: 4,
                  shadowColor: Colors.black.withOpacity(0.2),
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(Icons.error, color: Colors.red)),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildDiscountBanner(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('banners')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              height: 220,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError) {
            return const SizedBox.shrink();
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            if (userProvider.isAdmin) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.image_not_supported_outlined,
                          size: 40, color: Colors.grey),
                      const SizedBox(height: 8),
                      const Text("Belum ada banner promo.",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text("Ketuk untuk menambah banner baru.",
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => _navigateToBannerForm(),
                        child: const Text("Tambah Banner"),
                      )
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }

          final banners = snapshot.data!.docs
              .map((doc) => BannerModel.fromFirestore(doc))
              .toList();

          return Stack(
            alignment: Alignment.bottomCenter,
            children: [
              CarouselSlider.builder(
                itemCount: banners.length,
                options: CarouselOptions(
                  height: 220,
                  autoPlay: banners.length > 1,
                  autoPlayInterval: const Duration(seconds: 4),
                  enlargeCenterPage: true,
                  viewportFraction: 0.9,
                  aspectRatio: 16 / 9,
                ),
                itemBuilder: (context, index, realIndex) {
                  final banner = banners[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 5.0, vertical: 4.0),
                    elevation: 4,
                    shadowColor: Colors.black.withOpacity(0.2),
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          banner.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                                  child: Icon(Icons.error, color: Colors.red)),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.center,
                              colors: [
                                Colors.black.withOpacity(0.7),
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
                              Text(banner.title,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8.0),
                              Text(banner.description,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 14)),
                            ],
                          ),
                        ),
                        if (userProvider.isAdmin)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(20)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.white, size: 20),
                                      onPressed: () => _navigateToBannerForm(
                                          banner: banner)),
                                  IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red, size: 20),
                                      onPressed: () => _deleteBanner(
                                          context, banner.id, banner.imageUrl)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              if (userProvider.isAdmin)
                Positioned(
                  bottom: 12,
                  right: 24,
                  child: FloatingActionButton(
                    mini: true,
                    heroTag: 'add_banner',
                    onPressed: _navigateToBannerForm,
                    tooltip: 'Tambah Banner Baru',
                    child: const Icon(Icons.add),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMembershipBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Card(
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MembershipPage()),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black87, Colors.black],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: const [
                Icon(Icons.star, color: Colors.amber, size: 40),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Upgrade Jadi Member!',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      SizedBox(height: 4),
                      Text('Nikmati diskon dan keuntungan eksklusif.',
                          style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMemberStatusCard(BuildContext context, UserProvider provider) {
    final expiryDate = provider.memberUntil != null
        ? DateFormat('dd MMMM yyyy').format(provider.memberUntil!)
        : 'Tidak diketahui';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Card(
        color: Colors.green[50],
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Anda Adalah Member',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green),
                    ),
                    const SizedBox(height: 4),
                    Text('Aktif sampai: $expiryDate'),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridLapangs(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 1650
            ? 5
            : MediaQuery.of(context).size.width > 1200
                ? 4
                : MediaQuery.of(context).size.width > 750
                    ? 3
                    : 2,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 4 / 5,
      ),
      itemCount: lapangs.length,
      itemBuilder: (context, index) {
        return LapangGridItem(
          lapang: lapangs[index],
          onTap: () => goToDetailLapang(index),
        );
      },
    );
  }
}

class ProfileSlider extends StatefulWidget {
  const ProfileSlider({Key? key}) : super(key: key);

  @override
  State<ProfileSlider> createState() => _ProfileSliderState();
}

class _ProfileSliderState extends State<ProfileSlider> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncUserData(context);
    });
  }

  Future<void> _syncUserData(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && mounted) {
        await Provider.of<UserProvider>(context, listen: false)
            .fetchUserData(user.uid);
      }
    } catch (e) {
      debugPrint('Kesalahan sinkronisasi data pengguna: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Drawer(
          child: Center(child: Text("Pengguna tidak ditemukan.")));
    }

    final userProvider = Provider.of<UserProvider>(context);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildProfileHeader(userProvider),
          const SizedBox(height: 10),
          _buildListTile(
            context,
            'Ubah Profil',
            Icons.edit,
            () async {
              Navigator.pop(context);
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfilePage(
                    userName: userProvider.userName,
                    userEmail: userProvider.userEmail,
                    profileImageUrl: userProvider.profileImageUrl,
                    phoneNumber: userProvider.userPhone,
                  ),
                ),
              );
            },
          ),
          _buildAdminButton(context, user.uid),
          const Divider(indent: 16, endIndent: 16),
          _buildListTile(
            context,
            'Keluar',
            Icons.logout,
            () async {
              final navigator = Navigator.of(context);
              final userProvider =
                  Provider.of<UserProvider>(context, listen: false);

              final confirmLogout = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                  title: const Text('Konfirmasi Keluar'),
                  content: const Text('Apakah Anda yakin ingin keluar?'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Batal'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Keluar'),
                    ),
                  ],
                ),
              );

              if (confirmLogout == true) {
                await FirebaseAuth.instance.signOut();
                userProvider.clearUserData();
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const WelcomePage()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(UserProvider userProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 20),
      color: Colors.black,
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 45,
              backgroundImage: NetworkImage(
                userProvider.profileImageUrl.isNotEmpty
                    ? userProvider.profileImageUrl
                    : "https://via.placeholder.com/150",
              ),
            ),
            const SizedBox(height: 12),
            Text(
              userProvider.userName.isNotEmpty
                  ? userProvider.userName
                  : "Pengguna",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              userProvider.userEmail.isNotEmpty
                  ? userProvider.userEmail
                  : "Email tidak ditemukan",
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              userProvider.userPhone.isNotEmpty
                  ? userProvider.userPhone
                  : "No. telepon belum ditambahkan",
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminButton(BuildContext context, String uid) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData &&
            snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final isAdmin = userData['isAdmin'] ?? false;
          if (isAdmin) {
            return _buildListTile(
              context,
              'Kelola Booking',
              Icons.book_online,
              () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ManageBookingsPage()));
              },
            );
          }
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildListTile(
      BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(title),
      onTap: onTap,
    );
  }
}

class LapangGridItem extends StatefulWidget {
  final Lapang lapang;
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
          transform: _isHovered
              ? (Matrix4.identity()..scale(1.05))
              : Matrix4.identity(),
          transformAlignment: FractionalOffset.center,
          child: Card(
            elevation: _isHovered ? 10 : 5,
            shadowColor: Colors.black.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  widget.lapang.imagePath ?? 'assets/default_image.jpg',
                  fit: BoxFit.cover,
                ),
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
                            fontSize: 14,
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
                            fontSize: 10,
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
