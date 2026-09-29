import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';

class NotaPage extends StatelessWidget {
  final Map data;

  NotaPage({
    super.key,
    required this.data,
  });

  final ScreenshotController screenshotController =
      ScreenshotController();

  Widget itemRow(
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 18,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              title,
              style: GoogleFonts.poppins(
                color: Colors.grey[700],
                fontSize: 16,
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> saveToGallery(
    BuildContext context,
  ) async {
    await Permission.storage.request();
    await Permission.photos.request();

    Uint8List? image =
        await screenshotController.capture();

    if (image == null) return;

    final directory =
        await getTemporaryDirectory();

    final imagePath =
        "${directory.path}/nota_${data["kode"]}.png";

    File file = File(imagePath);

    await file.writeAsBytes(image);

    await GallerySaver.saveImage(
      file.path,
    );

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        backgroundColor: Colors.green,
        content: Text(
          "Nota berhasil disimpan 🖼️",
        ),
      ),
    );
  }

  Future<void> exportPdf(
    BuildContext context,
  ) async {
    Uint8List? image =
        await screenshotController.capture();

    if (image == null) return;

    final pdf = pw.Document();

    final imageProvider =
        pw.MemoryImage(image);

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment:
                  pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  "NOTA PENJUALAN",
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight:
                        pw.FontWeight.bold,
                  ),
                ),

                pw.SizedBox(height: 20),

                pw.Image(
                  imageProvider,
                  width: 450,
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async =>
          pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kode =
        data["kode"] ?? "-";

    final pembeli =
        data["namaPembeli"] ?? "-";

    final jenis =
        data["jenis"] ?? "-";

    final berat =
        data["berat"] ?? "-";

    final harga =
        data["hargaJual"] ?? "-";

    final asal =
        data["asalPembeli"] ?? "-";

    final wa =
        data["waPembeli"] ?? "-";

    final kondisi =
        data["kondisi"] ?? "-";

    final tanggal =
        DateTime.now();

    final nomorNota =
        "#NPK${tanggal.millisecondsSinceEpoch}";

    return Scaffold(
      backgroundColor:
          const Color(0xffF4F6F5),

      appBar: AppBar(
        backgroundColor:
            const Color(0xff0E9F4B),

        elevation: 0,

        title: Text(
          "Nota Penjualan",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(20),

        child: Column(
          children: [
            Screenshot(
              controller:
                  screenshotController,

              child: Container(
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
                              0.04),

                      blurRadius: 10,
                    ),
                  ],
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding:
                                const EdgeInsets
                                    .all(18),

                            decoration:
                                BoxDecoration(
                              color: const Color(
                                      0xff0E9F4B)
                                  .withOpacity(
                                      0.1),

                              shape:
                                  BoxShape.circle,
                            ),

                            child: const Icon(
                              Icons.pets,
                              color: Color(
                                  0xff0E9F4B),
                              size: 40,
                            ),
                          ),

                          const SizedBox(
                              height: 18),

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
                              height: 6),

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

                    Center(
                      child: QrImageView(
                        data: kode,
                        size: 140,
                      ),
                    ),

                    const SizedBox(
                        height: 20),

                    Center(
                      child: Text(
                        kode,

                        style:
                            GoogleFonts
                                .poppins(
                          fontWeight:
                              FontWeight.bold,

                          fontSize: 26,

                          color:
                              const Color(
                                  0xff0E9F4B),
                        ),
                      ),
                    ),

                    const SizedBox(
                        height: 30),

                    Divider(
                      color:
                          Colors.grey[300],
                    ),

                    const SizedBox(
                        height: 25),

                    itemRow(
                      "No Nota",
                      nomorNota,
                    ),

                    itemRow(
                      "Tanggal",
                      "${tanggal.day}-${tanggal.month}-${tanggal.year}",
                    ),

                    itemRow(
                      "Nama Pembeli",
                      pembeli,
                    ),

                    itemRow(
                      "Asal Pembeli",
                      asal,
                    ),

                    itemRow(
                      "WhatsApp",
                      wa,
                    ),

                    const SizedBox(
                        height: 10),

                    Divider(
                      color:
                          Colors.grey[300],
                    ),

                    const SizedBox(
                        height: 25),

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
                      "Kode Domba",
                      kode,
                    ),

                    itemRow(
                      "Jenis Domba",
                      jenis,
                    ),

                    itemRow(
                      "Berat",
                      "$berat Kg",
                    ),

                    itemRow(
                      "Kondisi",
                      kondisi,
                    ),

                    itemRow(
                      "Harga Jual",
                      "Rp $harga",
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

                        Flexible(
                          child: Text(
                            "Rp $harga",

                            textAlign:
                                TextAlign.right,

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
                        ),
                      ],
                    ),

                    const SizedBox(
                        height: 35),

                    Center(
                      child: Container(
                      padding:
    const EdgeInsets.symmetric(
  horizontal: 22,
  vertical: 12,
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
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 60,

              child:
                  ElevatedButton.icon(
                onPressed: () async {
                  await exportPdf(
                    context,
                  );
                },

                icon: const Icon(
                  Icons.picture_as_pdf,
                ),

                label: Text(
                  "Cetak PDF",

                  style:
                      GoogleFonts.poppins(
                    fontWeight:
                        FontWeight.bold,

                    fontSize: 18,
                  ),
                ),

                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(
                          0xff0E9F4B),

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                            18),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 60,

              child:
                  OutlinedButton.icon(
                onPressed: () async {
                  await saveToGallery(
                    context,
                  );
                },

                icon: const Icon(
                  Icons.image,
                ),

                label: Text(
                  "Simpan Gambar Nota",

                  style:
                      GoogleFonts.poppins(
                    fontWeight:
                        FontWeight.bold,

                    fontSize: 18,
                  ),
                ),

                style:
                    OutlinedButton.styleFrom(
                  foregroundColor:
                      const Color(
                          0xff0E9F4B),

                  side:
                      const BorderSide(
                    color:
                        Color(0xff0E9F4B),
                    width: 1.5,
                  ),

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                            18),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}