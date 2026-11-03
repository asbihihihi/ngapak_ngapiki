import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'pages/auth_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  await Hive.openBox('dombaBox');
  await Hive.openBox('penjualanBox');
  await Hive.openBox('bobotDombaBox');
  await Hive.openBox('aktivitasDombaBox');
  await Hive.openBox('batchBox');
  await Hive.openBox('barangBox');
  await Hive.openBox('pergerakanGudangBox');
  await Hive.openBox('keuanganBox');
  await Hive.openBox('posProductBox');
  await Hive.openBox('posSaleBox');
  await Hive.openBox('userBox');
  await Hive.openBox('dailyReportBox');
  await Hive.openBox('sessionBox');

  final dombaBox = Hive.box('dombaBox');
  final bobotBox = Hive.box('bobotDombaBox');
  for (var i = 0; i < dombaBox.length; i++) {
    final row = Map<String, dynamic>.from(dombaBox.getAt(i));
    final code = (row['kode'] ?? 'DMB-${(i + 1).toString().padLeft(6, '0')}')
        .toString();
    row['kode'] = code;
    row['id'] ??= dombaBox.keyAt(i).toString();
    row['qrCode'] ??= 'NGK-$code';
    row['tanggalMasuk'] ??= row['tanggal'] ?? '';
    row['kelamin'] ??= 'Tidak diketahui';
    row['bobotAwal'] ??= double.tryParse('${row['berat'] ?? 0}') ?? 0;
    row['bobotTerakhir'] ??= double.tryParse('${row['berat'] ?? 0}') ?? 0;
    row['hargaBeli'] ??= row['harga'] ?? '';
    row['status'] = (row['status'] ?? 'aktif').toString().toLowerCase();
    await dombaBox.putAt(i, row);
    final hasHistory = bobotBox.values.any(
      (entry) => entry['dombaId'] == row['id'] || entry['kode'] == code,
    );
    if (!hasHistory) {
      await bobotBox.add({
        'id': 'legacy-${row['id']}',
        'dombaId': row['id'],
        'kode': code,
        'tanggal': row['tanggalMasuk'],
        'bobot': row['bobotAwal'],
        'catatan': 'Bobot awal (data lama)',
      });
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
    );
  }
}
