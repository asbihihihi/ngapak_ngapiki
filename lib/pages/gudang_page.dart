import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../money_format.dart';
import '../operations_data.dart';

class GudangPage extends StatefulWidget {
  const GudangPage({super.key});

  @override
  State<GudangPage> createState() => _GudangPageState();
}

class _GudangPageState extends State<GudangPage> {
  final search = TextEditingController();
  String category = 'Semua';

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goods = FarmOperationsData.goods;
    final movements = FarmOperationsData.movements;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Gudang'),
        actions: [
          IconButton(
            tooltip: 'Tambah barang',
            onPressed: () => _editItem(context),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: goods.listenable(),
        builder: (context, _, _) => ValueListenableBuilder(
          valueListenable: movements.listenable(),
          builder: (context, _, _) {
            final items = goods.values
                .map((row) => Map<String, dynamic>.from(row))
                .where(
                  (row) => category == 'Semua' || row['kategori'] == category,
                )
                .where(
                  (row) => '${row['nama']} ${row['id']} ${row['kategori']}'
                      .toLowerCase()
                      .contains(search.text.toLowerCase()),
                )
                .toList();
            final lowStock = goods.values.where((raw) {
              final row = Map<String, dynamic>.from(raw);
              return FarmOperationsData.stockFor(row['id']) <=
                  (double.tryParse('${row['batasMinimum']}') ?? 0);
            }).length;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _summary(
                        'Jenis barang',
                        '${goods.length}',
                        Icons.inventory_2_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _summary(
                        'Stok minimum',
                        '$lowStock',
                        Icons.warning_amber_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: search,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    labelText: 'Cari barang',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Kategori'),
                  items: const ['Semua', 'Pakan', 'Obat-obatan', 'Perlengkapan']
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => category = value ?? 'Semua'),
                ),
                const SizedBox(height: 12),
                if (items.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Belum ada barang yang sesuai. Tambahkan barang untuk memulai.',
                      ),
                    ),
                  ),
                for (final item in items) _goodsCard(context, item),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editItem(context),
        icon: const Icon(Icons.add),
        label: const Text('Tambah barang'),
      ),
    );
  }

  Widget _summary(String title, String value, IconData icon) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(title)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    ),
  );

  Widget _goodsCard(BuildContext context, Map<String, dynamic> item) {
    final stock = FarmOperationsData.stockFor(item['id']);
    final minimum = double.tryParse('${item['batasMinimum']}') ?? 0;
    final low = stock <= minimum;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: low ? Colors.orange.shade100 : Colors.green.shade100,
          child: Icon(low ? Icons.warning_amber : Icons.inventory_2_outlined),
        ),
        title: Text('${item['nama']}'),
        subtitle: Text(
          '${item['kategori']} · Stok ${_quantity(stock)} ${item['satuan']}'
          '${low ? ' · Perlu restok' : ''}',
        ),
        onTap: () => _showDetail(context, item),
        trailing: PopupMenuButton<String>(
          onSelected: (action) {
            if (action == 'edit') _editItem(context, item: item);
            if (action == 'in') _moveStock(context, item, 'Masuk');
            if (action == 'out') _moveStock(context, item, 'Keluar');
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'in', child: Text('Catat stok masuk')),
            PopupMenuItem(value: 'out', child: Text('Catat stok keluar')),
            PopupMenuItem(value: 'edit', child: Text('Edit data barang')),
          ],
        ),
      ),
    );
  }

  Future<void> _editItem(
    BuildContext context, {
    Map<String, dynamic>? item,
  }) async {
    final name = TextEditingController(text: item?['nama'] ?? '');
    final unit = TextEditingController(text: item?['satuan'] ?? 'kg');
    final minimum = TextEditingController(
      text: '${item?['batasMinimum'] ?? 0}',
    );
    final opening = TextEditingController(text: '0');
    final purchasePrice = TextEditingController(
      text: item == null
          ? ''
          : formatThousands('${item['hargaBeliSatuan'] ?? ''}'),
    );
    var selectedCategory = item?['kategori'] ?? 'Pakan';
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, refresh) => AlertDialog(
          title: Text(item == null ? 'Tambah barang' : 'Edit barang'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Nama barang'),
                    validator: _required,
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(labelText: 'Kategori'),
                    items: const ['Pakan', 'Obat-obatan', 'Perlengkapan']
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        refresh(() => selectedCategory = value ?? 'Pakan'),
                  ),
                  TextFormField(
                    controller: unit,
                    decoration: const InputDecoration(labelText: 'Satuan'),
                    validator: _required,
                  ),
                  TextFormField(
                    controller: minimum,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Batas minimum',
                    ),
                    validator: _nonNegative,
                  ),
                  if (item == null)
                    TextFormField(
                      controller: opening,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Stok awal (dicatat sebagai stok masuk)',
                      ),
                      validator: _nonNegative,
                    ),
                  if (item == null)
                    TextFormField(
                      controller: purchasePrice,
                      keyboardType: TextInputType.number,
                      inputFormatters: const [
                        ThousandsSeparatorInputFormatter(),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Harga beli per satuan (Rp)',
                      ),
                      validator: (value) {
                        if ((double.tryParse(
                                  opening.text.replaceAll(',', '.'),
                                ) ??
                                0) >
                                0 &&
                            (FarmOperationsData.parseMoney(value ?? '') ??
                                    0) <=
                                0) {
                          return 'Harga beli diperlukan jika stok awal diisi.';
                        }
                        return null;
                      },
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
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    try {
      if (result == true) {
        await FarmOperationsData.saveGoods(
          id: item?['id'],
          name: name.text,
          category: selectedCategory,
          unit: unit.text,
          minimumStock: double.parse(minimum.text.replaceAll(',', '.')),
          openingStock: item == null
              ? double.parse(opening.text.replaceAll(',', '.'))
              : 0,
          purchasePrice: item == null
              ? FarmOperationsData.parseMoney(purchasePrice.text)
              : null,
        );
      }
    } catch (error) {
      if (mounted) _message('Gagal menyimpan barang: $error');
    } finally {
      name.dispose();
      unit.dispose();
      minimum.dispose();
      opening.dispose();
      purchasePrice.dispose();
    }
  }

  Future<void> _moveStock(
    BuildContext context,
    Map<String, dynamic> item,
    String type,
  ) async {
    final quantity = TextEditingController();
    final note = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Stok $type · ${item['nama']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tersedia: ${_quantity(FarmOperationsData.stockFor(item['id']))} ${item['satuan']}',
            ),
            TextField(
              controller: quantity,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Jumlah (${item['satuan']})',
              ),
            ),
            TextField(
              controller: note,
              decoration: const InputDecoration(labelText: 'Keterangan'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    try {
      if (result == true) {
        final amount = double.tryParse(
          quantity.text.trim().replaceAll(',', '.'),
        );
        if (amount == null || amount <= 0)
          throw ArgumentError('Jumlah harus lebih dari nol.');
        final operationId = 'MOV-${DateTime.now().microsecondsSinceEpoch}';
        await FarmOperationsData.moveStock(
          operationId: operationId,
          itemId: item['id'],
          type: type,
          quantity: amount,
          date: DateTime.now().toIso8601String(),
          note: note.text,
        );
        if (mounted) _message('Stok $type berhasil dicatat.');
      }
    } catch (error) {
      if (mounted) _message('Pergerakan stok gagal: $error');
    } finally {
      quantity.dispose();
      note.dispose();
    }
  }

  Future<void> _showDetail(
    BuildContext context,
    Map<String, dynamic> item,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ValueListenableBuilder(
          valueListenable: FarmOperationsData.movements.listenable(),
          builder: (context, _, _) {
            final history = FarmOperationsData.historyFor(item['id']);
            return ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  item['nama'],
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text('${item['id']} · ${item['kategori']}'),
                Text(
                  'Stok terkini: ${_quantity(FarmOperationsData.stockFor(item['id']))} ${item['satuan']}',
                ),
                Text(
                  'Batas minimum: ${item['batasMinimum']} ${item['satuan']}',
                ),
                const Divider(),
                const Text(
                  'Riwayat pergerakan',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (history.isEmpty)
                  const ListTile(title: Text('Belum ada pergerakan stok.')),
                for (final movement in history)
                  ListTile(
                    title: Text(
                      '${movement['tipe']} · ${movement['jumlah']} ${item['satuan']}',
                    ),
                    subtitle: Text(
                      '${movement['tanggal']}\n${movement['keterangan'] ?? ''}',
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Wajib diisi.' : null;
  String? _nonNegative(String? value) {
    final number = double.tryParse((value ?? '').trim().replaceAll(',', '.'));
    return number == null || !number.isFinite || number < 0
        ? 'Masukkan angka nol atau lebih.'
        : null;
  }

  String _quantity(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);
  void _message(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}
