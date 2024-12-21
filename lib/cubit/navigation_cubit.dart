// lib/cubit/navigation_cubit.dart

// ignore_for_file: constant_identifier_names

import 'package:flutter_bloc/flutter_bloc.dart';

/// Enum untuk menentukan halaman navigasi
enum NavigationState { home, gallery, information, about, payment, AlamatPage }

/// Cubit untuk mengelola state navigasi
class NavigationCubit extends Cubit<NavigationState> {
  NavigationCubit() : super(NavigationState.home);

  /// Fungsi untuk mengganti state navigasi
  void navigateTo(NavigationState state) => emit(state);
}
