# Faz Sonrası Team Lead Dev Denetimi

**Kural:** Her bir faz tamamlandıktan sonra, **Team Lead Dev** rolüyle o fazda yapılan işler **tüm yönleriyle** denetlenir. Denetim tamamlanmadan bir sonraki faza geçilmez.

**Referans:** `UYGULAMA_PLANI_BIRLESIK.md` → "Faz Sonrası Team Lead Dev Denetimi" bölümü.

---

## Denetim checklist (tüm fazlar için)

Her faz bittikten sonra aşağıdaki maddeler Team Lead Dev bakışıyla kontrol edilir. Tümü "Tamam" veya "N/A" olmalı.

### 1. Kod

| # | Madde | Tamam / Eksik / N/A |
|---|--------|---------------------|
| 1.1 | Proje derleniyor; ilgili script’lerde parse/derleme hatası yok | |
| 1.2 | Yeni/değişen script’lerde tip ve mantık hataları giderildi | |
| 1.3 | Gereksiz veya döngüsel bağımlılık eklenmedi | |
| 1.4 | Autoload / global erişim (GameData, AudioSystem vb.) doğru kullanılıyor | |

### 2. UI/UX

| # | Madde | Tamam / Eksik / N/A |
|---|--------|---------------------|
| 2.1 | Değişen/eklenen ekranlar için `docs/GORSEL_TASARIM_CHECKLIST.md` dolduruldu | |
| 2.2 | Renk, font, hizalama proje ile tutarlı | |
| 2.3 | Butonlar ve tıklanabilir alanlar doğru çalışıyor | |
| 2.4 | Farklı çözünürlüklerde (mobil/tablet) layout bozulmuyor | |

### 3. Test ve akış

| # | Madde | Tamam / Eksik / N/A |
|---|--------|---------------------|
| 3.1 | Menü → Lobi → Oyun (ve ilgili ekranlar) akışı sorunsuz | |
| 3.2 | İlgili fazda varsa birim/entegrasyon testleri çalışıyor | |
| 3.3 | `docs/MANUAL_TEST_CHECKLIST.md` ile ilgili satırlar kontrol edildi | |

### 4. Kayıt ve veri

| # | Madde | Tamam / Eksik / N/A |
|---|--------|---------------------|
| 4.1 | Save/load bozulmuyor; kayıt formatı değiştiyse geriye dönük uyum düşünüldü | |
| 4.2 | Yeni veri alanları (varsa) doğru saklanıyor ve yükleniyor | |

### 5. Performans ve stabilite

| # | Madde | Tamam / Eksik / N/A |
|---|--------|---------------------|
| 5.1 | Bu fazla eklenen özellikler belirgin FPS düşüşüne yol açmıyor | |
| 5.2 | Bellek sızıntısı veya açık resource leak yok (pool, stream vb.) | |

### 6. Dokümantasyon ve plan

| # | Madde | Tamam / Eksik / N/A |
|---|--------|---------------------|
| 6.1 | Değişen sistemler için mimari/API notu veya readme güncel | |
| 6.2 | Birleşik Planda ilgili faz maddeleri tamamlandı olarak işaretlendi (veya not düşüldü) | |

---

## Faz bazlı ek kontroller

Faza özel ek maddeler (gerektiğinde doldurulur).

| Faz | Ek kontrol |
|-----|------------|
| **Faz 0** | Lobi ve oyun sahnesi açılıyor; derleme hatası yok. |
| **Faz 1** | Ses menü/oyunda çalışıyor; ayarlar kalıcı; UI polish uygulandı. |
| **Faz 2** | Object pooling (mermi/düşman) varsa çalışıyor; içerik sayıları (düşman/silah) karşılandı. |
| **Faz 3** | Cloud save / analitik (varsa) çalışıyor; güvenlik kuralları kontrol edildi. |
| **Faz 4** | IAP (test ortamı) ve para birimi akışı tutarlı. |
| **Faz 5** | Liderlik tablosu, başarılar, günlük ödül görünür ve çalışır. |
| **Faz 6** | CI pipeline ve testler yeşil; loglama/hata takibi aktif. |
| **Faz 7** | Yeni modlar/içerik oyun tasarımı planı ile uyumlu. |

---

## Denetim kaydı

Her faz denetimi sonrası aşağıya kısa kayıt düşülür.

| Faz | Denetim tarihi | Sonuç | Not |
|-----|----------------|-------|-----|
| 0 | | | |
| 1 | | | |
| 2 | | | |
| ... | | | |

**Sonuç:** Tamam / Eksik var (açıklama not sütununda).

---

*Bu checklist, bir faz "tamamlandı" sayıldığında Team Lead Dev rolüyle tüm yönleriyle denetim yapılsın diye kullanılır.*
