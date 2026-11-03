import 'dart:async';

import 'package:hive/hive.dart';

import 'auth_data.dart';

class PosData {
  static Future<void> _saleQueue = Future<void>.value();

  static Box get products => Hive.box('posProductBox');
  static Box get sales => Hive.box('posSaleBox');
  static Box get ledger => Hive.box('keuanganBox');

  static bool get isOwner =>
      AuthData.currentUser?['role'] == AuthData.ownerRole;

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

  static String _newId(String prefix, Box box) {
    final base = '$prefix-${DateTime.now().microsecondsSinceEpoch}';
    var id = base;
    var suffix = 1;
    while (box.containsKey(id)) {
      id = '$base-$suffix';
      suffix++;
    }
    return id;
  }

  static List<Map<String, dynamic>> productList({bool activeOnly = true}) =>
      products.values
          .map((raw) => Map<String, dynamic>.from(raw as Map))
          .where((product) => !activeOnly || product['aktif'] != false)
          .toList()
        ..sort(
          (a, b) => '${a['nama']}'.toLowerCase().compareTo(
            '${b['nama']}'.toLowerCase(),
          ),
        );

  static Future<String> saveProduct({
    String? id,
    required String name,
    required String description,
    required double pricePerKg,
    double openingStockKg = 0,
  }) async {
    if (!isOwner) throw StateError('Hanya pemilik yang dapat mengelola produk.');
    final normalizedName = name.trim();
    if (normalizedName.isEmpty ||
        !pricePerKg.isFinite ||
        pricePerKg <= 0 ||
        !openingStockKg.isFinite ||
        openingStockKg < 0) {
      throw ArgumentError(
        'Nama, harga per kg, dan stok produk harus valid.',
      );
    }
    if (id != null && !products.containsKey(id)) {
      throw StateError('Produk tidak ditemukan.');
    }
    final productId = id ?? _newId('DAGING', products);
    final existing = id == null
        ? null
        : Map<String, dynamic>.from(products.get(id));
    await products.put(productId, {
      'id': productId,
      'nama': normalizedName,
      'deskripsi': description.trim(),
      'hargaPerKg': pricePerKg,
      'stokKg': existing?['stokKg'] ?? openingStockKg,
      'aktif': true,
      'dibuatPada': existing?['dibuatPada'] ?? DateTime.now().toIso8601String(),
      'diperbaruiPada': DateTime.now().toIso8601String(),
    });
    return productId;
  }

  static Future<void> deleteProduct(String id) async {
    if (!isOwner) throw StateError('Hanya pemilik yang dapat mengelola produk.');
    if (!products.containsKey(id)) throw StateError('Produk tidak ditemukan.');
    final product = Map<String, dynamic>.from(products.get(id));
    product['aktif'] = false;
    product['diperbaruiPada'] = DateTime.now().toIso8601String();
    await products.put(id, product);
  }

  static Future<void> addStock(String id, double quantityKg) async {
    if (!isOwner) throw StateError('Hanya pemilik yang dapat mengelola produk.');
    if (!quantityKg.isFinite || quantityKg <= 0) {
      throw ArgumentError('Jumlah stok tambahan harus lebih dari nol.');
    }
    if (!products.containsKey(id)) throw StateError('Produk tidak ditemukan.');
    final product = Map<String, dynamic>.from(products.get(id));
    if (product['aktif'] == false) {
      throw StateError('Produk nonaktif tidak dapat ditambah stoknya.');
    }
    product['stokKg'] = _number(product['stokKg']) + quantityKg;
    product['diperbaruiPada'] = DateTime.now().toIso8601String();
    await products.put(id, product);
  }

  static Future<String> checkout({
    required Map<String, double> quantitiesKg,
    required String paymentMethod,
    required double paidAmount,
    String paymentProofPath = '',
  }) => _withSaleLock(
    () => _checkoutNow(
      quantitiesKg: quantitiesKg,
      paymentMethod: paymentMethod,
      paidAmount: paidAmount,
      paymentProofPath: paymentProofPath,
    ),
  );

