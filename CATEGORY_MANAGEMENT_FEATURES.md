# Kategori Yönetimi Özellikleri Dokümantasyonu

Bu dokümantasyon, kategori yönetimi sayfasının tüm özelliklerini detaylı bir şekilde açıklamaktadır. Bu özellikler hem web hem de mobil uygulamalarda aynı şekilde çalışmalıdır.

## 📋 İçindekiler

1. [Genel Bakış](#genel-bakış)
2. [Kategori İşlemleri](#kategori-işlemleri)
3. [Ürün Yönetimi](#ürün-yönetimi)
4. [Teknik Detaylar](#teknik-detaylar)
5. [API Metodları](#api-metodları)
6. [UI/UX Özellikleri](#uiux-özellikleri)

---

## 🎯 Genel Bakış

Kategori yönetimi sayfası, admin panelinde kategorileri ve bu kategorilere ait ürünleri yönetmek için kullanılır. Sayfa şu ana bölümlerden oluşur:

- **İstatistik Kartları**: Toplam, aktif, pasif ve ürünlerden gelen kategori sayıları
- **Kategori Listesi**: Tüm kategorilerin grid görünümü
- **Ürün Yönetimi**: Her kategori için ürün görüntüleme ve yönetim özellikleri

---

## 📦 Kategori İşlemleri

### 1. Kategori Ekleme

**Özellikler:**
- Yeni kategori ekleme dialog'u
- Kategori adı (zorunlu)
- Kategori açıklaması (opsiyonel)
- Otomatik aktif durumda oluşturulur

**Kullanım:**
1. "Yeni Kategori" butonuna tıklayın
2. Kategori adını girin
3. (Opsiyonel) Açıklama ekleyin
4. "Kaydet" butonuna tıklayın

**Teknik Detaylar:**
- `addCategory()` metodu kullanılır
- Firestore'a `categories` koleksiyonuna eklenir
- Stream otomatik olarak güncellenir

### 2. Kategori Düzenleme

**Özellikler:**
- Mevcut kategori bilgilerini düzenleme
- Kategori adı ve açıklama güncelleme
- Anlık güncelleme (stream ile)

**Kullanım:**
1. Kategori kartındaki düzenle (mavi kalem) ikonuna tıklayın
2. Bilgileri düzenleyin
3. "Kaydet" butonuna tıklayın

**Teknik Detaylar:**
- `updateCategory()` metodu kullanılır
- `updatedAt` alanı otomatik güncellenir

### 3. Kategori Silme

**Özellikler:**
- Kategori silme onay dialog'u
- Server-side doğrulama
- Cache sorunlarını önleme
- Anlık listeden kaldırma

**Kullanım:**
1. Kategori kartındaki sil (kırmızı çöp kutusu) ikonuna tıklayın
2. Onay dialog'unda "Sil" butonuna tıklayın

**Teknik Detaylar:**
- `deleteCategory()` metodu kullanılır
- Silme işlemi server'dan doğrulanır
- Stream otomatik güncellenir
- Dropdown hatalarını önlemek için güvenli parsing yapılır

### 4. Kategori Durumu Değiştirme (Aktif/Pasif)

**Özellikler:**
- Tek tıkla aktif/pasif yapma
- Görsel geri bildirim (ikon değişimi)
- Anlık güncelleme

**Kullanım:**
1. Kategori kartındaki görünürlük (turuncu göz) ikonuna tıklayın
2. Kategori durumu otomatik değişir

**Teknik Detaylar:**
- `updateCategory()` metodu ile `isActive` alanı güncellenir
- Aktif kategoriler yeşil, pasif kategoriler gri renkte gösterilir

---

## 🛍️ Ürün Yönetimi

### 1. Kategorideki Ürünleri Görüntüleme

**Özellikler:**
- Kategorideki tüm ürünleri listeleme
- Ürün bilgileri: resim, isim, fiyat, stok
- Her ürün için düzenleme ve kategori değiştirme seçenekleri
- Ürün sayısı gösterimi

**Kullanım:**
1. Kategori kartındaki "Ürünleri Görüntüle" (mor göz) ikonuna tıklayın
2. Dialog açılır ve kategorideki tüm ürünler listelenir

**Dialog Özellikleri:**
- Başlık: "[Kategori Adı] Kategorisindeki Ürünler"
- Ürün sayısı bilgisi
- "Kategoriye Ürün Ekle" butonu
- Her ürün için:
  - Ürün resmi
  - Ürün adı
  - Fiyat ve stok bilgisi
  - Düzenle butonu (mavi kalem)
  - Kategori dropdown'ı (hızlı kategori değiştirme)

### 2. Ürün Kategorisini Değiştirme

**Özellikler:**
- Dropdown ile hızlı kategori değiştirme
- Anlık güncelleme
- Başarı mesajı
- Dialog otomatik yenilenir

**Kullanım:**
1. Ürün listesi dialog'unda ürünün yanındaki kategori dropdown'ından yeni kategori seçin
2. Değişiklik otomatik kaydedilir
3. Dialog yenilenir ve ürün listeden kaldırılır

**Teknik Detaylar:**
- `updateProductFields()` metodu kullanılır
- Sadece `category` alanı güncellenir
- Stream otomatik güncellenir

### 3. Ürün Düzenleme

**Özellikler:**
- Ürün bilgilerini düzenleme dialog'u
- Tüm ürün alanlarını düzenleme:
  - Ürün adı
  - Fiyat
  - Stok
  - Kategori
  - Açıklama
  - Ürün resmi
- Form validasyonu
- Resim yükleme desteği

**Kullanım:**
1. Ürün listesi dialog'unda ürünün yanındaki düzenle (mavi kalem) ikonuna tıklayın
2. Ürün düzenleme dialog'u açılır
3. Bilgileri düzenleyin
4. "Kaydet" butonuna tıklayın

**Teknik Detaylar:**
- `updateProduct()` metodu kullanılır
- `ProfessionalImageUploader` widget'ı ile resim yükleme
- Form validasyonu ile hata kontrolü
- `updatedAt` alanı otomatik güncellenir

### 4. Kategoriye Ürün Ekleme

**Özellikler:**
- Mevcut ürünleri kategorilere ekleme
- Tüm ürünleri listeleme
- Kategori durumu gösterimi:
  - Bu kategoride olan ürünler: "Bu ürün bu kategoride zaten ekli"
  - Bu kategoride olmayan ürünler: "Mevcut Kategori: [Kategori Adı]"
- İstatistikler: Toplam, bu kategoride, eklenebilir ürün sayıları
- Dialog açık kalır, eklemeye devam edilebilir

**Kullanım:**
1. Kategorideki ürünler dialog'unda "Kategoriye Ürün Ekle" butonuna tıklayın
2. Tüm ürünler listelenir
3. Eklemek istediğiniz ürünün yanındaki "Ekle" butonuna tıklayın
4. Ürün kategorisi güncellenir ve listeden kaldırılır
5. Dialog açık kalır, başka ürünler eklemeye devam edebilirsiniz

**Önemli Notlar:**
- Bu kategoride olan ürünler için "Ekle" butonu yerine "Zaten Ekli" etiketi gösterilir
- Aynı kategoriye tekrar ekleme engellenir
- Ürün eklendikten sonra liste otomatik güncellenir
- Dialog kapanmaz, eklemeye devam edilebilir

**Teknik Detaylar:**
- `updateProductFields()` metodu kullanılır
- StatefulBuilder ile dialog state yönetimi
- Server'dan ürünler yeniden yüklenir
- `setDialogState()` ile anlık güncelleme

---

## 🔧 Teknik Detaylar

### Stream Yönetimi

**Özellikler:**
- Firestore stream'leri kullanılır
- Hata yakalama ve güvenli parsing
- Cache sorunlarını önleme
- Anlık güncellemeler

**Kullanılan Stream'ler:**
- `getAllCategories()`: Tüm kategorileri getirir (aktif ve pasif)
- `getCategories()`: Sadece aktif kategorileri getirir

**Hata Yönetimi:**
- `handleError()` ile stream hataları yakalanır
- Geçersiz dokümanlar atlanır
- Stream kesilmez, boş liste döndürülür

### Güvenli Parsing

**Özellikler:**
- Null kontrolü
- Geçersiz veri kontrolü
- Varsayılan değerler
- Try-catch blokları

**ProductCategory.fromFirestore() Güvenlikleri:**
```dart
- Null data kontrolü
- Boş data kontrolü
- Tip dönüşümleri (bool, string)
- Hata durumunda varsayılan değerler
```

### Dropdown Güvenliği

**Sorun:**
- Kategori silindiğinde dropdown'larda hata oluşabilir
- Seçili kategori listede olmayabilir

**Çözüm:**
- Dropdown value kontrolü: `value` prop'u `items` listesinde olup olmadığı kontrol edilir
- Güvenli varsayılan değerler: Liste boşsa veya değer listede yoksa null veya varsayılan değer kullanılır
- Kategori yükleme sırasında kontrol: Kategoriler yüklendiğinde seçili kategori listede yoksa null yapılır

---

## 📡 API Metodları

### AdminService Metodları

#### Kategori İşlemleri

**1. addCategory(ProductCategory category)**
- **Açıklama**: Yeni kategori ekler
- **Parametreler**: `ProductCategory` nesnesi
- **Dönüş**: `Future<String>` - Oluşturulan kategori ID'si
- **Kullanım**: Kategori ekleme dialog'unda

**2. getAllCategories()**
- **Açıklama**: Tüm kategorileri getirir (aktif ve pasif)
- **Dönüş**: `Stream<List<ProductCategory>>`
- **Kullanım**: Kategori listesi ve istatistikler için

**3. getCategories()**
- **Açıklama**: Sadece aktif kategorileri getirir
- **Dönüş**: `Stream<List<ProductCategory>>`
- **Kullanım**: Aktif kategori listesi için

**4. updateCategory(ProductCategory category)**
- **Açıklama**: Kategori bilgilerini günceller
- **Parametreler**: `ProductCategory` nesnesi
- **Dönüş**: `Future<void>`
- **Kullanım**: Kategori düzenleme ve durum değiştirme

**5. deleteCategory(String categoryId)**
- **Açıklama**: Kategoriyi siler
- **Parametreler**: Kategori ID'si
- **Dönüş**: `Future<void>`
- **Özellikler**:
  - Server-side doğrulama
  - Silme işlemi kontrolü
  - Cache sorunlarını önleme

#### Ürün İşlemleri

**1. getProductsFromServer()**
- **Açıklama**: Tüm ürünleri server'dan getirir (cache bypass)
- **Dönüş**: `Future<List<AdminProduct>>`
- **Kullanım**: Ürün listesi ve kategoriye ürün ekleme

**2. updateProduct(String productId, AdminProduct product)**
- **Açıklama**: Ürün bilgilerini günceller
- **Parametreler**: Ürün ID'si ve güncellenmiş ürün nesnesi
- **Dönüş**: `Future<void>`
- **Kullanım**: Ürün düzenleme dialog'unda

**3. updateProductFields(String productId, Map<String, dynamic> updates)**
- **Açıklama**: Ürünün belirli alanlarını günceller
- **Parametreler**: Ürün ID'si ve güncellenecek alanlar
- **Dönüş**: `Future<void>`
- **Kullanım**: Kategori değiştirme ve hızlı güncellemeler

---

## 🎨 UI/UX Özellikleri

### İstatistik Kartları

**Özellikler:**
- 4 adet istatistik kartı:
  1. **Toplam Kategori**: Tüm kategoriler (Firestore + ürünlerden gelen)
  2. **Aktif Kategori**: Aktif durumdaki kategoriler
  3. **Pasif Kategori**: Pasif durumdaki kategoriler
  4. **Ürünlerden Gelen**: Ürünlerde var ama Firestore'da olmayan kategoriler

**Renkler:**
- Toplam: Mavi
- Aktif: Yeşil
- Pasif: Kırmızı
- Ürünlerden Gelen: Turuncu

### Kategori Kartları

**Görünüm:**
- Grid layout (responsive)
- Her kart:
  - Header: Kategori adı ve durum badge'i
  - İçerik: Kategori açıklaması
  - Footer: Aksiyon butonları

**Aksiyon Butonları:**
1. **Ürünleri Görüntüle** (Mor göz ikonu)
2. **Düzenle** (Mavi kalem ikonu)
3. **Aktif/Pasif Yap** (Turuncu göz ikonu)
4. **Sil** (Kırmızı çöp kutusu ikonu)

**Renkler:**
- Aktif kategoriler: Yeşil border ve arka plan
- Pasif kategoriler: Gri border ve arka plan

### Dialog'lar

**1. Kategori Ürünleri Dialog'u**
- Genişlik: Ekran genişliğinin %80'i
- Yükseklik: Ekran yüksekliğinin %80'i
- Scrollable liste
- Header: Kategori adı ve kapatma butonu
- İstatistik: Ürün sayısı
- "Kategoriye Ürün Ekle" butonu
- Ürün listesi

**2. Ürün Düzenleme Dialog'u**
- Genişlik: Ekran genişliğinin %60'ı
- Maksimum yükseklik: 800px
- Form alanları:
  - Resim yükleme
  - Ürün adı
  - Fiyat ve stok (yan yana)
  - Kategori dropdown
  - Açıklama
- Kaydet ve İptal butonları

**3. Kategoriye Ürün Ekle Dialog'u**
- Genişlik: Ekran genişliğinin %70'i
- Yükseklik: Ekran yüksekliğinin %80'i
- İstatistikler: Toplam, bu kategoride, eklenebilir
- Tüm ürünler listesi
- Her ürün için kategori durumu gösterimi
- "Ekle" butonu veya "Zaten Ekli" etiketi

### Renk Paleti

**Ana Renkler:**
- Mavi: `#3B82F6` (Düzenleme, genel aksiyonlar)
- Mor: `#6366F1` (Ürünleri görüntüleme, yeni ekleme)
- Yeşil: `#10B981` (Aktif durum, başarı mesajları)
- Kırmızı: `#EF4444` (Silme, hata mesajları)
- Turuncu: `#F59E0B` (Pasif yapma, uyarılar)

**Durum Renkleri:**
- Bu kategoride olan ürünler: Turuncu (`Colors.orange`)
- Bu kategoride olmayan ürünler: Mavi (`Colors.blue`)
- Zaten ekli durumu: Gri (`Colors.grey`)

---

## 🔄 State Yönetimi

### StreamBuilder Kullanımı

**Kategori Listesi:**
```dart
StreamBuilder<List<ProductCategory>>(
  key: ValueKey(_refreshKey),
  stream: _adminService.getAllCategories(),
  builder: (context, snapshot) {
    // UI oluşturma
  },
)
```

**Özellikler:**
- `_refreshKey` ile manuel yenileme
- Hata yakalama
- Loading state
- Empty state

### StatefulBuilder Kullanımı

**Dialog'larda:**
- Ürün ekleme dialog'u
- Ürün düzenleme dialog'u
- Kategoriye ürün ekleme dialog'u

**Avantajlar:**
- Dialog içinde state güncelleme
- Form validasyonu
- Loading state yönetimi

---

## 🛡️ Hata Yönetimi

### Stream Hataları

**Yakalama:**
```dart
.handleError((error) {
  debugPrint('❌ Stream hatası: $error');
  return <ProductCategory>[];
})
```

**Özellikler:**
- Stream kesilmez
- Boş liste döndürülür
- Hata loglanır

### Parsing Hataları

**Yakalama:**
```dart
try {
  return ProductCategory.fromFirestore(doc.data(), doc.id);
} catch (e) {
  debugPrint('⚠️ Parse hatası: $e');
  return null;
}
```

**Özellikler:**
- Geçersiz dokümanlar atlanır
- Stream devam eder
- Hata loglanır

### Dropdown Hataları

**Önleme:**
```dart
value: _selectedCategory != null && _allCategoryNames.contains(_selectedCategory)
    ? _selectedCategory
    : null,
```

**Özellikler:**
- Value kontrolü
- Güvenli varsayılan değerler
- Null safety

---

## 📱 Mobil ve Web Uyumluluğu

### Responsive Tasarım

**Grid Layout:**
- Mobil: 1 sütun
- Tablet: 2 sütun
- Laptop: 3 sütun
- Desktop: 4 sütun

**Dialog Boyutları:**
- Mobil: Tam ekran veya %90
- Tablet ve üzeri: Sabit genişlik (60-80%)

### Platform Farkları

**Web:**
- `ProfessionalImageUploader` widget'ı kullanılır
- Drag & drop resim yükleme
- Browser file picker

**Mobil:**
- `ImagePicker` kullanılabilir
- Kamera erişimi
- Galeri erişimi

---

## 🔐 Güvenlik ve Validasyon

### Form Validasyonu

**Kategori Ekleme/Düzenleme:**
- Kategori adı: Zorunlu, boş olamaz
- Açıklama: Opsiyonel

**Ürün Düzenleme:**
- Ürün adı: Zorunlu
- Fiyat: Zorunlu, sayı olmalı
- Stok: Zorunlu, sayı olmalı
- Kategori: Zorunlu, listede olmalı

### Server-Side Doğrulama

**Kategori Silme:**
- Belge varlık kontrolü
- Silme işlemi doğrulama
- Cache bypass

**Ürün Güncelleme:**
- Ürün varlık kontrolü
- Kategori geçerliliği kontrolü

---

## 📊 Performans Optimizasyonları

### Cache Yönetimi

**Server-Side Fetch:**
- `getProductsFromServer()`: Cache bypass
- `GetOptions(source: Source.server)`: Server'dan direkt çekme
- Anlık güncellemeler için kritik

### Stream Optimizasyonu

**includeMetadataChanges:**
```dart
.snapshots(includeMetadataChanges: false)
```

**Avantajlar:**
- Gereksiz güncellemeleri önler
- Performans iyileştirmesi
- Daha az widget rebuild

### Lazy Loading

**Ürün Listeleri:**
- ListView.builder kullanımı
- Sadece görünen öğeler render edilir
- Büyük listeler için performans

---

## 🧪 Test Senaryoları

### Kategori İşlemleri

1. **Kategori Ekleme**
   - ✅ Yeni kategori ekleme
   - ✅ Boş kategori adı kontrolü
   - ✅ Stream güncelleme kontrolü

2. **Kategori Düzenleme**
   - ✅ Mevcut kategori düzenleme
   - ✅ Bilgi güncelleme
   - ✅ Stream güncelleme kontrolü

3. **Kategori Silme**
   - ✅ Kategori silme
   - ✅ Onay dialog'u
   - ✅ Anlık listeden kaldırma
   - ✅ Dropdown hata kontrolü

4. **Kategori Durumu**
   - ✅ Aktif/Pasif yapma
   - ✅ Görsel geri bildirim
   - ✅ Stream güncelleme

### Ürün İşlemleri

1. **Ürünleri Görüntüleme**
   - ✅ Kategorideki ürünleri listeleme
   - ✅ Boş kategori kontrolü
   - ✅ Ürün sayısı gösterimi

2. **Kategori Değiştirme**
   - ✅ Dropdown ile kategori değiştirme
   - ✅ Anlık güncelleme
   - ✅ Dialog yenileme

3. **Ürün Düzenleme**
   - ✅ Ürün bilgilerini düzenleme
   - ✅ Form validasyonu
   - ✅ Resim yükleme

4. **Kategoriye Ürün Ekleme**
   - ✅ Mevcut ürünleri ekleme
   - ✅ Kategori durumu gösterimi
   - ✅ Aynı kategoriye tekrar ekleme engelleme
   - ✅ Dialog açık kalma
   - ✅ Liste güncelleme

---

## 🚀 Kullanım Örnekleri

### Senaryo 1: Yeni Kategori Oluşturma ve Ürün Ekleme

1. "Yeni Kategori" butonuna tıklayın
2. Kategori adı: "Yeni Kategori"
3. Açıklama: "Bu kategori için açıklama"
4. "Kaydet" butonuna tıklayın
5. Kategori kartındaki "Ürünleri Görüntüle" ikonuna tıklayın
6. "Kategoriye Ürün Ekle" butonuna tıklayın
7. İstediğiniz ürünlerin "Ekle" butonuna tıklayın
8. Ürünler kategorilere eklenir

### Senaryo 2: Mevcut Ürünün Kategorisini Değiştirme

1. Kategori kartındaki "Ürünleri Görüntüle" ikonuna tıklayın
2. Ürünün yanındaki kategori dropdown'ından yeni kategori seçin
3. Ürün otomatik olarak yeni kategoriye taşınır
4. Dialog yenilenir

### Senaryo 3: Ürün Bilgilerini Düzenleme

1. Kategori kartındaki "Ürünleri Görüntüle" ikonuna tıklayın
2. Ürünün yanındaki düzenle (mavi kalem) ikonuna tıklayın
3. Ürün bilgilerini düzenleyin
4. "Kaydet" butonuna tıklayın
5. Ürün güncellenir ve dialog yenilenir

---

## 📝 Notlar ve İpuçları

### Önemli Notlar

1. **Kategori Silme**: Kategori silindiğinde, o kategorideki ürünlerin kategorisi boşaltılmaz. Ürünlerin kategorilerini manuel olarak değiştirmeniz gerekir.

2. **Ürünlerden Gelen Kategoriler**: Ürünlerde var ama Firestore'da olmayan kategoriler, "Ürünlerden Gelen" olarak gösterilir. Bu kategorileri Firestore'a ekleyebilirsiniz.

3. **Stream Güncellemeleri**: Tüm değişiklikler anlık olarak stream'ler aracılığıyla güncellenir. Manuel yenileme gerekmez.

4. **Dialog State**: "Kategoriye Ürün Ekle" dialog'u açık kalır ve eklemeye devam edebilirsiniz. Dialog'u kapatmak için X butonuna tıklayın.

5. **Dropdown Güvenliği**: Kategori silindiğinde dropdown'larda hata oluşmaması için güvenli parsing yapılır. Seçili kategori listede yoksa null yapılır.

### İpuçları

1. **Toplu İşlemler**: Birden fazla ürünü aynı kategoriye eklemek için "Kategoriye Ürün Ekle" dialog'unu kullanın. Dialog açık kalır ve eklemeye devam edebilirsiniz.

2. **Hızlı Kategori Değiştirme**: Ürün listesi dialog'unda kategori dropdown'ını kullanarak hızlıca kategori değiştirebilirsiniz.

3. **Kategori Durumu**: Pasif kategoriler gri renkte gösterilir. Aktif kategoriler yeşil renkte gösterilir.

4. **Ürün Durumu**: "Kategoriye Ürün Ekle" dialog'unda, bu kategoride olan ürünler turuncu renkte gösterilir ve "Zaten Ekli" etiketi ile işaretlenir.

---

## 🔗 İlgili Dosyalar

### Model Dosyaları
- `lib/model/admin_product.dart`: AdminProduct ve ProductCategory modelleri

### Service Dosyaları
- `lib/services/admin_service.dart`: AdminService sınıfı ve tüm API metodları

### UI Dosyaları
- `lib/web_admin_category_management.dart`: Kategori yönetimi sayfası
- `lib/widgets/professional_image_uploader.dart`: Resim yükleme widget'ı

### Utility Dosyaları
- `lib/utils/responsive_helper.dart`: Responsive tasarım yardımcıları

---

## 📞 Destek

Herhangi bir sorun veya öneri için lütfen geliştirici ekibiyle iletişime geçin.

---

**Son Güncelleme**: 2024
**Versiyon**: 1.0.0

