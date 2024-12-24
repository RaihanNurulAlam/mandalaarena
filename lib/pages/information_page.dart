// ignore_for_file: use_key_in_widget_constructors, prefer_const_constructors_in_immutables

import 'package:flutter/material.dart';
import 'package:mandalaarenaapp/pages/models/articlecard.dart';
import 'package:mandalaarenaapp/pages/models/articlecard_page.dart';

class InformationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Informasi Terkini'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ArticleCard(
            title: 'Mau Tau? Sejarah Masuknya Mini Soccer ke Indonesia',
            imagePath: 'assets/lapangan_a.jpg',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ArticleDetailPage(
                    title: 'Mau Tau? Sejarah Masuknya Mini Soccer ke Indonesia',
                    imagePath: 'assets/lapangan_a.jpg',
                    content: [
                      const Text(
                        'Mini soccer, atau yang lebih dikenal dengan istilah "sepak bola mini," adalah varian olahraga sepak bola yang dimainkan di lapangan lebih kecil dengan jumlah pemain yang lebih sedikit dibandingkan sepak bola konvensional. Olahraga ini telah menjadi populer di berbagai belahan dunia, termasuk Indonesia. Berikut adalah sejarah dan perkembangan mini soccer di Indonesia.',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Asal Usul Mini Soccer',
                        style: TextStyle(fontSize: 20),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Mini soccer berasal dari adaptasi permainan sepak bola yang dirancang untuk dimainkan di area yang lebih kecil. Awalnya, mini soccer dikenal sebagai cara alternatif untuk berlatih sepak bola, terutama di negara-negara dengan keterbatasan lahan dan fasilitas olahraga. Olahraga ini kemudian berkembang menjadi sebuah permainan kompetitif yang memiliki aturan tersendiri, meskipun tetap merujuk pada prinsip dasar sepak bola.',
                        style: TextStyle(fontSize: 16),
                      ),
                      // Image.asset('assets/lapangan_a.jpg'),
                      const SizedBox(height: 16),
                      const Text(
                        'Mini Soccer Mulai Dikenal di Indonesia',
                        style: TextStyle(fontSize: 20),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Mini soccer mulai dikenal di Indonesia pada awal 2000-an. Popularitasnya meningkat seiring dengan kebutuhan masyarakat urban yang mencari alternatif olahraga yang lebih santai namun tetap kompetitif. Dalam konteks ini, lapangan futsal yang sebelumnya sudah populer menjadi salah satu tempat yang sering digunakan untuk bermain mini soccer. Perbedaannya dengan futsal terletak pada ukuran lapangan yang lebih besar serta jumlah pemain yang lebih banyak, yakni 5 hingga 7 orang per tim.',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Perkembangan Mini Soccer di Indonesia',
                        style: TextStyle(fontSize: 20),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '1. Pendirian Klub dan Komunitas, Pada pertengahan 2010-an, berbagai komunitas dan klub mini soccer mulai bermunculan di kota-kota besar seperti Jakarta, Bandung, Surabaya, dan Medan. Komunitas ini sering mengadakan pertandingan persahabatan serta turnamen untuk menarik lebih banyak penggemar.',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        '2. Turnamen dan Kompetisi, Kompetisi mini soccer mulai diselenggarakan oleh berbagai pihak, termasuk organisasi olahraga lokal, institusi pendidikan, hingga perusahaan. Turnamen ini tidak hanya menjadi ajang olahraga, tetapi juga sarana membangun relasi dan semangat kekeluargaan.',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        '3. Fasilitas dan Insfrastruktur, Dalam beberapa tahun terakhir, fasilitas khusus untuk mini soccer semakin banyak dibangun di Indonesia. Lapangan dengan rumput sintetis menjadi pilihan utama untuk memberikan pengalaman bermain yang optimal. Beberapa pusat olahraga bahkan menyediakan lapangan khusus untuk mini soccer yang dilengkapi dengan pencahayaan modern dan fasilitas pendukung lainnya.',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Daya Tarik Mini Soccer',
                        style: TextStyle(fontSize: 20),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Mini soccer memiliki sejumlah keunggulan yang membuatnya diminati masyarakat Indonesia:',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        '1. Aksesibilitas: Lapangan yang lebih kecil memungkinkan permainan ini diadakan di area perkotaan dengan keterbatasan lahan.',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        '2. Partisipasi: Dengan jumlah pemain yang lebih sedikit, lebih banyak orang bisa berpartisipasi dalam permainan.:',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        '3. Fleksibilitas: Aturan yang lebih sederhana dan waktu permainan yang lebih singkat membuat mini soccer ideal untuk hiburan santai maupun kompetisi serius.',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Tantangan dan Masa Depan Mini Soccer di Indonesia',
                        style: TextStyle(fontSize: 20),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Meskipun popularitasnya terus meningkat, mini soccer menghadapi beberapa tantangan, seperti kurangnya regulasi standar nasional dan minimnya dukungan dari federasi olahraga resmi. Namun, dengan semakin banyaknya penggemar dan partisipasi aktif dari komunitas, olahraga ini memiliki potensi besar untuk berkembang lebih jauh.',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Mini soccer telah memberikan warna baru dalam dunia olahraga di Indonesia. Dengan kemudahan akses dan daya tariknya yang universal, olahraga ini tidak hanya menjadi sarana hiburan tetapi juga alat untuk mempererat hubungan sosial di tengah masyarakat urban. Masa depan mini soccer di Indonesia tampaknya cerah, terutama jika didukung oleh pengelolaan yang lebih terorganisasi dan partisipasi yang lebih luas dari masyarakat.',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          ArticleCard(
            title: 'Artikel 2',
            imagePath: 'assets/lapangan_b.jpg',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ArticleDetailPage(
                    title: 'Artikel 2',
                    imagePath: 'assets/lapangan_b.jpg',
                    content: [
                      const Text(
                        'Deskripsi Artikel',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      // Image.asset('assets/lapangan_b.jpg'),
                      const SizedBox(height: 16),
                      const Text(
                        'Tulisan Lainnya',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
