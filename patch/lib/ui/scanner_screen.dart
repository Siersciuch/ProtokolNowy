import 'package:flutter/material.dart';
import 'package:hh_protokol/ui/cosmic_background.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool _locked = false;
  String? _last;

  @override
  Widget build(BuildContext context) {
    return CosmicBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(backgroundColor: Colors.transparent, title: const Text('Skaner')),
        body: Stack(
          children: [
            MobileScanner(
              onDetect: (capture) {
                if (_locked) return;
                final barcodes = capture.barcodes;
                if (barcodes.isEmpty) return;
                final raw = barcodes.first.rawValue;
                if (raw == null || raw.trim().isEmpty) return;

                setState(() {
                  _locked = true;
                  _last = raw.trim();
                });

                Future.delayed(const Duration(milliseconds: 250), () {
                  if (!mounted) return;
                  Navigator.of(context).pop(_last);
                });
              },
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.black.withOpacity(0.55),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: Text(
                  _last == null ? 'Nakieruj na kod…' : 'Złapano: $_last',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
