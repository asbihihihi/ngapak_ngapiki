import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotaPage extends StatelessWidget {
  const NotaPage({super.key});

  Widget itemRow(
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),

      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,

        children: [

          Text(
            title,

            style: GoogleFonts.poppins(
              color: Colors.grey[700],
              fontSize: 16,
            ),
          ),

          Text(
            value,

            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 16,
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

      body: SingleChildScrollView(

        child: Column(
          children: [

            /// HEADER
            Container(
              width: double.infinity,

              padding: const EdgeInsets.only(
                top: 65,
                left: 25,
                right: 25,
                bottom: 35,
              ),

              decoration: const BoxDecoration(

                gradient: LinearGradient(
                  colors: [
                    Color(0xff0E9F4B),
                    Color(0xff087F3A),
                  ],
                ),

                borderRadius: BorderRadius.only(
                  bottomLeft:
                      Radius.circular(35),
                  bottomRight:
                      Radius.circular(35),
                ),
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

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
                            "Nota Pembelian",

                            style:
                                GoogleFonts
                                    .poppins(
                              color:
                                  Colors.white,
                              fontWeight:
                                  FontWeight.bold,
                              fontSize: 30,
                            ),
                          ),

                          const SizedBox(
                              height: 8),

                          Text(
                            "Ngapak Farm",

                            style:
                                GoogleFonts
                                    .poppins(
                              color:
                                  Colors.white70,
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
                                      20),
                        ),

                        child: const Icon(
                          Icons.receipt_long,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            /// CONTENT
            Padding(
              padding: const EdgeInsets.all(22),

              child: Column(
                children: [

                  /// CARD NOTA
                  Container(
                    width: double.infinity,

                    padding:
                        const EdgeInsets.all(
                            24),

                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius:
                          BorderRadius.circular(
                              30),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withOpacity(
                                  0.03),

                          blurRadius: 12,
                        ),
                      ],
                    ),

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                      children: [

                        /// INFO TOKO
                        Center(
                          child: Column(
                            children: [

                              Text(
                                "NGAPAK FARM",

                                style:
                                    GoogleFonts
                                        .poppins(
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                  fontSize: 28,
                                  color:
                                      const Color(
                                          0xff0E9F4B),
                                ),
                              ),

                              const SizedBox(
                                  height: 8),

                              Text(
                                "Peternakan Domba Modern",

                                style:
                                    GoogleFonts
                                        .poppins(
                                  color:
                                      Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(
                            height: 35),

                        Divider(
                          color:
                              Colors.grey[300],
                        ),

                        const SizedBox(
                            height: 25),

                        /// INFO NOTA
                        itemRow(
                          "No Nota",
                          "#NPK001",
                        ),

                        itemRow(
                          "Tanggal",
                          "20 Mei 2026",
                        ),

                        itemRow(
                          "Pembeli",
                          "Setiyo",
                        ),

                        const SizedBox(
                            height: 10),

                        Divider(
                          color:
                              Colors.grey[300],
                        ),

                        const SizedBox(
                            height: 25),

                        /// DATA DOMBA
                        Text(
                          "Detail Domba",

                          style:
                              GoogleFonts
                                  .poppins(
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),

                        const SizedBox(
                            height: 25),

                        itemRow(
                          "Jenis Domba",
                          "Merino",
                        ),

                        itemRow(
                          "Jumlah",
                          "10 Ekor",
                        ),

                        itemRow(
                          "Berat",
                          "30 Kg",
                        ),

                        itemRow(
                          "Harga / Ekor",
                          "Rp 2.500.000",
                        ),

                        const SizedBox(
                            height: 20),

                        Divider(
                          thickness: 1.2,
                          color:
                              Colors.grey[300],
                        ),

                        const SizedBox(
                            height: 25),

                        /// TOTAL
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .spaceBetween,

                          children: [

                            Text(
                              "TOTAL",

                              style:
                                  GoogleFonts
                                      .poppins(
                                fontWeight:
                                    FontWeight
                                        .bold,
                                fontSize: 22,
                              ),
                            ),

                            Text(
                              "Rp 25.000.000",

                              style:
                                  GoogleFonts
                                      .poppins(
                                fontWeight:
                                    FontWeight
                                        .bold,
                                fontSize: 24,
                                color:
                                    const Color(
                                        0xff0E9F4B),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                            height: 35),

                        /// STATUS
                        Center(
                          child: Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),

                            decoration:
                                BoxDecoration(
                              color: Colors
                                  .green
                                  .withOpacity(
                                      0.12),

                              borderRadius:
                                  BorderRadius
                                      .circular(
                                          25),
                            ),

                            child: Text(
                              "LUNAS",

                              style:
                                  GoogleFonts
                                      .poppins(
                                color:
                                    Colors.green,
                                fontWeight:
                                    FontWeight
                                        .bold,
                                letterSpacing:
                                    1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// BUTTON PDF
                  SizedBox(
                    width: double.infinity,
                    height: 60,

                    child:
                        ElevatedButton.icon(

                      onPressed: () {},

                      icon: const Icon(
                        Icons.picture_as_pdf,
                      ),

                      label: Text(
                        "Export PDF",

                        style:
                            GoogleFonts
                                .poppins(
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),

                      style:
                          ElevatedButton
                              .styleFrom(
                        backgroundColor:
                            const Color(
                                0xff0E9F4B),

                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                                      18),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// BUTTON SHARE
                  SizedBox(
                    width: double.infinity,
                    height: 60,

                    child:
                        OutlinedButton.icon(

                      onPressed: () {},

                      icon:
                          const Icon(Icons.share),

                      label: Text(
                        "Bagikan Nota",

                        style:
                            GoogleFonts
                                .poppins(
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),

                      style:
                          OutlinedButton
                              .styleFrom(
                        foregroundColor:
                            const Color(
                                0xff0E9F4B),

                        side:
                            const BorderSide(
                          color: Color(
                              0xff0E9F4B),
                          width: 1.5,
                        ),

                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                                      18),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}