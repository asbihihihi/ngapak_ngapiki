import 'dart:async';

import 'package:hive/hive.dart';

import 'farm_data.dart';
import 'money_format.dart';

/// Storage operations for inventory and the non-sale financial ledger.
/// Sales are read from penjualanBox so sale income cannot be entered twice.
class FarmOperationsData {
  static Future<void> _stockQueue = Future<void>.value();

  static Box get goods => Hive.box('barangBox');
  static Box get movements => Hive.box('pergerakanGudangBox');
  static Box get ledger => Hive.box('keuanganBox');

  static String nextGoodsId() {
    var number = 1;
    while (goods.containsKey('BRG-${number.toString().padLeft(6, '0')}')) {
      number++;
    }
    return 'BRG-${number.toString().padLeft(6, '0')}';
  }

  static Future<T> _withStockLock<T>(Future<T> Function() operation) {
    final result = Completer<T>();
    _stockQueue = _stockQueue.then((_) async {
      try {
        result.complete(await operation());
      } catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      }
    });
    return result.future;
  }

  static Future<String> saveGoods({
    String? id,
    required String name,
    required String category,
    required String unit,
    required double minimumStock,
    double openingStock = 0,
    double? purchasePrice,
  }) => _withStockLock(
    () => _saveGoodsNow(
      id: id,
      name: name,
      category: category,
      unit: unit,
      minimumStock: minimumStock,
      openingStock: openingStock,
      purchasePrice: purchasePrice,
    ),
  );

  static Future<String> _saveGoodsNow({
    String? id,
    required String name,
    required String category,
    required String unit,
    required double minimumStock,
    required double openingStock,
    required double? purchasePrice,
  }) async {
    final normalizedName = name.trim();
    final normalizedUnit = unit.trim();
    if (normalizedName.isEmpty ||
        normalizedUnit.isEmpty ||
        !minimumStock.isFinite ||
        minimumStock < 0 ||
        !openingStock.isFinite ||
        openingStock < 0 ||
        (purchasePrice != null &&
            (!purchasePrice.isFinite || purchasePrice < 0))) {
      throw ArgumentError('Nama, satuan, dan nilai stok harus valid.');
    }
    if (!const {'Pakan', 'Obat-obatan', 'Perlengkapan'}.contains(category)) {
      throw ArgumentError('Pilih kategori barang yang valid.');
    }
    final itemId = id ?? nextGoodsId();
    if (id == null && goods.containsKey(itemId)) {
      throw StateError('ID barang sudah digunakan.');
    }
    final existed = goods.containsKey(itemId);
    final old = existed ? Map<String, dynamic>.from(goods.get(itemId)) : null;
    final unitPrice = purchasePrice ?? _number(old?['hargaBeliSatuan']);
    final expenseId = 'BUY-$itemId';
    if (!existed &&
        openingStock > 0 &&
        unitPrice > 0 &&
        ledger.containsKey(expenseId)) {
      throw StateError('Pengeluaran stok awal sudah pernah dicatat.');
    }
    dynamic movementId;
    var goodsWritten = false;
    var expenseWritten = false;
    try {
      await goods.put(itemId, {
        'id': itemId,
        'nama': normalizedName,
        'kategori': category,
        'satuan': normalizedUnit,
        'batasMinimum': minimumStock,
        'hargaBeliSatuan': unitPrice,
        'dibuatPada': old?['dibuatPada'] ?? DateTime.now().toIso8601String(),
        'diperbaruiPada': DateTime.now().toIso8601String(),
      });
      goodsWritten = true;
      if (!existed && openingStock > 0) {
        movementId = 'OPEN-$itemId';
        await movements.put(movementId, {
          'id': movementId,
          'barangId': itemId,
          'tipe': 'Masuk',
          'jumlah': openingStock,
          'tanggal': DateTime.now().toIso8601String(),
          'keterangan': 'Stok awal',
        });
      }
      final totalPurchase = openingStock * unitPrice;
      if (!existed && totalPurchase > 0) {
        await ledger.put(expenseId, {
          'id': expenseId,
          'jenis': 'Pengeluaran',
          'kategori': category,
          'jumlah': totalPurchase,
          'tanggal': DateTime.now().toIso8601String(),
          'keterangan':
              'Pembelian stok awal $normalizedName · '
              '${openingStock.toStringAsFixed(2)} $normalizedUnit × '
              'Rp ${unitPrice.toStringAsFixed(0)}',
          'sumber': 'pembelian_barang',
          'barangId': itemId,
          'namaBarang': normalizedName,
          'jumlahStok': openingStock,
          'hargaBeliSatuan': unitPrice,
        });
        expenseWritten = true;
      }
    } catch (_) {
      if (expenseWritten && ledger.containsKey(expenseId)) {
        await ledger.delete(expenseId);
      }
      if (movementId != null && movements.containsKey(movementId)) {
        await movements.delete(movementId);
      }
      if (goodsWritten) {
        if (existed && old != null) {
          await goods.put(itemId, old);
        } else {
          await goods.delete(itemId);
        }
      }
      rethrow;
    }
    return itemId;
  }

  static double stockFor(String itemId) {
    var total = 0.0;
    for (final movement in movements.values) {
      if (movement['barangId'] != itemId) continue;
      final quantity = _number(movement['jumlah']);
      total += movement['tipe'] == 'Keluar' ? -quantity : quantity;
    }
    return total;
  }

  static List<Map<String, dynamic>> historyFor(String itemId) =>
      movements.values
          .where((movement) => movement['barangId'] == itemId)
          .map((movement) => Map<String, dynamic>.from(movement))
          .toList()
        ..sort((a, b) => '${b['tanggal']}'.compareTo('${a['tanggal']}'));

  static Future<bool> moveStock({
    required String operationId,
    required String itemId,
    required String type,
    required double quantity,
    required String date,
    required String note,
  }) => _withStockLock(
    () => _moveStockNow(
      operationId: operationId,
      itemId: itemId,
      type: type,
      quantity: quantity,
      date: date,
      note: note,
    ),
  );

  static Future<bool> _moveStockNow({
    required String operationId,
    required String itemId,
    required String type,
    required double quantity,
    required String date,
    required String note,
  }) async {
    if (operationId.trim().isEmpty) {
      throw ArgumentError('ID pergerakan stok wajib diisi.');
    }
    if (movements.containsKey(operationId)) return false;
    if (!goods.containsKey(itemId)) throw StateError('Barang tidak ditemukan.');
    if (!const {'Masuk', 'Keluar'}.contains(type) ||
        !quantity.isFinite ||
        quantity <= 0 ||
        date.trim().isEmpty) {
      throw ArgumentError('Jenis, tanggal, dan jumlah harus valid.');
    }
    final current = stockFor(itemId);
    if (type == 'Keluar' && quantity > current) {
      throw StateError('Stok tersedia hanya ${current.toStringAsFixed(2)}.');
    }
    await movements.put(operationId, {
      'id': operationId,
      'barangId': itemId,
      'tipe': type,
      'jumlah': quantity,
      'tanggal': date,
      'keterangan': note.trim(),
    });
    return true;
  }

  static Future<void> useGoodsForAnimal({
    required int animalIndex,
    required String itemId,
    required double quantity,
    required String date,
    required String note,
  }) => _withStockLock(() async {
    if (animalIndex < 0 || animalIndex >= FarmData.domba.length) {
      throw ArgumentError('Data domba tidak ditemukan.');
    }
    if (!goods.containsKey(itemId)) {
      throw StateError('Barang gudang tidak ditemukan.');
    }
    if (!quantity.isFinite || quantity <= 0 || date.trim().isEmpty) {
      throw ArgumentError('Jumlah barang dan tanggal harus valid.');
    }
    final animal = Map<String, dynamic>.from(
      FarmData.domba.getAt(animalIndex),
    );
    if (FarmData.isSold(animal)) {
      throw StateError('Aktivitas kambing terjual tidak dapat diubah.');
    }
    final item = Map<String, dynamic>.from(goods.get(itemId));
    final currentStock = stockFor(itemId);
    if (quantity > currentStock) {
      throw StateError(
        'Stok ${item['nama']} tersedia hanya '
        '${currentStock.toStringAsFixed(2)} ${item['satuan']}.',
      );
    }

    final operationId = 'USE-${DateTime.now().microsecondsSinceEpoch}';
    final activityId = '$operationId-${animal['kode']}';
    final category = '${item['kategori'] ?? ''}';
    final type = category == 'Obat-obatan'
        ? 'Pemeriksaan Kesehatan'
        : 'Aktivitas Gudang';
    var movementWritten = false;
    try {
      await movements.put(operationId, {
        'id': operationId,
        'barangId': itemId,
        'tipe': 'Keluar',
        'jumlah': quantity,
        'tanggal': date,
        'keterangan':
            'Pemakaian untuk ${animal['kode']} · ${item['nama']}'
            '${note.trim().isEmpty ? '' : ' · ${note.trim()}'}',
        'dombaId': animal['id'],
        'kodeDomba': animal['kode'],
      });
      movementWritten = true;
      await FarmData.aktivitas.add({
        'id': activityId,
        'dombaId': animal['id'],
        'kode': animal['kode'],
        'tipe': type,
        'kategori': category,
        'barangId': itemId,
        'tanggal': date,
        'nama': item['nama'],
        'jumlah': quantity,
        'satuan': item['satuan'],
        'catatan': note.trim(),
      });
    } catch (_) {
      if (movementWritten) await movements.delete(operationId);
      rethrow;
    }
  });

  static String nextLedgerId() {
    final base = 'FIN-${DateTime.now().microsecondsSinceEpoch}';
    var id = base;
    var suffix = 1;
    while (ledger.containsKey(id)) {
      id = '$base-$suffix';
      suffix++;
    }
    return id;
  }

  static double? parseMoney(String input) {
    return parseMoneyInput(input);
  }

  static Future<String> addFinanceEntry({
    required String type,
    required String category,
    required double amount,
    required String date,
    required String note,
  }) async {
    if (!const {'Pemasukan', 'Pengeluaran'}.contains(type) ||
        category.trim().isEmpty ||
        !amount.isFinite ||
        amount <= 0 ||
        date.trim().isEmpty) {
      throw ArgumentError('Jenis, kategori, tanggal, dan nominal harus valid.');
    }
    final id = nextLedgerId();
    await ledger.put(id, {
      'id': id,
      'jenis': type,
      'kategori': category.trim(),
      'jumlah': amount,
      'tanggal': date,
      'keterangan': note.trim(),
      'sumber': 'manual',
    });
    return id;
  }

  static List<Map<String, dynamic>> financeEntries({
    String type = 'Semua',
    DateTime? from,
    DateTime? through,
  }) {
    final rows = <Map<String, dynamic>>[];
    for (final entry in ledger.values) {
      final row = Map<String, dynamic>.from(entry);
      if (type != 'Semua' && row['jenis'] != type) continue;
      if (!_withinDate(row['tanggal'], from, through)) continue;
      rows.add(row);
    }
    for (final raw in FarmData.penjualan.values) {
      final sale = FarmData.normalizeSaleTransaction(raw as Map);
      if (type != 'Semua' && type != 'Pemasukan') continue;
      if (!_withinDate(sale['tanggal'], from, through)) continue;
      rows.add({
        'id': sale['transaksiId'],
        'jenis': 'Pemasukan',
        'kategori': 'Penjualan kambing',
        'jumlah': sale['total'],
        'tanggal': sale['tanggal'],
        'keterangan':
            [
              if ('${sale['namaBatch'] ?? ''}'.trim().isNotEmpty)
                '${sale['namaBatch']}',
              '${sale['namaPembeli'] ?? ''}',
              '${sale['jumlahDomba']} ekor',
            ].join(' · '),
        'sumber': 'penjualan',
      });
    }
    rows.sort((a, b) => '${b['tanggal']}'.compareTo('${a['tanggal']}'));
    return rows;
  }

  static Map<String, double> financeSummary({
    DateTime? from,
    DateTime? through,
  }) {
    var income = 0.0;
    var expense = 0.0;
    for (final row in financeEntries(from: from, through: through)) {
      final amount = _number(row['jumlah']);
      if (row['jenis'] == 'Pemasukan') {
        income += amount;
      } else {
        expense += amount;
      }
    }
    return {
      'pemasukan': income,
      'pengeluaran': expense,
      'selisih': income - expense,
    };
  }

  static bool _withinDate(dynamic raw, DateTime? from, DateTime? through) {
    if (from == null && through == null) return true;
    final date = DateTime.tryParse('$raw');
    if (date == null) return false;
    final day = DateTime(date.year, date.month, date.day);
    if (from != null &&
        day.isBefore(DateTime(from.year, from.month, from.day))) {
      return false;
    }
    if (through != null &&
        day.isAfter(DateTime(through.year, through.month, through.day))) {
      return false;
    }
    return true;
  }

  static double _number(dynamic value) =>
      double.tryParse('$value'.trim().replaceAll(',', '.')) ?? 0;
}
