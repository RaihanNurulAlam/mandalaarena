// lib/cubit/navigation_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';

/// Enum untuk menentukan halaman navigasi
enum NavigationState { home, gallery, information, about, checkout }

/// Cubit untuk mengelola state navigasi
class NavigationCubit extends Cubit<NavigationState> {
  NavigationCubit() : super(NavigationState.home);

  /// Fungsi untuk mengganti state navigasi
  void navigateTo(NavigationState state) => emit(state);
}
