@echo off
REM Tuning Admin Panel - Deployment Script (Windows)
REM Bu script projeyi build edip Firebase Hosting'e deploy eder

echo 🚀 Tuning Admin Panel Deployment Başlıyor...

REM 1. Flutter clean
echo 📦 Flutter clean yapılıyor...
call flutter clean

REM 2. Pub get
echo 📥 Bağımlılıklar yükleniyor...
call flutter pub get

REM 3. Build web
echo 🔨 Web build alınıyor...
call flutter build web --release

REM Build başarılı mı kontrol et
if %errorlevel% neq 0 (
    echo ❌ Build başarısız!
    exit /b 1
)

echo ✅ Build başarılı!

REM 4. Firebase deploy
echo 🚀 Firebase Hosting'e deploy ediliyor...
call firebase deploy --only hosting

REM Deploy başarılı mı kontrol et
if %errorlevel% neq 0 (
    echo ❌ Deployment başarısız!
    exit /b 1
)

echo ✅ Deployment başarılı!
echo 🎉 Admin panel yayında!
pause

