import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'detail_domba_page.dart';
import '../farm_data.dart';

class DataDombaPage extends StatefulWidget {
  const DataDombaPage({super.key});

  @override
  State<DataDombaPage> createState() => _DataDombaPageState();
}

class _DataDombaPageState extends State<DataDombaPage> {
  final dombaBox = Hive.box('dombaBox');

  final searchController = TextEditingController();

  String searchText = "";
  String statusFilter = 'Aktif';

  Widget statCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    required bool selected,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: selected ? color : Colors.transparent,
          width: 2,
        ),

        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          CircleAvatar(
            radius: 25,

            backgroundColor: color.withOpacity(0.12),

            child: Icon(icon, color: color),
          ),

          const Spacer(),

          Text(
            title,

            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
          ),

          const SizedBox(height: 8),

          Text(
            value,

            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 30,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F6F5),

      body: ValueListenableBuilder(
        valueListenable: dombaBox.listenable(),

        builder: (context, Box box, _) {
          final searchedDomba = box.values.where((item) {
            final jenis = (item["jenis"] ?? '').toString().toLowerCase();
            final asal = (item["asal"] ?? '').toString().toLowerCase();
            final kode = (item["kode"] ?? '').toString().toLowerCase();
            final qr = (item["qrCode"] ?? '').toString().toLowerCase();
            final bobot =
                '${item['bobotAwal'] ?? ''} ${item['bobotTerakhir'] ?? item['berat'] ?? ''}'
                    .toLowerCase();

            return jenis.contains(searchText) ||
                asal.contains(searchText) ||
                kode.contains(searchText) ||
                qr.contains(searchText) ||
                bobot.contains(searchText);
          }).toList();

          final totalAktif = searchedDomba
              .where((item) => !FarmData.isSold(item))
              .length;
          final totalTerjual = searchedDomba.where(FarmData.isSold).length;
          final dataDomba = searchedDomba
              .where(
                (item) => statusFilter == 'Terjual'
                    ? FarmData.isSold(item)
                    : !FarmData.isSold(item),
              )
              .toList();

          return SingleChildScrollView(
            child: Column(
              children: [
                /// HEADER
                Container(
                  padding: const EdgeInsets.only(
                    top: 60,
                    left: 20,
                    right: 20,
                    bottom: 30,
                  ),

                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xff0E9F4B), Color(0xff087F3A)],
                    ),

                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(35),

                      bottomRight: Radius.circular(35),
                    ),
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        "Data Domba",

                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,

                          fontSize: 34,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        "Kelola dan pantau data domba Anda",

                        style: GoogleFonts.poppins(color: Colors.white70),
                      ),

                      const SizedBox(height: 25),

                      /// SEARCH
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18),

                        decoration: BoxDecoration(
                          color: Colors.white,

                          borderRadius: BorderRadius.circular(18),
                        ),

                        child: TextField(
                          controller: searchController,

                          onChanged: (value) {
                            setState(() {
                              searchText = value.toLowerCase();
                            });
                          },

                          decoration: InputDecoration(
                            border: InputBorder.none,

                            icon: const Icon(Icons.search),

                            hintText: "Cari domba...",

                            hintStyle: GoogleFonts.poppins(color: Colors.grey),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),

                  child: Column(
                    children: [
                      /// STAT
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() {
                                statusFilter = 'Aktif';
                              }),
                              child: SizedBox(
                                height: 150,
                                child: statCard(
                                  "Aktif",
                                  "$totalAktif",
                                  Icons.pets,
                                  Colors.green,
                                  selected: statusFilter == 'Aktif',
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 15),

                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() {
                                statusFilter = 'Terjual';
                              }),
                              child: SizedBox(
                                height: 150,
                                child: statCard(
                                  "Terjual",
                                  "$totalTerjual",
                                  Icons.sell,
                                  Colors.red,
                                  selected: statusFilter == 'Terjual',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,

                        children: [
                          Text(
                            "Daftar Domba",

                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,

                              fontSize: 24,
                            ),
                          ),

                          Text(
                            "${dataDomba.length} Data",

                            style: GoogleFonts.poppins(color: Colors.grey),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      /// LIST
                      if (dataDomba.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Text(
                            'Belum ada domba ${statusFilter.toLowerCase()}'
                            '${searchText.isEmpty ? '.' : ' yang cocok dengan pencarian.'}',
                            textAlign: TextAlign.center,
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: dataDomba.length,
                          itemBuilder: (context, index) {
                          final item = dataDomba[index];

                          final isTerjual = FarmData.isSold(item);

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,

                                MaterialPageRoute(
                                  builder: (context) => DetailDombaPage(
                                    data: Map<String, dynamic>.from(item),

                                    index: box.values.toList().indexOf(item),
                                  ),
                                ),
                              );
                            },

                            child: Container(
                              margin: const EdgeInsets.only(bottom: 18),

                              padding: const EdgeInsets.all(16),

                              decoration: BoxDecoration(
                                color: Colors.white,

                                borderRadius: BorderRadius.circular(28),

                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),

                                    blurRadius: 10,
                                  ),
                                ],
                              ),

                              child: Row(
                                children: [
                                  /// FOTO
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(20),

                                    child: item["foto"] != null &&
                                            item["foto"].toString().isNotEmpty
                                        ? Image.file(
                                            File(item["foto"]),
                                            width: 95,
                                            height: 95,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) =>
                                                _photoPlaceholder(),
                                          )
                                        : _photoPlaceholder(),
                                  ),

                                  const SizedBox(width: 16),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,

                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,

                                                children: [
                                                  Text(
                                                    item["kode"] ?? "-",

                                                    style: GoogleFonts.poppins(
                                                      fontWeight:
                                                          FontWeight.bold,

                                                      fontSize: 22,

                                                      color: const Color(
                                                        0xff0E9F4B,
                                                      ),
                                                    ),
                                                  ),

                                                  Text(
                                                    item["jenis"] ?? "-",

                                                    style: GoogleFonts.poppins(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,

                                                    vertical: 5,
                                                  ),

                                              decoration: BoxDecoration(
                                                color: isTerjual
                                                    ? Colors.red.withOpacity(
                                                        0.12,
                                                      )
                                                    : Colors.green.withOpacity(
                                                        0.12,
                                                      ),

                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),

                                              child: Text(
                                                isTerjual ? "Terjual" : "Aktif",

                                                style: GoogleFonts.poppins(
                                                  color: isTerjual
                                                      ? Colors.red
                                                      : Colors.green,

                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 10),

                                        Text(
                                          "Asal : ${item["asal"]}",

                                          style: GoogleFonts.poppins(
                                            color: Colors.grey[700],
                                          ),
                                        ),

                                        const SizedBox(height: 5),

                                        Text(
                                          "Berat : ${item["berat"]} Kg",

                                          style: GoogleFonts.poppins(
                                            color: Colors.grey[700],
                                          ),
                                        ),

                                        const SizedBox(height: 10),

                                        Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_month,

                                              size: 18,

                                              color: Colors.grey[600],
                                            ),

                                            const SizedBox(width: 6),

                                            Text(
                                              item["tanggal"] ?? "-",

                                              style: GoogleFonts.poppins(
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                          },
                        ),

                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _photoPlaceholder() => Container(
    width: 95,
    height: 95,
    color: const Color(0xffE8F5E9),
    child: const Icon(Icons.pets, size: 42, color: Color(0xff2D6A4F)),
  );
}
