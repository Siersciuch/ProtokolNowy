@echo off
setlocal
echo == Helium House Protokol - bootstrap (Windows) ==
where flutter >nul 2>nul
if errorlevel 1 (
  echo Flutter nie jest w PATH. Zainstaluj Flutter i uruchom ponownie.
  exit /b 1
)

if exist hh_protokol (
  echo Folder hh_protokol juz istnieje. Kasuje...
  rmdir /s /q hh_protokol
)

flutter create hh_protokol --platforms=android,ios --org eu.heliumhouse --project-name hh_protokol
if errorlevel 1 exit /b 1

xcopy /E /I /Y patch hh_protokol
if errorlevel 1 exit /b 1

cd hh_protokol
flutter pub get
if errorlevel 1 exit /b 1

echo.
echo GOTOWE. Wejdz do hh_protokol i odpal: flutter run
endlocal
