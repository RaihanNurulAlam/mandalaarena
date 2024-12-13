// ignore_for_file: use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandalaarenaapp/pages/about_page.dart';
import 'package:mandalaarenaapp/pages/booking_page.dart';
import 'package:mandalaarenaapp/pages/checkout_page.dart';
import 'package:mandalaarenaapp/pages/galery_page.dart';
import 'package:mandalaarenaapp/pages/information_page.dart';

// BLoC State
enum NavigationState { home, booking, gallery, information, about, checkout }

// BLoC Implementation
class NavigationCubit extends Cubit<NavigationState> {
  NavigationCubit() : super(NavigationState.home);

  void navigateTo(NavigationState state) => emit(state);
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NavigationCubit(),
      child: BlocBuilder<NavigationCubit, NavigationState>(
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
              currentPage = Center(child: Text('Welcome to Mandala Arena'));
          }

          return Scaffold(
            appBar: AppBar(title: Text('Mandala Arena')),
            drawer: _buildDrawer(context),
            body: currentPage,
          );
        },
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text('Navigation',
                style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Home'),
            onTap: () {
              Navigator.pop(context);
              context.read<NavigationCubit>().navigateTo(NavigationState.home);
            },
          ),
          ListTile(
            leading: Icon(Icons.calendar_today),
            title: Text('Jadwal Booking'),
            onTap: () {
              Navigator.pop(context);
              context
                  .read<NavigationCubit>()
                  .navigateTo(NavigationState.booking);
            },
          ),
          ListTile(
            leading: Icon(Icons.photo_library),
            title: Text('Galeri Aktivitas'),
            onTap: () {
              Navigator.pop(context);
              context
                  .read<NavigationCubit>()
                  .navigateTo(NavigationState.gallery);
            },
          ),
          ListTile(
            leading: Icon(Icons.article),
            title: Text('Informasi Terkini'),
            onTap: () {
              Navigator.pop(context);
              context
                  .read<NavigationCubit>()
                  .navigateTo(NavigationState.information);
            },
          ),
          ListTile(
            leading: Icon(Icons.info),
            title: Text('Tentang Aplikasi'),
            onTap: () {
              Navigator.pop(context);
              context.read<NavigationCubit>().navigateTo(NavigationState.about);
            },
          ),
          ListTile(
            leading: Icon(Icons.payment),
            title: Text('Checkout'),
            onTap: () {
              Navigator.pop(context);
              context
                  .read<NavigationCubit>()
                  .navigateTo(NavigationState.checkout);
            },
          ),
        ],
      ),
    );
  }
}
