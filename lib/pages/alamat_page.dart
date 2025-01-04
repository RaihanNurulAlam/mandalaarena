// lib/pages/alamat_page.dart

// ignore_for_file: use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AlamatPage extends StatelessWidget {
  final String address = "Jl. Jendral Sudirman No. 30 Rt. 01 Rw. 22 Rt/Rw: 001/022, Kelurahan Sukamentri, Kabupaten Garut";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lokasi Lapang'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              address,
              style: TextStyle(fontSize: 16),
            ),
          ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(-7.198671794403463, 107.91344726596695), // Coordinates for the given address
                zoom: 15,
              ),
              markers: {
                Marker(
                  markerId: MarkerId('lapang'),
                  position: LatLng(-7.198671794403463, 107.91344726596695), // Coordinates for the given address
                  infoWindow: InfoWindow(
                    title: 'Lokasi Lapang',
                    snippet: address,
                  ),
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}