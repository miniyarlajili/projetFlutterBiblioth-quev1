import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class IsbnScannerScreen extends StatelessWidget {
  final Function(String isbn) onDetect;

  const IsbnScannerScreen({super.key, required this.onDetect});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scanner ISBN"),
        backgroundColor: const Color(0xFFE86C1A),
      ),
      body: MobileScanner(
        onDetect: (capture) {
          final barcode = capture.barcodes.first;
          final code = barcode.rawValue;

          if (code != null) {
            Navigator.pop(context);
            onDetect(code);
          }
        },
      ),
    );
  }
}