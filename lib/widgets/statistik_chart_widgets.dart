import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class MonthlyFinance {
  const MonthlyFinance({
    required this.month,
    required this.income,
    required this.expense,
  });

  final int month;
  final double income;
  final double expense;

  MonthlyFinance copyWith({double? income, double? expense}) => MonthlyFinance(
    month: month,
    income: income ?? this.income,
    expense: expense ?? this.expense,
  );
}

class SalesLineChartWidget extends StatelessWidget {
  const SalesLineChartWidget({
    required this.values,
    required this.startDate,
    super.key,
  });

  final List<double> values;
  final DateTime startDate;

  static const _shortMonths = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  @override
  Widget build(BuildContext context) {
    final maximum = values.fold<double>(
      0,
      (current, value) => value > current ? value : current,
    );
    final maxY = maximum == 0 ? 1.0 : maximum * 1.2;
    return SizedBox(
      height: 224,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY,
          minX: 0,
          maxX: (values.length - 1).toDouble(),
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: Color(0xFFE9EEE8),
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                interval: maxY / 4,
                getTitlesWidget: (value, meta) => SideTitleWidget(
                  meta: meta,
                  space: 8,
                  child: Text(
                    _compactMoney(value),
                    style: const TextStyle(
                      color: AppTheme.mutedText,
                      fontSize: 9,
                    ),
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.round();
                  if (index < 0 || index >= values.length) {
                    return const SizedBox.shrink();
                  }
                  final date = startDate.add(Duration(days: index));
                  return SideTitleWidget(
                    meta: meta,
                    space: 8,
                    child: Text(
                      '${date.day} ${_shortMonths[date.month - 1]}',
                      style: const TextStyle(
                        color: AppTheme.mutedText,
                        fontSize: 9,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots
                  .map(
                    (spot) => LineTooltipItem(
                      '${_compactDate(startDate.add(Duration(days: spot.x.round())))}\n${_formatMoney(spot.y)}',
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        height: 1.5,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var index = 0; index < values.length; index++)
                  FlSpot(index.toDouble(), values[index]),
              ],
              isCurved: true,
              curveSmoothness: .32,
              barWidth: 3,
              color: AppTheme.forestGreen,
              gradient: const LinearGradient(
                colors: [AppTheme.oliveGreen, AppTheme.forestGreen],
              ),
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                      radius: 3,
                      color: Colors.white,
                      strokeWidth: 2,
                      strokeColor: AppTheme.forestGreen,
                    ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.oliveGreen.withValues(alpha: .28),
                    AppTheme.sageGreen.withValues(alpha: .06),
                  ],
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      ),
    );
  }
}

class FinanceBarChartWidget extends StatelessWidget {
  const FinanceBarChartWidget({required this.months, super.key});

  final List<MonthlyFinance> months;

  static const _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  @override
  Widget build(BuildContext context) {
    final values = months
        .expand((month) => [month.income, month.expense])
        .toList();
    final maximum = values.fold<double>(
      0,
      (current, value) => value > current ? value : current,
    );
    final maxY = maximum == 0 ? 1.0 : maximum * 1.18;
    return SizedBox(
      height: 238,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          minY: 0,
          alignment: BarChartAlignment.spaceAround,
          groupsSpace: 12,
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: Color(0xFFE9EEE8),
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                interval: maxY / 4,
                getTitlesWidget: (value, meta) => SideTitleWidget(
                  meta: meta,
                  space: 6,
                  child: Text(
                    _compactMoney(value),
                    style: const TextStyle(
                      color: AppTheme.mutedText,
                      fontSize: 9,
                    ),
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.round();
                  if (index < 0 || index >= months.length) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    meta: meta,
                    space: 6,
                    child: Text(
                      _monthNames[months[index].month - 1],
                      style: const TextStyle(
                        color: AppTheme.mutedText,
                        fontSize: 9,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final label = rodIndex == 0 ? 'Pemasukan' : 'Pengeluaran';
                return BarTooltipItem(
                  '$label\n${_formatMoney(rod.toY)}',
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                  ),
                );
              },
            ),
          ),
          barGroups: [
            for (var index = 0; index < months.length; index++)
              BarChartGroupData(
                x: index,
                barsSpace: 4,
                barRods: [
                  BarChartRodData(
                    toY: months[index].income,
                    width: 7,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(5),
                    ),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF718653), AppTheme.forestGreen],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  BarChartRodData(
                    toY: months[index].expense,
                    width: 7,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(5),
                    ),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF0C58E), Color(0xFFD98B42)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ],
              ),
          ],
        ),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      ),
    );
  }
}

