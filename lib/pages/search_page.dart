import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mandalaarenaapp/pages/detail_page.dart';
import 'package:mandalaarenaapp/pages/models/lapang.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<Lapang> lapangs = [];
  List<Lapang> _foundedLapangs = [];

  Future<void> getLapangs() async {
    String dataLapangJson = await rootBundle.loadString('assets/json/lapang.json');
    List<dynamic> jsonMap = json.decode(dataLapangJson);

    setState(() {
      lapangs = jsonMap.map((e) => Lapang.fromJson(e)).toList();
      _foundedLapangs = lapangs;
    });
  }

  onSearchLapang(String query){
    setState(() {
      _foundedLapangs = lapangs.where((element) => element.name!.toLowerCase().contains(query.toLowerCase())).toList();
    });
  }

  @override
  void initState() {
    getLapangs();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mencari Lapang'),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Mencari Lapang',
                contentPadding: EdgeInsets.fromLTRB(18, 0, 18, 0),
                prefixIcon: Icon(CupertinoIcons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                setState(() {
                  onSearchLapang(value.toString());
                });
              },
            ),
          ),

          // List Lapang
          _foundedLapangs.isEmpty ? Center(child: Text('Tidak ada lapang yang ditemukan')) : ListView.builder(
          shrinkWrap: true,
          itemCount: _foundedLapangs.length,
          itemBuilder: (context, index) {
            return ListTile(
              onTap: (){
                Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailPage(
          lapang: lapangs[index],
        ),
      ),
    );
              },
              leading: SizedBox(
                width: 50,
                height: 50,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(_foundedLapangs[index].imagePath.toString(),
                  fit: BoxFit.cover,
                  ),
                ),
              ),
              title: Text(
                _foundedLapangs[index].name.toString(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Text('IDR ${_foundedLapangs[index].price}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.star_fill,
                    size: 15,
                    color: Colors.yellow,
                  ),
                  SizedBox(width: 4),
                  Text(
                    _foundedLapangs[index].rating.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        ],
      ),
    );
  }
}
