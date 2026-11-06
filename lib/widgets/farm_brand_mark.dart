import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class FarmBrandMark extends StatelessWidget {
  const FarmBrandMark({
    super.key,
    this.size = 72,
    this.color = AppTheme.forestGreen,
    this.backgroundColor = AppTheme.sageGreen,
  });

  final double size;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(size * .32),
    ),
    padding: EdgeInsets.all(size * .16),
    child: CustomPaint(painter: _GoatHeadPainter(color)),
  );
}

class _GoatHeadPainter extends CustomPainter {
  const _GoatHeadPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .065
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;

    final horns = Path()
      ..moveTo(w * .34, h * .38)
      ..cubicTo(w * .10, h * .30, w * .14, h * .05, w * .32, h * .08)
      ..cubicTo(w * .43, h * .10, w * .41, h * .22, w * .40, h * .28)
      ..moveTo(w * .66, h * .38)
      ..cubicTo(w * .90, h * .30, w * .86, h * .05, w * .68, h * .08)
      ..cubicTo(w * .57, h * .10, w * .59, h * .22, w * .60, h * .28);
    canvas.drawPath(horns, stroke);

    final ears = Path()
      ..moveTo(w * .30, h * .43)
      ..cubicTo(w * .05, h * .30, w * .02, h * .45, w * .28, h * .56)
      ..moveTo(w * .70, h * .43)
      ..cubicTo(w * .95, h * .30, w * .98, h * .45, w * .72, h * .56);
    canvas.drawPath(ears, stroke);

    final face = Path()
      ..moveTo(w * .31, h * .37)
      ..cubicTo(w * .31, h * .28, w * .69, h * .28, w * .69, h * .37)
      ..cubicTo(w * .73, h * .54, w * .64, h * .76, w * .50, h * .88)
      ..cubicTo(w * .36, h * .76, w * .27, h * .54, w * .31, h * .37)
      ..close();
    canvas.drawPath(face, stroke);
    canvas.drawCircle(Offset(w * .41, h * .54), w * .035, fill);
    canvas.drawCircle(Offset(w * .59, h * .54), w * .035, fill);

    final muzzle = Path()
      ..moveTo(w * .44, h * .68)
      ..quadraticBezierTo(w * .50, h * .64, w * .56, h * .68)
      ..moveTo(w * .50, h * .66)
      ..lineTo(w * .50, h * .73);
    canvas.drawPath(muzzle, stroke);
  }

  @override
  bool shouldRepaint(_GoatHeadPainter oldDelegate) =>
      oldDelegate.color != color;
}

class FarmBrandLockup extends StatelessWidget {
  const FarmBrandLockup({
    super.key,
    this.markSize = 46,
    this.titleColor = AppTheme.deepGreen,
    this.subtitleColor = AppTheme.mutedText,
    this.showTagline = false,
  });

  final double markSize;
  final Color titleColor;
  final Color subtitleColor;
  final bool showTagline;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      FarmBrandMark(size: markSize),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'NGAPAK NGAPIKI FARM',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: titleColor,
                fontWeight: FontWeight.w800,
                letterSpacing: .5,
              ),
            ),
            if (showTagline)
              Text(
                'Mengelola Peternakan Lebih Mudah, Lebih Terarah.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: subtitleColor,
                  height: 1.4,
                ),
              )
            else
              Text(
                'FARM MANAGEMENT',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: subtitleColor,
                  letterSpacing: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    ],
  );
}
