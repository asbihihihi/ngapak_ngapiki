import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../money_format.dart';

import 'input_penjualan_page.dart';
import '../farm_data.dart';

class EditDombaPage extends StatefulWidget {
  final Map data;
  final int index;

  const EditDombaPage({super.key, required this.data, required this.index});

  @override
  State<EditDombaPage> createState() => _EditDombaPageState();
}

class _EditDombaPageState extends State<EditDombaPage> {
  final ScreenshotController screenshotController = ScreenshotController();

  late TextEditingController tanggalController;
  late TextEditingController asalController;
  late TextEditingController jenisController;
  late TextEditingController beratController;
  late TextEditingController hargaController;
  late TextEditingController keteranganController;

  String kodeDomba = "";
  String sex = 'Jantan';
  bool saving = false;

  @override
  void initState() {
    super.initState();

    kodeDomba = widget.data["kode"] ?? "-";

    tanggalController = TextEditingController(
      text: widget.data["tanggal"] ?? "",
    );

    asalController = TextEditingController(text: widget.data["asal"] ?? "");

    jenisController = TextEditingController(text: widget.data["jenis"] ?? "");

    beratController = TextEditingController(text: widget.data["berat"] ?? "");

    hargaController = TextEditingController(
      text: formatThousands('${widget.data["hargaBeli"] ?? widget.data["harga"] ?? ""}'),
    );
    sex = widget.data['kelamin'] == 'Betina' ? 'Betina' : 'Jantan';

    keteranganController = TextEditingController(
      text: widget.data["keterangan"] ?? "",
    );
  }

  @override
  void dispose() {
    tanggalController.dispose();
    asalController.dispose();
    jenisController.dispose();
    beratController.dispose();
    hargaController.dispose();
    keteranganController.dispose();
    super.dispose();
  }

  Widget buildInput({
    required String label,
    required TextEditingController controller,
    required IconData icon,
  }) {
    final isSold = FarmData.isSold(widget.data);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),

        const SizedBox(height: 10),

