import 'package:flutter/material.dart';
import '../farm_data.dart';
import '../health_data.dart';
import '../operations_data.dart';
import '../theme/app_theme.dart';
import '../widgets/animal_history_widgets.dart';
import 'health_management_page.dart';
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
  final _staff = TextEditingController();
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
    _staff.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final quantity = double.tryParse(_amount.text.trim().replaceAll(',', '.'));
    Navigator.of(context).pop({
      'barangId': _itemId!,
      'jumlah': quantity!.toString(),
      'catatan': _note.text.trim(),
      'petugas': _staff.text.trim(),
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
              validator: (value) =>
                  value == null ? 'Pilih barang yang tersedia.' : null,
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
            TextField(
              controller: _staff,
              decoration: const InputDecoration(labelText: 'Petugas'),
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
  final _date = TextEditingController(
    text: DateTime.now().toIso8601String().substring(0, 10),
  );

  @override
  void dispose() {
    _value.dispose();
    _note.dispose();
    _date.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop({
      'value': _value.text.trim(),
      'note': _note.text.trim(),
      'date': _date.text.trim(),
    });
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_date.text) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (selected != null) {
      _date.text = selected.toIso8601String().substring(0, 10);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: Form(
      key: _formKey,
      child: SingleChildScrollView(
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
            TextFormField(
              controller: _date,
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Tanggal timbang'),
              onTap: _pickDate,
              validator: (value) => DateTime.tryParse(value ?? '') == null
                  ? 'Tanggal penimbangan tidak valid.'
                  : null,
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
        staff: values['petugas']!,
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
    required Future<void> Function(String, String, String) save,
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
              'Simpan bobot ${result['value']} kg untuk kambing '
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
        await save(result['value']!, result['note']!, result['date']!);
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

  String _healthFilter = 'Semua';

  Future<void> _recordHealth(String type) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => HealthRecordFormPage(
          animal: Map<String, dynamic>.from(widget.data),
          animalIndex: widget.index,
          initialType: type,
        ),
      ),
    );
    if (saved == true && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final row = Map<String, dynamic>.from(FarmData.domba.getAt(widget.index));
    final sold = FarmData.isSold(row);
    final histories = FarmData.weightHistoryFor(row);
    final weightMetrics = FarmData.weightMetricsFor(row);
    final validWeights = FarmData.weightTrendFor(row);
    final healthHistory = HealthData.historyFor(row);
    final displayedHealthHistory = healthHistory.where((record) {
      if (_healthFilter == 'Semua') return true;
      return record['recordType'] == _healthFilter;
    }).toList();
    final activities = FarmData.aktivitas.values
        .where((e) => e['dombaId'] == row['id'] || e['kode'] == row['kode'])
        .toList()
        .reversed;
    Widget field(String name, String value) => Card(
      child: ListTile(
        title: Text(
          name,
          style: const TextStyle(
            color: AppTheme.mutedText,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          value.isEmpty ? '-' : value,
          style: const TextStyle(
            color: AppTheme.darkText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
    return Scaffold(
      appBar: AppBar(title: Text('Kambing #${row['kode']}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          field('QR', '${row['qrCode'] ?? '-'}'),
          if ('${row['nama'] ?? ''}'.trim().isNotEmpty)
            field('Nama / identitas', '${row['nama']}'),
          field('Jenis', '${row['jenis'] ?? '-'}'),
          field('Kelamin', '${row['kelamin'] ?? '-'}'),
          field(
            'Tanggal masuk',
            '${row['tanggalMasuk'] ?? row['tanggal'] ?? '-'}',
          ),
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
                    save: (v, note, date) {
                      final value = double.tryParse(v);
                      if (value == null) return Future<void>.value();
                      return FarmData.recordWeight(
                        widget.index,
                        value,
                        note.isEmpty ? 'Penimbangan' : note,
                        date: date,
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
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 18, 4, 8),
            child: Text(
              'Perkembangan bobot',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.deepGreen,
              ),
            ),
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              WeightMetric(
                label: 'Bobot awal',
                value: weightMetricText(weightMetrics['initial']),
              ),
              WeightMetric(
                label: 'Bobot terakhir',
                value: weightMetricText(weightMetrics['latest']),
              ),
              WeightMetric(
                label: 'Pertambahan terakhir',
                value: weightMetricText(
                  weightMetrics['previousGain'],
                  signed: true,
                ),
              ),
              WeightMetric(
                label: 'Sejak bobot awal',
                value: weightMetricText(weightMetrics['gain'], signed: true),
              ),
              WeightMetric(
                label: 'ADG',
                value: weightMetrics['adg'] == null
                    ? 'Belum cukup data'
                    : '${weightMetrics['adg']!.toStringAsFixed(3)} kg/hari '
                          '(${(weightMetrics['adg']! * 1000).toStringAsFixed(1)} g/hari)',
              ),
            ],
          ),
          if (validWeights.length > 1) ...[
            const SizedBox(height: 12),
            WeightTrendChart(points: validWeights),
          ],
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 18, 4, 8),
            child: Text(
              'Riwayat bobot',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.deepGreen,
              ),
            ),
          ),
          if (histories.isEmpty)
            Card(
              child: ListTile(
                title: Text(
                  '${row['tanggal'] ?? '-'} • ${row['bobotAwal'] ?? row['berat'] ?? '-'} kg',
                ),
                subtitle: const Text('Bobot awal'),
              ),
            ),
          for (final h in histories.reversed)
            Card(
              child: ListTile(
                title: Text('${h['tanggal']} • ${h['bobot']} kg'),
                subtitle: Text(
                  '${h['catatan'] ?? ''}'
                  '${h['waktuPencatatan'] == null ? '' : '\nDicatat ${h['waktuPencatatan']}'}',
                ),
              ),
            ),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 18, 4, 8),
            child: Text(
              'Kesehatan kambing',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.deepGreen,
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status terkini: ${row['statusKesehatan'] ?? 'Belum diperiksa'}',
                    style: const TextStyle(
                      color: AppTheme.deepGreen,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pemeriksaan terakhir: ${row['tanggalPemeriksaan'] ?? 'Belum dicatat'}',
                    style: const TextStyle(color: AppTheme.mutedText),
                  ),
                  if (healthHistory
                      .where(
                        (record) =>
                            record['recordType'] == HealthData.vaccination,
                      )
                      .isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Status vaksin berdasarkan jadwal tercatat',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    for (final name
                        in healthHistory
                            .where(
                              (record) =>
                                  record['recordType'] ==
                                  HealthData.vaccination,
                            )
                            .map((record) => '${record['namaVaksin'] ?? ''}')
                            .where((name) => name.trim().isNotEmpty)
                            .toSet())
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          '$name · ${HealthData.vaccinationStatus(healthHistory, name)}',
                        ),
                      ),
                  ],
                  if (!healthHistory.any(
                    (record) => record['recordType'] == HealthData.vaccination,
                  )) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Belum ada data vaksinasi; kebutuhan vaksin belum ditentukan.',
                      style: TextStyle(color: AppTheme.mutedText),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (!sold)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.medical_services_outlined, size: 18),
                  label: const Text('Pemeriksaan'),
                  onPressed: () => _recordHealth(HealthData.examination),
                ),
                ActionChip(
                  avatar: const Icon(Icons.vaccines_outlined, size: 18),
                  label: const Text('Vaksinasi'),
                  onPressed: () => _recordHealth(HealthData.vaccination),
                ),
                ActionChip(
                  avatar: const Icon(Icons.medication_outlined, size: 18),
                  label: const Text('Pemberian obat'),
                  onPressed: () => _recordHealth(HealthData.medication),
                ),
                ActionChip(
                  avatar: const Icon(Icons.healing_outlined, size: 18),
                  label: const Text('Tindakan'),
                  onPressed: () => _recordHealth(HealthData.treatment),
                ),
              ],
            ),
          if (healthHistory.isNotEmpty) ...[
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _healthFilter,
              decoration: const InputDecoration(labelText: 'Filter riwayat'),
              items: const [
                DropdownMenuItem(
                  value: 'Semua',
                  child: Text('Semua aktivitas'),
                ),
                DropdownMenuItem(
                  value: HealthData.examination,
                  child: Text('Pemeriksaan'),
                ),
                DropdownMenuItem(
                  value: HealthData.vaccination,
                  child: Text('Vaksinasi'),
                ),
                DropdownMenuItem(
                  value: HealthData.medication,
                  child: Text('Obat'),
                ),
                DropdownMenuItem(
                  value: HealthData.treatment,
                  child: Text('Tindakan'),
                ),
                DropdownMenuItem(value: 'legacy', child: Text('Catatan lama')),
              ],
              onChanged: (value) =>
                  setState(() => _healthFilter = value ?? 'Semua'),
            ),
            const SizedBox(height: 8),
            if (displayedHealthHistory.isEmpty)
              const Text('Tidak ada catatan pada filter ini.'),
            for (final record in displayedHealthHistory)
              HealthTimelineCard(record: record),
          ] else
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Belum ada riwayat kesehatan yang tercatat.'),
              ),
            ),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 18, 4, 8),
            child: Text(
              'Aktivitas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.deepGreen,
              ),
            ),
          ),
          for (final a in activities)
            Card(
              child: ListTile(
                title: Text('${a['tanggal']} • ${a['tipe']}'),
                subtitle: Text(
                  '${a['nama']} ${a['jumlah'] ?? ''} ${a['satuan'] ?? ''}\n${a['catatan'] ?? ''}',
                ),
              ),
            ),
        ],
      ),
    );
  }
}
