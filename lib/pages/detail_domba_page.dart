import 'package:flutter/material.dart';
import '../farm_data.dart';
import '../operations_data.dart';
import 'input_penjualan_page.dart';
import 'edit_domba_page.dart';

class DetailDombaPage extends StatefulWidget {
  const DetailDombaPage({super.key, required this.data, required this.index});
  final Map data;
  final int index;
  @override
  State<DetailDombaPage> createState() => _DetailDombaPageState();
}

class _ActivityFormDialog extends StatefulWidget {
  const _ActivityFormDialog();

  @override
  State<_ActivityFormDialog> createState() => _ActivityFormDialogState();
}

class _ActivityFormDialogState extends State<_ActivityFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  static const _categories = ['Pakan', 'Obat-obatan', 'Perlengkapan'];
  String _category = 'Pakan';
  String? _itemId;

  List<Map<String, dynamic>> get _items => FarmOperationsData.goods.values
      .where((item) => item['kategori'] == _category)
      .map((item) => Map<String, dynamic>.from(item))
      .where((item) => FarmOperationsData.stockFor('${item['id']}') > 0)
      .toList();

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final quantity = double.tryParse(_amount.text.trim().replaceAll(',', '.'));
    Navigator.of(context).pop({
      'barangId': _itemId!,
      'jumlah': quantity!.toString(),
      'catatan': _note.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Tambah Aktivitas'),
    content: Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Kategori gudang'),
              items: _categories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _category = value;
                  _itemId = null;
                });
              },
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _items.any((item) => item['id'] == _itemId)
                  ? _itemId
                  : null,
              decoration: InputDecoration(
                labelText: 'Barang',
                helperText: _items.isEmpty
                    ? 'Tidak ada stok tersedia di kategori ini.'
                    : null,
              ),
              items: _items
                  .map(
                    (item) => DropdownMenuItem(
                      value: '${item['id']}',
                      child: Text(
                        '${item['nama']} · Stok '
                        '${FarmOperationsData.stockFor('${item['id']}')} '
                        '${item['satuan']}',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _items.isEmpty
                  ? null
                  : (value) => setState(() => _itemId = value),
              validator: (value) => value == null
                  ? 'Pilih barang yang tersedia.'
                  : null,
            ),
            TextFormField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Jumlah dipakai'),
              validator: (value) {
                final amount = double.tryParse(
                  (value ?? '').trim().replaceAll(',', '.'),
                );
                if (amount == null || amount <= 0) {
                  return 'Jumlah harus lebih dari 0.';
                }
                final selected = _items.where(
                  (item) => '${item['id']}' == _itemId,
                );
                if (selected.isNotEmpty &&
                    amount >
                        FarmOperationsData.stockFor(
                          '${selected.first['id']}',
                        )) {
                  return 'Jumlah melebihi stok tersedia.';
                }
                return null;
              },
            ),
            TextField(
              controller: _note,
              decoration: const InputDecoration(labelText: 'Catatan'),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Batal'),
      ),
      FilledButton(onPressed: _save, child: const Text('Simpan')),
    ],
  );
}

class _WeightFormDialog extends StatefulWidget {
  const _WeightFormDialog({
    required this.title,
    required this.label,
    required this.numeric,
  });

  final String title;
  final String label;
  final bool numeric;

  @override
  State<_WeightFormDialog> createState() => _WeightFormDialogState();
}

class _WeightFormDialogState extends State<_WeightFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _value = TextEditingController();
  final _note = TextEditingController();

  @override
  void dispose() {
    _value.dispose();
    _note.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop({
      'value': _value.text.trim(),
      'note': _note.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _value,
            decoration: InputDecoration(labelText: widget.label),
            keyboardType: widget.numeric
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Bobot wajib diisi.';
              }
              final parsed = double.tryParse(
                value.trim().replaceAll(',', '.'),
              );
              return widget.numeric && (parsed == null || parsed <= 0)
                  ? 'Bobot harus berupa angka lebih dari 0.'
                  : null;
            },
          ),
          TextField(
            controller: _note,
            decoration: const InputDecoration(labelText: 'Catatan'),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Batal'),
      ),
      FilledButton(onPressed: _save, child: const Text('Simpan')),
    ],
  );
}

