import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'bulk_domba_page.dart';
import 'input_penjualan_page.dart';

class DombaKeluarPage extends StatefulWidget {
  const DombaKeluarPage({super.key});

  @override
  State<DombaKeluarPage> createState() => _DombaKeluarPageState();
}

class _DombaKeluarPageState extends State<DombaKeluarPage> {
  final selected = <int>{};

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('dombaBox');
    return Scaffold(
      appBar: AppBar(
        title: const Text('POS · Penjualan Domba'),
        actions: [
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const BulkDombaPage(salesOnly: true),
              ),
            ),
            child: const Text('Pilih banyak'),
          ),
        ],
      ),
      bottomNavigationBar: selected.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BulkSalePage(
                        indices: selected.toList()..sort(),
                      ),
                    ),
                  ).then((_) {
                    if (mounted) setState(() => selected.clear());
                  }),
                  icon: const Icon(Icons.sell_outlined),
                  label: Text('Jual ${selected.length} domba terpilih'),
                ),
              ),
            ),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, _, __) {
          final rows = <MapEntry<int, Map>>[];
          for (var i = 0; i < box.length; i++) {
            final row = Map.from(box.getAt(i));
            if ((row['status'] ?? 'aktif').toString().toLowerCase() !=
                'terjual')
              rows.add(MapEntry(i, row));
          }
          if (rows.isEmpty)
            return const Center(
              child: Text('Tidak ada domba aktif untuk dijual.'),
            );
          return ListView(
            children: [
              for (final entry in rows)
                ListTile(
                  leading: Checkbox(
                    value: selected.contains(entry.key),
                    onChanged: (value) => setState(() {
                      if (value == true) {
                        selected.add(entry.key);
                      } else {
                        selected.remove(entry.key);
                      }
                    }),
                  ),
                  title: Text(
                    '${entry.value['kode']} • ${entry.value['jenis']}',
                  ),
                  subtitle: Text(
                    'Bobot ${entry.value['bobotTerakhir'] ?? entry.value['berat'] ?? '-'} KG',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InputPenjualanPage(
                        data: entry.value,
                        index: entry.key,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
