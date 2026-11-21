import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../farm_data.dart';
import '../theme/app_theme.dart';

class EmployeeLivestockPage extends StatefulWidget {
  const EmployeeLivestockPage({super.key});

  @override
  State<EmployeeLivestockPage> createState() => _EmployeeLivestockPageState();
}

class _EmployeeLivestockPageState extends State<EmployeeLivestockPage> {
  Future<void> _updateCondition(int index, Map<String, dynamic> animal) async {
    var status = '${animal['statusKesehatan'] ?? ''}';
    var note = '';
    if (!const {'Sehat', 'Sakit', 'Karantina'}.contains(status)) {
      status = 'Sehat';
    }
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, refresh) => AlertDialog(
          title: Text('Update Kondisi · ${animal['kode']}'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const ['Sehat', 'Sakit', 'Karantina']
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) => refresh(() => status = value ?? status),
                ),
                TextFormField(
                  minLines: 2,
                  maxLines: 4,
                  onChanged: (value) => note = value,
                  decoration: const InputDecoration(
                    labelText: 'Catatan gejala / kondisi',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Catatan kondisi wajib diisi.'
                      : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, {
                    'status': status,
                    'note': note.trim(),
                  });
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    if (result == null || !mounted) return;
    try {
      await FarmData.recordHealth(
        index,
        status: result['status']!,
        note: result['note']!,
      );
      if (mounted) _message('Kondisi kambing berhasil diperbarui.');
    } catch (error) {
      if (mounted) _message('Kondisi gagal diperbarui: $error');
    }
  }

  Future<void> _recordMutation(
    List<MapEntry<int, Map<String, dynamic>>> animals,
  ) async {
    var date = DateTime.now().toIso8601String().substring(0, 10);
    var kind = 'Kambing';
    var weight = '';
    var note = '';
    final formKey = GlobalKey<FormState>();
    var type = 'Kelahiran';
    var sex = 'Jantan';
    int? animalIndex;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, refresh) => AlertDialog(
          title: const Text('Catat Mutasi'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: type,
                    decoration: const InputDecoration(labelText: 'Kejadian'),
                    items: const ['Kelahiran', 'Kematian']
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => refresh(() {
                      type = value ?? type;
                      animalIndex = null;
                    }),
                  ),
                  if (type == 'Kelahiran') ...[
                    TextFormField(
                      initialValue: kind,
                      decoration: const InputDecoration(labelText: 'Jenis'),
                      onSaved: (value) => kind = value ?? '',
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Jenis kambing wajib diisi.'
                          : null,
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: sex,
                      decoration: const InputDecoration(labelText: 'Kelamin'),
                      items: const ['Jantan', 'Betina']
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => refresh(() => sex = value ?? sex),
                    ),
                    TextFormField(
                      initialValue: weight,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onSaved: (value) => weight = value ?? '',
                      decoration: const InputDecoration(
                        labelText: 'Bobot awal (kg)',
                      ),
                      validator: (value) {
                        final parsed = double.tryParse(
                          (value ?? '').trim().replaceAll(',', '.'),
                        );
                        return parsed == null || parsed <= 0
                            ? 'Bobot harus lebih dari nol.'
                            : null;
                      },
                    ),
                  ] else
                    DropdownButtonFormField<int>(
                      initialValue:
                          animals.any((entry) => entry.key == animalIndex)
                          ? animalIndex
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Pilih kambing',
                      ),
                      items: animals
                          .map(
                            (entry) => DropdownMenuItem(
                              value: entry.key,
                              child: Text(
                                '${entry.value['kode']} · ${entry.value['jenis']}',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: animals.isEmpty
                          ? null
                          : (value) => refresh(() => animalIndex = value),
                      validator: (value) => value == null
                          ? 'Pilih kambing yang tercatat mati.'
                          : null,
                    ),
                  TextFormField(
                    key: ValueKey(date),
                    initialValue: date,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Tanggal kejadian',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    onTap: () async {
                      final current = DateTime.tryParse(date) ?? DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: current,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        refresh(() {
                          date = picked.toIso8601String().substring(0, 10);
                        });
                      }
                    },
                  ),
                  TextFormField(
                    initialValue: note,
                    decoration: const InputDecoration(
                      labelText: 'Catatan (opsional)',
                    ),
                    onSaved: (value) => note = value ?? '',
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  Navigator.pop(dialogContext, {
                    'type': type,
                    'date': date,
                    'kind': kind,
                    'sex': sex,
                    'weight': weight,
                    'note': note,
                    'animalIndex': animalIndex,
                  });
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    if (result == null || !mounted) return;
    try {
      if (result['type'] == 'Kelahiran') {
        await FarmData.recordBirth(
          date: result['date'] as String,
          kind: result['kind'] as String,
          sex: result['sex'] as String,
          initialWeight: double.parse(
            (result['weight'] as String).replaceAll(',', '.'),
          ),
          note: result['note'] as String,
        );
      } else {
        await FarmData.recordDeath(
          index: result['animalIndex'] as int,
          date: result['date'] as String,
          note: result['note'] as String,
        );
      }
      if (mounted) {
        _message(
          result['type'] == 'Kelahiran'
              ? 'Kelahiran dicatat dan kambing baru ditambahkan.'
              : 'Kematian dicatat. Riwayat kambing tetap tersimpan.',
        );
      }
    } catch (error) {
      if (mounted) _message('Mutasi gagal dicatat: $error');
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.warmCream,
    appBar: AppBar(title: const Text('Stok Kambing')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () {
        final animals = <MapEntry<int, Map<String, dynamic>>>[
          for (var index = 0; index < FarmData.domba.length; index++)
            MapEntry(
              index,
              Map<String, dynamic>.from(FarmData.domba.getAt(index)),
            ),
        ].where((entry) => FarmData.isActive(entry.value)).toList();
        _recordMutation(animals);
      },
      icon: const Icon(Icons.swap_horiz),
      label: const Text('Catat Mutasi'),
    ),
    body: ValueListenableBuilder(
      valueListenable: FarmData.domba.listenable(),
      builder: (context, _, _) {
        final animals = <MapEntry<int, Map<String, dynamic>>>[
          for (var index = 0; index < FarmData.domba.length; index++)
            MapEntry(
              index,
              Map<String, dynamic>.from(FarmData.domba.getAt(index)),
            ),
        ].where((entry) => FarmData.isActive(entry.value)).toList();
        if (animals.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Belum ada kambing aktif. Catat mutasi kelahiran untuk menambahkan kambing baru.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '${animals.length} kambing aktif · Pilih kambing untuk memperbarui kesehatannya.',
                ),
              ),
            ),
            for (final entry in animals)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          backgroundColor: AppTheme.sageGreen,
                          foregroundColor: AppTheme.forestGreen,
                          child: Icon(Icons.pets_outlined),
                        ),
                        title: Text(
                          '${entry.value['kode']} · ${entry.value['jenis']}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          'Kondisi: ${entry.value['statusKesehatan'] ?? 'Belum diperiksa'}'
                          '\nBobot: ${entry.value['bobotTerakhir'] ?? entry.value['berat'] ?? '-'} kg',
                        ),
                        isThreeLine: true,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _updateCondition(entry.key, entry.value),
                          icon: const Icon(Icons.health_and_safety_outlined),
                          label: const Text('Update Kondisi'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}
