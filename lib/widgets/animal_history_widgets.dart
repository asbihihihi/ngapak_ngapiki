import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class WeightMetric extends StatelessWidget {
  const WeightMetric({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 140, maxWidth: 220),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.mutedText),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppTheme.deepGreen,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class WeightTrendChart extends StatelessWidget {
  const WeightTrendChart({super.key, required this.points});

  final List<({DateTime date, double value})> points;

  @override
  Widget build(BuildContext context) {
    final minimum = points
        .map((point) => point.value)
        .reduce((first, second) => first < second ? first : second);
    final maximum = points
        .map((point) => point.value)
        .reduce((first, second) => first > second ? first : second);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Grafik perkembangan bobot',
              style: TextStyle(
                color: AppTheme.deepGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 170,
              width: double.infinity,
              child: CustomPaint(
                painter: _WeightTrendPainter(
                  points: points,
                  minimum: minimum,
                  maximum: maximum,
                  textDirection: Directionality.of(context),
                ),
              ),
            ),
            const SizedBox(height: 7),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_shortDate(points.first.date)),
                Text(_shortDate(points.last.date)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WeightTrendPainter extends CustomPainter {
  const _WeightTrendPainter({
    required this.points,
    required this.minimum,
    required this.maximum,
    required this.textDirection,
  });

  final List<({DateTime date, double value})> points;
  final double minimum;
  final double maximum;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 38.0;
    const right = 8.0;
    const top = 8.0;
    const bottom = 10.0;
    final plot = Rect.fromLTRB(
      left,
      top,
      size.width - right,
      size.height - bottom,
    );
    final range = maximum - minimum;
    final padding = range == 0
        ? (maximum.abs() * .08).clamp(1.0, 5.0)
        : range * .12;
    final low = minimum - padding;
    final high = maximum + padding;
    final grid = Paint()
      ..color = AppTheme.sageGreen
      ..strokeWidth = 1;
    final line = Paint()
      ..color = AppTheme.forestGreen
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final dot = Paint()..color = AppTheme.forestGreen;

    for (var index = 0; index < 3; index++) {
      final y = plot.top + plot.height * index / 2;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
      final value = high - (high - low) * index / 2;
      final label = TextPainter(
        text: TextSpan(
          text: value.toStringAsFixed(1),
          style: const TextStyle(fontSize: 10, color: AppTheme.mutedText),
        ),
        textDirection: textDirection,
      )..layout(maxWidth: left - 5);
      label.paint(canvas, Offset(0, y - label.height / 2));
    }

    final path = Path();
    final offsets = <Offset>[];
    final dateRange = points.last.date
        .difference(points.first.date)
        .inMicroseconds;
    for (var index = 0; index < points.length; index++) {
      final x = points.length == 1 || dateRange == 0
          ? plot.left +
                plot.width * index / (points.length - 1).clamp(1, points.length)
          : plot.left +
                plot.width *
                    points[index].date
                        .difference(points.first.date)
                        .inMicroseconds /
                    dateRange;
      final y =
          plot.bottom -
          ((points[index].value - low) / (high - low)) * plot.height;
      final offset = Offset(x, y);
      offsets.add(offset);
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, line);
    for (final offset in offsets) {
      canvas.drawCircle(offset, 4, Paint()..color = Colors.white);
      canvas.drawCircle(offset, 3, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _WeightTrendPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.minimum != minimum ||
      oldDelegate.maximum != maximum;
}

class HealthTimelineCard extends StatelessWidget {
  const HealthTimelineCard({super.key, required this.record});

  final Map<String, dynamic> record;

  @override
  Widget build(BuildContext context) {
    final type = '${record['recordType'] ?? 'legacy'}';
    final label = switch (type) {
      'pemeriksaan' => 'Pemeriksaan',
      'vaksinasi' => 'Vaksinasi',
      'obat' => 'Pemberian obat',
      'tindakan' => 'Tindakan kesehatan',
      _ => 'Catatan lama',
    };
    final detail = switch (type) {
      'pemeriksaan' =>
        'Status: ${record['statusKesehatan'] ?? '-'}'
            '${_optionalLine('Gejala', record['gejala'])}'
            '${_optionalLine('Hasil', record['hasilPemeriksaan'])}'
            '${_optionalLine('Tindakan', record['tindakan'])}',
      'vaksinasi' =>
        '${record['namaVaksin'] ?? '-'}'
            '${_optionalLine('Dosis', record['dosis'])}'
            '${_optionalLine('Jadwal berikutnya', record['jadwalBerikutnya'])}',
      'obat' =>
        '${record['namaObat'] ?? record['nama'] ?? '-'}'
            '${_optionalLine('Alasan', record['alasan'])}'
            '${_optionalLine('Dosis', record['dosis'])}',
      'tindakan' => '${record['tindakan'] ?? '-'}',
      _ => '${record['nama'] ?? record['catatan'] ?? '-'}',
    };
    final note = '${record['catatan'] ?? ''}'.trim();
    final staff = '${record['petugas'] ?? ''}'.trim();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(top: 5, right: 12),
              decoration: const BoxDecoration(
                color: AppTheme.oliveGreen,
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: AppTheme.deepGreen,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${record['tanggal'] ?? 'Tanggal tidak dicatat'}',
                        style: const TextStyle(
                          color: AppTheme.mutedText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(detail),
                  if (note.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Catatan: $note'),
                  ],
                  if (staff.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Petugas: $staff',
                      style: const TextStyle(
                        color: AppTheme.mutedText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String weightMetricText(double? value, {bool signed = false}) {
  if (value == null) return 'Belum tersedia';
  return '${signed && value >= 0 ? '+' : ''}${value.toStringAsFixed(1)} kg';
}

String _shortDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

String _optionalLine(String label, dynamic raw) {
  final value = '$raw'.trim();
  return value.isEmpty ? '' : '\n$label: $value';
}
