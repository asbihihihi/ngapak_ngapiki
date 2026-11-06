import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'bulk_receipt_page.dart';
import '../farm_data.dart';
import '../money_format.dart';
import '../operations_data.dart';
import '../theme/app_theme.dart';

class InputPenjualanPage extends StatefulWidget {
  final Map data;
  final int index;

  const InputPenjualanPage({
    super.key,
    required this.data,
    required this.index,
  });

  @override
  State<InputPenjualanPage> createState() => _InputPenjualanPageState();
}

class _InputPenjualanPageState extends State<InputPenjualanPage> {
  final namaController = TextEditingController();

  final tanggalController = TextEditingController(
    text: DateTime.now().toIso8601String().substring(0, 10),
  );

  final asalController = TextEditingController();

  final waController = TextEditingController();

  final beratController = TextEditingController();

  final hargaController = TextEditingController();

  final mapsController = TextEditingController();

  final kondisiController = TextEditingController();

  File? imageFile;
  bool saving = false;

  final picker = ImagePicker();

  @override
  void dispose() {
    namaController.dispose();
    tanggalController.dispose();
    asalController.dispose();
    waController.dispose();
    beratController.dispose();
    hargaController.dispose();
    mapsController.dispose();
    kondisiController.dispose();
    super.dispose();
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

  Future<void> _saveSale() async {
    final weight = double.tryParse(
      beratController.text.trim().replaceAll(',', '.'),
    );
    final price = FarmOperationsData.parseMoney(hargaController.text);
    if (namaController.text.trim().isEmpty ||
        weight == null ||
        weight <= 0 ||
        price == null ||
        price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Isi nama pembeli, bobot, dan harga yang valid.'),
        ),
      );
      return;
    }
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Konfirmasi penjualan'),
            content: Text(
              'Tandai kambing ${widget.data['kode']} sebagai terjual kepada '
              '${namaController.text.trim()} dengan bobot ${weight.toString()} '
              'kg dan harga Rp ${price.toString()}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Periksa lagi'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Konfirmasi jual'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;
    setState(() => saving = true);
    try {
      final id = await FarmData.sellTransaction(
        indices: [widget.index],
        date: tanggalController.text,
        buyer: namaController.text.trim(),
        whatsapp: waController.text.trim(),
        destination: asalController.text.trim(),
        note: kondisiController.text.trim(),
        weights: {widget.index: weight},
        prices: {widget.index: price.toString()},
        pricingMode: 'per ekor',
        metadata: {
          'maps': mapsController.text.trim(),
          'kondisi': kondisiController.text.trim(),
          'fotoJual': imageFile?.path ?? '',
        },
      );
      final transaction = Map<String, dynamic>.from(FarmData.penjualan.get(id));
      if (!mounted) return;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BulkReceiptPage(transaction: transaction),
        ),
      );
    } catch (error) {
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Penjualan gagal: $error')));
      }
    }
  }

  Widget input(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),

      child: TextField(
        controller: controller,
        keyboardType: label.contains('Harga')
            ? TextInputType.number
            : TextInputType.text,
        inputFormatters: label.contains('Harga')
            ? const [ThousandsSeparatorInputFormatter()]
            : null,

        decoration: InputDecoration(
          labelText: label,

          filled: true,
          fillColor: Colors.white,

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),

            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.warmCream,

      appBar: AppBar(
        title: Text(
          "Penjualan Kambing",

          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: AppTheme.deepGreen,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Container(
                width: double.infinity,

                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: Colors.white,

                  borderRadius: BorderRadius.circular(25),
                ),

                child: Column(
                  children: [
                    Text(
                      widget.data["kode"],

                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.forestGreen,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      widget.data["jenis"],

                      style: GoogleFonts.inter(fontSize: 16),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              TextField(
                controller: tanggalController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Tanggal Jual',
                  filled: true,
                  fillColor: Colors.white,
                ),
                onTap: () async {
                  final selected = await showDatePicker(
                    context: context,
                    initialDate:
                        DateTime.tryParse(tanggalController.text) ??
                        DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (selected != null)
                    tanggalController.text = selected
                        .toIso8601String()
                        .substring(0, 10);
                },
              ),

              const SizedBox(height: 18),

              input("Nama Pembeli", namaController),

              input("Asal Pembeli", asalController),

              input("No WhatsApp", waController),

              input("Bobot Terjual", beratController),

              input("Harga Terjual", hargaController),

              input("Link Google Maps", mapsController),

              input("Kondisi Kambing", kondisiController),

              GestureDetector(
                onTap: pickImage,

                child: Container(
                  height: 180,
                  width: double.infinity,

                  decoration: BoxDecoration(
                    color: Colors.white,

                    borderRadius: BorderRadius.circular(20),

                    border: Border.all(color: AppTheme.oliveGreen),
                  ),

                  child: imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),

                          child: Image.file(imageFile!, fit: BoxFit.cover),
                        )
                      : const Center(
                          child: Icon(
                            Icons.camera_alt,
                            size: 40,
                            color: AppTheme.forestGreen,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 60,

                child: ElevatedButton(
                  onPressed: saving ? null : _saveSale,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.forestGreen,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),

                  child: Text(
                    saving ? "MENYIMPAN..." : "TANDAI TERJUAL",

                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,

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
