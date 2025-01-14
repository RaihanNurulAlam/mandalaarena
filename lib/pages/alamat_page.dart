// ignore_for_file: use_key_in_widget_constructors, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class AlamatPage extends StatelessWidget {
  final String address =
      "Jl. Jendral Sudirman No. 30 Rt. 01 Rw. 22 Rt/Rw: 001/022, Kelurahan Sukamentri, Kabupaten Garut";
  final String virtualTourUrl =
      "https://webobook.com/public/66d6aaf1182f59592758ee22,en";

  // Method untuk membuka tautan
  Future<void> _openVirtualTour(BuildContext context) async {
    final Uri url = Uri.parse(virtualTourUrl);

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka tautan.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lokasi Lapang'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0), // Padding tambahan untuk ikon globe
            child: IconButton(
              icon: const Icon(Icons.public, color: Colors.black),
              onPressed: () => _openVirtualTour(context),
              tooltip: 'Lihat Virtual Tour',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0), // Padding untuk alamat
            child: Align(
              alignment: Alignment.centerLeft, // Alamat di pinggir kiri
              child: Text(
                address,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(-7.198671794403463, 107.91344726596695),
                zoom: 15,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('lapang'),
                  position: const LatLng(-7.198671794403463, 107.91344726596695),
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
