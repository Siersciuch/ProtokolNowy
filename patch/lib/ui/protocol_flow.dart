import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hh_protokol/models/protocol.dart';
import 'package:hh_protokol/services/draft_service.dart';
import 'package:hh_protokol/services/pdf_zip_service.dart';
import 'package:hh_protokol/ui/cosmic_background.dart';
import 'package:hh_protokol/ui/scanner_screen.dart';
import 'package:hh_protokol/ui/pdf_preview_screen.dart';
import 'package:hh_protokol/ui/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:signature/signature.dart';

class ProtocolFlowScreen extends StatefulWidget {
  final String authorName;
  final DraftService draft;
  const ProtocolFlowScreen({super.key, required this.authorName, required this.draft});

  @override
  State<ProtocolFlowScreen> createState() => _ProtocolFlowScreenState();
}

class _ProtocolFlowScreenState extends State<ProtocolFlowScreen> {
  int _step = 0;

  final _event = TextEditingController();
  final _city = TextEditingController();
  final _storeNo = TextEditingController();
  final _receiver = TextEditingController();
  final _notes = TextEditingController();

  ProtocolType _type = ProtocolType.przekazanie;

  final _picker = ImagePicker();
  late final SignatureController _sig;

  @override
  void initState() {
    super.initState();
    _sig = SignatureController(penStrokeWidth: 3, exportBackgroundColor: Colors.transparent);

    // preload from draft
    final d = widget.draft.draft;
    _type = d.type;
    _event.text = d.eventName;
    _city.text = d.city;
    _storeNo.text = d.storeNo;
    _receiver.text = d.receiver;
    _notes.text = d.notes;
  }

  @override
  void dispose() {
    _event.dispose();
    _city.dispose();
    _storeNo.dispose();
    _receiver.dispose();
    _notes.dispose();
    _sig.dispose();
    super.dispose();
  }

  void _syncBasics() {
    widget.draft.setBasics(
      type: _type,
      eventName: _event.text,
      city: _city.text,
      storeNo: _storeNo.text,
      receiver: _receiver.text,
    );
  }

  Future<void> _addPhoto(String category) async {
    final cam = await Permission.camera.request();
    if (!cam.isGranted) return;

    final x = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (x == null) return;

    widget.draft.addPhoto(x.path, category);
  }

  Future<void> _openScanner() async {
    final cam = await Permission.camera.request();
    if (!cam.isGranted) return;

    final code = await Navigator.of(context).push<String?>(
      MaterialPageRoute(builder: (_) => const ScannerScreen()),
    );
    if (code != null && code.trim().isNotEmpty) {
      widget.draft.addScan(code.trim());
    }
  }

