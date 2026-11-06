import 'package:hive/hive.dart';

import 'farm_data.dart';

class HealthData {
  static const examination = 'pemeriksaan';
  static const vaccination = 'vaksinasi';
  static const medication = 'obat';
  static const treatment = 'tindakan';

  static Box get records => Hive.box('healthRecordBox');

  static List<Map<String, dynamic>> historyFor(Map animal) {
    final animalId = '${animal['id'] ?? ''}';
    final code = '${animal['kode'] ?? ''}';
    final typed = records.values
        .where(
          (raw) =>
              raw is Map &&
              '${raw['dombaId'] ?? ''}' == animalId &&
              animalId.isNotEmpty,
        )
        .map((raw) => Map<String, dynamic>.from(raw as Map))
        .toList();

    final legacy = FarmData.aktivitas.values
        .where((raw) {
          if (raw is! Map) return false;
          final recordAnimalId = '${raw['dombaId'] ?? ''}';
          final sameAnimal = animalId.isNotEmpty
              ? recordAnimalId == animalId ||
                    (recordAnimalId.isEmpty &&
                        code.isNotEmpty &&
                        '${raw['kode'] ?? ''}' == code)
              : code.isNotEmpty && '${raw['kode'] ?? ''}' == code;
          if (!sameAnimal) return false;
          final type = '${raw['tipe'] ?? ''}'.toLowerCase();
          final category = '${raw['kategori'] ?? ''}'.toLowerCase();
          return type.contains('kesehatan') ||
              type.contains('pemberian obat') ||
              category == 'obat-obatan';
        })
        .map((raw) {
          final row = Map<String, dynamic>.from(raw as Map);
          final isMedication =
              '${row['kategori'] ?? ''}'.toLowerCase() == 'obat-obatan' ||
              '${row['tipe'] ?? ''}'.toLowerCase().contains('obat');
          final amount = row['jumlah'];
          final amountText = amount is num && amount == amount.roundToDouble()
              ? amount.toInt().toString()
              : '$amount';
          return <String, dynamic>{
            ...row,
            'recordType': isMedication ? medication : examination,
            if (isMedication) ...{
              'namaObat': row['nama'],
              'dosis': [
                if (amount != null) amountText,
                '${row['satuan'] ?? ''}',
              ].where((part) => part.trim().isNotEmpty).join(' '),
              'alasan': row['catatan'] ?? '',
            } else
              'statusKesehatan': row['nama'],
          };
        });

    final result = <Map<String, dynamic>>[...typed, ...legacy];
    result.sort(_compareNewestFirst);
    return result;
  }

  static String vaccinationStatus(
    Iterable<Map<String, dynamic>> history,
    String vaccineName, {
    DateTime? now,
  }) {
    final normalized = vaccineName.trim().toLowerCase();
    if (normalized.isEmpty) return 'Belum dicatat';
    final vaccinationRecords = history
        .where(
          (record) =>
              record['recordType'] == vaccination &&
              '${record['namaVaksin'] ?? ''}'.trim().toLowerCase() ==
                  normalized,
        )
        .toList();
    if (vaccinationRecords.isEmpty) return 'Belum dicatat';

    vaccinationRecords.sort(_compareNewestFirst);
    final dueText = '${vaccinationRecords.first['jadwalBerikutnya'] ?? ''}'
        .trim();
    if (dueText.isEmpty) return 'Sudah diberikan';
    final due = _dateOnly(dueText);
    if (due == null) return 'Sudah diberikan';
    final today = now ?? DateTime.now();
    final dueDay = due;
    final todayDay = DateTime(today.year, today.month, today.day);
    if (dueDay.isBefore(todayDay)) return 'Terlambat';
    if (dueDay.isAfter(todayDay)) return 'Terjadwal';
    return 'Jatuh tempo hari ini';
  }