class HealthPieChartWidget extends StatefulWidget {
  const HealthPieChartWidget({
    required this.healthy,
    required this.sick,
    required this.quarantine,
    required this.unrecorded,
    required this.total,
    super.key,
  });

  final int healthy;
  final int sick;
  final int quarantine;
  final int unrecorded;
  final int total;

  @override
  State<HealthPieChartWidget> createState() => _HealthPieChartWidgetState();
}

class _HealthPieChartWidgetState extends State<HealthPieChartWidget> {
  String? _touchedLabel;

  @override
  Widget build(BuildContext context) {
    final items = [
      _HealthSlice(
        label: 'Sehat',
        value: widget.healthy,
        color: const Color(0xFF3E8C63),
      ),
      _HealthSlice(
        label: 'Sakit',
        value: widget.sick,
        color: const Color(0xFFD95B50),
      ),
      _HealthSlice(
        label: 'Karantina',
        value: widget.quarantine,
        color: const Color(0xFFE5AD45),
      ),
      _HealthSlice(
        label: 'Belum tercatat',
        value: widget.unrecorded,
        color: const Color(0xFFB8C0B9),
      ),
    ];
    final visibleItems = items.where((item) => item.value > 0).toList();
    final hasData = visibleItems.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final chart = SizedBox(
          width: compact ? double.infinity : 230,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  centerSpaceRadius: 62,
                  sectionsSpace: 3,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      final index =
                          response?.touchedSection?.touchedSectionIndex;
                      setState(() {
                        _touchedLabel =
                            event is FlTapUpEvent ||
                                !event.isInterestedForInteractions ||
                                index == null ||
                                index < 0 ||
                                index >= visibleItems.length
                            ? null
                            : visibleItems[index].label;
                      });
                    },
                  ),
                  sections: hasData
                      ? [
                          for (final item in visibleItems)
                            PieChartSectionData(
                              value: item.value.toDouble(),
                              color: item.color,
                              radius: item.label == _touchedLabel ? 42 : 36,
                              title: _percentage(item.value, widget.total),
                              titleStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                        ]
                      : [
                          PieChartSectionData(
                            value: 1,
                            color: const Color(0xFFE6EBE5),
                            radius: 36,
                            title: '',
                          ),
                        ],
                ),
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${widget.total}',
                    style: const TextStyle(
                      color: AppTheme.deepGreen,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    'kambing',
                    style: TextStyle(color: AppTheme.mutedText, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        );
        final legend = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final item in items)
              _HealthLegendRow(
                item: item,
                total: widget.total,
                selected: item.label == _touchedLabel && hasData,
              ),
            if (!hasData)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Belum ada data kambing aktif.',
                  style: TextStyle(color: AppTheme.mutedText, fontSize: 11),
                ),
              ),
          ],
        );
        if (compact) {
          return Column(children: [chart, const SizedBox(height: 8), legend]);
        }
        return Row(
          children: [
            Expanded(child: Center(child: chart)),
            const SizedBox(width: 20),
            Expanded(child: legend),
          ],
        );
      },
    );
  }

  String _percentage(int value, int total) =>
      total == 0 ? '' : '${(value / total * 100).round()}%';
}

class _HealthSlice {
  const _HealthSlice({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;
}

class _HealthLegendRow extends StatelessWidget {
  const _HealthLegendRow({
    required this.item,
    required this.total,
    required this.selected,
  });

  final _HealthSlice item;
  final int total;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: selected ? 13 : 10,
            height: selected ? 13 : 10,
            decoration: BoxDecoration(
              color: item.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.label,
              style: TextStyle(
                color: AppTheme.darkText,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            '${item.value}',
            style: const TextStyle(
              color: AppTheme.deepGreen,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            total > 0 ? '(${(item.value / total * 100).round()}%)' : '(0%)',
            style: const TextStyle(color: AppTheme.mutedText, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

String _compactMoney(double value) {
  if (value.abs() >= 1000000000) {
    return ' ${(value / 1000000000).toStringAsFixed(1)}M';
  }
  if (value.abs() >= 1000000) {
    return ' ${(value / 1000000).toStringAsFixed(1)}jt';
  }
  if (value.abs() >= 1000) {
    return ' ${(value / 1000).toStringAsFixed(0)}rb';
  }
  return value.toStringAsFixed(0);
}

String _formatMoney(double value) {
  final digits = value.round().toString();
  return 'Rp ${digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}';
}

String _compactDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
