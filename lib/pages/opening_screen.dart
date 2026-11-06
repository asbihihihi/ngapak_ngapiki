import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/farm_brand_mark.dart';
import 'auth_page.dart';

class OpeningScreen extends StatefulWidget {
  const OpeningScreen({super.key});

  @override
  State<OpeningScreen> createState() => _OpeningScreenState();
}

class _OpeningScreenState extends State<OpeningScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(
      begin: .82,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();
    _openApp();
  }

  Future<void> _openApp() async {
    await Future<void>.delayed(const Duration(milliseconds: 2400));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, _, _) => const AuthGate(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.warmCream,
    body: Stack(
      children: [
        Positioned(
          top: -90,
          right: -60,
          child: _DecorationCircle(size: 250, opacity: .48),
        ),
        Positioned(
          bottom: -130,
          left: -90,
          child: _DecorationCircle(size: 300, opacity: .32),
        ),
        Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const FarmBrandMark(size: 112),
                  const SizedBox(height: 26),
                  Text(
                    'NGAPAK NGAPIKI',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.deepGreen,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    'FARM',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.oliveGreen,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Mengelola Peternakan Lebih Mudah,\nLebih Terarah.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.mutedText,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 34),
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AppTheme.forestGreen,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _DecorationCircle extends StatelessWidget {
  const _DecorationCircle({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: AppTheme.sageGreen.withValues(alpha: opacity),
    ),
  );
}
