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
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(22),

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
            radius: 24,
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
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            value,

            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 26,
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
          size: 32,
        ),
      ),

      bottomNavigationBar:
          BottomNavigationBar(

        currentIndex: 1,

        selectedItemColor:
            const Color(0xff0E9F4B),

        unselectedItemColor:
            Colors.grey,

        type:
            BottomNavigationBarType.fixed,

        items: const [

          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Beranda",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.pets),
            label: "Data Domba",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.add_box),
            label: "Input",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: "Laporan",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Akun",
          ),
        ],
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

            return jenis.contains(
                    searchText) ||
                asal.contains(searchText);

          }).toList();

          int totalDomba = 0;

          for (var item in dataDomba) {

            totalDomba +=
                int.tryParse(
                      item["jumlah"]
                          .toString(),
                    ) ??
                    0;
          }

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
                          Radius.circular(30),
                      bottomRight:
                          Radius.circular(30),
                    ),
                  ),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .spaceBetween,

                        children: [

                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                            children: [

                              Text(
                                "Data Domba",

                                style:
                                    GoogleFonts
                                        .poppins(
                                  color:
                                      Colors.white,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                  fontSize: 34,
                                ),
                              ),

                              const SizedBox(
                                  height: 8),

                              Text(
                                "Kelola dan pantau data domba Anda",

                                style:
                                    GoogleFonts
                                        .poppins(
                                  color: Colors
                                      .white70,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),

                          Container(
                            padding:
                                const EdgeInsets
                                    .all(14),

                            decoration:
                                BoxDecoration(
                              color:
                                  Colors.white24,

                              borderRadius:
                                  BorderRadius
                                      .circular(
                                          18),
                            ),

                            child:
                                const Icon(
                              Icons.filter_alt,
                              color:
                                  Colors.white,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                          height: 30),

                      /// SEARCH
                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 18,
                        ),

                        decoration:
                            BoxDecoration(
                          color:
                              Colors.white,

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
                                "Cari domba berdasarkan jenis atau asal...",

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

                /// CONTENT
                Padding(
                  padding:
                      const EdgeInsets.all(
                          20),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [

                      /// STATISTIK
                      SizedBox(
                        height: 150,

                        child: Row(
                          children: [

                            Expanded(
                              child:
                                  statCard(
                                "Total Domba",
                                "$totalDomba",
                                Icons.pets,
                                Colors.green,
                              ),
                            ),

                            const SizedBox(
                                width: 12),

                            Expanded(
                              child:
                                  statCard(
                                "Masuk",
                                "$totalDomba",
                                Icons.login,
                                Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                          height: 30),

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
                            "Terbaru",

                            style:
                                GoogleFonts
                                    .poppins(
                              color:
                                  Colors.grey,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                          height: 20),

                      /// LIST DATA
                      ListView.builder(

                        shrinkWrap: true,

                        physics:
                            const NeverScrollableScrollPhysics(),

                        itemCount:
                            dataDomba.length,

                        itemBuilder:
                            (context,
                                index) {

                          final item =
                              dataDomba[index];

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

                            child:
                                Container(

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
                                            25),

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
                                                18),

                                    child:
                                        Image.network(
                                      "https://images.unsplash.com/photo-1484557985045-edf25e08da73?q=80&w=1200&auto=format&fit=crop",

                                      width: 90,
                                      height: 90,

                                      fit:
                                          BoxFit.cover,
                                    ),
                                  ),

                                  const SizedBox(
                                      width:
                                          16),

                                  /// DATA
                                  Expanded(
                                    child:
                                        Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,

                                      children: [

                                        Row(
                                          children: [

                                            Expanded(
                                              child:
                                                  Text(
                                                item["jenis"] ??
                                                    "-",

                                                style:
                                                    GoogleFonts.poppins(
                                                  fontWeight:
                                                      FontWeight.bold,
                                                  fontSize:
                                                      20,
                                                ),
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
                                                color: Colors
                                                    .green
                                                    .withOpacity(
                                                        0.12),

                                                borderRadius:
                                                    BorderRadius.circular(
                                                        20),
                                              ),

                                              child:
                                                  Text(
                                                "Aktif",

                                                style:
                                                    GoogleFonts.poppins(
                                                  color:
                                                      Colors.green,

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
                                                Colors.grey[
                                                    700],
                                          ),
                                        ),

                                        const SizedBox(
                                            height:
                                                6),

                                        Text(
                                          "Jumlah : ${item["jumlah"]}",

                                          style:
                                              GoogleFonts.poppins(
                                            color:
                                                Colors.grey[
                                                    700],
                                          ),
                                        ),

                                        const SizedBox(
                                            height:
                                                6),

                                        Text(
                                          "Berat : ${item["berat"]}",

                                          style:
                                              GoogleFonts.poppins(
                                            color:
                                                Colors.grey[
                                                    700],
                                          ),
                                        ),

                                        const SizedBox(
                                            height:
                                                12),

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

                                      dombaBox
                                          .deleteAt(
                                              index);
                                    },

                                    icon:
                                        const Icon(
                                      Icons
                                          .delete,

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