  Future<void> _exportAndShare() async {
    _syncBasics();
    widget.draft.setNotes(_notes.text);

    if (_sig.isNotEmpty) {
      final bytes = await _sig.toPngBytes();
      widget.draft.setSignatureBytes(bytes);
    }

    if (!mounted) return;

    await PdfZipService.instance.shareProtocol(
      context: context,
      draft: widget.draft.draft,
      authorName: widget.authorName,
    );

    // po share: czyścimy draft (bez historii)
    widget.draft.reset();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Wygenerowano PDF+ZIP i otwarto udostępnianie.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.draft.draft;

    return CosmicBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Nowy protokół'),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  child: Stepper(
                    currentStep: _step,
                    onStepContinue: () => setState(() => _step = (_step + 1).clamp(0, 4)),
                    onStepCancel: () => setState(() => _step = (_step - 1).clamp(0, 4)),
                    controlsBuilder: (context, details) {
                      final isLast = _step == 4;
                      return Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: HHButton(
                                label: isLast ? 'Wyślij protokół' : 'Dalej',
                                icon: isLast ? Icons.send_rounded : Icons.arrow_forward_rounded,
                                onPressed: isLast ? _exportAndShare : details.onStepContinue,
                              ),
                            ),
                            const SizedBox(width: 10),
                            if (_step > 0)
                              Expanded(
                                child: HHButton(
                                  label: 'Wstecz',
                                  icon: Icons.arrow_back_rounded,
                                  filled: false,
                                  onPressed: details.onStepCancel,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                    steps: [
                      Step(
                        title: const Text('Dane'),
                        isActive: _step >= 0,
                        content: HHCard(
                          child: Column(
                            children: [
                              DropdownButtonFormField<ProtocolType>(
                                value: _type,
                                decoration: hhInput('Rodzaj', icon: Icons.tune_rounded),
                                items: ProtocolType.values
                                    .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                                    .toList(),
                                onChanged: (v) {
                                  if (v == null) return;
                                  setState(() => _type = v);
                                  _syncBasics();
                                },
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _event,
                                onChanged: (_) => _syncBasics(),
                                decoration: hhInput('Event', hint: 'np. Beauty Street', icon: Icons.event_outlined),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _city,
                                onChanged: (_) => _syncBasics(),
                                decoration: hhInput('Miejscowość', hint: 'np. Warszawa', icon: Icons.location_city_outlined),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _storeNo,
                                onChanged: (_) => _syncBasics(),
                                decoration: hhInput('Nr sklepu (w nawiasie)', hint: 'np. 0123', icon: Icons.numbers_rounded),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _receiver,
                                onChanged: (_) => _syncBasics(),
                                decoration: hhInput('Odbiorca', hint: 'np. Douglas / nazwisko', icon: Icons.person_outline),
                              ),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text('Sporządził: ${widget.authorName}', style: TextStyle(color: Colors.white.withOpacity(0.7))),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Step(
                        title: const Text('Skan'),
                        isActive: _step >= 1,
                        content: Column(
                          children: [
                            HHCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  HHButton(label: 'Skanuj kod', icon: Icons.qr_code_scanner_rounded, onPressed: _openScanner),
                                  const SizedBox(height: 8),
                                  HHButton(
                                    label: 'Dodaj ręcznie',
                                    icon: Icons.edit_rounded,
                                    filled: false,
                                    onPressed: () async {
                                      final c = await _prompt(context, 'Kod');
                                      if (c != null && c.trim().isNotEmpty) widget.draft.addScan(c.trim());
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (d.scans.isEmpty)
                              Text('Brak skanów.', style: TextStyle(color: Colors.white.withOpacity(0.6)))
                            else
                              HHCard(
                                child: Column(
                                  children: List.generate(d.scans.length, (i) {
                                    final s = d.scans[i];
                                    return ListTile(
                                      dense: true,
                                      title: Text(s.code, style: const TextStyle(fontWeight: FontWeight.w800)),
                                      subtitle: Text(s.at.toIso8601String().substring(11, 19)),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.close_rounded),
                                        onPressed: () => widget.draft.removeScanAt(i),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Step(
                        title: const Text('Zdjęcia'),
                        isActive: _step >= 2,
                        content: Column(
                          children: [
                            HHCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  HHButton(label: 'Foto: testery', icon: Icons.inventory_2_outlined, onPressed: () => _addPhoto('testery')),
                                  const SizedBox(height: 8),
                                  HHButton(label: 'Foto: stoisko', icon: Icons.storefront_outlined, filled: false, onPressed: () => _addPhoto('stoisko')),
                                  const SizedBox(height: 8),
                                  HHButton(label: 'Foto: usterki', icon: Icons.build_outlined, filled: false, onPressed: () => _addPhoto('usterki')),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (d.photos.isEmpty)
                              Text('Brak zdjęć.', style: TextStyle(color: Colors.white.withOpacity(0.6)))
                            else
                              HHCard(
                                child: Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: List.generate(d.photos.length, (i) {
                                    final ph = d.photos[i];
                                    return Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(16),
                                          child: Image.file(File(ph.path), width: 110, height: 110, fit: BoxFit.cover),
                                        ),
                                        Positioned(
                                          right: 0,
                                          top: 0,
                                          child: IconButton(
                                            icon: const Icon(Icons.close_rounded),
                                            onPressed: () => widget.draft.removePhotoAt(i),
                                          ),
                                        ),
                                        Positioned(
                                          left: 8,
                                          bottom: 6,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.55),
                                              borderRadius: BorderRadius.circular(999),
                                              border: Border.all(color: Colors.white.withOpacity(0.12)),
                                            ),
                                            child: Text(ph.category, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                                          ),
                                        ),
                                      ],
                                    );
                                  }),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Step(
                        title: const Text('Uwagi'),
                        isActive: _step >= 3,
                        content: HHCard(
                          child: Column(
                            children: [
                              TextField(
                                controller: _notes,
                                maxLines: 6,
                                decoration: hhInput('Uwagi (przed podpisem)', hint: 'Wpisz wszystko, co ma przeczytać odbiorca', icon: Icons.notes_rounded),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Step(
                        title: const Text('Podpis + Wyślij'),
                        isActive: _step >= 4,
                        content: Column(
                          children: [
                            HHCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text('Podpis palcem', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 10),
                                  Container(
                                    height: 160,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.white.withOpacity(0.12)),
                                      color: Colors.white.withOpacity(0.02),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Signature(controller: _sig, backgroundColor: Colors.transparent),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: HHButton(
                                          label: 'Wyczyść',
                                          icon: Icons.delete_sweep_outlined,
                                          filled: false,
                                          onPressed: _sig.clear,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: HHButton(
                                          label: 'Podgląd',
                                          icon: Icons.picture_as_pdf_outlined,
                                          filled: false,
                                          onPressed: () {
                                            _syncBasics();
                                            widget.draft.setNotes(_notes.text);
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) => PdfPreviewScreen(draft: widget.draft.draft, authorName: widget.authorName),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            HHCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text('Plik PDF ma nazwę:', style: TextStyle(color: Colors.white.withOpacity(0.7))),
                                  const SizedBox(height: 6),
                                  Text(
                                    'DATA__RODZAJ__EVENT__MIEJSCE',
                                    style: const TextStyle(fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '…a ZIP ma to samo + zdjęcia nazwane: DATA__EVENT__MIEJSCE__KATEGORIA__NR.jpg',
                                    style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<String?> _prompt(BuildContext context, String title) async {
    final c = TextEditingController();
    String? out;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(controller: c, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Anuluj')),
          TextButton(
            onPressed: () {
              out = c.text;
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
    return out;
  }
}
