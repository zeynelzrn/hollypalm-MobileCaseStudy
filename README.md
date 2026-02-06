# Holly Palm – Shopify Ürün Detay

**Repository:** [https://github.com/zeynelzrn/hollypalm-MobileCaseStudy](https://github.com/zeynelzrn/hollypalm-MobileCaseStudy)

Flutter, Riverpod ve GraphQL ile Clean Architecture prensiplerine uygun, Shopify Storefront API tabanlı tek ürün detay sayfası. Döküman gereksinimleriyle uyumlu, modern animasyonlar ve tutarlı UX kararlarıyla tasarlanmıştır.

## Mimari yaklaşım ve dosya yapısı

- **lib/data** – GraphQL client, Shopify config, repository katmanı
- **lib/models** – Product, ProductVariant, Money, ProductImage vb. domain modelleri
- **lib/providers** – Riverpod Notifier’lar (ürün detay, sepet, Shopify)
- **lib/ui** – Ekranlar (product detail), yeniden kullanılabilir widget’lar (toast, shimmer, accordion)

## Kurulum

**Gereksinim:** [Flutter SDK](https://docs.flutter.dev/get-started/install) kurulu olmalıdır.

```bash
# Repoyu klonladıktan sonra proje klasörüne girin, ardından:
flutter pub get
```

## Çalıştırma

```bash
flutter run
```

(Emülatör veya fiziksel cihaz bağlı olmalıdır; `flutter devices` ile listelenir.)

## Yapılandırma

Shopify mağaza bilgileri `lib/providers/shopify_providers.dart` içindeki `shopifyConfigProvider` ile verilir:

- **storeDomain**: `your-store.myshopify.com`
- **storefrontAccessToken**: Storefront API access token (Shopify Admin → Settings → Apps → Develop apps)

Varsayılan ürün `productHandle: 'the-complete-snowboard'` ile açılır (case study test store’daki ürün); `lib/main.dart` veya route argümanı ile değiştirilebilir.

## Riverpod kullanım gerekçesi

- **Tek kaynak (single source of truth):** Sepet state’i `CartNotifier` ile uygulama genelinde tek bir kaynaktan yönetilir. Floating footer, ürün detay alanı (Sepete Ekle / miktar artırıcı) ve AppBar’daki sepet badge’i aynı `cartProvider`’ı dinler; hepsi senkron çalışır.
- **Optimistic UI ve rollback:** Riverpod state anında güncellenebildiği için “Sepete Ekle” tıklanınca UI hemen değişir, API arka planda çalışır; hata durumunda önceki state’e dönülür (rollback).
- **Varyant yönetimi:** Ürün detay ve seçilen varyant `ProductDetailNotifier` ile tutulur. Varyant değişimi doğrudan API tetiklemez; UI state üzerinden yeniden render edilir.

## Shopify API entegrasyon stratejisi

- **GraphQL, minimum veri:** Sorgular yalnızca ekranda kullanılan alanları ister (product: id, title, handle, vendor, descriptionHtml, featuredImage, images, priceRange, variants; variant: id, title, availableForSale, price, image, selectedOptions). Gereksiz alan fetch edilmez.
- **Repository katmanı:** Tüm Storefront API çağrıları `ProductRepository` ve `CartRepository` içinde toplanır; UI ve state katmanı API’yi doğrudan bilmez.
- **Hata ve loading:** Loading durumu `ProductDetailState.isLoading`, hata `ProductDetailState.error` ile state’te tutulur ve UI (skeleton, hata mesajı, tekrar dene butonu) buna göre render edilir.

## Ürün Sayfası – Zorunlu Alanlar

Sayfada dökümanda istenen alanlar net ve okunaklı şekilde yer alır:

- **Marka** – Shopify `vendor` alanı; varsa başlık üstünde, primary renkte etiket olarak gösterilir.
- **Ürün Adı** – Büyük ve kalın tipografi ile ana başlık.
- **Fiyat** – Seçilen varyanta göre güncellenen fiyat ve para birimi; vurgulu renk.
- **Kısa Açıklama** – `descriptionHtml` içeriğinden türetilen, HTML etiketleri temizlenmiş ilk ~160 karakter; en fazla 3 satır, ellipsis ile.

Tam açıklama **Ürün Açıklaması** başlığına tıklanarak açılan **ExpansionTile** akordiyonunda, **flutter_html** ile HTML olarak render edilir.

**Not:** Dökümanda hem “Kısa açıklama” hem “Ürün Açıklama Alanı” (akordiyon) zorunlu alan olarak geçtiği için ikisi de sayfada yer alır. Her iki alan da aynı Shopify alanından (`descriptionHtml`) beslenir: kısa açıklama özet (ilk ~160 karakter), akordiyon tam metin. Aynı içeriğin iki yerde görünmesi bu nedenle bilinçli bir tercihtir ve dökümana tam uyum içindir.

## UX ve Mimari Kararlar

### Sticky (Floating) Footer

Sepete ekleme aksiyonu, kaydırılabilir içeriğin dışında, ekranın en altında sabit kalır. **Scaffold.bottomNavigationBar** kullanılır; panel yüksekliği ~100px + safe area ile sınırlıdır. Gölge, üst köşelerde yuvarlatma ve **BackdropFilter** ile hafif şeffaf/blur arka plan kullanılır. Sayfa ne kadar kaydırılırsa kaydırılsın buton her zaman görünür ve erişilebilir kalır.

### Optimistic UI

Varyant seçimi (`selectVariantByIndex`) anında state’e yansır; fiyat ve görsel listesi ek API çağrısı olmadan güncellenir. Sepete ekleme ve miktar değişiklikleri önce yerel state’te uygulanır, API yanıtına göre gerekirse rollback yapılır; hata durumunda stepper **shake** animasyonu ile kullanıcıya geri bildirim verilir.

### Görsel Geri Bildirim ve Animasyonlar

- **Sepete Ekle ↔ Miktar artırıcı:** Geçiş **AnimatedSwitcher** ile yapılır; fade ve hafif scale (0.92 → 1) ile yumuşak geçiş, “pat” diye değişim yok.
- **Bildirimler (Overlay):** Özel toast bileşeni ekranın üstünden **SlideTransition** ve **FadeTransition** ile süzülerek gelir; süre sonunda aynı animasyonla geri çıkar.
- **Varyant çipler:** Seçilen çip **AnimatedScale** ve **AnimatedContainer** ile hafifçe büyür ve rengi yumuşak geçişle değişir.
- **Carousel:** Varyant değişiminde görsel listesi güncellenir ve **animateToPage(0)** ile ilk sayfaya akıcı kayma sağlanır.

## Teknik Kararlar ve Karşılaşılan Zorluklar

### Varyant görselleri ve veri kaynaklı kısıtlama

Shopify tarafında bazı ürünlerde tüm varyantlar aynı görsel URL’sini paylaşabilir veya varyant `image` alanı null gelebilir. Bu **veri kaynaklı** bir kısıtlamadır. Mimari buna hazırlıklıdır:

- Görsel listesi **displayImages** state’te tek kaynak olarak tutulur; **computeDisplayImages(product, selectedVariantIndex)** ile her seferinde yeni liste türetilir (`List.from` ile kopya). Riverpod **copyWith** ile state güncellenir ve rebuild tetiklenir.
- Varyantın kendine özgü görseli yoksa veya ana ürün görseli ile aynıysa, ürün görselleri sıralaması varyant index’ine göre yapılır; aynı kod farklı görsel verisi olan mağazalarda da çalışır.

### Test ve doğrulama (geliştirme aşamasında)

Veri kaynaklı kısıtlamayı ve UI mantığını doğrulamak için şu yöntemler kullanılabilir (kod tabanında artık aktif değil; gerektiğinde tekrar eklenebilir):

- **Data audit:** Ürün yüklendikten sonra tüm varyantların `image.url` değerleri konsola yazılır. Tüm URL’ler aynıysa “Veri Kaynaklı Kısıtlama” mesajı basılır.
- **Fallback test:** Varyant görseli null veya ana görselle aynıysa, `displayImages` listesinin ilk sırasına geçici bir placeholder URL (ör. picsum) konur. Varyant değiştirildiğinde bu placeholder’ın görünmesi, state ve carousel güncellemesinin doğru çalıştığını kanıtlar.
- **Key / Logic check:** Carousel’a `ValueKey(product.id)` verilir; varyant değişiminde `selectedVariantIndex` ve `displayImages` güncellenir, gerekirse seçim anında konsola yazılarak senkronizasyon doğrulanır.

## Teslim

- **GitHub repository:** [https://github.com/zeynelzrn/hollypalm-MobileCaseStudy](https://github.com/zeynelzrn/hollypalm-MobileCaseStudy)
- **README** ve **kurulum/çalıştırma adımları** bu dosyada yer almaktadır.
