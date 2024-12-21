// lib/pages/alamat_page.dart

// ignore_for_file: use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AlamatPage extends StatelessWidget {
  final String address = "Jl. Jendral Sudirman No. 30 Rt. 01 Rw. 22 Rt/Rw: 001/022, Kelurahan Sukamentri";

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
              style: TextStyle(fontSize: 18),
            ),
          ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(-7.3431, 108.2234), // Replace with actual latitude and longitude of the location
                zoom: 15,
              ),
              markers: {
                Marker(
                  markerId: MarkerId('lapang-location'),
                  position: LatLng(-7.3431, 108.2234), // Replace with actual coordinates
                  infoWindow: InfoWindow(title: 'Lapang'),
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}
