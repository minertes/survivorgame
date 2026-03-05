# Görsel Tasarım Checklist

Her yeni ekran veya belirgin UI değişikliğinde bu checklist doldurulur. Tüm maddeler **Evet** veya **N/A** olmalı.

---

## Genel (Tüm Ekranlar)

| # | Madde | Evet / Hayır / N/A |
|---|--------|---------------------|
| 1 | Metin okunaklı (font boyutu, kontrast) | |
| 2 | Renk paleti proje ile uyumlu (sapma varsa bilinçli) | |
| 3 | Butonlar ve tıklanabilir alanlar net görünüyor | |
| 4 | Hizalama tutarlı (sol/orta/sağ kararı net) | |
| 5 | Boşluklar (margin/padding) düzenli, birbirine yapışık eleman yok | |
| 6 | Farklı çözünürlükte (mobil/tablet) layout bozulmuyor | |

---

## Ekran Bazlı Checklist

Aşağıdaki tabloyu kopyalayıp **ekran adı** ile doldurun; her release/PR öncesi güncelleyin.

### Şablon (yeni ekran eklerken bu bloğu kopyalayın)

```markdown
### [Ekran adı: örn. Mağaza, Lobi, Ana Menü]

| # | Madde | Evet / Hayır / N/A |
|---|--------|---------------------|
| 1 | Başlık ve alt öğeler hiyerarşisi net | |
| 2 | Liste/kartlar düzgün hizalanıyor | |
| 3 | Scroll gerekirse kaydırma alanı doğru çalışıyor | |
| 4 | Ana aksiyon butonu belirgin | |
| 5 | Geri/çıkış butonu bulunuyor ve tutarlı yerde | |
| **Onay** | Tarih ve onaylayan | |
```

---

### Mağaza (Shop)

| # | Madde | Evet / Hayır / N/A |
|---|--------|---------------------|
| 1 | Başlık ve elmas satırı okunaklı ve hizalı | |
| 2 | Ürün satırları (panel/kart) düzgün hizalanıyor | |
| 3 | Scroll alanı doğru çalışıyor | |
| 4 | “Satın Al” butonu belirgin | |
| 5 | “Ana Menü” butonu bulunuyor ve tutarlı | |
| **Onay** | Tarih ve onaylayan | |

---

### Lobi

| # | Madde | Evet / Hayır / N/A |
|---|--------|---------------------|
| 1 | Karakter/silah/bayrak seçim alanları düzenli | |
| 2 | Seçili öğe net vurgulanıyor | |
| 3 | “Oyna” butonu belirgin | |
| 4 | Geri butonu tutarlı konumda | |
| **Onay** | Tarih ve onaylayan | |

---

### Ana Menü

| # | Madde | Evet / Hayır / N/A |
|---|--------|---------------------|
| 1 | Başlık ve butonlar (Oyna, Mağaza, Ayarlar vb.) hizalı | |
| 2 | Butonlar tıklanabilir boyutta ve aralıklı | |
| 3 | Splash/logo (varsa) düzgün konumda | |
| **Onay** | Tarih ve onaylayan | |

---

### Oyun İçi HUD

| # | Madde | Evet / Hayır / N/A |
|---|--------|---------------------|
| 1 | Can/XP barları ve etiketler okunaklı | |
| 2 | Dalga/skor bilgisi görünür | |
| 3 | Upgrade paneli (açıldığında) düzenli ve okunaklı | |
| **Onay** | Tarih ve onaylayan | |

---

### Game Over / Pause

| # | Madde | Evet / Hayır / N/A |
|---|--------|---------------------|
| 1 | Skor/dalga bilgisi net | |
| 2 | “Yeniden Oyna” / “Devam” / “Ana Menü” butonları belirgin | |
| 3 | Overlay ile oyun alanı net ayrılıyor | |
| **Onay** | Tarih ve onaylayan | |

---

*Yeni ekran eklendiğinde bu dosyaya aynı şablonla yeni bir “Ekran adı” bölümü ekleyin.*
