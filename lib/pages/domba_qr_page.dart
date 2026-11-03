import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';

class DombaQrPage extends StatefulWidget {
  const DombaQrPage({super.key, required this.data});
  final Map data;

  @override
  State<DombaQrPage> createState() => _DombaQrPageState();
}

class _DombaQrPageState extends State<DombaQrPage> {
  final ScreenshotController capture = ScreenshotController();
  bool busy = false;

  Future<Uint8List> _captureQr() async {
    final bytes = await capture.capture();
    if (bytes == null) throw StateError('QR tidak berhasil dibuat.');
    return bytes;
  }

  Future<void> save() async {
    setState(() => busy = true);
    try {
      final bytes = await _captureQr();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${widget.data['kode']}.png');
      await file.writeAsBytes(bytes, flush: true);
      final result = await GallerySaver.saveImage(file.path);
      if (result != true) throw StateError('QR gagal disimpan ke galeri.');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('QR disimpan ke galeri')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan QR: $error')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> printPdf() async {
    setState(() => busy = true);
    try {
      final bytes = await _captureQr();
      final document = pw.Document();
      document.addPage(
        pw.Page(
          build: (_) => pw.Center(
            child: pw.Image(pw.MemoryImage(bytes), width: 350, height: 420),
          ),
        ),
      );
      await Printing.layoutPdf(
        onLayout: (_) async => document.save(),
        name: '${widget.data['kode']}-QR.pdf',
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyiapkan PDF QR: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('QR Domba')),
    body: Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Screenshot(
              controller: capture,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text(
                      'NGAPAK NGAPIKI FARM',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 18),
                    QrImageView(data: '${widget.data['qrCode']}', size: 230),
                    Text(
                      '${widget.data['qrCode']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('${widget.data['jenis']} • ${widget.data['kelamin']}'),
                    Text(
                      '${widget.data['bobotTerakhir'] ?? widget.data['berat']} KG',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: busy ? null : save,
              icon: const Icon(Icons.save_alt),
              label: const Text('Simpan QR'),
            ),
            OutlinedButton.icon(
              onPressed: busy ? null : printPdf,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Print / Simpan PDF'),
            ),
            OutlinedButton.icon(
              onPressed: busy ? null : () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Kembali'),
            ),
          ],
        ),
      ),
    ),
  );
}