  static Future<String> _checkoutNow({
    required Map<String, double> quantitiesKg,
    required String paymentMethod,
    required double paidAmount,
    required String paymentProofPath,
  }) async {
    final user = AuthData.currentUser;
    if (user == null ||
        !const {AuthData.ownerRole, AuthData.employeeRole}.contains(
          user['role'],
        )) {
      throw StateError('Masuk ke akun pemilik atau karyawan untuk berjualan.');
    }
    if (quantitiesKg.isEmpty ||
        !const {'Cash', 'QRIS'}.contains(paymentMethod)) {
      throw ArgumentError('Keranjang dan metode pembayaran harus valid.');
    }
    if (!paidAmount.isFinite || paidAmount < 0) {
      throw ArgumentError('Jumlah pembayaran tidak valid.');
    }
    if (paymentMethod == 'QRIS' && paymentProofPath.trim().isEmpty) {
      throw ArgumentError('Foto bukti pembayaran QRIS wajib dilampirkan.');
    }

    final items = <Map<String, dynamic>>[];
    var total = 0.0;
    var totalWeight = 0.0;
    final productSnapshots = <String, Map<String, dynamic>>{};
    for (final entry in quantitiesKg.entries) {
      if (!entry.value.isFinite || entry.value <= 0) {
        throw ArgumentError('Berat produk harus lebih dari nol.');
      }
      if (!products.containsKey(entry.key)) {
        throw StateError('Produk sudah tidak tersedia.');
      }
      final product = Map<String, dynamic>.from(products.get(entry.key));
      if (product['aktif'] == false) {
        throw StateError('Produk ${product['nama']} sudah tidak aktif.');
      }
      final stock = _number(product['stokKg']);
      if (entry.value > stock) {
        throw StateError(
          'Stok ${product['nama']} tersisa ${stock.toStringAsFixed(2)} kg.',
        );
      }
      final unitPrice = _number(product['hargaPerKg']);
      final lineTotal = (unitPrice * entry.value).roundToDouble();
      productSnapshots[entry.key] = product;
      items.add({
        'produkId': entry.key,
        'nama': product['nama'],
        'deskripsi': product['deskripsi'] ?? '',
        'beratKg': entry.value,
        'hargaPerKg': unitPrice,
        'subtotal': lineTotal,
      });
      total += lineTotal;
      totalWeight += entry.value;
    }
    if (paymentMethod == 'Cash' && paidAmount < total) {
      throw ArgumentError('Nominal uang diterima kurang dari total belanja.');
    }
    if (paymentMethod == 'QRIS' && paidAmount != 0 && paidAmount < total) {
      throw ArgumentError('Nominal QRIS harus mencukupi total belanja.');
    }

    final id = _newId('POS', sales);
    final saleDate = DateTime.now().toIso8601String();
    final sale = <String, dynamic>{
      'id': id,
      'tanggal': saleDate,
      'items': items,
      'totalBeratKg': totalWeight,
      'total': total,
      'metodePembayaran': paymentMethod,
      'uangDiterima': paymentMethod == 'Cash' ? paidAmount : total,
      'kembalian': paymentMethod == 'Cash' ? paidAmount - total : 0,
      'buktiPembayaran': paymentMethod == 'QRIS' ? paymentProofPath : '',
      'kasirId': user['id'] ?? '',
      'namaKasir': user['nama'] ?? 'Kasir',
    };

    try {
      for (final item in items) {
        final product = Map<String, dynamic>.from(
          productSnapshots[item['produkId']]!,
        );
        product['stokKg'] = _number(product['stokKg']) - _number(item['beratKg']);
        product['diperbaruiPada'] = saleDate;
        await products.put('${item['produkId']}', product);
      }
      await sales.put(id, sale);
      await ledger.put(id, {
        'id': id,
        'jenis': 'Pemasukan',
        'kategori': 'Penjualan produk daging',
        'jumlah': total,
        'tanggal': saleDate,
        'keterangan':
            '${items.length} jenis produk · ${totalWeight.toStringAsFixed(2)} kg · $paymentMethod',
        'sumber': 'penjualan_pos',
        'transaksiId': id,
      });
      return id;
    } catch (_) {
      if (ledger.containsKey(id)) await ledger.delete(id);
      if (sales.containsKey(id)) await sales.delete(id);
      for (final entry in productSnapshots.entries) {
        await products.put(entry.key, entry.value);
      }
      rethrow;
    }
  }

  static double get totalSoldKg => sales.values.fold<double>(
    0,
    (total, raw) => total + _number((raw as Map)['totalBeratKg']),
  );

  static double get totalSales => sales.values.fold<double>(
    0,
    (total, raw) => total + _number((raw as Map)['total']),
  );

  static double _number(dynamic value) =>
      double.tryParse('$value'.trim().replaceAll(',', '.')) ?? 0;
}
