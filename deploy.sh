#!/bin/bash

# Tuning Admin Panel - Deployment Script
# Bu script projeyi build edip Firebase Hosting'e deploy eder

echo "🚀 Tuning Admin Panel Deployment Başlıyor..."

# Renkler
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Flutter clean
echo -e "${BLUE}📦 Flutter clean yapılıyor...${NC}"
flutter clean

# 2. Pub get
echo -e "${BLUE}📥 Bağımlılıklar yükleniyor...${NC}"
flutter pub get

# 3. Build web
echo -e "${BLUE}🔨 Web build alınıyor...${NC}"
flutter build web --release

# Build başarılı mı kontrol et
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Build başarılı!${NC}"
else
    echo -e "${YELLOW}❌ Build başarısız!${NC}"
    exit 1
fi

# 4. Firebase deploy
echo -e "${BLUE}🚀 Firebase Hosting'e deploy ediliyor...${NC}"
firebase deploy --only hosting

# Deploy başarılı mı kontrol et
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Deployment başarılı!${NC}"
    echo -e "${GREEN}🎉 Admin panel yayında!${NC}"
else
    echo -e "${YELLOW}❌ Deployment başarısız!${NC}"
    exit 1
fi

