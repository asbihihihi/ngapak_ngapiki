import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../farm_data.dart';
import '../operations_data.dart';
import '../pos_data.dart';
import 'data_domba_page.dart';
import 'gudang_page.dart';
import 'keuangan_page.dart';

class StatistikPage extends StatelessWidget {
  const StatistikPage({super.key});

  String _rupiah(double amount) {
    final digits = amount.round().toString();
    return 'Rp ${digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}';
  }

  Widget _summary(String title, String value, IconData icon, Color color) =>
      Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color),
          ),
          title: Text(title),
          trailing: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );

  Widget _destination(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Widget page,
  ) => Card(
    child: ListTile(
      leading: Icon(icon, color: const Color(0xff2D6A4F)),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final animals = FarmData.domba;
    final goods = FarmOperationsData.goods;
    return Scaffold(
      appBar: AppBar(title: const Text('Statistik')),
      body: ValueListenableBuilder(
        valueListenable: animals.listenable(),
        builder: (context, _, _) => ValueListenableBuilder(
          valueListenable: goods.listenable(),
          builder: (context, _, _) => ValueListenableBuilder(
            valueListenable: FarmOperationsData.ledger.listenable(),
            builder: (context, _, _) => ValueListenableBuilder(
              valueListenable: Hive.box('penjualanBox').listenable(),
              builder: (context, _, _) => ValueListenableBuilder(
                valueListenable: PosData.sales.listenable(),
                builder: (context, _, _) {
                final active = animals.values.where((row) {
                  return !FarmData.isSold(Map<String, dynamic>.from(row));
                }).toList();
                final averageWeight = active.isEmpty
                    ? 0.0
                    : active
                              .map(
                                (row) => FarmData.weight(
                                  Map<String, dynamic>.from(row),
                                ),
                              )
                              .reduce((a, b) => a + b) /
                          active.length;
                final finance = FarmOperationsData.financeSummary();
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _summary(
                      'Domba aktif',
                      '${active.length}',
                      Icons.pets,
                      Colors.green,
                    ),
                    _summary(
                      'Bobot rata-rata',
                      '${averageWeight.toStringAsFixed(1)} kg',
                      Icons.monitor_weight_outlined,
                      Colors.blue,
                    ),
                    _summary(
                      'Nilai bersih keuangan',
                      _rupiah(finance['selisih'] ?? 0),
                      Icons.account_balance_wallet_outlined,
                      Colors.orange,
                    ),
                    _summary(
                      'Jenis barang gudang',
                      '${goods.length}',
                      Icons.inventory_2_outlined,
                      Colors.purple,
                    ),
                    _summary(
                      'Daging terjual',
                      '${PosData.totalSoldKg.toStringAsFixed(2)} kg',
                      Icons.set_meal_outlined,
                      Colors.brown,
                    ),
                    _summary(
                      'Pemasukan POS daging',
                      _rupiah(PosData.totalSales),
                      Icons.point_of_sale_outlined,
                      Colors.teal,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Lihat detail',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    _destination(
                      context,
                      'Keuangan',
                      'Pemasukan, pengeluaran, dan transaksi',
                      Icons.payments_outlined,
                      const KeuanganPage(),
                    ),
                    _destination(
                      context,
                      'Data domba',
                      'Daftar, bobot, dan kondisi ternak',
                      Icons.pets_outlined,
                      const DataDombaPage(),
                    ),
                    _destination(
                      context,
                      'Gudang',
                      'Stok barang dan pergerakan persediaan',
                      Icons.warehouse_outlined,
                      const GudangPage(),
                    ),
                  ],
                );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
