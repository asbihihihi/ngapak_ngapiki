import 'dart:async';

import 'package:hive/hive.dart';
import 'money_format.dart';

class AnimalWeightEntry {
  const AnimalWeightEntry({
    required this.index,
    required this.value,
    required this.note,
    this.date,
  });

  final int index;
  final double value;
  final String note;
  final String? date;
}

class FarmData {
  static Future<void> _saleQueue = Future<void>.value();
  static Future<void> _animalQueue = Future<void>.value();
  static String _batchDay = '';
  static int _batchSequence = 0;
  static final domba = Hive.box('dombaBox');
  static final bobot = Hive.box('bobotDombaBox');
  static final aktivitas = Hive.box('aktivitasDombaBox');
  static final penjualan = Hive.box('penjualanBox');

  /// Reads both current transaction records and the older one-row-per-animal
  /// records written by the original sale form.
  static Map<String, dynamic> normalizeSaleTransaction(
    Map<dynamic, dynamic> raw, {
    String? legacyKey,
  }) {
    final row = Map<String, dynamic>.from(raw);
    if (row['items'] is List) {
      final items = (row['items'] as List)
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      final total = items.fold<double>(
        0,
        (sum, item) => sum + _moneyValue(item['hargaJual']),
      );
      final totalWeight = items.fold<double>(
        0,
        (sum, item) => sum + _numberValue(item['beratJual']),
      );
      row['items'] = items;
      row['total'] = total;
      row['totalBerat'] = totalWeight;
      row['jumlahDomba'] = items.length;
      row['namaPembeli'] ??= row['nama'] ?? '';
      row['transaksiId'] ??= legacyKey ?? '';
      return row;
    }

    final amount = _moneyValue(row['hargaJual'] ?? row['harga']);
    final item = <String, dynamic>{
      'kode': row['kode'] ?? '',
      'dombaId': row['dombaId'] ?? row['id'],
      'hargaJual': amount,
      'beratJual': _numberValue(row['beratJual'] ?? row['berat']),
      'jenis': row['jenis'] ?? 'Domba',
      'kelamin': row['kelamin'] ?? '',
    };
    return <String, dynamic>{
      'transaksiId':
          row['transaksiId'] ??
          (legacyKey == null
              ? 'LEGACY-${row['kode'] ?? ''}'
              : 'LEGACY-$legacyKey'),
      'tanggal': row['tanggal'] ?? row['tanggalJual'] ?? '',
      'namaPembeli': row['namaPembeli'] ?? row['nama'] ?? '',
      'whatsapp': row['whatsapp'] ?? row['waPembeli'] ?? '',
      'tujuan': row['tujuan'] ?? row['asalPembeli'] ?? '',
      'modeHarga': row['modeHarga'] ?? 'per ekor',
      'catatan': row['catatan'] ?? '',
      'items': [item],
      'jumlahDomba': 1,
      'totalBerat': item['beratJual'],
      'total': amount,
      'legacy': true,
    };
  }

  static double _numberValue(dynamic value) =>
      double.tryParse('$value'.trim().replaceAll(',', '.')) ?? 0;

  static double _moneyValue(dynamic value) {
    if (value is num) return value.toDouble();
    var text = '$value'.trim().replaceAll(RegExp(r'[^0-9,.-]'), '');
    if (text.contains(',') && text.contains('.')) {
      text = text.replaceAll('.', '').replaceAll(',', '.');
    } else if (text.contains(',')) {
      final parts = text.split(',');
      text = parts.length == 2 && parts.last.length != 3
          ? '${parts.first}.${parts.last}'
          : text.replaceAll(',', '');
    } else if (text.contains('.')) {
      final parts = text.split('.');
      if (parts.length > 2 || (parts.length == 2 && parts.last.length == 3)) {
        text = text.replaceAll('.', '');
      }
    }
    return double.tryParse(text) ?? 0;
  }

  static double? parseMoney(String value) => parseMoneyInput(value);

