import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../farm_data.dart';
import '../money_format.dart';
import '../theme/app_theme.dart';
import 'domba_qr_page.dart';

class DombaMasukPage extends StatefulWidget {
  const DombaMasukPage({super.key});

  @override
  State<DombaMasukPage> createState() => _DombaMasukPageState();
}

class _DombaMasukPageState extends State<DombaMasukPage> {
  final tanggalController = TextEditingController();
  final asalController = TextEditingController();
  final jenisController = TextEditingController();
  final beratController = TextEditingController();
  final hargaController = TextEditingController();
  final keteranganController = TextEditingController();
  String kelamin = 'Jantan';

  String kodeDomba = "";
  String qrData = "";
  bool saving = false;

  File? imageFile;

  final ImagePicker picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    generateKode();
  }

  void generateKode() {
    kodeDomba = FarmData.nextCode();
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

  Future pickImage() async {
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      setState(() {
        imageFile = File(pickedFile.path);
      });
    }
  }

  Future<bool> _confirmAnimal(Map<String, String> details) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Konfirmasi data kambing'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pastikan data berikut sudah benar sebelum disimpan:',
                ),
                const SizedBox(height: 12),
                for (final entry in details.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('${entry.key}: ${entry.value}'),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Periksa lagi'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Simpan & buat QR'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _generateQr() async {
    final enteredWeight = double.tryParse(
      beratController.text.trim().replaceAll(',', '.'),
    );
    if (asalController.text.trim().isEmpty ||
        jenisController.text.trim().isEmpty ||
        enteredWeight == null ||
        enteredWeight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Asal, jenis, dan bobot yang valid wajib diisi"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirmed = await _confirmAnimal({
      'Kode': kodeDomba,
      'Tanggal masuk': tanggalController.text.trim().isEmpty
          ? '-'
          : tanggalController.text.trim(),
      'Asal': asalController.text.trim(),
      'Jenis': jenisController.text.trim(),
      'Kelamin': kelamin,
      'Bobot awal': '$enteredWeight kg',
      'Harga beli': hargaController.text.trim().isEmpty
          ? '-'
          : hargaController.text.trim(),
    });
    if (!confirmed || !mounted) return;

    setState(() => saving = true);
    try {
      final row = await FarmData.addAnimal(
        date: tanggalController.text,
        origin: asalController.text,
        kind: jenisController.text,
        sex: kelamin,
        initialWeight: enteredWeight,
        purchasePrice: hargaController.text,
        note: keteranganController.text,
        photoPath: imageFile?.path ?? '',
      );
      if (!mounted) return;
      final code = row['kode'] as String;
      final qr = row['qrCode'] as String;
      setState(() {
        qrData = qr;
        kodeDomba = code;
      });
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DombaQrPage(data: row)),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("QR kambing berhasil dibuat"),
          backgroundColor: AppTheme.forestGreen,
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kambing gagal disimpan: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

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
            Icon(icon, color: AppTheme.forestGreen, size: 20),

            const SizedBox(width: 8),

            Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        TextField(
          controller: controller,
          readOnly: label == "Tanggal Masuk",
          keyboardType: label == 'Harga Beli'
              ? TextInputType.number
              : TextInputType.text,
          inputFormatters: label == 'Harga Beli'
              ? const [ThousandsSeparatorInputFormatter()]
              : null,

          onTap: () async {
            if (label == "Tanggal Masuk") {
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );

              if (pickedDate != null) {
                controller.text =
                    "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
              }
            }
          },

          decoration: InputDecoration(
            hintText: hint,

            hintStyle: GoogleFonts.inter(color: AppTheme.mutedText),

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
      backgroundColor: AppTheme.warmCream,

      appBar: AppBar(
        elevation: 0,

        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },

          icon: const Icon(Icons.arrow_back_ios),
        ),

        title: Text(
          "Tambah Kambing",
          style: GoogleFonts.inter(
            color: AppTheme.deepGreen,
            fontWeight: FontWeight.bold,
          ),
        ),

        centerTitle: true,
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 156,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.deepGreen, AppTheme.forestGreen],
                ),
              ),
              child: const Center(
                child: Icon(Icons.pets_outlined, color: Colors.white, size: 64),
              ),
            ),

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
                    /// KODE
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),

                      decoration: BoxDecoration(
                        color: AppTheme.forestGreen,
                        borderRadius: BorderRadius.circular(22),
                      ),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Kode Kambing",
                            style: GoogleFonts.inter(color: Colors.white70),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            kodeDomba,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    buildInput(
                      label: "Tanggal Masuk",
                      hint: "Pilih tanggal masuk",
                      controller: tanggalController,
                      icon: Icons.calendar_month,
                    ),

                    buildInput(
                      label: "Asal Kambing",
                      hint: "Masukkan asal kambing",
                      controller: asalController,
                      icon: Icons.local_shipping,
                    ),

                    buildInput(
                      label: "Jenis Kambing",
                      hint: "Masukkan jenis kambing",
                      controller: jenisController,
                      icon: Icons.sell,
                    ),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.pets,
                              color: AppTheme.forestGreen,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Kelamin',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
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
                            selected: {kelamin},
                            onSelectionChanged: (value) =>
                                setState(() => kelamin = value.first),
                          ),
                        ),
                        const SizedBox(height: 22),
                      ],
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
                    GestureDetector(
                      onTap: pickImage,

                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),

                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),

                          border: Border.all(
                            color: AppTheme.forestGreen,
                            width: 1.5,
                          ),
                        ),

                        child: Column(
                          children: [
                            if (imageFile != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.file(
                                  imageFile!,
                                  height: 220,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              )
                            else
                              Column(
                                children: [
                                  CircleAvatar(
                                    radius: 35,

                                    backgroundColor: AppTheme.sageGreen,

                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: AppTheme.forestGreen,
                                      size: 35,
                                    ),
                                  ),

                                  const SizedBox(height: 15),

                                  Text(
                                    "Tap untuk tambah foto",

                                    style: GoogleFonts.inter(
                                      color: AppTheme.forestGreen,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),

                                  const SizedBox(height: 5),

                                  Text(
                                    "Ambil dari galeri HP",
                                    style: GoogleFonts.inter(
                                      color: AppTheme.mutedText,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    /// BUTTON QR
                    SizedBox(
                      width: double.infinity,
                      height: 60,

                      child: ElevatedButton.icon(
                        onPressed: saving ? null : _generateQr,

                        icon: saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.qr_code),

                        label: Text(
                          saving ? "Menyimpan..." : "Generate QR",

                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),

                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.forestGreen,

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    /// QR RESULT
                    if (qrData.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(25),

                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),

                        child: Column(
                          children: [
                            Text(
                              "QR Kambing",
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),

                            const SizedBox(height: 20),

                            QrImageView(
                              data: qrData,
                              version: QrVersions.auto,
                              size: 220,
                            ),

                            const SizedBox(height: 15),

                            Text(
                              kodeDomba,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                                color: AppTheme.forestGreen,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 20),
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
