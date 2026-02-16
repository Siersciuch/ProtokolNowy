import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:hh_protokol/models/protocol.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class PdfZipService {
  PdfZipService._();
  static final PdfZipService instance = PdfZipService._();

  String _safe(String s) {
    var out = s.trim();
    out = out.replaceAll(RegExp(r'\s+'), '_');
    out = out.replaceAll(RegExp(r'[^\w\-\(\)]'), '_');
    out = out.replaceAll(RegExp(r'_+'), '_');
    return out;
  }

  
  Future<Uint8List> buildPdfBytes({
    required ProtocolDraft draft,
    required String authorName,
  }) async {
    return _buildPdfBytes(draft: draft, authorName: authorName, generatedAt: DateTime.now());
  }

Future<({File pdf, File zip})> buildFiles({
    required ProtocolDraft draft,
    required String authorName,
  }) async {
    final now = DateTime.now();
    final date = DateFormat('yyyy-MM-dd').format(now);

    final type = draft.type.label;
    final place = draft.placeLabel.isEmpty ? 'BRAK_MIEJSCA' : draft.placeLabel;
    final event = draft.eventName.trim().isEmpty ? 'BRAK_EVENTU' : draft.eventName.trim();

    final baseName = '${date}__${_safe(type)}__${_safe(event)}__${_safe(place)}';
    final tmp = await getTemporaryDirectory();

    final pdfFile = File(p.join(tmp.path, '$baseName.pdf'));
    final zipFile = File(p.join(tmp.path, '$baseName.zip'));

    final pdfBytes = await _buildPdfBytes(draft: draft, authorName: authorName, generatedAt: now);
    await pdfFile.writeAsBytes(pdfBytes);

    final encoder = ZipFileEncoder();
    encoder.create(zipFile.path);
    encoder.addFile(pdfFile);

    // photos
    for (var i = 0; i < draft.photos.length; i++) {
      final ph = draft.photos[i];
      final f = File(ph.path);
      if (await f.exists()) {
        final ext = p.extension(ph.path).isEmpty ? '.jpg' : p.extension(ph.path);
        final fn = '${date}__${_safe(event)}__${_safe(place)}__${_safe(ph.category)}__${i + 1}$ext';
        encoder.addFile(f, fn);
      }
    }

    // signature
    if (draft.signaturePng != null) {
      final sig = File(p.join(tmp.path, '${baseName}__PODPIS.png'));
      await sig.writeAsBytes(draft.signaturePng!);
      encoder.addFile(sig);
    }

    encoder.close();

    return (pdf: pdfFile, zip: zipFile);
  }

  Future<void> shareProtocol({
    required BuildContext context,
    required ProtocolDraft draft,
    required String authorName,
  }) async {
    final files = await buildFiles(draft: draft, authorName: authorName);

    final subject = 'HH Protokół – ${draft.type.label} – ${draft.eventName} – ${draft.placeLabel}';
    final body = 'W załączniku PDF + ZIP(zdjęcia).';

    final params = ShareParams(
      subject: subject,
      text: body,
      files: [XFile(files.pdf.path), XFile(files.zip.path)],
    );

    await SharePlus.instance.share(params);
  }

  Future<Uint8List> _buildPdfBytes({
    required ProtocolDraft draft,
    required String authorName,
    required DateTime generatedAt,
  }) async {
    final doc = pw.Document();

    pw.Widget label(String k, String v) => pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 6),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(width: 110, child: pw.Text(k, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
              pw.Expanded(child: pw.Text(v.isEmpty ? '—' : v)),
            ],
          ),
        );

    // photos count by category
    int countCat(String cat) => draft.photos.where((p) => p.category == cat).length;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 10),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('HELIUM HOUSE – PROTOKÓŁ', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.Text(DateFormat('yyyy-MM-dd HH:mm').format(generatedAt)),
              ],
            ),
          ),
          pw.Divider(),

          label('Rodzaj', draft.type.label),
          label('Event', draft.eventName.trim()),
          label('Miejsce', draft.placeLabel),
          label('Odbiorca', draft.receiver.trim()),
          label('Sporządził', authorName),

          pw.SizedBox(height: 10),
          pw.Text('Skanowane kody', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          if (draft.scans.isEmpty)
            pw.Text('—')
          else
            pw.Table(
              border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey600),
              columnWidths: {
                0: const pw.FlexColumnWidth(1),
                1: const pw.FlexColumnWidth(4),
                2: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('#', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Kod', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Czas', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  ],
                ),
                ...List.generate(draft.scans.length, (i) {
                  final s = draft.scans[i];
                  return pw.TableRow(children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${i + 1}')),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(s.code)),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(DateFormat('HH:mm:ss').format(s.at))),
                  ]);
                }),
              ],
            ),

          pw.SizedBox(height: 12),
          pw.Text('Zdjęcia', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Bullet(text: 'Testery: ${countCat('testery')}'),
          pw.Bullet(text: 'Stoisko: ${countCat('stoisko')}'),
          pw.Bullet(text: 'Usterki: ${countCat('usterki')}'),

          pw.SizedBox(height: 12),
          pw.Text('Uwagi', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey600, width: 0.5),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Text(draft.notes.trim().isEmpty ? '—' : draft.notes.trim()),
          ),

          pw.SizedBox(height: 14),
          pw.Text('Podpis', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          if (draft.signaturePng == null)
            pw.Text('—')
          else
            pw.Container(
              height: 90,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey600, width: 0.5),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              padding: const pw.EdgeInsets.all(8),
              child: pw.Image(pw.MemoryImage(draft.signaturePng!)),
            ),

          pw.SizedBox(height: 18),
          pw.Text('Wygenerowano przez aplikację HH Protokół (bez historii protokołów na urządzeniu).', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        ],
      ),
    );

    return doc.save();
  }
}
