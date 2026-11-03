import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../farm_data.dart';
import '../money_format.dart';
import 'domba_masuk_page.dart';
import 'detail_domba_page.dart';
import 'bulk_domba_detail_page.dart';
import 'bulk_receipt_page.dart';

class BulkDombaPage extends StatefulWidget {
  const BulkDombaPage({super.key, this.salesOnly = false});

  final bool salesOnly;

  @override
  State<BulkDombaPage> createState() => _BulkDombaPageState();
}

class _BulkDombaPageState extends State<BulkDombaPage> {
  final selected = <int>{};
  String status = 'Semua';
  String batch = 'Semua';
  String query = '';

  @override
  void initState() {
    super.initState();
    if (widget.salesOnly) status = 'Aktif';
  }

  Future<void> _newBatch() async {
    final count = TextEditingController(text: '20');
    final origin = TextEditingController();
    final kind = TextEditingController();
    final sex = TextEditingController(text: 'Jantan');
    final price = TextEditingController();
    final note = TextEditingController();
    final date = TextEditingController(
      text: DateTime.now().toIso8601String().substring(0, 10),
    );
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Banyak Domba'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: count,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Jumlah Domba'),
              ),
              TextField(
                controller: date,
                decoration: const InputDecoration(
                  labelText: 'Tanggal Masuk (YYYY-MM-DD)',
                ),
              ),
              TextField(
                controller: origin,
                decoration: const InputDecoration(labelText: 'Asal'),
              ),
              TextField(
                controller: kind,
                decoration: const InputDecoration(labelText: 'Jenis Default'),
              ),
              DropdownButtonFormField<String>(
                initialValue: sex.text,
                decoration: const InputDecoration(labelText: 'Kelamin Default'),
                items: const [
                  DropdownMenuItem(value: 'Jantan', child: Text('Jantan')),
                  DropdownMenuItem(value: 'Betina', child: Text('Betina')),
                ],
                onChanged: (value) => sex.text = value ?? 'Jantan',
              ),
              TextField(
                controller: price,
                keyboardType: TextInputType.number,
                inputFormatters: const [ThousandsSeparatorInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Harga Beli Total',
                ),
              ),
              TextField(
                controller: note,
                decoration: const InputDecoration(labelText: 'Catatan'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Buat Batch'),
          ),
        ],
      ),
    );
    if (result == true) {
      final n = int.tryParse(count.text.trim());
      if (n == null ||
          n < 1 ||
          origin.text.trim().isEmpty ||
          kind.text.trim().isEmpty) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Jumlah, asal, dan jenis wajib diisi.'),
            ),
          );
      } else {
        final batchId = FarmData.nextBatchCode();
        if (mounted)
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BulkDombaDetailPage(
                batchId: batchId,
                count: n,
                date: date.text.trim(),
                origin: origin.text.trim(),
                defaultKind: kind.text.trim(),
                defaultSex: sex.text.trim().isEmpty
                    ? 'Jantan'
                    : sex.text.trim(),
                totalPrice: price.text.trim(),
                note: note.text.trim(),
              ),
            ),
          );
      }
    }
    count.dispose();
    origin.dispose();
    kind.dispose();
    sex.dispose();
    price.dispose();
    note.dispose();
    date.dispose();
  }

  Future<void> _continue() async {
    if (selected.isEmpty) return;
    final action = widget.salesOnly
        ? 'Jual'
        : await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final pair in [
              ('💉 Nutrisi', 'Nutrisi'),
              ('💊 Obat / Suntik', 'Obat'),
              ('🩺 Pemeriksaan', 'Pemeriksaan'),
              ('📝 Aktivitas Lain', 'Aktivitas'),
              ('⚖️ Update Bobot', 'Bobot'),
              ('🚚 Jual / Kirim', 'Jual'),
            ])
              ListTile(
                title: Text(pair.$1),
                onTap: () => Navigator.pop(ctx, pair.$2),
              ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;
    final ids = selected.toList();
    if (action == 'Bobot')
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BatchWeightPage(indices: ids)),
      );
    else if (action == 'Jual')
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BulkSalePage(indices: ids)),
      );
    else
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BulkActivityPage(indices: ids, type: action),
        ),
      );
    if (mounted) setState(() => selected.clear());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.salesOnly ? 'Pilih Kambing untuk Dijual' : 'Pilih Domba'),
      actions: [
        if (!widget.salesOnly)
        PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'single')
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DombaMasukPage()),
              );
            else
              _newBatch();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'single', child: Text('Tambah 1 Domba')),
            PopupMenuItem(value: 'batch', child: Text('Tambah Banyak Domba')),
          ],
        ),
      ],
    ),
    floatingActionButton: widget.salesOnly
        ? null
        : FloatingActionButton.extended(
      onPressed: _newBatch,
      icon: const Icon(Icons.add),
      label: const Text('Tambah Banyak'),
    ),
    body: ValueListenableBuilder(
      valueListenable: FarmData.domba.listenable(),
      builder: (context, box, _) {
        final all = <MapEntry<int, Map<String, dynamic>>>[];
        for (var i = 0; i < box.length; i++) {
          final row = Map<String, dynamic>.from(box.getAt(i));
          if (status == 'Aktif' && FarmData.isSold(row) ||
              status == 'Terjual' && !FarmData.isSold(row))
            continue;
          if (batch != 'Semua' && row['batchId'] != batch) continue;
          if (!'${row['kode']} ${row['qrCode']} ${row['jenis']} ${row['asal']}'
              .toLowerCase()
              .contains(query.toLowerCase()))
            continue;
          all.add(MapEntry(i, row));
        }
        final batches = FarmData.domba.values
            .map((r) => '${r['batchId'] ?? ''}')
            .where((v) => v.isNotEmpty)
            .toSet()
            .toList();
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Cari kode, jenis, asal, QR',
                    ),
                    onChanged: (v) => setState(() => query = v),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: status,
                          items: ['Semua', 'Aktif', 'Terjual']
                              .map(
                                (v) => DropdownMenuItem(
                                  value: v,
                                  child: Text('Status: $v'),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => status = v ?? 'Semua'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: batches.contains(batch) || batch == 'Semua'
                              ? batch
                              : 'Semua',
                          items: ['Semua', ...batches]
                              .map(
                                (v) => DropdownMenuItem(
                                  value: v,
                                  child: Text(
                                    'Batch: $v',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => batch = v ?? 'Semua'),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${selected.length} domba dipilih  ·  tekan lama untuk memilih',
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  for (final e in all)
                    Builder(
                      builder: (context) {
                        final canSelect = !FarmData.isSold(e.value);
                        final checked = selected.contains(e.key);
                        return ListTile(
                          leading: Checkbox(
                            value: checked,
                            onChanged: canSelect
                                ? (v) => setState(() {
                                    if (v == true)
                                      selected.add(e.key);
                                    else
                                      selected.remove(e.key);
                                  })
                                : null,
                          ),
                          title: Text(
                            '${e.value['jenis'] ?? 'Domba'} · ${FarmData.weight(e.value)} kg',
                          ),
                          subtitle: Text(
                            '${e.value['kode']} · ${e.value['batchId'] ?? 'tanpa batch'} · ${e.value['status']}',
                          ),
                          onLongPress: canSelect
                              ? () => setState(() {
                                  checked
                                      ? selected.remove(e.key)
                                      : selected.add(e.key);
                                })
                              : null,
                          trailing: IconButton(
                            tooltip: 'Buka detail domba',
                            icon: const Icon(Icons.open_in_new),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailDombaPage(
                                  data: e.value,
                                  index: e.key,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            if (selected.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _continue,
                    child: const Text('LANJUT'),
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}

class BatchWeightPage extends StatefulWidget {
  const BatchWeightPage({
    super.key,
    this.indices = const [],
    this.rows = const [],
  });
  final List<int> indices;
  final List<Map<String, dynamic>> rows;
  @override
  State<BatchWeightPage> createState() => _BatchWeightPageState();
}

class _BatchWeightPageState extends State<BatchWeightPage> {
  late final List<int> indices = widget.rows.isNotEmpty
      ? widget.rows
            .map(
              (r) => FarmData.domba.values.toList().indexWhere(
                (v) => v['kode'] == r['kode'],
              ),
            )
            .where((i) => i >= 0)
            .toList()
      : widget.indices;
  late final controllers = indices
      .map(
        (i) => TextEditingController(
          text: widget.rows.isNotEmpty
              ? ''
              : '${FarmData.weight(FarmData.domba.getAt(i))}',
        ),
      )
      .toList();
  bool saving = false;

  Future<void> save() async {
    final values = <double>[];
    for (var j = 0; j < indices.length; j++) {
      final value = double.tryParse(
        controllers[j].text.trim().replaceAll(',', '.'),
      );
      if (value == null || value <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Isi bobot valid untuk semua domba.')),
        );
        return;
      }
      values.add(value);
    }
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Konfirmasi update bobot'),
            content: Text(
              'Simpan bobot untuk ${indices.length} domba sekaligus?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Periksa lagi'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Simpan semua'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;
    setState(() => saving = true);
    try {
      for (var j = 0; j < indices.length; j++) {
        await FarmData.recordWeight(
          indices[j],
          values[j],
          widget.rows.isNotEmpty ? 'Bobot awal batch' : 'Update bobot massal',
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui bobot: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.rows.isNotEmpty
            ? 'Input Bobot Batch · ${widget.rows.first['batchId']}'
            : 'Update Bobot',
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (var j = 0; j < indices.length; j++)
          TextField(
            controller: controllers[j],
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText:
                  '${FarmData.domba.getAt(indices[j])['kode']} · Bobot kg',
            ),
          ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: saving ? null : save,
          child: Text(saving ? 'MENYIMPAN...' : 'SIMPAN SEMUA'),
        ),
      ],
    ),
  );
}

class BulkActivityPage extends StatefulWidget {
  const BulkActivityPage({
    super.key,
    required this.indices,
    required this.type,
  });
  final List<int> indices;
  final String type;
  @override
  State<BulkActivityPage> createState() => _BulkActivityPageState();
}

class _BulkActivityPageState extends State<BulkActivityPage> {
  final name = TextEditingController();
  final amount = TextEditingController();
  final unit = TextEditingController();
  final note = TextEditingController();
  Future<void> save() async {
    if (name.text.trim().isEmpty) return;
    for (final i in widget.indices) {
      if (!FarmData.isSold(FarmData.domba.getAt(i)))
        await FarmData.recordActivity(
          i,
          tipe: widget.type,
          nama: name.text.trim(),
          jumlah: amount.text.trim(),
          satuan: unit.text.trim(),
          catatan: note.text.trim(),
        );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.type)),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('${widget.indices.length} domba dipilih'),
        TextField(
          controller: name,
          decoration: const InputDecoration(labelText: 'Jenis / nama'),
        ),
        TextField(
          controller: amount,
          decoration: const InputDecoration(labelText: 'Jumlah'),
        ),
        TextField(
          controller: unit,
          decoration: const InputDecoration(labelText: 'Satuan'),
        ),
        TextField(
          controller: note,
          decoration: const InputDecoration(labelText: 'Catatan'),
        ),
        const SizedBox(height: 18),
        FilledButton(onPressed: save, child: const Text('SIMPAN UNTUK SEMUA')),
      ],
    ),
  );
}

class BulkSalePage extends StatefulWidget {
  const BulkSalePage({super.key, required this.indices});
  final List<int> indices;
  @override
  State<BulkSalePage> createState() => _BulkSalePageState();
}

class _BulkSalePageState extends State<BulkSalePage> {
  final batchName = TextEditingController();
  final buyer = TextEditingController();
  final whatsapp = TextEditingController();
  final destination = TextEditingController();
  final note = TextEditingController();
  final date = TextEditingController(
    text: DateTime.now().toIso8601String().substring(0, 10),
  );
  final weights = <int, TextEditingController>{};
  final prices = <int, TextEditingController>{};
  String mode = 'per ekor';
  bool saving = false;
  late final String saleBatchCode =
      'JUAL-${DateTime.now().microsecondsSinceEpoch}';
  @override
  void initState() {
    super.initState();
    for (final i in widget.indices) {
      weights[i] = TextEditingController(
        text: '${FarmData.weight(FarmData.domba.getAt(i))}',
      );
      prices[i] = TextEditingController();
    }
  }

  @override
  void dispose() {
    batchName.dispose();
    buyer.dispose();
    whatsapp.dispose();
    destination.dispose();
    note.dispose();
    date.dispose();
    for (final controller in weights.values) {
      controller.dispose();
    }
    for (final controller in prices.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    final w = <int, double>{};
    for (final i in widget.indices) {
      final value = double.tryParse(weights[i]!.text.trim());
      final priceValue = FarmData.parseMoney(prices[i]!.text);
      if (value == null ||
          value <= 0 ||
          priceValue == null ||
          priceValue <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lengkapi bobot jual dan harga setiap domba.'),
          ),
        );
        return;
      }
      w[i] = value;
    }
    if (batchName.text.trim().isEmpty ||
        buyer.text.trim().isEmpty ||
        whatsapp.text.trim().isEmpty ||
        destination.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Isi nama batch, pembeli, WhatsApp, dan alamat/tujuan.'),
        ),
      );
      return;
    }
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Konfirmasi penjualan batch'),
            content: Text(
              'Tandai ${widget.indices.length} domba pada batch '
              '${batchName.text.trim()} sebagai terjual kepada ${buyer.text.trim()}?',
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
      final code = await FarmData.sellTransaction(
        indices: widget.indices,
        date: date.text.trim(),
        buyer: buyer.text.trim(),
        whatsapp: whatsapp.text.trim(),
        destination: destination.text.trim(),
        note: note.text.trim(),
        weights: w,
        prices: {
          for (final i in widget.indices)
            i: mode == 'per kg'
                ? ((FarmData.parseMoney(prices[i]!.text) ?? 0) * w[i]!)
                    .round()
                    .toString()
                : (FarmData.parseMoney(prices[i]!.text) ?? 0).toString(),
        },
        pricingMode: mode,
        metadata: {
          'namaBatch': batchName.text.trim(),
          'kodeBatch': saleBatchCode,
        },
      );
      if (!mounted) return;
      final transaction = Map<String, dynamic>.from(
        FarmData.penjualan.get(code),
      );
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BulkReceiptPage(transaction: transaction),
        ),
      );
    } catch (error) {
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Penjualan batch gagal: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Jual / Kirim Banyak')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: batchName,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nama batch penjualan',
            hintText: 'Contoh: Batch Bogor',
          ),
        ),
        TextField(
          controller: buyer,
          decoration: const InputDecoration(labelText: 'Pembeli'),
        ),
        TextField(
          controller: whatsapp,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Nomor WhatsApp'),
        ),
        TextField(
          controller: date,
          readOnly: true,
          decoration: const InputDecoration(labelText: 'Tanggal Penjualan'),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.tryParse(date.text) ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null)
              date.text = picked.toIso8601String().substring(0, 10);
          },
        ),
        TextField(
          controller: destination,
          decoration: const InputDecoration(labelText: 'Tujuan'),
        ),
        TextField(
          controller: note,
          decoration: const InputDecoration(labelText: 'Catatan'),
        ),
        DropdownButton<String>(
          value: mode,
          items: const [
            DropdownMenuItem(value: 'per ekor', child: Text('Harga per ekor')),
            DropdownMenuItem(value: 'per kg', child: Text('Harga per kg')),
          ],
          onChanged: (v) => setState(() => mode = v ?? mode),
        ),
        for (final i in widget.indices)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text('${FarmData.domba.getAt(i)['kode']}'),
                  TextField(
                    controller: weights[i],
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Bobot jual (kg)',
                    ),
                  ),
                  TextField(
                    controller: prices[i],
                    keyboardType: TextInputType.number,
                    inputFormatters: const [
                      ThousandsSeparatorInputFormatter(),
                    ],
                    decoration: InputDecoration(
                      labelText: mode == 'per kg'
                          ? 'Harga per kg'
                          : 'Harga per ekor',
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: saving ? null : save,
          child: Text(
            saving ? 'MENYIMPAN...' : 'LANJUT · SIMPAN & LIHAT STRUK',
          ),
        ),
      ],
    ),
  );
}