class _DetailDombaPageState extends State<DetailDombaPage> {
  Future<void> addActivity() async {
    final values = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => const _ActivityFormDialog(),
    );
    if (values == null || !mounted) return;
    try {
      await FarmOperationsData.useGoodsForAnimal(
        animalIndex: widget.index,
        itemId: values['barangId']!,
        quantity: double.parse(values['jumlah']!),
        date: DateTime.now().toIso8601String(),
        note: values['catatan']!,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Aktivitas gagal disimpan: $error')),
        );
      }
    }

    if (mounted) setState(() {});
  }

  Future<void> ask({
    required String title,
    required String label,
    bool numeric = false,
    required Future<void> Function(String, String) save,
  }) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) =>
          _WeightFormDialog(title: title, label: label, numeric: numeric),
    );
    if (result == null || !mounted) return;
    final parsed = double.tryParse(result['value']!.replaceAll(',', '.'));
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Konfirmasi update bobot'),
            content: Text(
              'Simpan bobot ${result['value']} kg untuk domba '
              '${widget.data['kode']}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Periksa lagi'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Simpan bobot'),
              ),
            ],
          ),
        ) ??
        false;
    if (confirmed && mounted && parsed != null) {
      try {
        await save(result['value']!, result['note']!);
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Bobot gagal diperbarui: $error')),
          );
        }
      }
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final row = Map<String, dynamic>.from(FarmData.domba.getAt(widget.index));
    final sold = FarmData.isSold(row);
    final histories = FarmData.bobot.values
        .where((e) => e['dombaId'] == row['id'] || e['kode'] == row['kode'])
        .toList()
        .reversed;
    final activities = FarmData.aktivitas.values
        .where((e) => e['dombaId'] == row['id'] || e['kode'] == row['kode'])
        .toList()
        .reversed;
    Widget field(String name, String value) => ListTile(
      title: Text(name),
      subtitle: Text(value.isEmpty ? '-' : value),
    );
    return Scaffold(
      appBar: AppBar(title: Text('Domba #${row['kode']}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          field('QR', '${row['qrCode'] ?? '-'}'),
          field('Jenis', '${row['jenis'] ?? '-'}'),
          field('Kelamin', '${row['kelamin'] ?? '-'}'),
          field('Asal', '${row['asal'] ?? '-'}'),
          field('Bobot Awal', '${row['bobotAwal'] ?? row['berat'] ?? '-'} KG'),
          field(
            'Bobot Terakhir',
            '${row['bobotTerakhir'] ?? row['berat'] ?? '-'} KG',
          ),
          field('Status', sold ? 'TERJUAL' : 'AKTIF'),
          if ('${row['statusKesehatan'] ?? ''}'.isNotEmpty)
            field('Catatan kesehatan terakhir', '${row['statusKesehatan']}'),
          if (sold) ...[
            field(
              'Tanggal Jual',
              '${row['tanggalJual'] ?? row['tanggal'] ?? '-'}',
            ),
            field('Bobot Jual', '${row['beratJual'] ?? '-'} KG'),
            field('Harga', 'Rp ${row['hargaJual'] ?? '-'}'),
            field('Tujuan', '${row['tujuan'] ?? row['asalPembeli'] ?? '-'}'),
          ],
          if (!sold)
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('Edit Data'),
                  onPressed: () =>
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              EditDombaPage(data: row, index: widget.index),
                        ),
                      ).then((_) {
                        if (mounted) setState(() {});
                      }),
                ),
                ActionChip(
                  label: const Text('Update Bobot'),
                  onPressed: () => ask(
                    title: 'Penimbangan',
                    label: 'Bobot (KG)',
                    numeric: true,
                    save: (v, note) {
                      final value = double.tryParse(v);
                      if (value == null) return Future<void>.value();
                      return FarmData.recordWeight(
                        widget.index,
                        value,
                        note.isEmpty ? 'Penimbangan' : note,
                      );
                    },
                  ),
                ),
                ActionChip(
                  label: const Text('Tambah Aktivitas'),
                  onPressed: addActivity,
                ),
                ActionChip(
                  label: const Text('Jual / Kirim'),
                  onPressed: () =>
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => InputPenjualanPage(
                            data: row,
                            index: widget.index,
                          ),
                        ),
                      ).then((_) {
                        if (mounted) setState(() {});
                      }),
                ),
              ],
            ),
          const Divider(),
          const Text(
            'Histori Bobot',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (histories.isEmpty)
            ListTile(
              title: Text(
                '${row['tanggal'] ?? '-'} • ${row['bobotAwal'] ?? row['berat'] ?? '-'} KG',
              ),
              subtitle: const Text('Bobot awal'),
            ),
          for (final h in histories)
            ListTile(
              title: Text('${h['tanggal']} • ${h['bobot']} KG'),
              subtitle: Text('${h['catatan'] ?? ''}'),
            ),
          const Divider(),
          const Text(
            'Aktivitas',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          for (final a in activities)
            ListTile(
              title: Text('${a['tanggal']} • ${a['tipe']}'),
              subtitle: Text(
                '${a['nama']} ${a['jumlah'] ?? ''} ${a['satuan'] ?? ''}\n${a['catatan'] ?? ''}',
              ),
            ),
        ],
      ),
    );
  }
}
