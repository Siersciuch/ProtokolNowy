# Helium House – Protokół (Flutter) v0.1

To jest **jedna baza kodu**, z której budujesz **Android** i **iOS** (czyli „dwie apki”, ale bez dwóch kodów).

Założenia (zgodnie z Twoimi zmianami):
- Brak API i brak synchronizacji między telefonami.
- Internet może być, ale dane i tak są lokalne.
- Pierwszy login: **ręczne wpisanie imienia i nazwiska** + ustawienie hasła (bez listy „ekipa” na logowaniu).
- Protokół: typ (Przekazanie / Odebranie / Montaż / Demontaż), event, miejscowość + **nr sklepu w nawiasie**.
- Skan: kody (kamera), opcjonalnie NFC (tekst), ręczne dopiski.
- Zdjęcia w kategoriach: **testery / stoisko / usterki**.
- Podpis palcem.
- Generowanie **PDF + ZIP(zdjęcia)** i udostępnienie przez systemowy „share” (Mail, WhatsApp itd.).
- Brak „Historii protokołów” w aplikacji – po wysłaniu draft jest czyszczony.

## 0) Wymagania na komputerze
- Flutter >= 3.22 (Dart >= 3.4)
- Android Studio (Android) i/lub Xcode (iOS)

## 1) Bootstrap projektu (tworzy pełny projekt z android/ios)
### Windows
1. Zainstaluj Flutter.
2. Rozpakuj ZIP.
3. Uruchom: `bootstrap_windows.bat`

### macOS
1. Zainstaluj Flutter + Xcode.
2. Rozpakuj ZIP.
3. W terminalu: `chmod +x bootstrap_mac.sh && ./bootstrap_mac.sh`

Skrypt:
- robi `flutter create hh_protokol`
- kopiuje ten folder `patch/` na wierzch
- odpala `flutter pub get`

## 2) Uruchomienie
W katalogu `hh_protokol/`:
- `flutter run` (wybierz urządzenie)

## 3) Build
Android APK:
- `flutter build apk --release`

iOS (na Macu):
- `flutter build ios --release`

## 4) Uprawnienia
Apka prosi o:
- Kamera (skan + zdjęcia)
- Zdjęcia (opcjonalnie podgląd)
- NFC (opcjonalnie)

## 5) Najważniejsze pliki
- `lib/main.dart` – start, routing, theme
- `lib/ui/` – ekrany
- `lib/services/pdf_zip_service.dart` – PDF + ZIP + Share
- `lib/services/auth_service.dart` – hasło (lokalnie w secure storage)
- `lib/services/db_service.dart` – SQLite (Sklepy/Ekipa)

## 6) Notatka o udostępnianiu maila
Na mobile najpewniej działa **systemowy share sheet** (to jest to, co robi share_plus):
- wybierasz „Mail” → wiadomość ma załączniki PDF/ZIP
- albo WhatsApp/Teams itd.

Źródła:
- share_plus (share dialog + pliki) – https://pub.dev/packages/share_plus
- printing/pdf (generowanie i print/share PDF) – https://pub.dev/packages/printing
- mobile_scanner (skan kodów) – https://pub.dev/packages/mobile_scanner
- nfc_manager (NFC) – https://pub.dev/packages/nfc_manager
