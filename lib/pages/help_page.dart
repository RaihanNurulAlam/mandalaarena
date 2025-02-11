import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bantuan"),
        // centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // const Text(
            //   "Pusat Bantuan",
            //   style: TextStyle(
            //     fontSize: 24,
            //     fontWeight: FontWeight.bold,
            //   ),
            // ),
            // const SizedBox(height: 16),
            const Text(
              "Di bawah ini adalah beberapa topik yang mungkin membantu Anda:",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.account_circle),
              title: const Text("Masalah Login"),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Masalah Login"),
                    content: const Text(
                        "Jika Anda mengalami masalah saat login, pastikan email dan password Anda sudah benar. Jika lupa password, gunakan fitur 'Lupa Password'."),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("OK"),
                      ),
                    ],
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text("Cara Menggunakan Aplikasi"),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Cara Menggunakan Aplikasi"),
                    content: const Text(
                        "Untuk menggunakan aplikasi ini, Anda dapat login dengan akun yang sudah terdaftar atau membuat akun baru. Setelah login, Anda akan diarahkan ke halaman utama."),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("OK"),
                      ),
                    ],
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.contact_support),
              title: const Text("Hubungi Dukungan"),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Hubungi Dukungan"),
                    content: const Text(
                        "Anda dapat menghubungi tim dukungan kami melalui email di mandalaarena@gmail.com atau melalui telepon di +62 821-1755-6907."),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("OK"),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
