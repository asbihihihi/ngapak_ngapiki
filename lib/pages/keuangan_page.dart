import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../money_format.dart';
import '../operations_data.dart';

class KeuanganPage extends StatefulWidget {
  const KeuanganPage({super.key});

  @override
  State<KeuanganPage> createState() => _KeuanganPageState();
}

class _KeuanganPageState extends State<KeuanganPage> {
  String type = 'Semua';
  DateTime? from;
  DateTime? through;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Keuangan'),
        actions: [
          IconButton(
            tooltip: 'Tambah transaksi',
            onPressed: _addEntry,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: FarmOperationsData.ledger.listenable(),
        builder: (context, _, _) => ValueListenableBuilder(
          valueListenable: FarmOperationsData.goods.listenable(),
          builder: (context, _, _) => ValueListenableBuilder(
            valueListenable: FarmOperationsData.movements.listenable(),
            builder: (context, _, _) => ValueListenableBuilder(
              valueListenable: _salesListenable(),
              builder: (context, _, _) {
                final summary = FarmOperationsData.financeSummary(
                  from: from,
                  through: through,
                );
                final entries = FarmOperationsData.financeEntries(
                  type: type,
                  from: from,
                  through: through,
                );
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _summaryCard(
                      'Pemasukan',
                      _rupiah(summary['pemasukan']!),
                      Colors.green,
                    ),
                    _summaryCard(
                      'Pengeluaran',
                      _rupiah(summary['pengeluaran']!),
                      Colors.red,
                    ),
                    _summaryCard(
                      'Selisih',
                      _rupiah(summary['selisih']!),
                      Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: type,
                      decoration: const InputDecoration(
                        labelText: 'Jenis transaksi',
                      ),
                      items: const ['Semua', 'Pemasukan', 'Pengeluaran']
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => type = value ?? 'Semua'),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _dateFilter(
                            'Dari tanggal',
                            from,
                            (date) => setState(() => from = date),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _dateFilter(
                            'Sampai tanggal',
                            through,
                            (date) => setState(() => through = date),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Hapus filter tanggal',
                          onPressed: from == null && through == null
                              ? null
                              : () => setState(() {
                                  from = null;
                                  through = null;
                                }),
                          icon: const Icon(Icons.clear),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Riwayat transaksi (${entries.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (entries.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('Belum ada transaksi pada rentang ini.'),
                        ),
                      ),
                    for (final row in entries) _entryTile(row),
                  ],
                );
              },
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addEntry,
        icon: const Icon(Icons.add),
        label: const Text('Catat transaksi'),
      ),
    );
  }

  // A listener on the sales box keeps summaries fresh after a sale is posted.
  ValueListenable<Box> _salesListenable() =>
      Hive.box('penjualanBox').listenable();

  Widget _summaryCard(String title, String amount, Color color) => Card(
    child: ListTile(
      leading: Icon(Icons.account_balance_wallet_outlined, color: color),
      title: Text(title),
      trailing: Text(
        amount,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    ),
  );

  Widget _dateFilter(
    String label,
    DateTime? value,
    ValueChanged<DateTime?> onChanged,
  ) => OutlinedButton.icon(
    onPressed: () async {
      final picked = await showDatePicker(
        context: context,
        initialDate: value ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (picked != null) onChanged(picked);
    },
    icon: const Icon(Icons.calendar_month, size: 18),
    label: Text(value == null ? label : _date(value)),
  );

  Widget _entryTile(Map<String, dynamic> row) {
    final incoming = row['jenis'] == 'Pemasukan';
    return Card(
      child: ListTile(
        leading: Icon(
          incoming ? Icons.south_west : Icons.north_east,
          color: incoming ? Colors.green : Colors.red,
        ),
        title: Text(
          '${row['kategori']} · ${_rupiah((row['jumlah'] as num?)?.toDouble() ?? double.tryParse('${row['jumlah']}') ?? 0)}',
        ),
        subtitle: Text('${row['tanggal'] ?? '-'}\n${row['keterangan'] ?? ''}'),
        trailing: Text(incoming ? 'Masuk' : 'Keluar'),
      ),
    );
  }

  Future<void> _addEntry() async {
    final amount = TextEditingController();
    final note = TextEditingController();
    final date = TextEditingController(text: _date(DateTime.now()));
    var entryType = 'Pengeluaran';
    var category = 'Operasional';
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, refresh) {
          final categories = entryType == 'Pemasukan'
              ? const ['Pemasukan lain']
              : const [
                  'Pembelian kambing',
                  'Pakan',
                  'Obat-obatan',
                  'Operasional',
                  'Perlengkapan',
                  'Lainnya',
                ];
          if (!categories.contains(category)) category = categories.first;
          return AlertDialog(
            title: const Text('Catat transaksi keuangan'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: entryType,
                      decoration: const InputDecoration(labelText: 'Jenis'),
                      items: const ['Pemasukan', 'Pengeluaran']
                          .map(
                            (v) => DropdownMenuItem(value: v, child: Text(v)),
                          )
                          .toList(),
                      onChanged: (value) => refresh(() {
                        entryType = value ?? entryType;
                        category = entryType == 'Pemasukan'
                            ? 'Pemasukan lain'
                            : 'Operasional';
                      }),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: const InputDecoration(labelText: 'Kategori'),
                      items: categories
                          .map(
                            (v) => DropdownMenuItem(value: v, child: Text(v)),
                          )
                          .toList(),
                      onChanged: (value) =>
                          refresh(() => category = value ?? category),
                    ),
                    TextFormField(
                      controller: amount,
                      keyboardType: TextInputType.number,
                      inputFormatters: const [
                        ThousandsSeparatorInputFormatter(),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Nominal (Rp)',
                      ),
                      validator: (value) {
                        final parsed = FarmOperationsData.parseMoney(
                          value ?? '',
                        );
                        return parsed == null || parsed <= 0
                            ? 'Nominal harus lebih dari nol.'
                            : null;
                      },
                    ),
                    TextFormField(
                      controller: date,
                      readOnly: true,
                      decoration: const InputDecoration(labelText: 'Tanggal'),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) date.text = _date(picked);
                      },
                    ),
                    TextFormField(
                      controller: note,
                      decoration: const InputDecoration(
                        labelText: 'Keterangan',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState!.validate())
                    Navigator.pop(dialogContext, true);
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
    try {
      if (result == true) {
        final parsed = FarmOperationsData.parseMoney(amount.text);
        if (parsed == null) throw ArgumentError('Nominal tidak valid.');
        await FarmOperationsData.addFinanceEntry(
          type: entryType,
          category: category,
          amount: parsed,
          date: date.text,
          note: note.text,
        );
        if (mounted) _message('Transaksi keuangan berhasil dicatat.');
      }
    } catch (error) {
      if (mounted) _message('Transaksi gagal disimpan: $error');
    } finally {
      amount.dispose();
      note.dispose();
      date.dispose();
    }
  }

  String _date(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  String _rupiah(double amount) {
    final digits = amount.round().toString();
    return 'Rp ${digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}';
  }

  void _message(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}
