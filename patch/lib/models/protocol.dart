import 'dart:typed_data';

enum ProtocolType { przekazanie, odebranie, montaz, demontaz }

extension ProtocolTypeX on ProtocolType {
  String get label => switch (this) {
        ProtocolType.przekazanie => 'Przekazanie',
        ProtocolType.odebranie => 'Odebranie',
        ProtocolType.montaz => 'Montaż',
        ProtocolType.demontaz => 'Demontaż',
      };
}

class ScanItem {
  final String code;
  final DateTime at;
  ScanItem({required this.code, required this.at});
}

class PhotoItem {
  final String path;
  final String category; // testery / stoisko / usterki
  final DateTime at;
  PhotoItem({required this.path, required this.category, required this.at});
}

class ProtocolDraft {
  ProtocolType type;
  String eventName;
  String city;
  String storeNo;
  String receiver; // np. Douglas / osoba
  String notes;

  final List<ScanItem> scans;
  final List<PhotoItem> photos;

  Uint8List? signaturePng;

  ProtocolDraft({
    this.type = ProtocolType.przekazanie,
    this.eventName = '',
    this.city = '',
    this.storeNo = '',
    this.receiver = '',
    this.notes = '',
    List<ScanItem>? scans,
    List<PhotoItem>? photos,
    this.signaturePng,
  })  : scans = scans ?? <ScanItem>[],
        photos = photos ?? <PhotoItem>[];

  String get placeLabel {
    final c = city.trim();
    final s = storeNo.trim();
    if (c.isEmpty && s.isEmpty) return '';
    if (s.isEmpty) return c;
    if (c.isEmpty) return '($s)';
    return '$c ($s)';
  }
}
