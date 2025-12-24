# Firebase Storage Bucket Manuel Oluşturma

## Google Cloud Console'dan Bucket Oluşturma

1. **Google Cloud Console'a gidin:**
   https://console.cloud.google.com/storage/browser?project=tuning-app-789ce

2. **"Create Bucket" butonuna tıklayın**

3. **Bucket ayarları:**
   - **Name:** `tuning-app-789ce.firebasestorage.app` (otomatik oluşturulacak)
   - **Location type:** Regional
   - **Location:** us-central1 (Iowa) - ÜCRETSİZ
   - **Storage class:** Standard
   - **Access control:** Uniform
   - **Public access prevention:** Enforce public access prevention OFF (resimlerin herkese açık olması için)

4. **"Create" butonuna tıklayın**

5. **Firebase Console'a geri dönün ve sayfayı yenileyin**

## Alternatif: Firebase CLI ile

```bash
# Google Cloud SDK yüklü olmalı
gsutil mb -p tuning-app-789ce -c STANDARD -l us-central1 gs://tuning-app-789ce.firebasestorage.app
```

