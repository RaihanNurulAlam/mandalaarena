// ignore_for_file: use_key_in_widget_constructors, deprecated_member_use, prefer_typing_uninitialized_variables, unreachable_switch_case, avoid_print, prefer_interpolation_to_compose_strings, use_build_context_synchronously, use_super_parameters, unused_local_variable

import 'dart:convert';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mandalaarenaapp/Login%20Signup/Screen/login.dart';
import 'package:mandalaarenaapp/pages/alamat_page.dart';
import 'package:mandalaarenaapp/pages/booking_summary_page.dart';
import 'package:mandalaarenaapp/pages/detailpage.dart';
import 'package:mandalaarenaapp/pages/membership_page.dart';
import 'package:mandalaarenaapp/pages/models/lapang.dart';
import 'package:mandalaarenaapp/pages/points_page.dart';
import 'package:mandalaarenaapp/pages/profile_navigation.dart';
import 'package:mandalaarenaapp/pages/sparring_team_page.dart';
import 'package:mandalaarenaapp/provider/cart.dart';
import 'package:mandalaarenaapp/provider/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../cubit/navigation_cubit.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Lapang> lapangs = [];
  bool isExpanded = false;
  bool isHoveredToggle = false;

  @override
  void initState() {
    super.initState();
    getLapangs();
    Intl.defaultLocale = 'id_ID';
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
              else
                Consumer<UserProvider>(
                  builder: (context, provider, child) {
                    return GestureDetector(
                      onTap: () {
                        newContext.read<NavigationCubit>().navigateToIndex(2);
                      },
                      child: Padding(
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
          body: Stack(
            children: [
              BlocBuilder<NavigationCubit, NavigationState>(
                builder: (context, state) {
                  switch (state) {
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
                          child:
                              const Icon(Icons.facebook, color: Colors.white),
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
                      onEnter: (_) => setState(() {
                        isHoveredToggle = true;
                      }),
                      onExit: (_) => setState(() {
                        isHoveredToggle = false;
                      }),
                      child: FloatingActionButton(
                        heroTag: "toggle",
                        onPressed: _toggleMenu,
                        backgroundColor: Colors.black
                            .withOpacity(isHoveredToggle ? 1.0 : 0.5),
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
    final userProvider = Provider.of<UserProvider>(context);
    final user = FirebaseAuth.instance.currentUser;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDiscountBanner(context),
          if (user != null)
            if (userProvider.isMembershipActive)
              _buildMemberStatusCard(context, userProvider)
            else
              _buildMembershipBanner(context),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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

  Widget _buildDiscountBanner(BuildContext context) {
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
            return const SizedBox.shrink();
          }

          final banners = snapshot.data!.docs
              .map((doc) => BannerModel.fromFirestore(doc))
              .toList();

          return CarouselSlider.builder(
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
                margin:
                    const EdgeInsets.symmetric(horizontal: 5.0, vertical: 4.0),
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
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
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
                  ],
                ),
              );
            },
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
      physics: NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
  final String id;
  final String imageUrl;
  final String title;
  final String description;

  BannerModel({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.description,
  });

  factory BannerModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return BannerModel(
      id: doc.id,
      imageUrl: data['imageUrl'] ?? '',
      title: data['title'] ?? 'Judul Tidak Tersedia',
      description: data['description'] ?? 'Deskripsi tidak tersedia.',
    );
  }
}
