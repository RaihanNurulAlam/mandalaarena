// ignore_for_file: use_key_in_widget_constructors, deprecated_member_use, prefer_typing_uninitialized_variables, unreachable_switch_case, avoid_print, prefer_interpolation_to_compose_strings, use_build_context_synchronously, use_super_parameters, unused_local_variable, sized_box_for_whitespace, sort_child_properties_last

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
import 'package:mandalaarenaapp/pages/about_page.dart';
import 'package:mandalaarenaapp/pages/alamat_page.dart';
import 'package:mandalaarenaapp/pages/booking_summary_page.dart';
import 'package:mandalaarenaapp/pages/detailpage.dart';
import 'package:mandalaarenaapp/pages/edit_profile_page.dart';
import 'package:mandalaarenaapp/pages/galery_page.dart';
import 'package:mandalaarenaapp/pages/information_page.dart';
import 'package:mandalaarenaapp/pages/manage_booking_page.dart';
import 'package:mandalaarenaapp/pages/membership_page.dart';
import 'package:mandalaarenaapp/pages/models/lapang.dart';
import 'package:mandalaarenaapp/pages/points_page.dart';
import 'package:mandalaarenaapp/pages/sparring_team_page.dart';
import 'package:mandalaarenaapp/pages/welcome_page.dart';
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

  String? videoUrl;
  String? videoTitle;
  String? thumbnailUrl;

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

    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive padding and max content width
        const double mobileBreakpoint = 600;
        const double desktopMaxWidth = 1200;
        final bool isMobile = constraints.maxWidth < mobileBreakpoint;
        final double horizontalPadding = isMobile
            ? 20.0
            : ((constraints.maxWidth - desktopMaxWidth) / 2)
                .clamp(20.0, double.infinity);

        return BlocProvider(
          create: (context) => NavigationCubit(),
          child: Builder(builder: (BuildContext newContext) {
            return Scaffold(
              endDrawer: const ProfileSlider(),
              appBar: AppBar(
                toolbarHeight: 80,
                title: Padding(
                  padding: EdgeInsets.only(left: horizontalPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Mandala Arena',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.map_pin,
                            size: 12,
                            color: Colors.grey,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Garut, Indonesia',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  if (user != null)
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const PointsPage()),
                        );
                      },
                      icon: const Icon(Icons.star,
                          color: Colors.orange, size: 17),
                      label: Text(
                        userProvider.points.toString(),
                        style: const TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(30, 30),
                      ),
                    ),
                  if (user != null) const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => AlamatPage()));
                    },
                    icon: const Icon(Icons.location_on, size: 25),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  Consumer<Cart>(
                    builder: (context, value, child) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            IconButton(
                              onPressed: goToCart,
                              icon: const Icon(CupertinoIcons.bag, size: 25),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            if (value.cart.isNotEmpty)
                              Positioned(
                                top: 2,
                                right: -2,
                                child: CircleAvatar(
                                  radius: 7,
                                  backgroundColor: Colors.yellow,
                                  child: Center(
                                    child: Text(
                                      value.cart.length.toString(),
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
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
                  const SizedBox(width: 8),
                  Padding(
                    padding: EdgeInsets.only(right: horizontalPadding),
                    child: user == null
                        ? ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const LoginScreen()),
                              );
                            },
                            child: const Text("Login",
                                style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 12),
                            ),
                          )
                        : Builder(
                            builder: (newContext) => GestureDetector(
                              onTap: () {
                                Scaffold.of(newContext).openEndDrawer();
                              },
                              child: CircleAvatar(
                                radius: 15,
                                backgroundImage: NetworkImage(
                                  userProvider.profileImageUrl.isNotEmpty
                                      ? userProvider.profileImageUrl
                                      : "https://via.placeholder.com/150",
                                ),
                              ),
                            ),
                          ),
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
                          return _buildHomeContent(context, horizontalPadding);
                      }
                    },
                  ),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (isExpanded) ...[
                          _buildSocialButton(
                            "whatsapp",
                            Colors.green,
                            "https://img.icons8.com/?size=100&id=16733&format=png&color=FFFFFF",
                            'https://wa.me/6281111122525',
                          ),
                          const SizedBox(height: 8),
                          _buildSocialButton(
                            "facebook",
                            Colors.blue,
                            Icons.facebook,
                            'https://www.facebook.com/mandala.arena',
                            isIcon: true,
                          ),
                          const SizedBox(height: 8),
                          _buildSocialButton(
                            "instagram",
                            Colors.purple,
                            "https://img.icons8.com/?size=100&id=59813&format=png&color=FFFFFF",
                            'https://www.instagram.com/mandalaarena',
                          ),
                          const SizedBox(height: 8),
                          _buildSocialButton(
                            "email",
                            Colors.red,
                            "https://img.icons8.com/?size=100&id=ptAjLogGbrSi&format=png&color=FFFFFF",
                            'mailto:mandalaarena@gmail.com',
                          ),
                          const SizedBox(height: 8),
                        ],
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
              bottomNavigationBar:
                  BlocBuilder<NavigationCubit, NavigationState>(
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
            );
          }),
        );
      },
    );
  }

  Widget _buildSocialButton(
      String heroTag, Color color, dynamic iconData, String url,
      {bool isIcon = false}) {
    return FloatingActionButton(
      heroTag: heroTag,
      onPressed: () => _launchURL(url),
      backgroundColor: color,
      child: isIcon
          ? Icon(iconData, color: Colors.white)
          : Image.network(
              iconData,
              width: 25,
              height: 25,
            ),
    );
  }

  Widget _buildGalleryPreview(BuildContext context, double horizontalPadding) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Galeri',
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
                height: 220,
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
                height: 220,
                autoPlay: galleryDocs.length > 1,
                autoPlayInterval: const Duration(seconds: 5),
                enlargeCenterPage: false, // Diubah ke false agar lebih pas
                viewportFraction: 1.0, // ### DIUBAH DI SINI ###
                aspectRatio: 16 / 9,
              ),
              itemBuilder: (context, index, realIndex) {
                final doc = galleryDocs[index];
                final imageUrl = doc['imageUrl'];

                // Gunakan padding di dalam item builder untuk memberi jarak
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
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
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(
                              child: Icon(Icons.error, color: Colors.red)),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildHomeContent(BuildContext context, double horizontalPadding) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = FirebaseAuth.instance.currentUser;
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user != null)
              if (userProvider.isMembershipActive)
                _buildMemberStatusCard(context, userProvider, horizontalPadding)
              else
                _buildMembershipBanner(context, horizontalPadding),
            _buildDiscountBanner(context, horizontalPadding),
            _buildGalleryPreview(context, horizontalPadding),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  horizontalPadding, 20, horizontalPadding, 16),
              child: const Text(
                'Pilih Lapang',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildGridLapangs(context, horizontalPadding),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscountBanner(BuildContext context, double horizontalPadding) {
    return StreamBuilder<QuerySnapshot>(
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
            enlargeCenterPage: false, // Diubah ke false agar lebih pas
            viewportFraction: 1.0, // ### DIUBAH DI SINI ###
            aspectRatio: 16 / 9,
          ),
          itemBuilder: (context, index, realIndex) {
            final banner = banners[index];
            // Gunakan padding di dalam item builder untuk memberi jarak
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Card(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
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
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMembershipBanner(
      BuildContext context, double horizontalPadding) {
    return Padding(
      padding:
          EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 10),
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

  Widget _buildMemberStatusCard(
      BuildContext context, UserProvider provider, double horizontalPadding) {
    final expiryDate = provider.memberUntil != null
        ? DateFormat('dd MMMM yyyy').format(provider.memberUntil!)
        : 'Tidak diketahui';

    String getFriendlyMembershipName(String typeId) {
      switch (typeId) {
        case 'minisoccer':
          return 'Member Mini Soccer';
        case 'basket_vinyl':
          return 'Member Basket A';
        case 'basket_karet':
          return 'Member Basket B';
        default:
          return 'Member';
      }
    }

    final membershipName = getFriendlyMembershipName(provider.membershipType);

    return Padding(
      padding:
          EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
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
                    Text(
                      membershipName,
                      style: const TextStyle(
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

  Widget _buildGridLapangs(BuildContext context, double horizontalPadding) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
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
      ),
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
      if (mounted) {
        _syncUserData(context);
      }
    });
  }

  Future<void> _syncUserData(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final userData = userDoc.data();
        if (userData != null && mounted) {
          Provider.of<UserProvider>(context, listen: false).setUserData(
            userId: user.uid,
            userName: userData['name'] ?? '',
            userEmail: user.email ?? '',
            profileImageUrl: userData['profileImageUrl'] ?? '',
            userPhone: userData['phone'] ?? '',
            isMember: userData['isMember'] ?? false,
            points: userData['points'] ?? 0,
            memberUntil: (userData['memberUntil'] as Timestamp?)?.toDate(),
            membershipType: userData['membershipType'] ?? '',
          );
        }
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
              final result = await Navigator.push(
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

              if (result == true && mounted) {
                await _syncUserData(context);
              }
              if (mounted) {
                Navigator.pop(context);
              }
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
              final cartProvider = Provider.of<Cart>(context, listen: false);
              final confirmLogout = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                  title: const Text('Konfirmasi Keluar'),
                  content: const Text('Apakah Anda yakin ingin keluar?'),
                  actions: <Widget>[
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Keluar'),
                    ),
                  ],
                ),
              );

              if (confirmLogout == true) {
                await FirebaseAuth.instance.signOut();
                userProvider.clearUserData();
                cartProvider.clearCart();
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
            snapshot.hasData) {
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
