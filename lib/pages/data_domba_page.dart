import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'edit_domba_page.dart';

class DataDombaPage extends StatefulWidget {
  const DataDombaPage({super.key});

  @override
  State<DataDombaPage> createState() =>
      _DataDombaPageState();
}

class _DataDombaPageState
    extends State<DataDombaPage> {

  final dombaBox = Hive.box('dombaBox');

  final searchController =
      TextEditingController();

  String searchText = "";

  Widget statCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {

    return Container(

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(25),

        boxShadow: [

          BoxShadow(
            color:
                Colors.black.withOpacity(0.03),

            blurRadius: 10,
          ),
        ],
      ),

      child: Column(

        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          CircleAvatar(

            radius: 25,

            backgroundColor:
                color.withOpacity(0.12),

            child: Icon(
              icon,
              color: color,
            ),
          ),

          const Spacer(),

          Text(
            title,

            style: GoogleFonts.poppins(
              color: Colors.grey,
              fontSize: 14,
            ),
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

      backgroundColor:
          const Color(0xffF4F6F5),

      floatingActionButton:
          FloatingActionButton(

        backgroundColor:
            const Color(0xff0E9F4B),

        onPressed: () {

          Navigator.pop(context);
        },

        child: const Icon(
          Icons.add,
          size: 30,
        ),
      ),

      body: ValueListenableBuilder(

        valueListenable:
            dombaBox.listenable(),

        builder: (context, Box box, _) {

          final dataDomba =
              box.values.where((item) {

            final jenis = item["jenis"]
                .toString()
                .toLowerCase();

            final asal = item["asal"]
                .toString()
                .toLowerCase();

            final kode = item["kode"]
                .toString()
                .toLowerCase();

            return jenis.contains(
                        searchText) ||
                    asal.contains(
                        searchText) ||
                    kode.contains(
                        searchText);

          }).toList();

          int totalAktif =
              dataDomba.where((item) {

            return item["status"] !=
                "terjual";

          }).length;

          int totalTerjual =
              dataDomba.where((item) {

            return item["status"] ==
                "terjual";

          }).length;

          return SingleChildScrollView(

            child: Column(
              children: [

                /// HEADER
                Container(

                  padding:
                      const EdgeInsets.only(
                    top: 60,
                    left: 20,
                    right: 20,
                    bottom: 30,
                  ),

                  decoration:
                      const BoxDecoration(

                    gradient:
                        LinearGradient(
                      colors: [
                        Color(0xff0E9F4B),
                        Color(0xff087F3A),
                      ],
                    ),

                    borderRadius:
                        BorderRadius.only(
                      bottomLeft:
                          Radius.circular(35),

                      bottomRight:
                          Radius.circular(35),
                    ),
                  ),

                  child: Column(

                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [

                      Text(
                        "Data Domba",

                        style:
                            GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight:
                              FontWeight.bold,

                          fontSize: 34,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        "Kelola dan pantau data domba Anda",

                        style:
                            GoogleFonts.poppins(
                          color: Colors.white70,
                        ),
                      ),

                      const SizedBox(height: 25),

                      /// SEARCH
                      Container(

                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 18,
                        ),

                        decoration:
                            BoxDecoration(
                          color: Colors.white,

                          borderRadius:
                              BorderRadius
                                  .circular(
                                      18),
                        ),

                        child: TextField(

                          controller:
                              searchController,

                          onChanged: (value) {

                            setState(() {

                              searchText =
                                  value
                                      .toLowerCase();
                            });
                          },

                          decoration:
                              InputDecoration(
                            border:
                                InputBorder
                                    .none,

                            icon:
                                const Icon(
                              Icons.search,
                            ),

                            hintText:
                                "Cari domba...",

                            hintStyle:
                                GoogleFonts
                                    .poppins(
                              color:
                                  Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(

                  padding:
                      const EdgeInsets.all(
                          20),

                  child: Column(

                    children: [

                      /// STAT
                      Row(
                        children: [

                          Expanded(
                            child: SizedBox(
                              height: 150,

                              child: statCard(
                                "Aktif",
                                "$totalAktif",
                                Icons.pets,
                                Colors.green,
                              ),
                            ),
                          ),

                          const SizedBox(width: 15),

                          Expanded(
                            child: SizedBox(
                              height: 150,

                              child: statCard(
                                "Terjual",
                                "$totalTerjual",
                                Icons.sell,
                                Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      Row(

                        mainAxisAlignment:
                            MainAxisAlignment
                                .spaceBetween,

                        children: [

                          Text(
                            "Daftar Domba",

                            style:
                                GoogleFonts
                                    .poppins(
                              fontWeight:
                                  FontWeight
                                      .bold,

                              fontSize: 24,
                            ),
                          ),

                          Text(
                            "${dataDomba.length} Data",

                            style:
                                GoogleFonts
                                    .poppins(
                              color:
                                  Colors.grey,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      /// LIST
                      ListView.builder(

                        shrinkWrap: true,

                        physics:
                            const NeverScrollableScrollPhysics(),

                        itemCount:
                            dataDomba.length,

                        itemBuilder:
                            (context, index) {

                          final item =
                              dataDomba[index];

                          final status =
                              item["status"] ??
                                  "aktif";

                          final isTerjual =
                              status ==
                                  "terjual";

                          return GestureDetector(

                            onTap: () {

                              Navigator.push(

                                context,

                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          EditDombaPage(

                                    data: Map<
                                            String,
                                            dynamic>
                                        .from(
                                            item),

                                    index:
                                        index,
                                  ),
                                ),
                              );
                            },

                            child: Container(

                              margin:
                                  const EdgeInsets
                                      .only(
                                bottom: 18,
                              ),

                              padding:
                                  const EdgeInsets
                                      .all(16),

                              decoration:
                                  BoxDecoration(

                                color:
                                    Colors.white,

                                borderRadius:
                                    BorderRadius
                                        .circular(
                                            28),

                                boxShadow: [

                                  BoxShadow(
                                    color: Colors
                                        .black
                                        .withOpacity(
                                            0.03),

                                    blurRadius:
                                        10,
                                  ),
                                ],
                              ),

                              child: Row(
                                children: [

                                  /// FOTO
                                  ClipRRect(

                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                                20),

                                    child:
                                        item["foto"] !=
                                                    null &&
                                                item["foto"]
                                                    .toString()
                                                    .isNotEmpty

                                            ? Image.file(
                                                File(
                                                    item["foto"]),

                                                width:
                                                    95,

                                                height:
                                                    95,

                                                fit: BoxFit
                                                    .cover,
                                              )

                                            : Image.network(

                                                "https://images.unsplash.com/photo-1484557985045-edf25e08da73?q=80&w=1200&auto=format&fit=crop",

                                                width:
                                                    95,

                                                height:
                                                    95,

                                                fit: BoxFit
                                                    .cover,
                                              ),
                                  ),

                                  const SizedBox(
                                      width:
                                          16),

                                  Expanded(

                                    child: Column(

                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,

                                      children: [

                                        Row(
                                          children: [

                                            Expanded(

                                              child:
                                                  Column(

                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,

                                                children: [

                                                  Text(
                                                    item["kode"] ??
                                                        "-",

                                                    style:
                                                        GoogleFonts.poppins(

                                                      fontWeight:
                                                          FontWeight.bold,

                                                      fontSize:
                                                          22,

                                                      color:
                                                          const Color(0xff0E9F4B),
                                                    ),
                                                  ),

                                                  Text(
                                                    item["jenis"] ??
                                                        "-",

                                                    style:
                                                        GoogleFonts.poppins(
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
                                                horizontal:
                                                    12,

                                                vertical:
                                                    5,
                                              ),

                                              decoration:
                                                  BoxDecoration(

                                                color: isTerjual

                                                    ? Colors.red
                                                        .withOpacity(
                                                            0.12)

                                                    : Colors.green
                                                        .withOpacity(
                                                            0.12),

                                                borderRadius:
                                                    BorderRadius.circular(
                                                        20),
                                              ),

                                              child:
                                                  Text(

                                                isTerjual
                                                    ? "Terjual"
                                                    : "Aktif",

                                                style:
                                                    GoogleFonts.poppins(

                                                  color: isTerjual
                                                      ? Colors.red
                                                      : Colors.green,

                                                  fontWeight:
                                                      FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(
                                            height:
                                                10),

                                        Text(
                                          "Asal : ${item["asal"]}",

                                          style:
                                              GoogleFonts.poppins(
                                            color:
                                                Colors.grey[700],
                                          ),
                                        ),

                                        const SizedBox(
                                            height:
                                                5),

                                        Text(
                                          "Berat : ${item["berat"]} Kg",

                                          style:
                                              GoogleFonts.poppins(
                                            color:
                                                Colors.grey[700],
                                          ),
                                        ),

                                        const SizedBox(
                                            height:
                                                10),

                                        Row(
                                          children: [

                                            Icon(
                                              Icons
                                                  .calendar_month,

                                              size:
                                                  18,

                                              color:
                                                  Colors.grey[
                                                      600],
                                            ),

                                            const SizedBox(
                                                width:
                                                    6),

                                            Text(
                                              item["tanggal"] ??
                                                  "-",

                                              style:
                                                  GoogleFonts.poppins(
                                                color:
                                                    Colors.grey[
                                                        600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  /// DELETE
                                  IconButton(

                                    onPressed:
                                        () {

                                      showDialog(

                                        context:
                                            context,

                                        builder:
                                            (context) {

                                          return AlertDialog(

                                            title:
                                                const Text(
                                              "Hapus Data?",
                                            ),

                                            content:
                                                const Text(
                                              "Data domba akan dihapus permanen.",
                                            ),

                                            actions: [

                                              TextButton(

                                                onPressed:
                                                    () {

                                                  Navigator.pop(
                                                      context);
                                                },

                                                child:
                                                    const Text(
                                                  "Batal",
                                                ),
                                              ),

                                              TextButton(

                                                onPressed:
                                                    () {

                                                  dombaBox
                                                      .deleteAt(
                                                          index);

                                                  Navigator.pop(
                                                      context);
                                                },

                                                child:
                                                    const Text(
                                                  "Hapus",
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },

                                    icon:
                                        const Icon(
                                      Icons.delete,
                                      color:
                                          Colors.red,
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
}