  static Future<Map<String, dynamic>> addRecord({
    required int animalIndex,
    required String type,
    required String date,
    required String note,
    required String staff,
    String healthStatus = '',
    String symptoms = '',
    String result = '',
    String action = '',
    String vaccineName = '',
    String dose = '',
    String method = '',
    String nextDueDate = '',
    String medicineName = '',
    String reason = '',
    String route = '',
  }) async {
    if (!const {
      examination,
      vaccination,
      medication,
      treatment,
    }.contains(type)) {
      throw ArgumentError('Jenis catatan kesehatan tidak dikenal.');
    }
    if (animalIndex < 0 || animalIndex >= FarmData.domba.length) {
      throw ArgumentError('Data kambing tidak ditemukan.');
    }
    final eventDate = _dateOnly(date);
    if (eventDate == null) throw ArgumentError('Tanggal kegiatan tidak valid.');
    final todayDate = DateTime.now().toIso8601String().substring(0, 10);
    if (eventDate.isAfter(_dateOnly(todayDate)!)) {
      throw ArgumentError('Tanggal kegiatan tidak boleh di masa mendatang.');
    }
    final nextDue = nextDueDate.trim().isEmpty ? null : _dateOnly(nextDueDate);
    if (nextDueDate.trim().isNotEmpty && nextDue == null) {
      throw ArgumentError('Tanggal vaksinasi berikutnya tidak valid.');
    }
    if (nextDue != null && nextDue.isBefore(eventDate)) {
      throw ArgumentError(
        'Jadwal vaksinasi berikutnya tidak boleh sebelum tanggal pemberian.',
      );
    }
    final row = Map<String, dynamic>.from(FarmData.domba.getAt(animalIndex));
    if ('${row['id'] ?? ''}'.trim().isEmpty) {
      throw StateError('ID kambing tidak tersedia untuk mengaitkan catatan.');
    }
    if (FarmData.isSold(row)) {
      throw StateError('Catatan kesehatan kambing terjual tidak dapat diubah.');
    }
    _validateFields(
      type: type,
      healthStatus: healthStatus,
      vaccineName: vaccineName,
      medicineName: medicineName,
      action: action,
    );
    final time = DateTime.now();
    final baseId = 'HLT-${time.microsecondsSinceEpoch}';
    var recordId = baseId;
    var suffix = 1;
    while (records.values.any((existing) => existing['id'] == recordId)) {
      recordId = '$baseId-${suffix++}';
    }
    final record = <String, dynamic>{
      'id': recordId,
      'dombaId': '${row['id'] ?? ''}',
      'kode': '${row['kode'] ?? ''}',
      'recordType': type,
      'tanggal': eventDate.toIso8601String().substring(0, 10),
      'waktuPencatatan': time.toIso8601String(),
      'petugas': staff.trim(),
      'catatan': note.trim(),
    };
    switch (type) {
      case examination:
        record.addAll({
          'statusKesehatan': healthStatus.trim(),
          'gejala': symptoms.trim(),
          'hasilPemeriksaan': result.trim(),
          'tindakan': action.trim(),
        });
        break;
      case vaccination:
        record.addAll({
          'namaVaksin': vaccineName.trim(),
          'dosis': dose.trim(),
          'metode': method.trim(),
          'jadwalBerikutnya': nextDue == null
              ? ''
              : nextDue.toIso8601String().substring(0, 10),
        });
        break;
      case medication:
        record.addAll({
          'namaObat': medicineName.trim(),
          'alasan': reason.trim(),
          'dosis': dose.trim(),
          'caraPemberian': route.trim(),
        });
        break;
      case treatment:
        record.addAll({
          'tindakan': action.trim(),
          'hasilPemeriksaan': result.trim(),
        });
        break;
    }

    final recordKey = await records.add(record);
    if (type != examination) return record;
    try {
      row['statusKesehatan'] = healthStatus.trim();
      row['tanggalPemeriksaan'] = record['tanggal'];
      row['catatanKesehatan'] = note.trim();
      await FarmData.domba.putAt(animalIndex, row);
    } catch (_) {
      await records.delete(recordKey);
      rethrow;
    }
    return record;
  }

  static void _validateFields({
    required String type,
    required String healthStatus,
    required String vaccineName,
    required String medicineName,
    required String action,
  }) {
    switch (type) {
      case examination:
        if (healthStatus.trim().isEmpty) {
          throw ArgumentError('Status hasil pemeriksaan wajib dipilih.');
        }
        break;
      case vaccination:
        if (vaccineName.trim().isEmpty) {
          throw ArgumentError('Nama vaksin wajib diisi.');
        }
        break;
      case medication:
        if (medicineName.trim().isEmpty) {
          throw ArgumentError('Nama obat wajib diisi.');
        }
        break;
      case treatment:
        if (action.trim().isEmpty) {
          throw ArgumentError('Tindakan perawatan wajib diisi.');
        }
        break;
    }
  }

  static DateTime? _dateOnly(String value) {
    final text = value.trim();
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text)) return null;
    final parsed = DateTime.tryParse(text);
    if (parsed == null ||
        parsed.year.toString().padLeft(4, '0') != text.substring(0, 4) ||
        parsed.month.toString().padLeft(2, '0') != text.substring(5, 7) ||
        parsed.day.toString().padLeft(2, '0') != text.substring(8, 10)) {
      return null;
    }
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  static int _compareNewestFirst(
    Map<String, dynamic> first,
    Map<String, dynamic> second,
  ) {
    final firstDate = DateTime.tryParse('${first['tanggal'] ?? ''}');
    final secondDate = DateTime.tryParse('${second['tanggal'] ?? ''}');
    if (firstDate == null && secondDate != null) return 1;
    if (secondDate == null && firstDate != null) return -1;
    if (firstDate != null && secondDate != null) {
      final dateOrder = secondDate.compareTo(firstDate);
      if (dateOrder != 0) return dateOrder;
    }
    return '${second['waktuPencatatan'] ?? ''}'.compareTo(
      '${first['waktuPencatatan'] ?? ''}',
    );
  }
}
