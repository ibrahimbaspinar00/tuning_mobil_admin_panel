# Ürün Resimlerini Public Yapma - Kurulum Rehberi

Bu rehber, yeni kullanıcıların ürün fotoğraflarını görebilmesi için yapılan değişiklikleri açıklar.

## ✅ Yapılan Değişiklikler

### 1. Firebase Storage Rules Güncellendi
- `storage.rules` dosyası güncellendi
- Ürün resimleri artık herkese açık (public) okuma iznine sahip
- Yeni kullanıcılar da resimleri görebilir

### 2. Cloud Function Eklendi
- Yeni yüklenen resimler otomatik olarak public yapılıyor
- `functions/index.js` dosyasına `makeProductImagesPublic` fonksiyonu eklendi

### 3. Flutter Kod Güncellemeleri
- Resim yükleme sırasında public metadata eklendi
- Public URL formatı kullanılıyor (süresi dolmaz)

## 🚀 Kurulum Adımları

### Adım 1: Storage Rules'ı Deploy Edin

```bash
firebase deploy --only storage
```

### Adım 2: Cloud Functions'ı Deploy Edin

```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

### Adım 3: Mevcut Resimleri Public Yapın (Opsiyonel)

Mevcut tüm ürün resimlerini public yapmak için:

```bash
cd functions
node makeImagesPublic.js
```

Bu script:
- `product_images/` klasöründeki tüm dosyaları bulur
- Her birini public yapar
- Metadata'yı günceller
- İlerlemeyi konsola yazdırır

## 📋 Kontrol Listesi

- [ ] Storage rules deploy edildi
- [ ] Cloud Functions deploy edildi
- [ ] Mevcut resimler public yapıldı (opsiyonel)
- [ ] Yeni resim yükleme test edildi
- [ ] Mobil uygulamada resimler görüntüleniyor mu kontrol edildi

## 🔍 Sorun Giderme

### Resimler hala görünmüyor

1. **Storage Rules Kontrolü:**
   ```bash
   firebase firestore:rules:get
   ```

2. **Cloud Function Logları:**
   ```bash
   firebase functions:log
   ```

3. **Manuel Public Yapma:**
   - Firebase Console > Storage > product_images klasörüne gidin
   - Dosyaya tıklayın
   - "Make public" butonuna tıklayın

### Cloud Function çalışmıyor

1. Functions'ın deploy edildiğinden emin olun
2. Firebase Console > Functions bölümünden kontrol edin
3. Log'larda hata var mı bakın

## 📝 Notlar

- Public URL formatı: `https://storage.googleapis.com/BUCKET_NAME/FILE_PATH`
- Download URL'ler süresi dolabilir, public URL'ler süresizdir
- Cache kontrolü 1 yıl olarak ayarlandı (performans için)

## 🎯 Sonuç

Bu değişikliklerle:
- ✅ Yeni kullanıcılar ürün fotoğraflarını görebilir
- ✅ Resimler otomatik olarak public yapılır
- ✅ Flutter yedekleme sorunları çözülür
- ✅ Public URL'ler süresi dolmaz

