// lib/cubit/navigation_cubit.dart

// ignore_for_file: constant_identifier_names

import 'package:flutter_bloc/flutter_bloc.dart';

/// Enum untuk menentukan halaman navigasi
enum NavigationState { home, gallery, information, about, payment, sparring }

/// Cubit untuk mengelola state navigasi
class NavigationCubit extends Cubit<NavigationState> {
  NavigationCubit() : super(NavigationState.home);

  /// Fungsi untuk mengganti state navigasi
  void navigateTo(NavigationState state) => emit(state);

  /// Fungsi untuk mengganti state navigasi berdasarkan index
  void navigateToIndex(int index) {
    switch (index) {
      case 0:
        emit(NavigationState.home);
        break;
      case 1:
        emit(NavigationState.gallery);
        break;
      case 2:
        emit(NavigationState.information);
        break;
      case 3:
        emit(NavigationState.about);
        break;
      case 4:
        emit(NavigationState.payment);
        break;
      case 5:
        emit(NavigationState.sparring);
        break;
      default:
        emit(NavigationState.home);
        break;
    }
  }
}
