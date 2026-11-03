import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:ngapak_farm/auth_data.dart';
import 'package:ngapak_farm/operations_data.dart';
import 'package:ngapak_farm/pages/pos_page.dart';
import 'package:ngapak_farm/pos_data.dart';

void main() {
  late Directory testDirectory;

  setUpAll(() async {
    testDirectory = await Directory.systemTemp.createTemp('farm-pos-test-');
    Hive.init(testDirectory.path);
    await Hive.openBox('userBox');
    await Hive.openBox('sessionBox');
    await Hive.openBox('posProductBox');
    await Hive.openBox('posSaleBox');
    await Hive.openBox('keuanganBox');
    await Hive.openBox('penjualanBox');
  });

  setUp(() async {
    await AuthData.users.clear();
    await AuthData.session.clear();
    await PosData.products.clear();
    await PosData.sales.clear();
    await PosData.ledger.clear();
    await AuthData.registerOwner(
      name: 'Pemilik',
      email: 'pemilik@example.com',
      password: 'rahasia123',
    );
  });

  tearDownAll(() async {
    await Hive.close();
    await testDirectory.delete(recursive: true);
  });

  test('owner manages products and employee can only sell them', () async {
    final productId = await PosData.saveProduct(
      name: 'Iga',
      description: 'Iga segar',
      pricePerKg: 150000,
      openingStockKg: 20,
    );
    await AuthData.createEmployee(
      name: 'Kasir',
      email: 'kasir@example.com',
      password: 'karyawan123',
    );
    await AuthData.logout();
    await AuthData.login(email: 'kasir@example.com', password: 'karyawan123');

    expect(PosData.isOwner, isFalse);
    await expectLater(
      PosData.saveProduct(
        name: 'Produk terlarang',
        description: '',
        pricePerKg: 1,
        openingStockKg: 1,
      ),
      throwsA(isA<StateError>()),
    );

    final saleId = await PosData.checkout(
      quantitiesKg: {productId: 2.5},
      paymentMethod: 'Cash',
      paidAmount: 500000,
    );

    final sale = PosData.sales.get(saleId) as Map;
    expect(sale['items'].single['nama'], 'Iga');
    expect(sale['totalBeratKg'], 2.5);
    expect(sale['total'], 375000);
    expect(sale['kembalian'], 125000);
    expect(sale['namaKasir'], 'Kasir');
    expect((PosData.products.get(productId) as Map)['stokKg'], 17.5);
    expect(PosData.ledger.get(saleId)['jenis'], 'Pemasukan');
    expect(PosData.ledger.get(saleId)['sumber'], 'penjualan_pos');
    expect(FarmOperationsData.financeSummary()['pemasukan'], 375000);
    expect(PosData.totalSoldKg, 2.5);
    expect(PosData.totalSales, 375000);

    await AuthData.logout();
    await AuthData.login(email: 'pemilik@example.com', password: 'rahasia123');
    await PosData.addStock(productId, 5);
    expect((PosData.products.get(productId) as Map)['stokKg'], 22.5);
    await PosData.deleteProduct(productId);
    expect(PosData.productList(), isEmpty);
    expect((PosData.products.get(productId) as Map)['aktif'], isFalse);
  });

  test(
    'QRIS checkout requires proof and stores proof path with receipt data',
    () async {
      final productId = await PosData.saveProduct(
        name: 'Daging',
        description: '',
        pricePerKg: 100000,
        openingStockKg: 3,
      );

      await expectLater(
        PosData.checkout(
          quantitiesKg: {productId: 1},
          paymentMethod: 'QRIS',
          paidAmount: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect((PosData.products.get(productId) as Map)['stokKg'], 3);

      final saleId = await PosData.checkout(
        quantitiesKg: {productId: 1},
        paymentMethod: 'QRIS',
        paidAmount: 0,
        paymentProofPath: 'proof.png',
      );

      expect(
        (PosData.sales.get(saleId) as Map)['buktiPembayaran'],
        'proof.png',
      );
      expect((PosData.products.get(productId) as Map)['stokKg'], 2);
      expect(PosData.ledger.containsKey(saleId), isTrue);
    },
  );

  test('checkout rejects insufficient stock without creating a sale', () async {
    final productId = await PosData.saveProduct(
      name: 'Daging',
      description: '',
      pricePerKg: 100000,
      openingStockKg: 1,
    );

    await expectLater(
      PosData.checkout(
        quantitiesKg: {productId: 1.5},
        paymentMethod: 'Cash',
        paidAmount: 200000,
      ),
      throwsA(isA<StateError>()),
    );
    expect(PosData.sales, isEmpty);
    expect(PosData.ledger, isEmpty);
    expect((PosData.products.get(productId) as Map)['stokKg'], 1);
  });

  testWidgets('only owner sees POS product management controls', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PosPage()));
    await tester.pump();
    expect(find.byTooltip('Tambah produk'), findsOneWidget);

    await tester.runAsync(() async {
      await AuthData.createEmployee(
        name: 'Kasir',
        email: 'kasir@example.com',
        password: 'karyawan123',
      );
      await AuthData.logout();
      await AuthData.login(email: 'kasir@example.com', password: 'karyawan123');
    });
    await tester.pumpWidget(const MaterialApp(home: PosPage()));
    await tester.pump();

    expect(find.byTooltip('Tambah produk'), findsNothing);
    expect(find.text('Belum ada produk daging.'), findsOneWidget);
  });
}
