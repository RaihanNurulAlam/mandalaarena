// ignore_for_file: use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandalaarenaapp/pages/about_page.dart';
import 'package:mandalaarenaapp/pages/booking_page.dart';
import 'package:mandalaarenaapp/pages/checkout_page.dart';
import 'package:mandalaarenaapp/pages/galery_page.dart';
import 'package:mandalaarenaapp/pages/home_page.dart';
import 'package:mandalaarenaapp/pages/information_page.dart';

enum NavigationEvent {
  home,
  booking,
  gallery,
  information,
  about,
  checkout,
}

class NavigationBloc extends Bloc<NavigationEvent, Widget> {
  NavigationBloc() : super(HomePage()) {
    on<NavigationEvent>((event, emit) {
      switch (event) {
        case NavigationEvent.home:
          emit(HomePage());
          break;
        case NavigationEvent.booking:
          emit(BookingPage());
          break;
        case NavigationEvent.gallery:
          emit(GalleryPage());
          break;
        case NavigationEvent.information:
          emit(InformationPage());
          break;
        case NavigationEvent.about:
          emit(AboutPage());
          break;
        case NavigationEvent.checkout:
          emit(CheckoutPage());
          break;
      }
    });
  }
}
