import 'package:flutter/material.dart';
import '../farm_data.dart';
import 'bulk_qr_preview_page.dart';

class BulkDombaDetailPage extends StatefulWidget {
  const BulkDombaDetailPage({
    super.key,
    required this.batchId,
    required this.count,
    required this.date,
    required this.origin,
    required this.defaultKind,
    required this.defaultSex,
    required this.totalPrice,
    required this.note,
  });
  final String batchId, date, origin, defaultKind, defaultSex, totalPrice, note;
  final int count;
  @override
  State<BulkDombaDetailPage> createState() => _BulkDombaDetailPageState();
}

class _BulkDombaDetailPageState extends State<BulkDombaDetailPage> {
  late final weights = List.generate(
    widget.count,
    (_) => TextEditingController(),
  );
  late final kinds = List.generate(widget.count, (_) => widget.defaultKind);
  late final sexes = List.generate(widget.count, (_) => widget.defaultSex);
  late final customKinds = List.generate(
    widget.count,
    (i) => TextEditingController(text: widget.defaultKind),
  );
  bool saving = false;
  final choices = const [
    'Gembel',
    'Garut',
    'Merino',
    'Texel',
    'Lokal',
    'Lainnya',
  ];

  String _kind(int index) =>
      kinds[index] == 'Lainnya' ? customKinds[index].text.trim() : kinds[index];

  Future<void> save() async {
    final details = <Map<String, dynamic>>[];
    for (var i = 0; i < widget.count; i++) {
      final weight = double.tryParse(
        weights[i].text.trim().replaceAll(',', '.'),
      );
      if (weight == null || weight <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Bobot domba ${i + 1} wajib berupa angka lebih dari 0.',
            ),
          ),
        );
        return;
      }
      if (_kind(i).isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Isi jenis domba ${i + 1}.')));
        return;
      }
      details.add({'bobot': weight, 'jenis': _kind(i), 'kelamin': sexes[i]});
    }
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Konfirmasi data batch'),
            content: Text(
              'Simpan ${widget.count} data domba untuk batch '
              '${widget.batchId} dan buat QR?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Periksa lagi'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Simpan batch'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;
    setState(() => saving = true);
    try {
      final rows = await FarmData.createBatch(
        count: widget.count,
        date: widget.date,
        origin: widget.origin,
        kind: widget.defaultKind,
        sex: widget.defaultSex,
        totalPrice: widget.totalPrice,
        note: widget.note,
        animalDetails: details,
        batchId: widget.batchId,
      );
      if (!mounted) return;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              BulkQrPreviewPage(batchId: widget.batchId, rows: rows),
        ),
      );
    } catch (error) {
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Batch gagal disimpan: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Detail Domba · ${widget.batchId}')),
    body: ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: widget.count,
      itemBuilder: (context, i) {
        final items = {
          ...choices,
          if (!choices.contains(widget.defaultKind)) widget.defaultKind,
        }.toList();
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Domba ${i + 1}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextField(
                  controller: weights[i],
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Bobot (kg)',
                    suffixText: 'kg',
                  ),
                ),
                DropdownButtonFormField<String>(
                  value: kinds[i],
                  decoration: const InputDecoration(labelText: 'Jenis'),
                  items: items
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) => setState(() {
                    kinds[i] = v ?? widget.defaultKind;
                    if (kinds[i] == 'Lainnya') {
                      customKinds[i].clear();
                    } else {
                      customKinds[i].text = kinds[i];
                    }
                  }),
                ),
                if (kinds[i] == 'Lainnya')
                  TextField(
                    controller: customKinds[i],
                    decoration: const InputDecoration(labelText: 'Nama jenis'),
                  ),
                DropdownButtonFormField<String>(
                  value: sexes[i],
                  decoration: const InputDecoration(labelText: 'Kelamin'),
                  items: const [
                    DropdownMenuItem(value: 'Jantan', child: Text('Jantan')),
                    DropdownMenuItem(value: 'Betina', child: Text('Betina')),
                  ],
                  onChanged: (v) =>
                      setState(() => sexes[i] = v ?? widget.defaultSex),
                ),
              ],
            ),
          ),
        );
      },
    ),
    bottomNavigationBar: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: saving ? null : save,
          icon: saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.arrow_forward),
          label: Text(
            saving ? 'MENYIMPAN...' : 'LANJUT · SIMPAN ${widget.count} DOMBA',
          ),
        ),
      ),
    ),
  );
}