        TextField(
          enabled: !isSold,

          controller: controller,
          keyboardType: label == 'Harga'
              ? TextInputType.number
              : TextInputType.text,
          inputFormatters: label == 'Harga'
              ? const [ThousandsSeparatorInputFormatter()]
              : null,

          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xff0E9F4B)),

            filled: true,

            fillColor: isSold ? Colors.grey.shade200 : Colors.white,

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

  Future<void> saveQrToGallery() async {
    await Permission.storage.request();
    await Permission.photos.request();

    Uint8List? image = await screenshotController.capture();

    if (image == null) return;

    final directory = await getTemporaryDirectory();

    final imagePath = "${directory.path}/$kodeDomba.png";

    File file = File(imagePath);

    await file.writeAsBytes(image);

    await GallerySaver.saveImage(file.path);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.green,

        content: Text("QR berhasil disimpan ke galeri 📸"),
      ),
    );
  }

  Future<void> printPdf() async {
    Uint8List? image = await screenshotController.capture();

    if (image == null) return;

    final pdf = pw.Document();

    final imageProvider = pw.MemoryImage(image);

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,

              children: [
                pw.Text(
                  "QR Domba",

                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),

                pw.SizedBox(height: 20),

                pw.Image(imageProvider, width: 250, height: 250),

                pw.SizedBox(height: 20),

                pw.Text(
                  kodeDomba,

                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Future<bool> _confirmUpdate(double weight) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Konfirmasi perubahan'),
          content: Text(
            'Simpan perubahan data domba $kodeDomba dengan bobot '
            '${weight.toStringAsFixed(1)} kg?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Periksa lagi'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Simpan perubahan'),
            ),
          ],
        ),
      ) ??
      false;

  void showOption() {
    showModalBottomSheet(
      context: context,

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),

      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              Text(
                "Pilih Aksi QR",

                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),

              const SizedBox(height: 25),

              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xffE8F5E9),

                  child: Icon(Icons.image, color: Colors.green),
                ),

                title: Text(
                  "Simpan ke Galeri",

                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),

                onTap: () async {
                  Navigator.pop(context);

                  await saveQrToGallery();
                },
              ),

              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xffFFEBEE),

                  child: Icon(Icons.picture_as_pdf, color: Colors.red),
                ),

                title: Text(
                  "Print PDF",

                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),

                onTap: () async {
                  Navigator.pop(context);

                  await printPdf();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSold = FarmData.isSold(widget.data);

    return Scaffold(
      backgroundColor: const Color(0xffF4F6F5),

      appBar: AppBar(
        backgroundColor: const Color(0xff0E9F4B),

        elevation: 0,

        title: Text(
          "Edit Domba",

          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            Screenshot(
              controller: screenshotController,

              child: Container(
                width: double.infinity,

                padding: const EdgeInsets.all(25),

                decoration: BoxDecoration(
                  color: Colors.white,

                  borderRadius: BorderRadius.circular(30),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),

                      blurRadius: 10,
                    ),
                  ],
                ),

                child: Column(
                  children: [
                    Text(
                      "QR Domba",

                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,

                        fontSize: 22,
                      ),
                    ),

                    const SizedBox(height: 20),

                    QrImageView(data: kodeDomba, size: 220),

                    const SizedBox(height: 20),

                    Text(
                      kodeDomba,

                      style: GoogleFonts.poppins(
                        color: const Color(0xff0E9F4B),

                        fontWeight: FontWeight.bold,

                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 55,

              child: ElevatedButton.icon(
                onPressed: showOption,

                icon: const Icon(Icons.print),

                label: Text(
                  "Print / Simpan QR",

                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff0E9F4B),

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            Container(
              padding: const EdgeInsets.all(24),

              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius: BorderRadius.circular(30),
              ),

              child: Column(
                children: [
                  /// STATUS
                  Container(
                    width: double.infinity,

                    padding: const EdgeInsets.all(16),

                    decoration: BoxDecoration(
                      color: isSold
                          ? Colors.red.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),

                      borderRadius: BorderRadius.circular(20),
                    ),

                    child: Row(
                      children: [
                        Icon(
                          isSold ? Icons.sell : Icons.pets,

                          color: isSold ? Colors.red : Colors.green,
                        ),

                        const SizedBox(width: 10),

                        Text(
                          isSold ? "Domba Sudah Terjual" : "Domba Aktif",

                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,

                            color: isSold ? Colors.red : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

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
                    label: "Jenis",
                    controller: jenisController,
                    icon: Icons.pets,
                  ),

                  buildInput(
                    label: "Berat",
                    controller: beratController,
                    icon: Icons.scale,
                  ),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Kelamin',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'Jantan',
                          label: Text('Jantan'),
                          icon: Icon(Icons.male),
                        ),
                        ButtonSegment(
                          value: 'Betina',
                          label: Text('Betina'),
                          icon: Icon(Icons.female),
                        ),
                      ],
                      selected: {sex},
                      onSelectionChanged: isSold
                          ? null
                          : (selection) =>
                                setState(() => sex = selection.first),
                    ),
                  ),
                  const SizedBox(height: 20),

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

                  const SizedBox(height: 10),

                  /// BUTTON JUAL
                  if (!isSold)
                    SizedBox(
                      width: double.infinity,
                      height: 60,

                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,

                            MaterialPageRoute(
                              builder: (context) => InputPenjualanPage(
                                data: widget.data,

                                index: widget.index,
                              ),
                            ),
                          );
                        },

                        icon: const Icon(Icons.sell),

                        label: Text(
                          "Jual Domba",

                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,

                            fontSize: 18,
                          ),
                        ),

                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),

                  if (!isSold) const SizedBox(height: 15),

                  /// BUTTON UPDATE
                  if (!isSold)
                    SizedBox(
                      width: double.infinity,
                      height: 60,

                      child: ElevatedButton.icon(
                        onPressed: saving
                            ? null
                            : () async {
                                final updatedWeight = double.tryParse(
                                  beratController.text.trim().replaceAll(
                                    ',',
                                    '.',
                                  ),
                                );
                                if (asalController.text.trim().isEmpty ||
                                    jenisController.text.trim().isEmpty ||
                                    updatedWeight == null ||
                                    updatedWeight <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Asal, jenis, dan bobot positif wajib diisi.',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                if (!await _confirmUpdate(updatedWeight) ||
                                    !context.mounted) {
                                  return;
                                }
                                setState(() => saving = true);
                                try {
                                  await FarmData.updateAnimal(
                                    index: widget.index,
                                    date: tanggalController.text,
                                    origin: asalController.text,
                                    kind: jenisController.text,
                                    sex: sex,
                                    weightValue: updatedWeight,
                                    purchasePrice: hargaController.text,
                                    note: keteranganController.text,
                                  );
                                } catch (error) {
                                  if (context.mounted) {
                                    setState(() => saving = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Data gagal diperbarui: $error',
                                        ),
                                      ),
                                    );
                                  }
                                  return;
                                }

                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    backgroundColor: Colors.green,

                                    content: Text("Data berhasil diupdate ✅"),
                                  ),
                                );

                                Navigator.pop(context);
                              },

                        icon: saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save),

                        label: Text(
                          saving ? "Menyimpan..." : "Update Data",

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

                  if (isSold)
                    Container(
                      width: double.infinity,

                      padding: const EdgeInsets.all(20),

                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.08),

                        borderRadius: BorderRadius.circular(20),
                      ),

                      child: Column(
                        children: [
                          const Icon(Icons.lock, color: Colors.red, size: 45),

                          const SizedBox(height: 10),

                          Text(
                            "Data Sudah Dikunci",

                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,

                              fontSize: 18,

                              color: Colors.red,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Text(
                            "Domba sudah terjual dan tidak bisa diedit lagi 🐏",

                            textAlign: TextAlign.center,

                            style: GoogleFonts.poppins(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
