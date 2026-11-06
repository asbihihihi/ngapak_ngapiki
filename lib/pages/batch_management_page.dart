import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../farm_data.dart';
import '../theme/app_theme.dart';
import 'bulk_domba_page.dart';
import 'detail_domba_page.dart';

class BatchManagementPage extends StatelessWidget {
  const BatchManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final batches = Hive.box('batchBox');
    final animals = FarmData.domba;
    return Scaffold(
      backgroundColor: AppTheme.warmCream,
      appBar: AppBar(title: const Text('Batch kambing')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const BulkDombaPage())),
        icon: const Icon(Icons.add),
        label: const Text('Buat batch'),
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          batches.listenable(),
          animals.listenable(),
        ]),
        builder: (context, _) {
          final grouped = <String, List<MapEntry<int, Map<String, dynamic>>>>{};
          for (var index = 0; index < animals.length; index++) {
            final animal = Map<String, dynamic>.from(animals.getAt(index));
            final id = '${animal['batchId'] ?? ''}'.trim();
            if (id.isEmpty) continue;
            grouped.putIfAbsent(id, () => []).add(MapEntry(index, animal));
          }
          final ids = <String>{...grouped.keys};
          for (final raw in batches.values) {
            if (raw is Map && '${raw['batchId'] ?? ''}'.trim().isNotEmpty) {
              ids.add('${raw['batchId']}');
            }
          }
          final cards =
              ids.map((id) {
                final batch = batches.get(id);
                final metadata = batch is Map
                    ? Map<String, dynamic>.from(batch)
                    : <String, dynamic>{};
                final members = grouped[id] ?? const [];
                return BatchSummary(
                  id: id,
                  metadata: metadata,
                  members: members,
                );
              }).toList()..sort((a, b) {
                final dateOrder = '${b.metadata['tanggalMasuk'] ?? ''}'
                    .compareTo('${a.metadata['tanggalMasuk'] ?? ''}');
                return dateOrder != 0 ? dateOrder : b.id.compareTo(a.id);
              });

          if (cards.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: Text(
                  'Belum ada data batch kambing.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: cards.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final batch = cards[index];
              return _BatchCard(
                batch: batch,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => BatchDetailPage(batch: batch),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class BatchSummary {
  const BatchSummary({
    required this.id,
    required this.metadata,
    required this.members,
  });

  final String id;
  final Map<String, dynamic> metadata;
  final List<MapEntry<int, Map<String, dynamic>>> members;

  String get status {
    if (members.isEmpty) return 'Tanpa data anggota';
    final sold = members.where((entry) => FarmData.isSold(entry.value)).length;
    if (sold == 0) return 'Aktif';
    if (sold == members.length) return 'Terjual';
    return 'Sebagian terjual';
  }

  String get purchasePrice {
    final saved = '${metadata['totalHargaBeli'] ?? ''}'.trim();
    if (saved.isNotEmpty) {
      final parsed = FarmData.parseMoney(saved);
      if (parsed != null) return _rupiah(parsed);
      return saved;
    }
    final recorded = members
        .map(
          (entry) => FarmData.parseMoney('${entry.value['hargaBeli'] ?? ''}'),
        )
        .whereType<double>()
        .toList();
    if (recorded.isEmpty) return 'Belum dicatat';
    return _rupiah(recorded.fold<double>(0, (total, price) => total + price));
  }
}

class _BatchCard extends StatelessWidget {
  const _BatchCard({required this.batch, required this.onTap});

  final BatchSummary batch;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date = '${batch.metadata['tanggalMasuk'] ?? ''}'.trim();
    final origin = '${batch.metadata['asal'] ?? ''}'.trim();
    final statusColor = batch.status == 'Terjual'
        ? const Color(0xFFB5473B)
        : AppTheme.forestGreen;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.sageGreen,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      color: AppTheme.forestGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          batch.id,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppTheme.deepGreen,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          date.isEmpty ? 'Tanggal tidak tersedia' : date,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.mutedText),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: _StatusBadge(
                      label: batch.status,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 20,
                runSpacing: 12,
                children: [
                  _BatchInfo(
                    icon: Icons.place_outlined,
                    label: 'Asal',
                    value: origin.isEmpty ? 'Tidak dicatat' : origin,
                  ),
                  _BatchInfo(
                    icon: Icons.pets_outlined,
                    label: 'Jumlah kambing',
                    value: '${batch.members.length}',
                  ),
                  _BatchInfo(
                    icon: Icons.payments_outlined,
                    label: 'Total pembelian',
                    value: batch.purchasePrice,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      'Lihat anggota batch',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: AppTheme.forestGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: AppTheme.forestGreen,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BatchInfo extends StatelessWidget {
  const _BatchInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 142,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: AppTheme.oliveGreen),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppTheme.mutedText, fontSize: 11),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.darkText,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
    ),
  );
}

class BatchDetailPage extends StatelessWidget {
  const BatchDetailPage({super.key, required this.batch});

  final BatchSummary batch;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.warmCream,
    appBar: AppBar(title: Text('Batch ${batch.id}')),
    body: batch.members.isEmpty
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Data batch tersedia, tetapi daftar anggota belum ditemukan.',
                textAlign: TextAlign.center,
              ),
            ),
          )
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _BatchCard(batch: batch, onTap: () {}),
              const SizedBox(height: 18),
              Text(
                'Anggota batch (${batch.members.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.deepGreen,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              for (final entry in batch.members)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.sageGreen,
                      foregroundColor: AppTheme.forestGreen,
                      child: const Icon(Icons.pets_outlined),
                    ),
                    title: Text(
                      '${entry.value['kode'] ?? 'Tanpa kode'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${entry.value['jenis'] ?? 'Jenis tidak dicatat'} · '
                      '${FarmData.weight(entry.value).toStringAsFixed(1)} kg · '
                      '${FarmData.isSold(entry.value) ? 'Terjual' : 'Aktif'}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => DetailDombaPage(
                          data: entry.value,
                          index: entry.key,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
  );
}

String _rupiah(double amount) {
  final grouped = amount.round().toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return 'Rp $grouped';
}
