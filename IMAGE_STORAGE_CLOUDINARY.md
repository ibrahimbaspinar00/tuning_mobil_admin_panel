## Firebase Storage yok: Ürün resimlerini Cloudinary ile saklama

Bu admin panelde ürün görseli alanı `products.imageUrl` olarak tutulur. Firebase Storage kotanız dolduysa, görselleri **Firebase dışında** saklayıp sadece URL’i Firestore’a yazabilirsiniz.

### 1) Cloudinary hesabı aç
- Cloudinary Dashboard’tan **Cloud name** değerini al.

### 2) Unsigned Upload Preset oluştur
- Settings → Upload → **Upload presets**
- **Add upload preset**
- **Unsigned**: ON
- (Öneri) **Folder** kısıtla: `tuning_app/products`
- (Öneri) Allowed formats: `jpg,jpeg,png,webp`
- (Öneri) Max file size limiti koy

### 3) Proje config’ini doldur
`lib/config/external_image_storage_config.dart` içinde şunları doldur:
- `cloudinaryCloudName`
- `cloudinaryUnsignedUploadPreset`

### 4) Nasıl çalışır?
- Admin panelde resim seçilir → Cloudinary’ye yüklenir → dönen `secure_url` ürünün `imageUrl` alanına kaydedilir.
- Böylece Firebase Storage kullanılmaz.

### Güvenlik notu (önemli)
Unsigned preset istemci tarafında görüneceği için teorik olarak kötüye kullanılabilir.
- Preseti Cloudinary’de kısıtlayın (format/size/folder).
- İsterseniz bir sonraki adımda **signed upload** için küçük bir backend (Express/VPS) ekleyebiliriz.


