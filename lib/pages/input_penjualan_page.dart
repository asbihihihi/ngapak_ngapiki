import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';

import 'nota_penjualan_page.dart';

class InputPenjualanPage extends StatefulWidget {

  final Map data;
  final int index;

  const InputPenjualanPage({
    super.key,
    required this.data,
    required this.index,
  });

  @override
  State<InputPenjualanPage> createState() =>
      _InputPenjualanPageState();
}

class _InputPenjualanPageState
    extends State<InputPenjualanPage> {

  late Box dombaBox;
  late Box penjualanBox;

  final namaController =
      TextEditingController();

  final asalController =
      TextEditingController();

  final waController =
      TextEditingController();

  final beratController =
      TextEditingController();

  final hargaController =
      TextEditingController();

  final mapsController =
      TextEditingController();

  final kondisiController =
      TextEditingController();

  File? imageFile;

  final picker = ImagePicker();

  @override
  void initState() {

    super.initState();

    dombaBox = Hive.box('dombaBox');
    penjualanBox = Hive.box('penjualanBox');
  }

  Future pickImage() async {

    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (picked != null) {

      setState(() {

        imageFile = File(picked.path);
      });
    }
  }

  Widget input(
    String label,
    TextEditingController controller,
  ) {

    return Padding(

      padding: const EdgeInsets.only(
        bottom: 18,
      ),

      child: TextField(

        controller: controller,

        decoration: InputDecoration(

          labelText: label,

          filled: true,
          fillColor: Colors.white,

          border: OutlineInputBorder(

            borderRadius:
                BorderRadius.circular(18),

            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
          const Color(0xffF4F6F5),

      appBar: AppBar(

        backgroundColor:
            const Color(0xff0E9F4B),

        title: Text(

          "Penjualan Domba",

          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(

        child: SingleChildScrollView(

          padding: const EdgeInsets.all(20),

          child: Column(

            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              Container(

                width: double.infinity,

                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(

                  color: Colors.white,

                  borderRadius:
                      BorderRadius.circular(25),
                ),

                child: Column(

                  children: [

                    Text(

                      widget.data["kode"],

                      style: GoogleFonts.poppins(

                        fontSize: 28,

                        fontWeight:
                            FontWeight.bold,

                        color:
                            const Color(0xff0E9F4B),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(

                      widget.data["jenis"],

                      style: GoogleFonts.poppins(
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              input(
                "Nama Pembeli",
                namaController,
              ),

              input(
                "Asal Pembeli",
                asalController,
              ),

              input(
                "No WhatsApp",
                waController,
              ),

              input(
                "Bobot Terjual",
                beratController,
              ),

              input(
                "Harga Terjual",
                hargaController,
              ),

              input(
                "Link Google Maps",
                mapsController,
              ),

              input(
                "Kondisi Domba",
                kondisiController,
              ),

              GestureDetector(

                onTap: pickImage,

                child: Container(

                  height: 180,
                  width: double.infinity,

                  decoration: BoxDecoration(

                    color: Colors.white,

                    borderRadius:
                        BorderRadius.circular(20),

                    border: Border.all(
                      color:
                          const Color(0xff0E9F4B),
                    ),
                  ),

                  child: imageFile != null

                      ? ClipRRect(

                          borderRadius:
                              BorderRadius.circular(
                                  20),

                          child: Image.file(

                            imageFile!,

                            fit: BoxFit.cover,
                          ),
                        )

                      : const Center(

                          child: Icon(
                            Icons.camera_alt,
                            size: 40,
                            color:
                                Color(0xff0E9F4B),
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(

                width: double.infinity,
                height: 60,

                child: ElevatedButton(

                  onPressed: () async {

                    await dombaBox.putAt(

                      widget.index,

                      {

                        ...widget.data,

                        "status": "terjual",

                        "namaPembeli":
                            namaController.text,

                        "asalPembeli":
                            asalController.text,

                        "waPembeli":
                            waController.text,

                        "beratJual":
                            beratController.text,

                        "hargaJual":
                            hargaController.text,

                        "maps":
                            mapsController.text,

                        "kondisi":
                            kondisiController.text,

                        "fotoJual":
                            imageFile?.path ?? "",
                      },
                    );

                    await penjualanBox.add({

                      "kode":
                          widget.data["kode"],

                      "jenis":
                          widget.data["jenis"],

                      "nama":
                          namaController.text,

                      "harga":
                          hargaController.text,

                      "tanggal":
                          DateTime.now()
                              .toString(),
                    });

                    ScaffoldMessenger.of(context)
                        .showSnackBar(

                      const SnackBar(

                        backgroundColor:
                            Colors.green,

                        content: Text(
                          "Domba berhasil dijual 🐐",
                        ),
                      ),
                    );

                    Navigator.pushReplacement(

  context,

  MaterialPageRoute(

    builder: (context) => NotaPage(

      data: {

        ...widget.data,

        "namaPembeli":
            namaController.text,

        "asalPembeli":
            asalController.text,

        "waPembeli":
            waController.text,

        "hargaJual":
            hargaController.text,

        "kondisi":
            kondisiController.text,
      },
    ),
  ),
);
                  },

                  style:
                      ElevatedButton.styleFrom(

                    backgroundColor:
                        Colors.red,

                    shape:
                        RoundedRectangleBorder(

                      borderRadius:
                          BorderRadius.circular(
                              18),
                    ),
                  ),

                  child: Text(

                    "TANDAI TERJUAL",

                    style: GoogleFonts.poppins(

                      fontWeight:
                          FontWeight.bold,

                      fontSize: 18,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}