  static List<Map<String, dynamic>> healthHistoryFor(dynamic animal) {
    final id = '${animal['id'] ?? ''}';
    final code = '${animal['kode'] ?? ''}';
    final row = <String, dynamic>{};
    final currentHealth = '${animal['statusKesehatan'] ?? ''}'.trim();
    if (currentHealth.isNotEmpty && currentHealth != 'Belum diperiksa') {
      row.addAll({
        'tanggal': animal['tanggalPemeriksaan'] ?? animal['tanggalMasuk'] ?? '',
        'nama': currentHealth,
        'catatan': animal['catatanKesehatan'] ?? '',
      });
    }
    final history =
        aktivitas.values
            .where((entry) {
              final recordId = '${entry['dombaId'] ?? ''}';
              final matchesAnimal = id.isNotEmpty
                  ? recordId == id ||
                        (recordId.isEmpty &&
                            code.isNotEmpty &&
                            '${entry['kode'] ?? ''}' == code)
                  : code.isNotEmpty && '${entry['kode'] ?? ''}' == code;
              if (!matchesAnimal) return false;
              final type = '${entry['tipe'] ?? ''}'.toLowerCase();
              final category = '${entry['kategori'] ?? ''}'.toLowerCase();
              return type.contains('kesehatan') ||
                  type.contains('pemberian obat') ||
                  category == 'obat-obatan';
            })
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList()
          ..sort((a, b) => '${a['tanggal']}'.compareTo('${b['tanggal']}'));
    if (row.isNotEmpty &&
        !history.any((entry) => entry['nama'] == row['nama'])) {
      history.insert(0, row);
    }
    return history;
  }

  static String _nextSequential(
    String prefix,
    Iterable<dynamic> values,
    String field,
  ) {
    var next = 1;
    for (final row in values) {
      final code = '${row[field] ?? ''}';
      final match = RegExp(r'(\d+)$').firstMatch(code);
      final n = int.tryParse(match?.group(1) ?? '0') ?? 0;
      if (n >= next) next = n + 1;
    }
    String make(int n) => '$prefix${n.toString().padLeft(3, '0')}';
    while (values.any((row) => row[field] == make(next))) {
      next++;
    }
    return make(next);
  }

  static String nextBatchCode() {
    final day = DateTime.now()
        .toIso8601String()
        .substring(0, 10)
        .replaceAll('-', '');
    if (_batchDay != day) {
      _batchDay = day;
      _batchSequence = 0;
    }
    final base = _nextSequential(
      'BATCH-$day-',
      Hive.box('batchBox').values,
      'batchId',
    );
    final stored = int.tryParse(base.split('-').last) ?? 0;
    final current = _batchSequence > stored - 1 ? _batchSequence : stored - 1;
    _batchSequence = current + 1;
    return 'BATCH-$day-${_batchSequence.toString().padLeft(3, '0')}';
  }

  static String nextSaleCode() => _nextSequential(
    'TRX-${DateTime.now().toIso8601String().substring(0, 10).replaceAll('-', '')}-',
    penjualan.values,
    'transaksiId',
  );

  static Future<List<Map<String, dynamic>>> createBatch({
    required int count,
    required String date,
    required String origin,
    required String kind,
    required String sex,
    required String totalPrice,
    required String note,
    required List<Map<String, dynamic>> animalDetails,
    required String batchId,
  }) => _withAnimalLock(
    () => _createBatchNow(
      count: count,
      date: date,
      origin: origin,
      kind: kind,
      sex: sex,
      totalPrice: totalPrice,
      note: note,
      animalDetails: animalDetails,
      batchId: batchId,
    ),
  );

