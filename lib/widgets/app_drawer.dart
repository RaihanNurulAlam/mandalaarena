// ignore_for_file: use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandalaarenaapp/blocs/navigation_bloc.dart';

class AppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text('Mandala Arena App',
                style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Home'),
            onTap: () {
              BlocProvider.of<NavigationBloc>(context)
                  .add(NavigationEvent.home);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.calendar_today),
            title: Text('Jadwal Booking'),
            onTap: () {
              BlocProvider.of<NavigationBloc>(context)
                  .add(NavigationEvent.booking);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.photo_library),
            title: Text('Galeri Aktivitas'),
            onTap: () {
              BlocProvider.of<NavigationBloc>(context)
                  .add(NavigationEvent.gallery);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.article),
            title: Text('Informasi Terkini'),
            onTap: () {
              BlocProvider.of<NavigationBloc>(context)
                  .add(NavigationEvent.information);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.info),
            title: Text('Tentang Aplikasi'),
            onTap: () {
              BlocProvider.of<NavigationBloc>(context)
                  .add(NavigationEvent.about);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.payment),
            title: Text('Checkout'),
            onTap: () {
              BlocProvider.of<NavigationBloc>(context)
                  .add(NavigationEvent.checkout);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
