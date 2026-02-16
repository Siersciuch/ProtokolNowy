#!/usr/bin/env bash
set -euo pipefail
echo "== Helium House Protokol - bootstrap (macOS) =="

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter nie jest w PATH. Zainstaluj Flutter i uruchom ponownie."
  exit 1
fi

rm -rf hh_protokol || true
flutter create hh_protokol --platforms=android,ios --org eu.heliumhouse --project-name hh_protokol
rsync -a patch/ hh_protokol/
cd hh_protokol
flutter pub get
echo "GOTOWE. Odpal: flutter run"