  static Future<List<Map<String, dynamic>>> _createBatchNow({
    required int count,
    required String date,
    required String origin,
    required String kind,
    required String sex,
    required String totalPrice,
    required String note,
    required List<Map<String, dynamic>> animalDetails,
    required String batchId,
  }) async {
    if (count < 1) throw ArgumentError('Jumlah domba harus lebih dari nol');
    if (animalDetails.length != count ||
        animalDetails.any(
          (animal) => (double.tryParse('${animal['bobot']}') ?? 0) <= 0,
        )) {
      throw ArgumentError(
        'Detail bobot setiap domba harus valid sebelum batch disimpan',
      );
    }
    final batches = Hive.box('batchBox');
    if (batchId.trim().isEmpty || batches.containsKey(batchId)) {
      throw ArgumentError('ID batch kosong atau sudah pernah digunakan.');
    }
    final entries = <Map<String, dynamic>>[];
    final dombaKeys = <dynamic>[];
    final weightKeys = <dynamic>[];
    final finance = Hive.box('keuanganBox');
    final purchasePrice = totalPrice.trim().isEmpty
        ? null
        : parseMoney(totalPrice);
    if (totalPrice.trim().isNotEmpty &&
        (purchasePrice == null ||
            !purchasePrice.isFinite ||
            purchasePrice < 0)) {
      throw ArgumentError('Total harga beli batch tidak valid.');
    }
    final expenseId = 'BUY-$batchId';
    if (purchasePrice != null &&
        purchasePrice > 0 &&
        finance.containsKey(expenseId)) {
      throw StateError('Pengeluaran batch sudah pernah dicatat.');
    }
    final now = DateTime.now();
    var expenseWritten = false;
    try {
      for (var i = 0; i < count; i++) {
        final code = nextCode();
        final row = <String, dynamic>{
          'id': 'local-${now.microsecondsSinceEpoch}-$i',
          'kode': code,
          'kodeDomba': code,
          'qrCode': qrFor(code),
          'batchId': batchId,
          'tanggalMasuk': date,
          'tanggal': date,
          'asal': origin,
          'jenis': animalDetails[i]['jenis'] ?? kind,
          'kelamin': animalDetails[i]['kelamin'] ?? sex,
          'bobotAwal': animalDetails[i]['bobot'],
          'bobotTerakhir': animalDetails[i]['bobot'],
          'berat': '${animalDetails[i]['bobot']}',
          'hargaBeli': purchasePrice == null ? '' : purchasePrice / count,
          'harga': purchasePrice == null ? '' : purchasePrice / count,
          'catatan': note,
          'status': 'aktif',
          'foto': '',
        };
        final key = await domba.add(row);
        dombaKeys.add(key);
        row['id'] = key.toString();
        await domba.put(key, row);
        weightKeys.add(
          await bobot.add({
            'id': 'initial-${now.microsecondsSinceEpoch}-$i',
            'dombaId': row['id'],
            'kode': code,
            'tanggal': date,
            'waktuPencatatan': now.toIso8601String(),
            'bobot': animalDetails[i]['bobot'],
            'catatan': 'Bobot awal',
          }),
        );
        entries.add(row);
      }
      await batches.put(batchId, {
        'batchId': batchId,
        'tanggalMasuk': date,
        'asal': origin,
        'jumlahDomba': count,
        'jenis': kind,
        'keterangan': note,
        'totalHargaBeli': totalPrice,
        'kodeDomba': entries.map((row) => row['kode']).toList(),
        'jenisPerDomba': entries.map((row) => row['jenis']).toList(),
        'kelaminPerDomba': entries.map((row) => row['kelamin']).toList(),
      });
      if (purchasePrice != null && purchasePrice > 0) {
        await finance.put(expenseId, {
          'id': expenseId,
          'jenis': 'Pengeluaran',
          'kategori': 'Pembelian kambing',
          'jumlah': purchasePrice,
          'tanggal': date,
          'keterangan': 'Pembelian batch $batchId · $count ekor dari $origin',
          'sumber': 'pembelian_domba_batch',
          'batchId': batchId,
          'kodeDomba': entries.map((row) => row['kode']).toList(),
        });
        expenseWritten = true;
      }
      return entries;
    } catch (_) {
      if (expenseWritten && finance.containsKey(expenseId)) {
        await finance.delete(expenseId);
      }
      if (batches.containsKey(batchId)) await batches.delete(batchId);
      for (final key in dombaKeys) {
        await domba.delete(key);
      }
      for (final key in weightKeys) {
        await bobot.delete(key);
      }
      rethrow;
    }
  }

  static String nextCode() {
    var next = 1;
    for (final row in domba.values) {
      final code = (row['kode'] ?? '').toString();
      final match = RegExp(r'(\d+)$').firstMatch(code);
      final number = int.tryParse(match?.group(1) ?? '0') ?? 0;
      if (number >= next) next = number + 1;
    }
    String codeFor(int n) => 'DMB-${n.toString().padLeft(6, '0')}';
    while (domba.values.any(
      (row) =>
          row['kode'] == codeFor(next) ||
          row['qrCode'] == 'NGK-${codeFor(next)}',
    )) {
      next++;
    }
    return codeFor(next);
  }

  static Future<Map<String, dynamic>> addAnimal({
    required String date,
    required String origin,
    required String kind,
    required String sex,
    required double initialWeight,
    String purchasePrice = '',
    String note = '',
    String photoPath = '',
  }) => _withAnimalLock(
    () => _addAnimalNow(
      date: date,
      origin: origin,
      kind: kind,
      sex: sex,
      initialWeight: initialWeight,
      purchasePrice: purchasePrice,
      note: note,
      photoPath: photoPath,
    ),
  );

