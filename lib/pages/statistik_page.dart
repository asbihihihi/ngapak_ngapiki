import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../farm_data.dart';
import '../operations_data.dart';
import '../pos_data.dart';
import '../theme/app_theme.dart';
import '../widgets/statistik_chart_widgets.dart';
import 'data_domba_page.dart';
import 'gudang_page.dart';
import 'keuangan_page.dart';

class StatistikPage extends StatefulWidget {
  const StatistikPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<StatistikPage> createState() => _StatistikPageState();
}

class _StatistikPageState extends State<StatistikPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  )..forward();

  late final Animation<double> _fade = CurvedAnimation(
    parent: _entrance,
    curve: Curves.easeOutCubic,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, .035),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _entrance, curve: Curves.easeOutCubic));

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  String _rupiah(double amount) {
    final digits = amount.round().toString();
    return 'Rp ${digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}';
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = _buildBody();
    if (widget.embedded) return dashboard;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Statistik'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang statistik',
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: dashboard,
    );
  }

  Widget _buildBody() {
    return ValueListenableBuilder(
      valueListenable: FarmData.domba.listenable(),
      builder: (context, _, _) => ValueListenableBuilder(
        valueListenable: FarmOperationsData.goods.listenable(),
        builder: (context, _, _) => ValueListenableBuilder(
          valueListenable: FarmOperationsData.ledger.listenable(),
          builder: (context, _, _) => ValueListenableBuilder(
            valueListenable: FarmData.penjualan.listenable(),
            builder: (context, _, _) => ValueListenableBuilder(
              valueListenable: PosData.products.listenable(),
              builder: (context, _, _) => ValueListenableBuilder(
                valueListenable: PosData.sales.listenable(),
                builder: (context, _, _) => FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: _slide,
                    child: _buildDashboard(context),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final animals = FarmData.domba.values
        .map((raw) => Map<String, dynamic>.from(raw as Map))
        .where((animal) => !FarmData.isSold(animal))
        .toList();
    final finance = FarmOperationsData.financeSummary();
    final meatStockKg = PosData.products.values.fold<double>(0, (total, raw) {
      final product = Map<String, dynamic>.from(raw as Map);
      return total + _number(product['stokKg']);
    });
    final healthCounts = _healthCounts(animals);
    final weeklySales = _weeklySales(today);
    final monthlyFinance = _monthlyFinance(today);
    final hasWeeklySales = weeklySales.any((amount) => amount > 0);
    final hasMonthlyFinance = monthlyFinance.any(
      (month) => month.income > 0 || month.expense > 0,
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.embedded) ...[
          _PageHeading(today: today),
          const SizedBox(height: 22),
          _SummaryCards(
            items: [
              _SummaryItem(
                title: 'Total Pendapatan',
                value: _rupiah(finance['pemasukan'] ?? 0),
                icon: Icons.account_balance_wallet_rounded,
                gradient: const [Color(0xFF245B43), Color(0xFF36765A)],
                footnote: 'Akumulasi transaksi tercatat',
              ),
              _SummaryItem(
                title: 'Jumlah Kambing Saat Ini',
                value: '${animals.length} ekor',
                icon: Icons.pets_rounded,
                gradient: const [Color(0xFF718653), Color(0xFF899B65)],
                footnote: 'Kambing yang belum terjual',
              ),
              _SummaryItem(
                title: 'Stok Daging',
                value: '${meatStockKg.toStringAsFixed(2)} kg',
                icon: Icons.set_meal_rounded,
                gradient: const [Color(0xFF526D75), Color(0xFF759198)],
                footnote: 'Total stok produk POS saat ini',
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
        if (widget.embedded) ...[
          const _SectionHeading(
            title: 'Statistik peternakan',
            subtitle: 'Tren penjualan, arus keuangan, dan kesehatan',
          ),
          const SizedBox(height: 16),
        ],
        _SectionHeading(
          title: 'Tren Penjualan',
          subtitle: 'Pendapatan tercatat selama 7 hari terakhir',
          trailing: _PeriodPill(
            label: '7 hari',
            icon: Icons.calendar_today_rounded,
          ),
        ),
        const SizedBox(height: 12),
        _ChartCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ChartMetric(
                label: 'Pendapatan 7 hari',
                value: _rupiah(
                  weeklySales.fold<double>(0, (sum, value) => sum + value),
                ),
                color: AppTheme.forestGreen,
              ),
              const SizedBox(height: 16),
              SalesLineChartWidget(
                values: weeklySales,
                startDate: today.subtract(const Duration(days: 6)),
              ),
              if (!hasWeeklySales) ...[
                const SizedBox(height: 8),
                const _EmptyChartNote(
                  text: 'Belum ada transaksi penjualan pada periode ini.',
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        _SectionHeading(
          title: 'Arus Keuangan Bulanan',
          subtitle: 'Perbandingan pemasukan dan pengeluaran tahun ini',
          trailing: _PeriodPill(
            label: '${today.year}',
            icon: Icons.date_range_rounded,
          ),
        ),
        const SizedBox(height: 12),
        _ChartCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _ChartLegend(
                items: [
                  _LegendItem(label: 'Pemasukan', color: AppTheme.forestGreen),
                  _LegendItem(label: 'Pengeluaran', color: Color(0xFFE0A45D)),
                ],
              ),
              const SizedBox(height: 18),
              FinanceBarChartWidget(months: monthlyFinance),
              if (!hasMonthlyFinance) ...[
                const SizedBox(height: 8),
                const _EmptyChartNote(
                  text: 'Belum ada transaksi keuangan tahun ini.',
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        _SectionHeading(
          title: 'Status Kesehatan Kambing',
          subtitle: 'Ringkasan dari status kesehatan yang tercatat',
        ),
        const SizedBox(height: 12),
        _ChartCard(
          child: HealthPieChartWidget(
            healthy: healthCounts.healthy,
            sick: healthCounts.sick,
            quarantine: healthCounts.quarantine,
            unrecorded: healthCounts.unrecorded,
            total: animals.length,
          ),
        ),
        const SizedBox(height: 26),
        if (!widget.embedded) ...[
          const _SectionHeading(
            title: 'Akses Cepat',
            subtitle: 'Buka data operasional lebih lengkap',
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 760 ? 3 : 1;
              final width =
                  (constraints.maxWidth - 12 * (columns - 1)) / columns;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: width,
                    child: _DestinationTile(
                      title: 'Keuangan',
                      subtitle: 'Pemasukan, pengeluaran, transaksi',
                      icon: Icons.payments_outlined,
                      onTap: () => _open(context, const KeuanganPage()),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _DestinationTile(
                      title: 'Data kambing',
                      subtitle: 'Daftar, bobot, dan kondisi ternak',
                      icon: Icons.pets_outlined,
                      onTap: () => _open(context, const DataDombaPage()),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _DestinationTile(
                      title: 'Gudang',
                      subtitle: 'Stok dan pergerakan persediaan',
                      icon: Icons.warehouse_outlined,
                      onTap: () => _open(context, const GudangPage()),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ],
    );
    if (widget.embedded) return content;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: content,
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  List<double> _weeklySales(DateTime today) {
    final start = today.subtract(const Duration(days: 6));
    final amounts = List<double>.filled(7, 0);
    for (final row in FarmOperationsData.financeEntries(
      from: start,
      through: today,
    )) {
      if (row['jenis'] != 'Pemasukan') continue;
      final date = DateTime.tryParse('${row['tanggal']}');
      if (date == null) continue;
      final index = DateTime(
        date.year,
        date.month,
        date.day,
      ).difference(start).inDays;
      if (index >= 0 && index < amounts.length) {
        amounts[index] += _number(row['jumlah']);
      }
    }
    return amounts;
  }

  List<MonthlyFinance> _monthlyFinance(DateTime today) {
    final start = DateTime(today.year);
    final totals = List<MonthlyFinance>.generate(
      today.month,
      (index) => MonthlyFinance(month: index + 1, income: 0, expense: 0),
    );
    for (final row in FarmOperationsData.financeEntries(
      from: start,
      through: today,
    )) {
      final date = DateTime.tryParse('${row['tanggal']}');
      if (date == null || date.year != today.year || date.month > today.month) {
        continue;
      }
      final current = totals[date.month - 1];
      final amount = _number(row['jumlah']);
      totals[date.month - 1] = row['jenis'] == 'Pemasukan'
          ? current.copyWith(income: current.income + amount)
          : current.copyWith(expense: current.expense + amount);
    }
    return totals;
  }

  _HealthCounts _healthCounts(List<Map<String, dynamic>> animals) {
    var healthy = 0;
    var sick = 0;
    var quarantine = 0;
    for (final animal in animals) {
      final status = '${animal['statusKesehatan'] ?? ''}'.trim().toLowerCase();
      if (status.contains('karantina')) {
        quarantine++;
      } else if (status.contains('sakit') || status.contains('tidak sehat')) {
        sick++;
      } else if (status == 'sehat') {
        healthy++;
      }
    }
    return _HealthCounts(
      healthy: healthy,
      sick: sick,
      quarantine: quarantine,
      unrecorded: animals.length - healthy - sick - quarantine,
    );
  }

  double _number(dynamic value) =>
      double.tryParse('$value'.trim().replaceAll(',', '.')) ?? 0;
}

class _HealthCounts {
  const _HealthCounts({
    required this.healthy,
    required this.sick,
    required this.quarantine,
    required this.unrecorded,
  });

  final int healthy;
  final int sick;
  final int quarantine;
  final int unrecorded;
}

class _PageHeading extends StatelessWidget {
  const _PageHeading({required this.today});

  final DateTime today;

  @override
  Widget build(BuildContext context) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ringkasan peternakan',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.deepGreen,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${today.day} ${months[today.month - 1]} ${today.year} · Data aktual',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.mutedText),
              ),
            ],
          ),
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.sageGreen,
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.insights_rounded,
            color: AppTheme.forestGreen,
          ),
        ),
      ],
    );
  }
}

class _SummaryItem {
  const _SummaryItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
    required this.footnote,
  });

  final String title;
  final String value;
  final IconData icon;
  final List<Color> gradient;
  final String footnote;
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.items});

  final List<_SummaryItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 740) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < items.length; index++) ...[
                if (index > 0) const SizedBox(width: 14),
                Expanded(child: _SummaryCard(item: items[index])),
              ],
            ],
          );
        }
        return SizedBox(
          height: 158,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) => SizedBox(
              width: constraints.maxWidth < 380 ? 255 : 285,
              child: _SummaryCard(item: items[index]),
            ),
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.item});

  final _SummaryItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 158),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: item.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: item.gradient.first.withValues(alpha: .18),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .17),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .12),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(item.icon, color: Colors.white, size: 21),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              item.value,
              maxLines: 1,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w800,
                letterSpacing: -.4,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.footnote,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .82),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.deepGreen,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.mutedText),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
    );
  }
}

class _PeriodPill extends StatelessWidget {
  const _PeriodPill({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.sageGreen,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.forestGreen),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.deepGreen,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8ECE5)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepGreen.withValues(alpha: .045),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ChartMetric extends StatelessWidget {
  const _ChartMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.mutedText),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendItem {
  const _LegendItem({required this.label, required this.color});

  final String label;
  final Color color;
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.items});

  final List<_LegendItem> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        for (final item in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: item.color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 7),
              Text(
                item.label,
                style: const TextStyle(
                  color: AppTheme.mutedText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _EmptyChartNote extends StatelessWidget {
  const _EmptyChartNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: AppTheme.mutedText),
    );
  }
}

class _DestinationTile extends StatelessWidget {
  const _DestinationTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8ECE5)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.sageGreen,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: AppTheme.forestGreen),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.deepGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.mutedText,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppTheme.mutedText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
