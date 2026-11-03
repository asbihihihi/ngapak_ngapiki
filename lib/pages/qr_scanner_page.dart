import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../farm_data.dart';
import 'detail_domba_page.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});
  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  bool handled = false;
  String? error;
  void scanned(BarcodeCapture capture) async {
    if (handled) return;
    final value = capture.barcodes.firstOrNull?.rawValue;
    if (value == null || value.isEmpty) return;
    handled = true;
    final index = FarmData.indexForQr(value);
    if (!mounted) return;
    if (index == null) {
      setState(() => error = 'QR Domba tidak ditemukan.');
      await Future<void>.delayed(const Duration(seconds: 2));
      if (mounted) setState(() { error = null; handled = false; });
      return;
    }
    final row = Map<String, dynamic>.from(FarmData.domba.getAt(index));
    await Navigator.push(context, MaterialPageRoute(builder: (_) => DetailDombaPage(data: row, index: index)));
    if (mounted) setState(() => handled = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Scan QR Domba')), body: Stack(children: [
    MobileScanner(onDetect: scanned, errorBuilder: (context, error) => Center(child: Text('Kamera tidak dapat dibuka: ${error.errorCode}'))),
    if (error != null) Center(child: Card(child: Padding(padding: const EdgeInsets.all(20), child: Text(error!)))),
  ]));
}
