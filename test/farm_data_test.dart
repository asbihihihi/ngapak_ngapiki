import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:ngapak_farm/farm_data.dart';
import 'package:ngapak_farm/health_data.dart';
import 'package:ngapak_farm/operations_data.dart';
import 'package:ngapak_farm/pages/batch_management_page.dart';
import 'package:ngapak_farm/pages/gudang_page.dart';
import 'package:ngapak_farm/pages/keuangan_page.dart';

void main() {
  late Directory testDirectory;

  setUpAll(() async {
    testDirectory = await Directory.systemTemp.createTemp('ngapak-farm-test-');
    Hive.init(testDirectory.path);
    await Hive.openBox('dombaBox');
    await Hive.openBox('penjualanBox');
    await Hive.openBox('bobotDombaBox');
    await Hive.openBox('aktivitasDombaBox');
    await Hive.openBox('barangBox');
    await Hive.openBox('pergerakanGudangBox');
    await Hive.openBox('keuanganBox');
    await Hive.openBox('batchBox');
    await Hive.openBox('healthRecordBox');
  });

  tearDown(() async {
    for (final box in [
      FarmData.domba,
      FarmData.penjualan,
      FarmData.bobot,
      FarmData.aktivitas,
      Hive.box('barangBox'),
      Hive.box('pergerakanGudangBox'),
      Hive.box('keuanganBox'),
      Hive.box('batchBox'),
      HealthData.records,
    ]) {
      if (box.isOpen) await box.clear();
    }
  });

  tearDownAll(() async {
    await Hive.close();
    await testDirectory.delete(recursive: true);
  });

  test('normalizes an existing single sale record for receipt history', () {
    final transaction = FarmData.normalizeSaleTransaction({
      'kode': 'DMB-000001',
      'dombaId': '1',
      'jenis': 'Garut',
      'nama': 'Pembeli Lama',
      'harga': '1500000',
      'tanggal': '2026-10-30',
      'beratJual': '25',
    }, legacyKey: '0');

    expect(transaction['transaksiId'], 'LEGACY-0');
    expect(transaction['items'], hasLength(1));
    expect(transaction['items'].single['dombaId'], '1');
    expect(transaction['total'], 1500000);
    expect(transaction['totalBerat'], 25);
    expect(FarmOperationsData.parseMoney('Rp 1.500.000'), 1500000);
  });

  test('recalculates current transaction totals from its item details', () {
    final transaction = FarmData.normalizeSaleTransaction({
      'transaksiId': 'TRX-1',
      'total': 1,
      'items': [
        {'kode': 'DMB-1', 'hargaJual': 1200, 'beratJual': 10},
        {'kode': 'DMB-2', 'hargaJual': 800, 'beratJual': 8},
      ],
    });

    expect(transaction['total'], 2000);
    expect(transaction['totalBerat'], 18);
    expect(transaction['jumlahDomba'], 2);
  });

  test(
    'saves a single animal sale with the shared transaction schema',
    () async {
      await FarmData.domba.add({
        'id': 'animal-1',
        'kode': 'DMB-000001',
        'qrCode': 'NGK-DMB-000001',
        'jenis': 'Garut',
        'kelamin': 'Jantan',
        'status': 'aktif',
        'bobotTerakhir': 20,
      });

      final id = await FarmData.sellTransaction(
        indices: [0],
        date: '2026-10-30',
        buyer: 'Pembeli',
        whatsapp: '0812345678',
        destination: 'Banyumas',
        note: '',
        weights: {0: 22},
        prices: {0: '1750000'},
        pricingMode: 'per ekor',
      );
      final transaction = FarmData.penjualan.get(id) as Map;

      expect(transaction['transaksiId'], id);
      expect(transaction['items'], hasLength(1));
      expect(transaction['total'], 1750000);
      expect((FarmData.domba.getAt(0) as Map)['status'], 'terjual');
      expect(FarmData.bobot.length, 1);
    },
  );

  test('rejects a duplicate sale for an already sold animal', () async {
    await FarmData.domba.add({
      'id': 'animal-sold',
      'kode': 'DMB-000002',
      'status': 'terjual',
      'bobotTerakhir': 20,
    });

    await expectLater(
      FarmData.sellTransaction(
        indices: [0],
        date: '2026-10-30',
        buyer: 'Pembeli',
        whatsapp: '',
        destination: '',
        note: '',
        weights: {0: 20},
        prices: {0: '1000'},
        pricingMode: 'per ekor',
      ),
      throwsA(isA<StateError>()),
    );
    expect(FarmData.penjualan, isEmpty);
  });

  test('concurrent sale attempts cannot sell one animal twice', () async {
    await FarmData.domba.add({
      'id': 'animal-concurrent',
      'kode': 'DMB-000022',
      'status': 'aktif',
      'bobotTerakhir': 20,
    });
    Future<bool> attempt(String buyer) => FarmData.sellTransaction(
      indices: [0],
      date: '2026-10-30',
      buyer: buyer,
      whatsapp: '',
      destination: '',
      note: '',
      weights: {0: 20},
      prices: {0: '1000000'},
      pricingMode: 'per ekor',
    ).then((_) => true, onError: (_) => false);

    final results = await Future.wait([
      attempt('Pembeli A'),
      attempt('Pembeli B'),
    ]);
    expect(results.where((success) => success), hasLength(1));
    expect(FarmData.penjualan, hasLength(1));
    expect(FarmData.bobot, hasLength(1));
  });

  test('records weight and health with histories and QR lookup', () async {
    await FarmData.domba.add({
      'id': 'animal-history',
      'kode': 'DMB-000003',
      'qrCode': 'NGK-DMB-000003',
      'status': 'aktif',
      'bobotAwal': 19,
      'bobotTerakhir': 19,
    });

    await FarmData.recordWeight(0, 21.5, 'Penimbangan berkala');
    await FarmData.recordHealth(
      0,
      status: 'Observasi',
      note: 'Nafsu makan menurun',
    );

    final row = FarmData.domba.getAt(0) as Map;
    expect(row['bobotTerakhir'], 21.5);
    expect(row['statusKesehatan'], 'Observasi');
    expect(FarmData.indexForQr('NGK-DMB-000003'), 0);
    expect(FarmData.bobot, hasLength(1));
    expect(FarmData.aktivitas, hasLength(1));
  });

  test(
    'backdated weighing does not replace the chronologically latest weight',
    () async {
      await FarmData.domba.add({
        'id': 'animal-weight-date',
        'kode': 'DMB-WEIGHT-DATE',
        'status': 'aktif',
        'bobotAwal': 18,
        'bobotTerakhir': 18,
      });
      final today = DateTime.now();
      final todayDate = today.toIso8601String().substring(0, 10);
      final yesterdayDate = today
          .subtract(const Duration(days: 1))
          .toIso8601String()
          .substring(0, 10);

      await FarmData.recordWeight(
        0,
        22,
        'Penimbangan terbaru',
        date: todayDate,
      );
      await FarmData.recordWeight(
        0,
        20,
        'Catatan terlambat',
        date: yesterdayDate,
      );

      expect((FarmData.domba.getAt(0) as Map)['bobotTerakhir'], 22);
      final metrics = FarmData.weightMetricsFor(FarmData.domba.getAt(0));
      expect(metrics['latest'], 22);
      expect(metrics['previousGain'], 2);
      expect(metrics['gain'], 2);
      expect(metrics['adg'], 2);
    },
  );

  test(
    'weight entry rejects invalid and future dates without saving',
    () async {
      await FarmData.domba.add({
        'id': 'animal-invalid-weight-date',
        'kode': 'DMB-INVALID-DATE',
        'status': 'aktif',
      });
      final futureDate = DateTime.now()
          .add(const Duration(days: 1))
          .toIso8601String()
          .substring(0, 10);

      await expectLater(
        FarmData.recordWeight(0, 20, 'Future', date: futureDate),
        throwsArgumentError,
      );
      await expectLater(
        FarmData.recordWeight(0, 20, 'Invalid date', date: '2026-02-31'),
        throwsArgumentError,
      );
      expect(FarmData.bobot, isEmpty);
      expect((FarmData.domba.getAt(0) as Map)['bobotTerakhir'], isNull);
    },
  );

  test(
    'batch weight entries are validated before any data is written',
    () async {
      for (var index = 0; index < 2; index++) {
        await FarmData.domba.add({
          'id': 'animal-bulk-weight-$index',
          'kode': 'DMB-BULK-$index',
          'status': 'aktif',
        });
      }

      await expectLater(
        FarmData.recordWeights([
          const AnimalWeightEntry(index: 0, value: 21, note: 'Timbang'),
          const AnimalWeightEntry(index: 1, value: double.nan, note: 'Timbang'),
        ]),
        throwsArgumentError,
      );
      expect(FarmData.bobot, isEmpty);
      expect((FarmData.domba.getAt(0) as Map)['bobotTerakhir'], isNull);
      expect((FarmData.domba.getAt(1) as Map)['bobotTerakhir'], isNull);
    },
  );

  test('ADG is omitted when weighings have no positive date range', () async {
    await FarmData.domba.add({
      'id': 'animal-same-day-weight',
      'kode': 'DMB-SAME-DAY',
      'status': 'aktif',
    });
    final today = DateTime.now().toIso8601String().substring(0, 10);

    await FarmData.recordWeight(0, 20, 'Timbang 1', date: today);
    await FarmData.recordWeight(0, 21, 'Timbang 2', date: today);

    final metrics = FarmData.weightMetricsFor(FarmData.domba.getAt(0));
    expect(metrics['latest'], 21);
    expect(metrics['gain'], 1);
    expect(metrics['adg'], isNull);
  });

  test(
    'health records stay linked to one animal and only exam changes status',
    () async {
      for (var index = 0; index < 2; index++) {
        await FarmData.domba.add({
          'id': 'animal-health-$index',
          'kode': 'DMB-HEALTH-$index',
          'status': 'aktif',
          'statusKesehatan': 'Perlu pemantauan',
        });
      }
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final dueDate = DateTime.now()
          .add(const Duration(days: 7))
          .toIso8601String()
          .substring(0, 10);

      await HealthData.addRecord(
        animalIndex: 0,
        type: HealthData.examination,
        date: today,
        note: 'Nafsu makan baik',
        staff: 'Petugas A',
        healthStatus: 'Sehat',
        symptoms: 'Tidak ada',
        result: 'Kondisi normal',
      );
      await HealthData.addRecord(
        animalIndex: 0,
        type: HealthData.vaccination,
        date: today,
        note: '',
        staff: 'Petugas A',
        vaccineName: 'Vaksin X',
        nextDueDate: dueDate,
      );
      await HealthData.addRecord(
        animalIndex: 0,
        type: HealthData.medication,
        date: today,
        note: '',
        staff: '',
        medicineName: 'Obat Y',
        reason: 'Sesuai resep',
      );

      final first = Map<String, dynamic>.from(FarmData.domba.getAt(0));
      final second = Map<String, dynamic>.from(FarmData.domba.getAt(1));
      final firstHistory = HealthData.historyFor(first);
      expect(firstHistory, hasLength(3));
      expect(firstHistory.map((record) => record['dombaId']).toSet(), {
        'animal-health-0',
      });
      expect(HealthData.historyFor(second), isEmpty);
      expect(first['statusKesehatan'], 'Sehat');
      expect(second['statusKesehatan'], 'Perlu pemantauan');
      expect(
        HealthData.vaccinationStatus(firstHistory, 'Vaksin X'),
        'Terjadwal',
      );
      expect(
        HealthData.vaccinationStatus(firstHistory, 'Vaksin belum tercatat'),
        'Belum dicatat',
      );
      await expectLater(
        HealthData.addRecord(
          animalIndex: 0,
          type: HealthData.vaccination,
          date: '2026-02-31',
          note: '',
          staff: '',
          vaccineName: 'Vaksin tanggal tidak valid',
        ),
        throwsArgumentError,
      );
      expect(HealthData.historyFor(first), hasLength(3));
      await FarmData.domba.putAt(0, {...first, 'status': 'terjual'});
      expect(HealthData.historyFor(FarmData.domba.getAt(0)), hasLength(3));
      expect((FarmData.domba.getAt(0) as Map)['statusKesehatan'], 'Sehat');
      final overdueDate = DateTime.now()
          .subtract(const Duration(days: 1))
          .toIso8601String()
          .substring(0, 10);
      expect(
        HealthData.vaccinationStatus([
          {
            'recordType': HealthData.vaccination,
            'namaVaksin': 'Vaksin Z',
            'tanggal': overdueDate,
            'waktuPencatatan': overdueDate,
            'jadwalBerikutnya': overdueDate,
          },
        ], 'Vaksin Z'),
        'Terlambat',
      );
    },
  );

  testWidgets('batch cards remain readable on a narrow phone layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(
      () => FarmData.domba.add({
        'id': 'animal-batch-responsive',
        'kode': 'DMB-RESPONSIVE',
        'batchId': 'BATCH-RESPONSIVE',
        'status': 'aktif',
        'bobotTerakhir': 20,
      }),
    );

    await tester.pumpWidget(const MaterialApp(home: BatchManagementPage()));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('BATCH-RESPONSIVE'), findsOneWidget);
    expect(find.text('Jumlah kambing'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('BATCH-RESPONSIVE'));
    await tester.pumpAndSettle();
    expect(find.text('Anggota batch (1)'), findsOneWidget);
    expect(find.text('DMB-RESPONSIVE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test(
    'creates a batch with one identity and initial weight per animal',
    () async {
      final rows = await FarmData.createBatch(
        count: 2,
        date: '2026-10-30',
        origin: 'Banyumas',
        kind: 'Garut',
        sex: 'Jantan',
        totalPrice: '2000000',
        note: '',
        batchId: 'BATCH-TEST-001',
        animalDetails: const [
          {'bobot': 20, 'jenis': 'Garut', 'kelamin': 'Jantan'},
          {'bobot': 22, 'jenis': 'Texel', 'kelamin': 'Betina'},
        ],
      );

      expect(rows, hasLength(2));
      expect(rows[0]['kode'], isNot(rows[1]['kode']));
      expect(FarmData.bobot, hasLength(2));
      expect(Hive.box('batchBox').get('BATCH-TEST-001')['jumlahDomba'], 2);
      expect(
        Hive.box('keuanganBox').get('BUY-BATCH-TEST-001')['jumlah'],
        2000000,
      );
      await expectLater(
        FarmData.createBatch(
          count: 2,
          date: '2026-10-30',
          origin: 'Banyumas',
          kind: 'Garut',
          sex: 'Jantan',
          totalPrice: '',
          note: '',
          batchId: 'BATCH-TEST-001',
          animalDetails: const [
            {'bobot': 20, 'jenis': 'Garut', 'kelamin': 'Jantan'},
            {'bobot': 22, 'jenis': 'Texel', 'kelamin': 'Betina'},
          ],
        ),
        throwsArgumentError,
      );
    },
  );

  test(
    'batch sale stores all animals in one transaction and totals items',
    () async {
      for (var index = 0; index < 2; index++) {
        await FarmData.domba.add({
          'id': 'batch-$index',
          'kode': 'DMB-${index + 10}',
          'jenis': 'Garut',
          'status': 'aktif',
          'bobotTerakhir': 20,
        });
      }
      await FarmData.recordHealth(0, status: 'Sehat', note: 'Kondisi baik');
      final id = await FarmData.sellTransaction(
        indices: [0, 1],
        date: '2026-10-30',
        buyer: 'Pembeli Batch',
        whatsapp: '',
        destination: 'Banyumas',
        note: '',
        weights: {0: 21, 1: 22},
        prices: {0: '1000000', 1: '1500000'},
        pricingMode: 'per ekor',
        metadata: {'namaBatch': 'Batch Banyumas', 'kodeBatch': 'JUAL-TEST'},
      );

      final sale = FarmData.penjualan.get(id) as Map;
      expect(sale['items'], hasLength(2));
      expect(sale['jumlahDomba'], 2);
      expect(sale['total'], 2500000);
      expect(sale['namaBatch'], 'Batch Banyumas');
      expect(sale['items'].first['riwayatKesehatan'], isNotEmpty);
      expect(
        FarmData.domba.values.every((row) => row['status'] == 'terjual'),
        isTrue,
      );
    },
  );

  test('warehouse opening stock and movements are the stock source', () async {
    final id = await FarmOperationsData.saveGoods(
      name: 'Pakan',
      category: 'Pakan',
      unit: 'kg',
      minimumStock: 2,
      openingStock: 10,
      purchasePrice: 100000,
    );
    expect(FarmOperationsData.stockFor(id), 10);
    expect(FarmOperationsData.historyFor(id), hasLength(1));
    expect(Hive.box('keuanganBox').get('BUY-$id')['jumlah'], 1000000);

    await FarmOperationsData.moveStock(
      operationId: 'move-1',
      itemId: id,
      type: 'Keluar',
      quantity: 4,
      date: '2026-10-30',
      note: 'Pemakaian',
    );
    expect(FarmOperationsData.stockFor(id), 6);
    expect(
      await FarmOperationsData.moveStock(
        operationId: 'move-1',
        itemId: id,
        type: 'Keluar',
        quantity: 4,
        date: '2026-10-30',
        note: 'Pemakaian',
      ),
      isFalse,
    );
    expect(FarmOperationsData.historyFor(id), hasLength(2));
    await expectLater(
      FarmOperationsData.moveStock(
        operationId: 'move-too-much',
        itemId: id,
        type: 'Keluar',
        quantity: 7,
        date: '2026-10-30',
        note: '',
      ),
      throwsA(isA<StateError>()),
    );
    expect(FarmOperationsData.stockFor(id), 6);
  });

  test(
    'medicine use lowers stock and feed is excluded from health history',
    () async {
      final animal = await FarmData.addAnimal(
        date: '2026-11-03',
        origin: 'Banyumas',
        kind: 'Garut',
        sex: 'Betina',
        initialWeight: 24,
      );
      final itemId = await FarmOperationsData.saveGoods(
        name: 'Vaksin Cacing',
        category: 'Obat-obatan',
        unit: 'dosis',
        minimumStock: 1,
        openingStock: 5,
      );

      await FarmOperationsData.useGoodsForAnimal(
        animalIndex: 0,
        itemId: itemId,
        quantity: 1,
        date: '2026-11-03T08:30:00',
        note: 'Diberikan setelah pemeriksaan.',
        staff: 'Petugas A',
      );

      expect(FarmOperationsData.stockFor(itemId), 4);
      final activity = FarmData.aktivitas.values.single;
      expect(activity['nama'], 'Vaksin Cacing');
      expect(activity['kategori'], 'Obat-obatan');
      expect(activity['tipe'], 'Pemberian Obat');
      expect(activity['kode'], animal['kode']);
      expect(activity['petugas'], 'Petugas A');
      expect(FarmData.healthHistoryFor(animal).single['nama'], 'Vaksin Cacing');
      final healthRecord = HealthData.historyFor(animal).single;
      expect(healthRecord['recordType'], HealthData.medication);
      expect(healthRecord['namaObat'], 'Vaksin Cacing');
      expect(healthRecord['dosis'], '1 dosis');

      final feedItemId = await FarmOperationsData.saveGoods(
        name: 'Rumput',
        category: 'Pakan',
        unit: 'kg',
        minimumStock: 1,
        openingStock: 10,
      );
      await FarmOperationsData.useGoodsForAnimal(
        animalIndex: 0,
        itemId: feedItemId,
        quantity: 2,
        date: '2026-11-03T08:35:00',
        note: '',
      );
      expect(FarmOperationsData.stockFor(feedItemId), 8);

      final transactionId = await FarmData.sellTransaction(
        indices: [0],
        date: '2026-11-03',
        buyer: 'Pembeli',
        whatsapp: '',
        destination: '',
        note: '',
        weights: {0: 24},
        prices: {0: '1000000'},
        pricingMode: 'per ekor',
      );
      final sale = FarmData.penjualan.get(transactionId) as Map;
      final receiptHistory = sale['items'].single['riwayatKesehatan'] as List;
      expect(
        receiptHistory.map((entry) => entry['nama']),
        contains('Vaksin Cacing'),
      );
      expect(
        receiptHistory.map((entry) => entry['nama']),
        isNot(contains('Rumput')),
      );
    },
  );

  test(
    'overlapping stock withdrawals are serialized before balance checks',
    () async {
      final id = await FarmOperationsData.saveGoods(
        name: 'Obat',
        category: 'Obat-obatan',
        unit: 'botol',
        minimumStock: 1,
        openingStock: 10,
      );
      Future<bool> withdraw(String operationId) => FarmOperationsData.moveStock(
        operationId: operationId,
        itemId: id,
        type: 'Keluar',
        quantity: 7,
        date: '2026-10-30',
        note: '',
      ).then((_) => true, onError: (_) => false);

      final results = await Future.wait([withdraw('out-a'), withdraw('out-b')]);
      expect(results.where((success) => success), hasLength(1));
      expect(FarmOperationsData.stockFor(id), 3);
    },
  );

  test(
    'financial summary counts sale income once and manual expenses',
    () async {
      await FarmData.penjualan.put('old-sale', {
        'kode': 'DMB-9',
        'nama': 'Pembeli Lama',
        'harga': '250000',
        'tanggal': '2026-10-30',
      });
      await FarmOperationsData.addFinanceEntry(
        type: 'Pengeluaran',
        category: 'Pakan',
        amount: 50000,
        date: '2026-10-30',
        note: 'Belanja pakan',
      );

      final summary = FarmOperationsData.financeSummary(
        from: DateTime(2026, 10, 30),
        through: DateTime(2026, 10, 30),
      );
      expect(summary['pemasukan'], 250000);
      expect(summary['pengeluaran'], 50000);
      expect(summary['selisih'], 200000);
    },
  );

  test('sale write failure rolls back the animal and weight history', () async {
    await FarmData.domba.add({
      'id': 'rollback-animal',
      'kode': 'DMB-000004',
      'status': 'aktif',
      'bobotTerakhir': 18,
    });
    await FarmData.aktivitas.close();
    try {
      await expectLater(
        FarmData.sellTransaction(
          indices: [0],
          date: '2026-10-30',
          buyer: 'Pembeli',
          whatsapp: '',
          destination: '',
          note: '',
          weights: {0: 20},
          prices: {0: '1000'},
          pricingMode: 'per ekor',
        ),
        throwsA(anything),
      );
    } finally {
      await Hive.openBox('aktivitasDombaBox');
    }
    expect((FarmData.domba.getAt(0) as Map)['status'], 'aktif');
    expect(FarmData.bobot, isEmpty);
    expect(FarmData.penjualan, isEmpty);
  });

  testWidgets('warehouse screen exposes item creation and empty state', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: GudangPage()));
    await tester.pumpAndSettle();

    expect(find.text('Manajemen Gudang'), findsOneWidget);
    expect(find.textContaining('Belum ada barang'), findsOneWidget);
    await tester.tap(find.text('Tambah barang'));
    await tester.pumpAndSettle();
    expect(find.text('Nama barang'), findsOneWidget);
  });

  test(
    'creates an animal with stable ID, QR and opening weight history',
    () async {
      final animal = await FarmData.addAnimal(
        date: '2026-10-30',
        origin: 'Peternak Lokal',
        kind: 'Garut',
        sex: 'Jantan',
        initialWeight: 20,
        purchasePrice: '1500000',
      );

      expect(animal['id'], isNotEmpty);
      expect(animal['status'], 'aktif');
      expect(animal['qrCode'], 'NGK-${animal['kode']}');
      expect(FarmData.indexForQr(animal['qrCode']), 0);
      expect(FarmData.bobot, hasLength(1));
      expect(
        Hive.box('keuanganBox').get('BUY-${animal['kode']}')['jumlah'],
        1500000,
      );
    },
  );

  testWidgets('finance screen shows sales and expense summaries', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: KeuanganPage()));
    await tester.pumpAndSettle();

    expect(find.text('Manajemen Keuangan'), findsOneWidget);
    expect(find.text('Pemasukan'), findsOneWidget);
    expect(find.text('Pengeluaran'), findsOneWidget);
    expect(find.text('Belum ada transaksi pada rentang ini.'), findsOneWidget);
  });

  test('edits animal fields and records a changed weight in history', () async {
    await FarmData.addAnimal(
      date: '2026-10-01',
      origin: 'Peternak Lama',
      kind: 'Lokal',
      sex: 'Betina',
      initialWeight: 18,
    );
    await FarmData.updateAnimal(
      index: 0,
      date: '2026-10-30',
      origin: 'Peternak Baru',
      kind: 'Garut',
      weightValue: 20,
      purchasePrice: '1800000',
      note: 'Data diperbarui',
    );

    final animal = FarmData.domba.getAt(0) as Map;
    expect(animal['jenis'], 'Garut');
    expect(animal['asal'], 'Peternak Baru');
    expect(animal['hargaBeli'], '1800000');
    expect(animal['bobotTerakhir'], 20);
    expect(FarmData.bobot, hasLength(2));
  });
}