  static Future<Map<String, dynamic>> _addAnimalNow({
    required String date,
    required String origin,
    required String kind,
    required String sex,
    required double initialWeight,
    required String purchasePrice,
    required String note,
    required String photoPath,
  }) async {
    if (origin.trim().isEmpty ||
        kind.trim().isEmpty ||
        !initialWeight.isFinite ||
        initialWeight <= 0) {
      throw ArgumentError('Asal, jenis, dan bobot positif wajib diisi.');
    }
    final code = nextCode();
    final now = DateTime.now();
    final intakeDate = date.trim().isEmpty
        ? now.toIso8601String()
        : date.trim();
    final parsedPrice = purchasePrice.trim().isEmpty
        ? null
        : parseMoney(purchasePrice);
    if (purchasePrice.trim().isNotEmpty &&
        (parsedPrice == null || !parsedPrice.isFinite || parsedPrice < 0)) {
      throw ArgumentError('Harga beli domba tidak valid.');
    }
    final finance = Hive.box('keuanganBox');
    final expenseId = 'BUY-$code';
    if (parsedPrice != null &&
        parsedPrice > 0 &&
        finance.containsKey(expenseId)) {
      throw StateError('Pengeluaran domba sudah pernah dicatat.');
    }
    final row = <String, dynamic>{
      'kode': code,
      'qrCode': qrFor(code),
      'tanggalMasuk': intakeDate,
      'tanggal': intakeDate,
      'asal': origin.trim(),
      'jenis': kind.trim(),
      'kelamin': sex.trim().isEmpty ? 'Tidak diketahui' : sex.trim(),
      'bobotAwal': initialWeight,
      'bobotTerakhir': initialWeight,
      'berat': initialWeight.toString(),
      'hargaBeli': parsedPrice ?? '',
      'harga': parsedPrice ?? '',
      'catatan': note.trim(),
      'keterangan': note.trim(),
      'foto': photoPath,
      'status': 'aktif',
      'statusKesehatan': 'Belum diperiksa',
    };
    final key = await domba.add(row);
    row['id'] = key.toString();
    dynamic weightKey;
    var expenseWritten = false;
    try {
      await domba.put(key, row);
      weightKey = await bobot.add({
        'id': 'initial-${now.microsecondsSinceEpoch}',
        'dombaId': row['id'],
        'kode': code,
        'tanggal': intakeDate,
        'waktuPencatatan': now.toIso8601String(),
        'bobot': initialWeight,
        'catatan': 'Bobot awal',
      });
      if (parsedPrice != null && parsedPrice > 0) {
        await finance.put(expenseId, {
          'id': expenseId,
          'jenis': 'Pengeluaran',
          'kategori': 'Pembelian kambing',
          'jumlah': parsedPrice,
          'tanggal': intakeDate,
          'keterangan': 'Pembelian domba $code · ${kind.trim()} · $sex',
          'sumber': 'pembelian_domba',
          'kodeDomba': code,
        });
        expenseWritten = true;
      }
      return row;
    } catch (_) {
      await domba.delete(key);
      if (weightKey != null) await bobot.delete(weightKey);
      if (expenseWritten && finance.containsKey(expenseId)) {
        await finance.delete(expenseId);
      }
      rethrow;
    }
  }

  static String qrFor(String code) => 'NGK-$code';
  static bool isSold(dynamic row) =>
      (row['status'] ?? 'aktif').toString().toLowerCase() == 'terjual';
  static double weight(dynamic row) =>
      double.tryParse(
        (row['bobotTerakhir'] ?? row['berat'] ?? '').toString(),
      ) ??
      0;

  static List<Map<String, dynamic>> weightHistoryFor(dynamic animal) {
    final animalId = '${animal['id'] ?? ''}';
    final code = '${animal['kode'] ?? ''}';
    final history = bobot.values
        .where((entry) {
          if (entry is! Map) return false;
          final entryAnimalId = '${entry['dombaId'] ?? ''}';
          if (animalId.isNotEmpty && entryAnimalId.isNotEmpty) {
            return entryAnimalId == animalId;
          }
          return code.isNotEmpty && '${entry['kode'] ?? ''}' == code;
        })
        .map((entry) => Map<String, dynamic>.from(entry as Map))
        .toList();
    history.sort((a, b) {
      final dateA = DateTime.tryParse('${a['tanggal'] ?? ''}');
      final dateB = DateTime.tryParse('${b['tanggal'] ?? ''}');
      if (dateA == null) return dateB == null ? 0 : 1;
      if (dateB == null) return -1;
      final byDate = dateA.compareTo(dateB);
      if (byDate != 0) return byDate;
      return '${a['waktuPencatatan'] ?? ''}'.compareTo(
        '${b['waktuPencatatan'] ?? ''}',
      );
    });
    return history;
  }

  static Map<String, double?> weightMetricsFor(dynamic animal) {
    final parsed = weightTrendFor(animal);
    if (parsed.isEmpty) {
      return {
        'initial': null,
        'latest': null,
        'gain': null,
        'adg': null,
        'previousGain': null,
      };
    }
    final latest = parsed.last;
    final initial = parsed.first;
    final previous = parsed.length > 1 ? parsed[parsed.length - 2] : null;
    final days = latest.date.difference(initial.date).inDays;
    return {
      'initial': initial.value,
      'latest': latest.value,
      'gain': latest.value - initial.value,
      'adg': days > 0 ? (latest.value - initial.value) / days : null,
      'previousGain': previous == null ? null : latest.value - previous.value,
    };
  }

