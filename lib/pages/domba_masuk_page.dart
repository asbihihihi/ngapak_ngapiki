import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';

class DombaMasukPage extends StatefulWidget {
  const DombaMasukPage({super.key});

  @override
  State<DombaMasukPage> createState() => _DombaMasukPageState();
}

class _DombaMasukPageState extends State<DombaMasukPage> {

  final dombaBox = Hive.box('dombaBox');

  final tanggalController = TextEditingController();
  final asalController = TextEditingController();
  final jumlahController = TextEditingController();
  final jenisController = TextEditingController();
  final beratController = TextEditingController();
  final hargaController = TextEditingController();
  final keteranganController = TextEditingController();

  Widget buildInput({
    required String label,
    required String hint,
    required TextEditingController controller,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Row(
          children: [

            Icon(
              icon,
              color: const Color(0xff0E9F4B),
              size: 20,
            ),

            const SizedBox(width: 8),

            Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,

            hintStyle: GoogleFonts.poppins(
              color: Colors.grey,
            ),

            filled: true,
            fillColor: Colors.white,

            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
        ),

        const SizedBox(height: 22),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xffF4F6F5),

      body: SingleChildScrollView(
        child: Column(
          children: [

            /// HEADER
            Stack(
              children: [

                Container(
                  height: 280,
                  width: double.infinity,

                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xff0E9F4B),
                        Color(0xff087F3A),
                      ],
                    ),
                  ),
                ),

                Positioned(
                  top: 55,
                  left: 20,

                  child: IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },

                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                    ),
                  ),
                ),

                Positioned(
                  top: 60,
                  left: 0,
                  right: 0,

                  child: Center(
                    child: Text(
                      "Input Domba Masuk",

                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                ),

                Positioned(
                  bottom: 0,

                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: 220,

                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(
                          "https://images.unsplash.com/photo-1484557985045-edf25e08da73?q=80&w=1200&auto=format&fit=crop",
                        ),

                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                Positioned(
                  bottom: 30,
                  right: 20,

                  child: Container(
                    width: 300,
                    padding: const EdgeInsets.all(18),

                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(25),
                    ),

                    child: Row(
                      children: [

                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white24,

                          child: const Icon(
                            Icons.pets,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),

                        const SizedBox(width: 16),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,

                            children: [

                              Text(
                                "Input Domba Masuk",

                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),

                              const SizedBox(height: 5),

                              Text(
                                "Catat data domba yang masuk ke kandang",

                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),

            /// FORM
            Padding(
              padding: const EdgeInsets.all(20),

              child: Container(
                padding: const EdgeInsets.all(22),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),

                child: Column(
                  children: [

                    buildInput(
                      label: "Tanggal Masuk",
                      hint: "21 Mei 2026",
                      controller: tanggalController,
                      icon: Icons.calendar_month,
                    ),

                    buildInput(
                      label: "Asal Domba",
                      hint: "Pilih asal domba",
                      controller: asalController,
                      icon: Icons.local_shipping,
                    ),

                    buildInput(
                      label: "Jumlah Domba",
                      hint: "Masukkan jumlah domba",
                      controller: jumlahController,
                      icon: Icons.pets,
                    ),

                    buildInput(
                      label: "Jenis Domba",
                      hint: "Pilih jenis domba",
                      controller: jenisController,
                      icon: Icons.sell,
                    ),

                    buildInput(
                      label: "Berat Rata-rata",
                      hint: "Masukkan berat rata-rata",
                      controller: beratController,
                      icon: Icons.balance,
                    ),

                    buildInput(
                      label: "Harga Beli",
                      hint: "Masukkan harga beli",
                      controller: hargaController,
                      icon: Icons.payments,
                    ),

                    buildInput(
                      label: "Keterangan",
                      hint: "Tambahkan keterangan...",
                      controller: keteranganController,
                      icon: Icons.edit_note,
                    ),

                    /// FOTO
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(30),

                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),

                        border: Border.all(
                          color: const Color(0xff0E9F4B),
                          width: 1.5,
                        ),
                      ),

                      child: Column(
                        children: [

                          CircleAvatar(
                            radius: 35,

                            backgroundColor:
                                const Color(0xff0E9F4B)
                                    .withOpacity(0.1),

                            child: const Icon(
                              Icons.camera_alt,
                              color: Color(0xff0E9F4B),
                              size: 35,
                            ),
                          ),

                          const SizedBox(height: 15),

                          Text(
                            "Tap untuk tambah foto",

                            style: GoogleFonts.poppins(
                              color: const Color(0xff0E9F4B),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Text(
                            "Maksimal 5 foto",

                            style: GoogleFonts.poppins(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    /// BUTTON SIMPAN
                    SizedBox(
                      width: double.infinity,
                      height: 60,

                      child: ElevatedButton.icon(

                        onPressed: () async {

                          if (asalController.text.isEmpty ||
                              jumlahController.text.isEmpty ||
                              jenisController.text.isEmpty) {

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Data wajib diisi"),
                                backgroundColor: Colors.red,
                              ),
                            );

                            return;
                          }

                          await dombaBox.add({

                            "tanggal": tanggalController.text,
                            "asal": asalController.text,
                            "jumlah": jumlahController.text,
                            "jenis": jenisController.text,
                            "berat": beratController.text,
                            "harga": hargaController.text,
                            "keterangan": keteranganController.text,

                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Data domba berhasil disimpan",
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );

                          tanggalController.clear();
                          asalController.clear();
                          jumlahController.clear();
                          jenisController.clear();
                          beratController.clear();
                          hargaController.clear();
                          keteranganController.clear();
                        },

                        icon: const Icon(Icons.check_circle),

                        label: Text(
                          "Simpan",

                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),

                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff0E9F4B),

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    /// BUTTON BATAL
                    SizedBox(
                      width: double.infinity,
                      height: 60,

                      child: OutlinedButton.icon(

                        onPressed: () {
                          Navigator.pop(context);
                        },

                        icon: const Icon(Icons.close),

                        label: Text(
                          "Batal",

                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),

                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              const Color(0xff0E9F4B),

                          side: const BorderSide(
                            color: Color(0xff0E9F4B),
                            width: 1.5,
                          ),

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}