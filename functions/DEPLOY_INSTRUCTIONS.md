# Firebase Functions Deploy Talimatları

## ✅ Service Account Key Kurulumu Tamamlandı!

Dosya başarıyla yüklendi ve çalışıyor. Terminal çıktısında görüldüğü gibi:
```
✅ Firebase Admin SDK Service Account ile başlatıldı (Local)
```

## Production'a Deploy Etmek İçin

### 1. Önce Dependencies'leri Güncelleyin (Opsiyonel)

```bash
cd functions
npm install --save firebase-functions@latest
npm install
```

### 2. Deploy Edin

```bash
# Functions klasöründeyken
firebase deploy --only functions
```

**ÖNEMLİ:** Production'a deploy ederken Service Account key dosyasına ihtiyaç yok! Firebase otomatik olarak kullanır.

## Node.js Versiyonu Hakkında

Terminal'de Node.js 24 kullanıyorsunuz ama package.json'da 18 belirtilmiş. Bu normaldir:
- **Local development:** Sisteminizdeki Node.js versiyonunu kullanır (24)
- **Production:** Firebase Cloud Functions Node 18 kullanır (package.json'daki ayar)

Bu uyarıyı görmezden gelebilirsiniz, sorun değil.

## Test

Local'de test etmek için:
```bash
cd functions
firebase emulators:start --only functions
```

Production'a deploy etmek için:
```bash
cd functions
firebase deploy --only functions
```

## Güvenlik Hatırlatması

✅ Service Account key dosyası `.gitignore`'a eklendi
✅ Dosya Git'e commit edilmeyecek
✅ Production'da otomatik çalışacak

## Sorun Giderme

### "Permission denied" hatası alırsanız:

1. Firebase Console > IAM & Admin > Service Accounts
2. Service account'un "Firebase Cloud Messaging API" iznine sahip olduğundan emin olun

### Functions deploy edilmiyor:

```bash
# Firebase CLI'yi güncelleyin
npm install -g firebase-tools

# Tekrar deneyin
firebase deploy --only functions
```