  static List<({DateTime date, double value})> weightTrendFor(dynamic animal) {
    final today = DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);
    return weightHistoryFor(animal)
        .map((entry) {
          final date = _calendarDate(entry['tanggal']);
          final value = double.tryParse('${entry['bobot'] ?? ''}');
          if (date == null ||
              date.isAfter(todayDay) ||
              value == null ||
              !value.isFinite ||
              value <= 0) {
            return null;
          }
          return (date: date, value: value);
        })
        .whereType<({DateTime date, double value})>()
        .toList();
  }

  static int? indexForQr(String qr) {
    for (var i = 0; i < domba.length; i++) {
      final row = domba.getAt(i);
      if (row['qrCode'] == qr || row['kode'] == qr) return i;
    }
    return null;
  }

  static DateTime? _calendarDate(dynamic raw) {
    final text = '$raw'.trim();
    if (text.length < 10) return null;
    final dayText = text.substring(0, 10);
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dayText)) return null;
    final parsed = DateTime.tryParse(dayText);
    if (parsed == null ||
        parsed.year.toString().padLeft(4, '0') != dayText.substring(0, 4) ||
        parsed.month.toString().padLeft(2, '0') != dayText.substring(5, 7) ||
        parsed.day.toString().padLeft(2, '0') != dayText.substring(8, 10)) {
      return null;
    }
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  static Future<T> _withSaleLock<T>(Future<T> Function() operation) {
    final result = Completer<T>();
    _saleQueue = _saleQueue.then((_) async {
      try {
        result.complete(await operation());
      } catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      }
    });
    return result.future;
  }

  static Future<T> _withAnimalLock<T>(Future<T> Function() operation) {
    final result = Completer<T>();
    _animalQueue = _animalQueue.then((_) async {
      try {
        result.complete(await operation());
      } catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      }
    });
    return result.future;
  }

  static Future<void> recordWeight(
    int index,
    double value,
    String note, {
    String? date,
  }) => recordWeights([
    AnimalWeightEntry(index: index, value: value, note: note, date: date),
  ]);

  static Future<void> recordWeights(
    List<AnimalWeightEntry> entries,
  ) => _withAnimalLock(() async {
    if (entries.isEmpty ||
        entries.map((entry) => entry.index).toSet().length != entries.length) {
      throw ArgumentError('Pilih kambing yang valid untuk ditimbang.');
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final prepared =
        <
          ({
            int index,
            Map<String, dynamic> before,
            Map<String, dynamic> after,
            DateTime date,
            double value,
            String note,
          })
        >[];
    for (final entry in entries) {
      if (entry.index < 0 ||
          entry.index >= domba.length ||
          !entry.value.isFinite ||
          entry.value <= 0) {
        throw ArgumentError('Bobot harus berupa angka lebih dari nol.');
      }
      final eventDate = _calendarDate(entry.date ?? now.toIso8601String());
      if (eventDate == null) {
        throw ArgumentError('Tanggal penimbangan tidak valid.');
      }
      if (eventDate.isAfter(today)) {
        throw ArgumentError(
          'Tanggal penimbangan tidak boleh di masa mendatang.',
        );
      }
      final before = Map<String, dynamic>.from(domba.getAt(entry.index));
      if (isSold(before)) {
        throw StateError('Bobot kambing terjual tidak dapat diubah.');
      }
      if ('${before['id'] ?? ''}'.trim().isEmpty) {
        throw StateError('ID kambing tidak tersedia untuk mengaitkan riwayat.');
      }
      final after = Map<String, dynamic>.from(before);
      final previousLatest = weightHistoryFor(before)
          .map((record) => _calendarDate(record['tanggal']))
          .whereType<DateTime>()
          .where((day) => !day.isAfter(today))
          .fold<DateTime?>(null, (latest, day) {
            return latest == null || day.isAfter(latest) ? day : latest;
          });
      if (previousLatest == null || !eventDate.isBefore(previousLatest)) {
        after['bobotTerakhir'] = entry.value;
        after['berat'] = entry.value.toString();
      }
      if (after['batchId'] != null &&
          (double.tryParse('${after['bobotAwal'] ?? 0}') ?? 0) == 0) {
        after['bobotAwal'] = entry.value;
      }
      prepared.add((
        index: entry.index,
        before: before,
        after: after,
        date: eventDate,
        value: entry.value,
        note: entry.note.trim(),
      ));
    }

    final weightKeys = <dynamic>[];
    final changedRows = <int>[];
    final recordIds = <String>{};
    try {
      for (var index = 0; index < prepared.length; index++) {
        final item = prepared[index];
        final capturedAt = DateTime.now();
        var recordId = capturedAt.microsecondsSinceEpoch.toString();
        var suffix = 1;
        while (bobot.values.any((record) => record['id'] == recordId) ||
            recordIds.contains(recordId)) {
          recordId = '${capturedAt.microsecondsSinceEpoch}-${suffix++}';
        }
        recordIds.add(recordId);
        weightKeys.add(
          await bobot.add({
            'id': recordId,
            'dombaId': item.before['id'],
            'kode': item.before['kode'],
            'tanggal': item.date.toIso8601String().substring(0, 10),
            'waktuPencatatan': capturedAt.toIso8601String(),
            'bobot': item.value,
            'catatan': item.note,
          }),
        );
      }
      for (final item in prepared) {
        changedRows.add(item.index);
        await domba.putAt(item.index, item.after);
      }
    } catch (error, stackTrace) {
      final rollbackErrors = <Object>[];
      for (final index in changedRows.reversed) {
        try {
          final item = prepared.firstWhere((entry) => entry.index == index);
          await domba.putAt(index, item.before);
        } catch (rollbackError) {
          rollbackErrors.add(rollbackError);
        }
      }
      for (final key in weightKeys) {
        try {
          await bobot.delete(key);
        } catch (rollbackError) {
          rollbackErrors.add(rollbackError);
        }
      }
      if (rollbackErrors.isNotEmpty) {
        throw StateError(
          'Penyimpanan bobot gagal ($error) dan pemulihan data tidak '
          'selesai: ${rollbackErrors.join('; ')}',
        );
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  });

  static Future<void> recordActivity(
    int index, {
    required String tipe,
    required String nama,
    String jumlah = '',
    String satuan = '',
    String catatan = '',
  }) async {
    final row = domba.getAt(index);
    await aktivitas.add({
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'dombaId': row['id'],
      'kode': row['kode'],
      'tipe': tipe,
      'tanggal': DateTime.now().toIso8601String(),
      'waktuPencatatan': DateTime.now().toIso8601String(),
      'nama': nama,
      'jumlah': jumlah,
      'satuan': satuan,
      'catatan': catatan,
    });
  }

  static Future<void> recordHealth(
    int index, {
    required String status,
    required String note,
  }) async {
    final normalized = status.trim();
    if (normalized.isEmpty) {
      throw ArgumentError('Status kesehatan wajib dipilih.');
    }
    final row = Map<String, dynamic>.from(domba.getAt(index));
    if (isSold(row)) {
      throw StateError('Data kesehatan kambing terjual tidak dapat diubah.');
    }
    final eventId = 'HEALTH-${DateTime.now().microsecondsSinceEpoch}';
    final eventKey = await aktivitas.add({
      'id': eventId,
      'dombaId': row['id'],
      'kode': row['kode'],
      'tipe': 'Pemeriksaan Kesehatan',
      'tanggal': DateTime.now().toIso8601String().substring(0, 10),
      'waktuPencatatan': DateTime.now().toIso8601String(),
      'nama': normalized,
      'jumlah': '',
      'satuan': '',
      'catatan': note.trim(),
    });
    try {
      row['statusKesehatan'] = normalized;
      row['catatanKesehatan'] = note.trim();
      row['tanggalPemeriksaan'] = DateTime.now().toIso8601String().substring(
        0,
        10,
      );
      await domba.putAt(index, row);
    } catch (_) {
      await aktivitas.delete(eventKey);
      rethrow;
    }
  }

  static Future<void> updateAnimal({
    required int index,
    required String date,
    required String origin,
    required String kind,
    required double weightValue,
    required String purchasePrice,
    required String note,
    String? sex,
  }) async {
    if (index < 0 ||
        index >= domba.length ||
        date.trim().isEmpty ||
        origin.trim().isEmpty ||
        kind.trim().isEmpty ||
        !weightValue.isFinite ||
        weightValue <= 0) {
      throw ArgumentError(
        'Tanggal, asal, jenis, dan bobot positif wajib diisi.',
      );
    }
    final parsedPrice = purchasePrice.trim().isEmpty
        ? null
        : parseMoney(purchasePrice);
    if (purchasePrice.trim().isNotEmpty &&
        (parsedPrice == null || !parsedPrice.isFinite || parsedPrice < 0)) {
      throw ArgumentError('Harga beli domba tidak valid.');
    }
    final row = Map<String, dynamic>.from(domba.getAt(index));
    if (isSold(row)) throw StateError('Kambing terjual tidak dapat diedit.');
    dynamic historyKey;
    if (weightValue != weight(row)) {
      final recordedAt = DateTime.now();
      historyKey = await bobot.add({
        'id': 'edit-${recordedAt.microsecondsSinceEpoch}',
        'dombaId': row['id'],
        'kode': row['kode'],
        'tanggal': recordedAt.toIso8601String(),
        'waktuPencatatan': recordedAt.toIso8601String(),
        'bobot': weightValue,
        'catatan': 'Bobot diperbarui dari edit data',
      });
    }
    row.addAll({
      'tanggal': date.trim(),
      'tanggalMasuk': date.trim(),
      'asal': origin.trim(),
      'jenis': kind.trim(),
      'berat': weightValue.toString(),
      'bobotTerakhir': weightValue,
      'harga': parsedPrice?.toStringAsFixed(0) ?? '',
      'hargaBeli': parsedPrice?.toStringAsFixed(0) ?? '',
      'catatan': note.trim(),
      'keterangan': note.trim(),
    });
    if (sex != null && const {'Jantan', 'Betina'}.contains(sex)) {
      row['kelamin'] = sex;
    }
    try {
      await domba.putAt(index, row);
    } catch (_) {
      if (historyKey != null) await bobot.delete(historyKey);
      rethrow;
    }
  }

  /// Persists one sale transaction for one or more active animals. Writes are
  /// rolled back on failure so stock status and the sales ledger stay aligned.
  static Future<String> sellTransaction({
    required List<int> indices,
    required String date,
    required String buyer,
    required String whatsapp,
    required String destination,
    required String note,
    required Map<int, double> weights,
    required Map<int, String> prices,
    required String pricingMode,
    Map<String, dynamic> metadata = const {},
  }) => _withSaleLock(
    () => _sellTransactionNow(
      indices: indices,
      date: date,
      buyer: buyer,
      whatsapp: whatsapp,
      destination: destination,
      note: note,
      weights: weights,
      prices: prices,
      pricingMode: pricingMode,
      metadata: metadata,
    ),
  );

  static Future<String> _sellTransactionNow({
    required List<int> indices,
    required String date,
    required String buyer,
    required String whatsapp,
    required String destination,
    required String note,
    required Map<int, double> weights,
    required Map<int, String> prices,
    required String pricingMode,
    required Map<String, dynamic> metadata,
  }) async {
    if (indices.isEmpty || indices.toSet().length != indices.length) {
      throw ArgumentError('Pilih kambing yang valid untuk dijual.');
    }
    if (date.trim().isEmpty || buyer.trim().isEmpty) {
      throw ArgumentError('Tanggal dan nama pembeli wajib diisi.');
    }
    final original = <int, Map<String, dynamic>>{};
    final weightsByIndex = <int, double>{};
    final pricesByIndex = <int, double>{};
    for (final index in indices) {
      if (index < 0 || index >= domba.length) {
        throw ArgumentError('Data kambing tidak ditemukan.');
      }
      final row = Map<String, dynamic>.from(domba.getAt(index));
      if (isSold(row)) {
        throw StateError('Kambing ${row['kode']} sudah terjual.');
      }
      if ('${row['id'] ?? ''}'.isEmpty || '${row['kode'] ?? ''}'.isEmpty) {
        throw StateError('Identitas kambing tidak valid.');
      }
      final weightValue = weights[index] ?? weight(row);
      final priceValue = _moneyValue(prices[index]);
      if (!weightValue.isFinite ||
          weightValue <= 0 ||
          !priceValue.isFinite ||
          priceValue <= 0) {
        throw ArgumentError('Bobot dan harga jual harus lebih dari nol.');
      }
      original[index] = row;
      weightsByIndex[index] = weightValue;
      pricesByIndex[index] = priceValue;
    }

    final transactionId = nextSaleCode();
    final weightKeys = <dynamic>[];
    final activityKeys = <dynamic>[];
    var transactionWritten = false;
    try {
      final items = <Map<String, dynamic>>[];
      var total = 0.0;
      var totalWeight = 0.0;
      for (final index in indices) {
        final row = Map<String, dynamic>.from(original[index]!);
        final itemWeight = weightsByIndex[index]!;
        final itemPrice = pricesByIndex[index]!;
        final healthHistory = healthHistoryFor(row);
        final recordedAt = DateTime.now();
        weightKeys.add(
          await bobot.add({
            'id': '$transactionId-${row['kode']}-weight',
            'dombaId': row['id'],
            'kode': row['kode'],
            'tanggal': date,
            'waktuPencatatan': recordedAt.toIso8601String(),
            'bobot': itemWeight,
            'catatan': 'Bobot saat dijual',
          }),
        );
        row.addAll({
          ...metadata,
          'status': 'terjual',
          'tanggalJual': date,
          'namaPembeli': buyer,
          'asalPembeli': destination,
          'tujuan': destination,
          'catatanPenjualan': note,
          'beratJual': itemWeight,
          'bobotTerakhir': itemWeight,
          'berat': itemWeight.toString(),
          'hargaJual': itemPrice,
          'transaksiId': transactionId,
        });
        await domba.putAt(index, row);
        activityKeys.add(
          await aktivitas.add({
            'id': '$transactionId-${row['kode']}-sale',
            'dombaId': row['id'],
            'kode': row['kode'],
            'tipe': 'Penjualan',
            'tanggal': date,
            'nama': buyer,
            'jumlah': itemPrice,
            'satuan': pricingMode,
            'catatan': '$transactionId - $destination - $note',
          }),
        );
        items.add({
          ...metadata,
          'kode': row['kode'],
          'dombaId': row['id'],
          'hargaJual': itemPrice,
          'beratJual': itemWeight,
          'jenis': row['jenis'],
          'kelamin': row['kelamin'],
          'riwayatKesehatan': healthHistory,
        });
        total += itemPrice;
        totalWeight += itemWeight;
      }
      await penjualan.put(transactionId, {
        'transaksiId': transactionId,
        'tanggal': date,
        'namaPembeli': buyer,
        'whatsapp': whatsapp,
        'tujuan': destination,
        'modeHarga': pricingMode,
        'catatan': note,
        'items': items,
        'jumlahDomba': items.length,
        'totalBerat': totalWeight,
        'total': total,
        'source': 'penjualan_kambing',
        'metadata': metadata,
        'namaBatch': metadata['namaBatch'] ?? '',
        'kodeBatch': metadata['kodeBatch'] ?? '',
      });
      transactionWritten = true;
      return transactionId;
    } catch (_) {
      if (transactionWritten || penjualan.containsKey(transactionId)) {
        await penjualan.delete(transactionId);
      }
      for (final entry in original.entries) {
        await domba.putAt(entry.key, entry.value);
      }
      for (final key in weightKeys) {
        await bobot.delete(key);
      }
      for (final key in activityKeys) {
        await aktivitas.delete(key);
      }
      rethrow;
    }
  }

  static Future<String> sellMany({
    required List<int> indices,
    required String date,
    required String buyer,
    required String whatsapp,
    required String destination,
    required String note,
    required Map<int, double> weights,
    required Map<int, String> prices,
    required String pricingMode,
  }) => sellTransaction(
    indices: indices,
    date: date,
    buyer: buyer,
    whatsapp: whatsapp,
    destination: destination,
    note: note,
    weights: weights,
    prices: prices,
    pricingMode: pricingMode,
  );

  // ignore: unused_element
  static Future<String> _sellManyOld({
    required List<int> indices,
    required String date,
    required String buyer,
    required String whatsapp,
    required String destination,
    required String note,
    required Map<int, double> weights,
    required Map<int, String> prices,
    required String pricingMode,
  }) async {
    final trx = nextSaleCode();
    final items = <Map<String, dynamic>>[];
    var total = 0.0;
    var totalWeight = 0.0;
    for (final index in indices) {
      final row = Map<String, dynamic>.from(domba.getAt(index));
      if (isSold(row)) continue;
      final weightValue = weights[index] ?? weight(row);
      await recordWeight(index, weightValue, 'Bobot saat dijual', date: date);
      row.addAll({
        'status': 'terjual',
        'tanggalJual': date,
        'namaPembeli': buyer,
        'asalPembeli': destination,
        'tujuan': destination,
        'catatanPenjualan': note,
        'beratJual': '$weightValue',
        'bobotTerakhir': weightValue,
        'hargaJual': prices[index] ?? '',
        'transaksiId': trx,
      });
      await domba.putAt(index, row);
      await recordActivity(
        index,
        tipe: 'Penjualan',
        nama: buyer,
        jumlah: prices[index] ?? '',
        satuan: pricingMode,
        catatan: '$trx · $destination · $note',
      );
      final amount = double.tryParse(prices[index] ?? '') ?? 0;
      total += amount;
      totalWeight += weightValue;
      items.add({
        'kode': row['kode'],
        'dombaId': row['id'],
        'hargaJual': prices[index] ?? '',
        'beratJual': weightValue,
        'jenis': row['jenis'],
        'kelamin': row['kelamin'],
      });
    }
    await penjualan.put(trx, {
      'transaksiId': trx,
      'tanggal': date,
      'namaPembeli': buyer,
      'whatsapp': whatsapp,
      'tujuan': destination,
      'modeHarga': pricingMode,
      'catatan': note,
      'items': items,
      'jumlahDomba': items.length,
      'totalBerat': totalWeight,
      'total': total,
    });
    return trx;
  }
}
