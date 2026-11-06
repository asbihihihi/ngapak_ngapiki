import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../farm_data.dart';
import '../theme/app_theme.dart';
import 'detail_domba_page.dart';

class WeightManagementPage extends StatelessWidget {
  const WeightManagementPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.warmCream,
    appBar: AppBar(title: const Text('Bobot kambing')),
    body: ValueListenableBuilder(
      valueListenable: FarmData.domba.listenable(),
      builder: (context, box, _) {
        if (box.isEmpty) {
          return const Center(child: Text('Belum ada data kambing.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: box.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final animal = Map<String, dynamic>.from(box.getAt(index));
            final history = FarmData.weightHistoryFor(animal);
            final metrics = FarmData.weightMetricsFor(animal);
            final lastWeighing = history.isEmpty
                ? null
                : '${history.last['tanggal'] ?? ''}';
            return Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.sageGreen,
                  foregroundColor: AppTheme.forestGreen,
                  child: Icon(Icons.monitor_weight_outlined),
                ),
                title: Text(
                  '${animal['kode'] ?? 'Tanpa kode'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${animal['jenis'] ?? 'Kambing'} · ${animal['kelamin'] ?? 'Tidak diketahui'}\n'
                  'Terakhir ${FarmData.weight(animal).toStringAsFixed(1)} kg'
                  '${lastWeighing == null || lastWeighing.isEmpty ? '' : ' · $lastWeighing'}'
                  '${metrics['gain'] == null ? '' : ' · ${_signed(metrics['gain']!)} kg sejak awal'}',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => DetailDombaPage(data: animal, index: index),
                  ),
                ),
              ),
            );
          },
        );
      },
    ),
  );
}

String _signed(double value) =>
    '${value >= 0 ? '+' : ''}${value.toStringAsFixed(1)}';
