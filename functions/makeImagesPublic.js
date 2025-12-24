/**
 * Mevcut tüm ürün resimlerini public yapmak için script
 * Kullanım: node makeImagesPublic.js
 */

const admin = require('firebase-admin');
const serviceAccount = require('./tuning-app-789ce-firebase-adminsdk-fbsvc-aa924058c5.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const bucket = admin.storage().bucket();

async function makeAllImagesPublic() {
  try {
    console.log('📸 Tüm ürün resimlerini public yapılıyor...');
    
    // product_images klasöründeki tüm dosyaları listele
    const [files] = await bucket.getFiles({
      prefix: 'product_images/',
    });
    
    console.log(`📊 Toplam ${files.length} dosya bulundu`);
    
    let successCount = 0;
    let errorCount = 0;
    
    for (const file of files) {
      try {
        // Dosyayı public yap
        await file.makePublic();
        
        // Metadata'yı güncelle
        await file.setMetadata({
          cacheControl: 'public, max-age=31536000',
          metadata: {
            ...file.metadata.metadata,
            public: 'true',
            madePublicAt: new Date().toISOString(),
          },
        });
        
        successCount++;
        console.log(`✅ ${successCount}/${files.length} - ${file.name} public yapıldı`);
      } catch (error) {
        errorCount++;
        console.error(`❌ Hata (${file.name}):`, error.message);
      }
    }
    
    console.log('\n📊 Özet:');
    console.log(`✅ Başarılı: ${successCount}`);
    console.log(`❌ Hatalı: ${errorCount}`);
    console.log(`📦 Toplam: ${files.length}`);
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Genel hata:', error);
    process.exit(1);
  }
}

makeAllImagesPublic();

