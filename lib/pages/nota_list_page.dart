import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../farm_data.dart';
import '../operations_data.dart';
import 'bulk_receipt_page.dart';

class NotaListPage extends StatefulWidget {
  const NotaListPage({super.key});

  @override
  State<NotaListPage> createState() => _NotaListPageState();
}

class _NotaListPageState extends State<NotaListPage> {
  String filter = 'Semua';

  String _rupiah(dynamic raw) {
    final amount = double.tryParse('$raw') ?? 0;
    final digits = amount.round().toString();
    return 'Rp ${digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Riwayat Pembelian & Penjualan')),
    body: ValueListenableBuilder(
      valueListenable: Hive.box('keuanganBox').listenable(),
      builder: (context, _, _) => ValueListenableBuilder(
        valueListenable: Hive.box('penjualanBox').listenable(),
        builder: (context, _, _) {
          final entries = FarmOperationsData.financeEntries()
              .where((row) {
                if (filter == 'Penjualan') return row['sumber'] == 'penjualan';
                if (filter == 'Pembelian') {
                  final source = '${row['sumber'] ?? ''}';
                  return source.startsWith('pembelian_') ||
                      (source.isEmpty &&
                          '${row['kategori'] ?? ''}'
                              .toLowerCase()
                              .contains('pembelian'));
                }
                return true;
              })
              .toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<String>(
                initialValue: filter,
                decoration: const InputDecoration(labelText: 'Filter riwayat'),
                items: const ['Semua', 'Pembelian', 'Penjualan']
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(value),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => filter = value ?? 'Semua'),
              ),
              const SizedBox(height: 12),
              if (entries.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      filter == 'Semua'
                          ? 'Belum ada riwayat transaksi.'
                          : 'Belum ada riwayat $filter.',
                    ),
                  ),
                ),
              for (final entry in entries) _entryTile(entry),
            ],
          );
        },
      ),
    ),
  );

  Widget _entryTile(Map<String, dynamic> entry) {
    final isSale = entry['sumber'] == 'penjualan';
    final amount = _rupiah(entry['jumlah']);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isSale ? Colors.green.shade100 : Colors.orange.shade100,
          child: Icon(
            isSale ? Icons.south_west : Icons.shopping_cart_outlined,
            color: isSale ? Colors.green.shade800 : Colors.orange.shade800,
          ),
        ),
        title: Text(
          isSale
              ? '${entry['kategori']} · ${entry['id']}'
              : '${entry['kategori']} · $amount',
        ),
        subtitle: Text(
          '${entry['tanggal'] ?? '-'}\n${entry['keterangan'] ?? ''}',
        ),
        isThreeLine: true,
        trailing: isSale
            ? const Icon(Icons.receipt_long_outlined)
            : const Text('Pembelian'),
        onTap: isSale ? () => _openReceipt('${entry['id']}') : null,
      ),
    );
  }

  void _openReceipt(String id) {
    final raw = FarmData.penjualan.get(id);
    if (raw == null) return;
    final transaction = FarmData.normalizeSaleTransaction(
      Map<String, dynamic>.from(raw),
      legacyKey: id,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BulkReceiptPage(transaction: transaction),
      ),
    );
  }
}
