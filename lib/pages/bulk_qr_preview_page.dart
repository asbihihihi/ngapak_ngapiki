import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart' as pdf;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';

class BulkQrPreviewPage extends StatefulWidget {
  const BulkQrPreviewPage({
    super.key,
    required this.batchId,
    required this.rows,
  });
  final String batchId;
  final List<Map<String, dynamic>> rows;
  @override
  State<BulkQrPreviewPage> createState() => _BulkQrPreviewPageState();
}

class _BulkQrPreviewPageState extends State<BulkQrPreviewPage> {
  bool busy = false;
  final capture = ScreenshotController();

  Widget qrCard(Map<String, dynamic> row, {double size = 150}) => Container(
    width: 250,
    padding: const EdgeInsets.all(14),
    color: Colors.white,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'NGAPAK NGAPIKI FARM',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        QrImageView(
          data: '${row['qrCode']}',
          size: size,
          backgroundColor: Colors.white,
        ),
        const SizedBox(height: 6),
        Text(
          '${row['kode']}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text('${row['jenis']} - ${row['kelamin']}'),
        Text('${row['bobotAwal']} KG'),
      ],
    ),
  );

  Future<Uint8List> imageFor(Map<String, dynamic> row) =>
      capture.captureFromWidget(
        qrCard(row),
        pixelRatio: 3,
        context: context,
        targetSize: const Size(250, 270),
        delay: const Duration(milliseconds: 100),
      );

  Future<void> saveAll() async {
    setState(() => busy = true);
    var saved = 0;
    try {
      final dir = await getTemporaryDirectory();
      for (final row in widget.rows) {
        final bytes = await imageFor(row);
        final file = File('${dir.path}/${row['qrCode']}.png');
        await file.writeAsBytes(bytes, flush: true);
        final result = await GallerySaver.saveImage(file.path);
        if (result == true) saved++;
      }
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$saved dari ${widget.rows.length} QR berhasil disimpan ke galeri.',
            ),
          ),
        );
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan QR ke galeri: $error')),
        );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> printAll() async {
    setState(() => busy = true);
    try {
      final images = <Uint8List>[];
      for (final row in widget.rows) {
        images.add(await imageFor(row));
      }
      final doc = pw.Document();
      for (var pageStart = 0; pageStart < images.length; pageStart += 12) {
        final pageImages = images.skip(pageStart).take(12).toList();
        final rows = <pw.Widget>[];
        for (var offset = 0; offset < pageImages.length; offset += 3) {
          final rowImages = pageImages.skip(offset).take(3).toList();
          rows.add(
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                for (final bytes in rowImages)
                  pw.Container(
                    width: 170,
                    margin: const pw.EdgeInsets.only(right: 10, bottom: 10),
                    padding: const pw.EdgeInsets.all(5),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: const pdf.PdfColor(0.75, 0.75, 0.75),
                      ),
                    ),
                    child: pw.Image(
                      pw.MemoryImage(bytes),
                      fit: pw.BoxFit.contain,
                    ),
                  ),
              ],
            ),
          );
        }
        doc.addPage(
          pw.Page(
            pageFormat: pdf.PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(22),
            build: (_) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Label QR Domba · ${widget.batchId}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                ...rows,
              ],
            ),
          ),
        );
      }
      await Printing.layoutPdf(
        onLayout: (_) async => doc.save(),
        name: '${widget.batchId}-QR.pdf',
      );
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyiapkan PDF QR: $error')),
        );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('QR Batch - ${widget.batchId}')),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Text(
            '${widget.rows.length} QR berhasil dibuat',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: widget.rows.length,
            itemBuilder: (_, i) => Center(
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: qrCard(widget.rows[i]),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: busy ? null : printAll,
                    icon: const Icon(Icons.print),
                    label: const Text('Print Semua QR'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: busy ? null : saveAll,
                    icon: const Icon(Icons.save_alt),
                    label: const Text('Simpan Semua QR'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
