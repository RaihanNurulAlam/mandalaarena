// ignore_for_file: use_key_in_widget_constructors, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class AlamatPage extends StatefulWidget {
  @override
  _AlamatPageState createState() => _AlamatPageState();
}

class _AlamatPageState extends State<AlamatPage> {
  final String address =
      "RW28+W56, Sukamentri, Kec. Garut Kota, Kabupaten Garut, Jawa Barat 44116";
  final String virtualTourUrl =
      "https://webobook.com/public/66d6aaf1182f59592758ee22,en";

  static const LatLng destination =
      LatLng(-7.197780761030425, 107.9164070197299);
  Position? _currentPosition;

  // Method untuk membuka tautan Virtual Tour
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

  // Method untuk mendapatkan lokasi saat ini
  Future<void> _determinePosition(BuildContext context) async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap aktifkan layanan lokasi (GPS).')),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin lokasi ditolak.')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Izin lokasi ditolak secara permanen. Aktifkan di pengaturan.'),
        ),
      );
      return;
    }

    _currentPosition = await Geolocator.getCurrentPosition();
    setState(() {});
    _openGoogleMapsNavigation();
  }

  // Method untuk membuka Google Maps untuk navigasi
  Future<void> _openGoogleMapsNavigation() async {
    if (_currentPosition == null) return;

    final Uri googleMapsUrl = Uri.parse(
      "https://www.google.com/maps/dir/?api=1&origin=${_currentPosition!.latitude},${_currentPosition!.longitude}&destination=${destination.latitude},${destination.longitude}&travelmode=driving",
    );

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka Google Maps.')),
      );
    }
  }

  // Method untuk membuka navigasi melalui website
  Future<void> _openWebNavigation() async {
    final Uri webMapsUrl = Uri.parse(
      "https://www.google.com/maps/dir/?api=1&destination=${destination.latitude},${destination.longitude}&travelmode=driving",
    );

    if (await canLaunchUrl(webMapsUrl)) {
      await launchUrl(webMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka navigasi web.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lokasi Lapang'),
        actions: [
          IconButton(
            icon: const Icon(Icons.public, color: Colors.black),
            onPressed: () => _openVirtualTour(context),
            tooltip: 'Lihat Virtual Tour',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                address,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentPosition != null
                    ? LatLng(
                        _currentPosition!.latitude, _currentPosition!.longitude)
                    : destination,
                zoom: 15,
              ),
              markers: {
                if (_currentPosition != null)
                  Marker(
                    markerId: const MarkerId('current_location'),
                    position: LatLng(_currentPosition!.latitude,
                        _currentPosition!.longitude),
                    infoWindow: const InfoWindow(title: 'Lokasi Anda'),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueBlue),
                  ),
                Marker(
                  markerId: const MarkerId('lapang'),
                  position: destination,
                  infoWindow: InfoWindow(
                    title: 'Lokasi Lapang',
                    snippet: address,
                  ),
                ),
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors
                        .black, // Mengatur warna teks dan ikon menjadi putih
                  ),
                  onPressed: () => _determinePosition(context),
                  icon: const Icon(Icons.directions,
                      color: Colors.black), // Ikon putih
                  label: const Text('Navigasi ke Lokasi (Aplikasi)',
                      style: TextStyle(color: Colors.black)), // Teks putih
                ),
                SizedBox(height: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black),
                  onPressed: _openWebNavigation,
                  icon: const Icon(Icons.open_in_browser, color: Colors.black),
                  label: const Text('Navigasi ke Lokasi (Web)',
                      style: TextStyle(color: Colors.black)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
