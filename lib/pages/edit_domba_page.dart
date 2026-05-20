import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';

class EditDombaPage extends StatefulWidget {

  final Map data;
  final int index;

  const EditDombaPage({
    super.key,
    required this.data,
    required this.index,
  });

  @override
  State<EditDombaPage> createState() =>
      _EditDombaPageState();
}

class _EditDombaPageState
    extends State<EditDombaPage> {

  final dombaBox = Hive.box('dombaBox');

  late TextEditingController tanggalController;
  late TextEditingController asalController;
  late TextEditingController jumlahController;
  late TextEditingController jenisController;
  late TextEditingController beratController;
  late TextEditingController hargaController;
  late TextEditingController keteranganController;

  @override
  void initState() {
    super.initState();

    tanggalController = TextEditingController(
      text: widget.data["tanggal"],
    );

    asalController = TextEditingController(
      text: widget.data["asal"],
    );

    jumlahController = TextEditingController(
      text: widget.data["jumlah"],
    );

    jenisController = TextEditingController(
      text: widget.data["jenis"],
    );

    beratController = TextEditingController(
      text: widget.data["berat"],
    );

    hargaController = TextEditingController(
      text: widget.data["harga"],
    );

    keteranganController = TextEditingController(
      text: widget.data["keterangan"],
    );
  }

  Widget buildInput({
    required String label,
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
            ),

            const SizedBox(width: 8),

            Text(
              label,

              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        TextField(
          controller: controller,

          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xffF4F6F5),

      appBar: AppBar(
        title: Text(
          "Edit Data Domba",

          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),

        backgroundColor: const Color(0xff0E9F4B),
      ),

      body: SingleChildScrollView(

        padding: const EdgeInsets.all(20),

        child: Container(

          padding: const EdgeInsets.all(20),

          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),

          child: Column(
            children: [

              buildInput(
                label: "Tanggal",
                controller: tanggalController,
                icon: Icons.calendar_month,
              ),

              buildInput(
                label: "Asal",
                controller: asalController,
                icon: Icons.location_on,
              ),

              buildInput(
                label: "Jumlah",
                controller: jumlahController,
                icon: Icons.numbers,
              ),

              buildInput(
                label: "Jenis",
                controller: jenisController,
                icon: Icons.pets,
              ),

              buildInput(
                label: "Berat",
                controller: beratController,
                icon: Icons.scale,
              ),

              buildInput(
                label: "Harga",
                controller: hargaController,
                icon: Icons.payments,
              ),

              buildInput(
                label: "Keterangan",
                controller: keteranganController,
                icon: Icons.notes,
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 60,

                child: ElevatedButton.icon(

                  onPressed: () async {

                    await dombaBox.putAt(
                      widget.index,
                      {

                        "tanggal":
                            tanggalController.text,

                        "asal":
                            asalController.text,

                        "jumlah":
                            jumlahController.text,

                        "jenis":
                            jenisController.text,

                        "berat":
                            beratController.text,

                        "harga":
                            hargaController.text,

                        "keterangan":
                            keteranganController.text,
                      },
                    );

                    ScaffoldMessenger.of(context)
                        .showSnackBar(

                      const SnackBar(
                        content:
                            Text("Data berhasil diupdate"),

                        backgroundColor: Colors.green,
                      ),
                    );

                    Navigator.pop(context);
                  },

                  icon: const Icon(Icons.save),

                  label: Text(
                    "Update Data",

                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),

                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xff0E9F4B),

                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}