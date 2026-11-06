import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../farm_data.dart';
import '../health_data.dart';
import '../theme/app_theme.dart';
import 'detail_domba_page.dart';

class HealthManagementPage extends StatelessWidget {
  const HealthManagementPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.warmCream,
    appBar: AppBar(title: const Text('Kesehatan kambing')),
    body: AnimatedBuilder(
      animation: Listenable.merge([
        FarmData.domba.listenable(),
        HealthData.records.listenable(),
        FarmData.aktivitas.listenable(),
      ]),
      builder: (context, _) {
        final animals = <MapEntry<int, Map<String, dynamic>>>[
          for (var index = 0; index < FarmData.domba.length; index++)
            MapEntry(
              index,
              Map<String, dynamic>.from(FarmData.domba.getAt(index)),
            ),
        ];
        if (animals.isEmpty) {
          return const Center(child: Text('Belum ada data kambing.'));
        }
        final dueCount = animals.fold<int>(0, (total, entry) {
          final history = HealthData.historyFor(entry.value);
          final names = history
              .where((record) => record['recordType'] == HealthData.vaccination)
              .map((record) => '${record['namaVaksin'] ?? ''}')
              .where((name) => name.trim().isNotEmpty)
              .toSet();
          return total +
              names
                  .where(
                    (name) =>
                        HealthData.vaccinationStatus(history, name) ==
                        'Terlambat',
                  )
                  .length;
        });
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.health_and_safety_outlined,
                    color: AppTheme.forestGreen,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pemantauan kesehatan',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppTheme.deepGreen,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$dueCount jadwal vaksin terlambat berdasarkan jadwal yang dicatat',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.mutedText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            for (final entry in animals)
              _AnimalHealthCard(
                animal: entry.value,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        DetailDombaPage(data: entry.value, index: entry.key),
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}

class _AnimalHealthCard extends StatelessWidget {
  const _AnimalHealthCard({required this.animal, required this.onTap});

  final Map<String, dynamic> animal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final history = HealthData.historyFor(animal);
    final examinations = history
        .where((record) => record['recordType'] == HealthData.examination)
        .toList();
    final currentStatus = '${animal['statusKesehatan'] ?? 'Belum diperiksa'}';
    final latestDate = examinations.isEmpty
        ? null
        : '${examinations.first['tanggal'] ?? ''}';
    final tone = currentStatus.toLowerCase().contains('sakit')
        ? const Color(0xFFB5473B)
        : AppTheme.forestGreen;
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const CircleAvatar(
          backgroundColor: AppTheme.sageGreen,
          foregroundColor: AppTheme.forestGreen,
          child: Icon(Icons.pets_outlined),
        ),
        title: Text(
          '${animal['kode'] ?? 'Tanpa kode'}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          'Status: $currentStatus'
          '${latestDate == null || latestDate.isEmpty ? '' : ' · Diperiksa $latestDate'}'
          '\n${history.length} catatan kesehatan',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: true,
        trailing: Icon(Icons.chevron_right, color: tone),
      ),
    );
  }
}

class HealthRecordFormPage extends StatefulWidget {
  const HealthRecordFormPage({
    super.key,
    required this.animal,
    required this.animalIndex,
    this.initialType = HealthData.examination,
  });

  final Map<String, dynamic> animal;
  final int animalIndex;
  final String initialType;

  @override
  State<HealthRecordFormPage> createState() => _HealthRecordFormPageState();
}

class _HealthRecordFormPageState extends State<HealthRecordFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _date = TextEditingController(
    text: DateTime.now().toIso8601String().substring(0, 10),
  );
  final _staff = TextEditingController();
  final _note = TextEditingController();
  final _symptoms = TextEditingController();
  final _result = TextEditingController();
  final _action = TextEditingController();
  final _vaccine = TextEditingController();
  final _dose = TextEditingController();
  final _method = TextEditingController();
  final _nextDue = TextEditingController();
  final _medicine = TextEditingController();
  final _reason = TextEditingController();
  final _route = TextEditingController();

  late String _type = widget.initialType;
  String? _status;
  bool _saving = false;

