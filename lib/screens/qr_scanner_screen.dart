import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen();

  @override
  State<QrScannerScreen> createState() => QrScannerScreenState();
}

class QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _hasFoundResult = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear código'),
      ),
      body: MobileScanner(
        controller: _controller,
        onDetect: (capture) {
          if (_hasFoundResult) return;
          for (final barcode in capture.barcodes) {
            final rawValue = barcode.rawValue;
            if (rawValue != null && rawValue.isNotEmpty) {
              _hasFoundResult = true;
              Navigator.of(context).pop(rawValue);
              break;
            }
          }
        },
      ),
    );
  }
}
