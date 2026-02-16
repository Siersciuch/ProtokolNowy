import 'package:flutter/foundation.dart';
import 'package:hh_protokol/models/protocol.dart';

class DraftService extends ChangeNotifier {
  ProtocolDraft draft = ProtocolDraft();

  void reset() {
    draft = ProtocolDraft();
    notifyListeners();
  }

  void setBasics({
    ProtocolType? type,
    String? eventName,
    String? city,
    String? storeNo,
    String? receiver,
  }) {
    if (type != null) draft.type = type;
    if (eventName != null) draft.eventName = eventName;
    if (city != null) draft.city = city;
    if (storeNo != null) draft.storeNo = storeNo;
    if (receiver != null) draft.receiver = receiver;
    notifyListeners();
  }

  void setNotes(String notes) {
    draft.notes = notes;
    notifyListeners();
  }

  void addScan(String code) {
    final c = code.trim();
    if (c.isEmpty) return;
    draft.scans.add(ScanItem(code: c, at: DateTime.now()));
    notifyListeners();
  }

  void removeScanAt(int index) {
    if (index < 0 || index >= draft.scans.length) return;
    draft.scans.removeAt(index);
    notifyListeners();
  }

  void addPhoto(String path, String category) {
    draft.photos.add(PhotoItem(path: path, category: category, at: DateTime.now()));
    notifyListeners();
  }

  void removePhotoAt(int index) {
    if (index < 0 || index >= draft.photos.length) return;
    draft.photos.removeAt(index);
    notifyListeners();
  }

  void setSignatureBytes(Uint8List? png) {
    draft.signaturePng = png;
    notifyListeners();
  }
}