  @override
  void dispose() {
    for (final controller in [
      _date,
      _staff,
      _note,
      _symptoms,
      _result,
      _action,
      _vaccine,
      _dose,
      _method,
      _nextDue,
      _medicine,
      _reason,
      _route,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final current = DateTime.tryParse(controller.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      controller.text = picked.toIso8601String().substring(0, 10);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await HealthData.addRecord(
        animalIndex: widget.animalIndex,
        type: _type,
        date: _date.text,
        note: _note.text,
        staff: _staff.text,
        healthStatus: _status ?? '',
        symptoms: _symptoms.text,
        result: _result.text,
        action: _action.text,
        vaccineName: _vaccine.text,
        dose: _dose.text,
        method: _method.text,
        nextDueDate: _nextDue.text,
        medicineName: _medicine.text,
        reason: _reason.text,
        route: _route.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Catatan gagal disimpan: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.warmCream,
    appBar: AppBar(title: const Text('Catat kesehatan')),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.pets_outlined,
                color: AppTheme.forestGreen,
              ),
              title: Text(
                '${widget.animal['kode'] ?? 'Tanpa kode'}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                '${widget.animal['jenis'] ?? 'Kambing'} · ${widget.animal['kelamin'] ?? 'Tidak diketahui'}',
              ),
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'Jenis catatan'),
            items: const [
              DropdownMenuItem(
                value: HealthData.examination,
                child: Text('Pemeriksaan kesehatan'),
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
                child: Text('Tindakan / perawatan'),
              ),
            ],
            onChanged: _saving
                ? null
                : (value) => setState(() => _type = value ?? _type),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _date,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Tanggal kegiatan',
              prefixIcon: Icon(Icons.calendar_today_outlined),
            ),
            onTap: () => _pickDate(_date),
            validator: (value) => DateTime.tryParse(value ?? '') == null
                ? 'Tanggal kegiatan wajib valid.'
                : null,
          ),
          const SizedBox(height: 12),
          if (_type == HealthData.examination) ...[
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: 'Status hasil pemeriksaan',
              ),
              items: const [
                DropdownMenuItem(value: 'Sehat', child: Text('Sehat')),
                DropdownMenuItem(
                  value: 'Perlu pemantauan',
                  child: Text('Perlu pemantauan'),
                ),
                DropdownMenuItem(value: 'Sakit', child: Text('Sakit')),
                DropdownMenuItem(value: 'Dirujuk', child: Text('Dirujuk')),
              ],
              validator: (value) =>
                  value == null ? 'Pilih hasil pemeriksaan.' : null,
              onChanged: (value) => setState(() => _status = value),
            ),
            const SizedBox(height: 12),
            _field(_symptoms, 'Gejala atau keluhan', maxLines: 3),
            _field(_result, 'Hasil pemeriksaan', maxLines: 3),
            _field(_action, 'Tindakan yang dilakukan', maxLines: 2),
          ],
          if (_type == HealthData.vaccination) ...[
            _field(_vaccine, 'Nama vaksin', required: true),
            _field(_dose, 'Dosis'),
            _field(_method, 'Metode pemberian'),
            TextFormField(
              controller: _nextDue,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Jadwal vaksin berikutnya (opsional)',
                prefixIcon: Icon(Icons.event_available_outlined),
              ),
              onTap: () => _pickDate(_nextDue),
              validator: (value) {
                if (value == null || value.isEmpty) return null;
                return DateTime.tryParse(value) == null
                    ? 'Tanggal jadwal tidak valid.'
                    : null;
              },
            ),
            const SizedBox(height: 12),
          ],
          if (_type == HealthData.medication) ...[
            _field(_medicine, 'Nama obat', required: true),
            _field(_reason, 'Alasan pemberian'),
            _field(_dose, 'Dosis'),
            _field(_route, 'Cara pemberian'),
          ],
          if (_type == HealthData.treatment)
            _field(
              _action,
              'Tindakan / perawatan',
              required: true,
              maxLines: 3,
            ),
          _field(_staff, 'Petugas'),
          _field(_note, 'Catatan tambahan', maxLines: 3),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_saving ? 'Menyimpan...' : 'Simpan catatan'),
          ),
        ],
      ),
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    int maxLines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      textCapitalization: TextCapitalization.sentences,
      minLines: maxLines == 1 ? null : maxLines,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label),
      validator: required
          ? (value) => value == null || value.trim().isEmpty
                ? '$label wajib diisi.'
                : null
          : null,
    ),
  );
}
