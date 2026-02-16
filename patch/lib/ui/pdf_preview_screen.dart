import 'package:flutter/material.dart';
import 'package:hh_protokol/models/protocol.dart';
import 'package:hh_protokol/services/pdf_zip_service.dart';
import 'package:printing/printing.dart';

class PdfPreviewScreen extends StatelessWidget {
  final ProtocolDraft draft;
  final String authorName;

  const PdfPreviewScreen({super.key, required this.draft, required this.authorName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Podgląd PDF')),
      body: PdfPreview(
        canChangeOrientation: false,
        canChangePageFormat: false,
        build: (format) => PdfZipService.instance.buildPdfBytes(draft: draft, authorName: authorName),
      ),
    );
  }
}
