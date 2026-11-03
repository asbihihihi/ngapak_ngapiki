import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class BulkReceiptPage extends StatelessWidget {
  const BulkReceiptPage({super.key, required this.transaction});
  final Map<String, dynamic> transaction;

  List<Map<String, dynamic>> get grouped {
    final result = <String, Map<String, dynamic>>{};
    final items = (transaction['items'] as List?) ?? const [];
    for (final raw in items) {
      final item = Map<String, dynamic>.from(raw as Map);
      final kind = '${item['jenis'] ?? 'Domba'}';
      final current = result.putIfAbsent(
        kind,
        () => {'jenis': kind, 'jumlah': 0, 'total': 0.0, 'berat': 0.0},
      );
      current['jumlah'] = (current['jumlah'] as int) + 1;
      current['total'] =
          (current['total'] as double) +
          (double.tryParse('${item['hargaJual'] ?? 0}') ?? 0);
      current['berat'] =
          (current['berat'] as double) +
          (double.tryParse('${item['beratJual'] ?? 0}') ?? 0);
    }
    return result.values.toList();
  }

  Map<String, int> get sexCounts {
    final counts = <String, int>{};
    for (final raw in (transaction['items'] as List?) ?? const []) {
      final item = Map<String, dynamic>.from(raw as Map);
      final sex = '${item['kelamin'] ?? 'Tidak diketahui'}';
      counts[sex] = (counts[sex] ?? 0) + 1;
    }
    return counts;
  }

  List<Map<String, dynamic>> get animals =>
      ((transaction['items'] as List?) ?? const [])
          .map((raw) => Map<String, dynamic>.from(raw as Map))
          .toList();

  List<String> _healthLines(Map<String, dynamic> item) {
    final history = (item['riwayatKesehatan'] as List?) ?? const [];
    if (history.isEmpty) {
      return ['${item['kode']}: Belum ada riwayat pemeriksaan'];
    }
    return history.map((entry) {
      final row = Map<String, dynamic>.from(entry as Map);
      final note = '${row['catatan'] ?? ''}'.trim();
      return '${item['kode']}: ${row['tanggal'] ?? '-'} · ${row['nama'] ?? '-'}'
          '${note.isEmpty ? '' : ' · $note'}';
    }).toList();
  }

  double get total => double.tryParse('${transaction['total'] ?? 0}') ?? 0;
  double get totalWeight =>
      double.tryParse('${transaction['totalBerat'] ?? 0}') ?? 0;
  String money(double amount) {
    final digits = amount.round().toString();
    final grouped = digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
    return 'Rp $grouped';
  }

  Future<void> printReceipt() async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(24),
        build: (_) => [
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  'NGAPAK NGAPIKI FARM',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text('STRUK PENJUALAN'),
              ],
            ),
          ),
          pw.SizedBox(height: 18),
          pw.Text('Kode Transaksi: ${transaction['transaksiId']}'),
          if ('${transaction['namaBatch'] ?? ''}'.isNotEmpty)
            pw.Text(
              'Batch: ${transaction['namaBatch']} · ${transaction['kodeBatch'] ?? ''}',
            ),
          pw.Text('Tanggal: ${transaction['tanggal']}'),
          pw.SizedBox(height: 12),
          pw.Text('Pembeli: ${transaction['namaPembeli']}'),
          pw.Text('WhatsApp: ${transaction['whatsapp']}'),
          pw.Text('Alamat: ${transaction['tujuan']}'),
          pw.Divider(),
          for (final item in grouped)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 5),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          '${item['jenis']}',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text('${item['jumlah']} ekor · ${item['berat']} kg'),
                      ],
                    ),
                  ),
                  pw.Text(money(item['total'] as double)),
                ],
              ),
            ),
          pw.Divider(),
          pw.Text('Total Domba: ${transaction['jumlahDomba']} ekor'),
          pw.Text(
            'Jenis kelamin: ${sexCounts.entries.map((entry) => '${entry.key} ${entry.value}').join(' · ')}',
          ),
          pw.Text('Total Berat: ${totalWeight.toStringAsFixed(1)} kg'),
          if (transaction['modeHarga'] == 'per kg' && totalWeight > 0)
            pw.Text('Harga/kg rata-rata: ${money(total / totalWeight)}'),
          pw.Text('Model Harga: ${transaction['modeHarga']}'),
          pw.SizedBox(height: 8),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'TOTAL  ${money(total)}',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
          ),
          if ('${transaction['catatan'] ?? ''}'.isNotEmpty)
            pw.Text('Catatan: ${transaction['catatan']}'),
          pw.SizedBox(height: 12),
          pw.Text(
            'RIWAYAT KESEHATAN DOMBA',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          for (final item in animals)
            for (final line in _healthLines(item)) pw.Text(line),
        ],
      ),
    );
    await Printing.layoutPdf(
      onLayout: (_) async => doc.save(),
      name: '${transaction['transaksiId']}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Struk Penjualan')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Column(
                    children: [
                      Text(
                        'NGAPAK NGAPIKI FARM',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 19,
                        ),
                      ),
                      Text('STRUK PENJUALAN'),
                    ],
                  ),
                ),
                const Divider(height: 28),
                Text('Kode Transaksi: ${transaction['transaksiId']}'),
                if ('${transaction['namaBatch'] ?? ''}'.isNotEmpty)
                  Text(
                    'Batch: ${transaction['namaBatch']} · ${transaction['kodeBatch'] ?? ''}',
                  ),
                Text('Tanggal: ${transaction['tanggal']}'),
                const SizedBox(height: 12),
                Text('Pembeli: ${transaction['namaPembeli']}'),
                Text('WhatsApp: ${transaction['whatsapp']}'),
                Text('Alamat: ${transaction['tujuan']}'),
                const Divider(height: 28),
                for (final item in grouped)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${item['jenis']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${item['jumlah']} ekor - ${item['berat']} kg',
                              ),
                            ],
                          ),
                        ),
                        Text(money(item['total'] as double)),
                      ],
                    ),
                  ),
                const Divider(height: 28),
                Text('Total Domba: ${transaction['jumlahDomba']} ekor'),
                Text(
                  'Jenis kelamin: ${sexCounts.entries.map((entry) => '${entry.key} ${entry.value}').join(' · ')}',
                ),
                Text('Total Berat: ${totalWeight.toStringAsFixed(1)} KG'),
                if (transaction['modeHarga'] == 'per kg' && totalWeight > 0)
                  Text('Harga/kg rata-rata: ${money(total / totalWeight)}'),
                Text('Model Harga: ${transaction['modeHarga']}'),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'TOTAL  ${money(total)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                if ('${transaction['catatan'] ?? ''}'.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text('Catatan: ${transaction['catatan']}'),
                ],
                const Divider(height: 28),
                const Text(
                  'Riwayat kesehatan domba',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                for (final item in animals)
                  for (final line in _healthLines(item))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(line),
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: printReceipt,
          icon: const Icon(Icons.print),
          label: const Text('PRINT / SIMPAN PDF'),
        ),
      ],
    ),
  );
}
