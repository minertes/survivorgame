# 🎮 SURVIVOR GAME - GERÇEKÇİ OYUN TASARIM PLANI

## 🎯 **GERÇEKÇİ OYUN TASARIMI - 20K$/AY HEDEF**

### **TEMEL OYUN MEKANİKLERİ**
```yaml
# MVP (Minimum Viable Product) Özellikleri:
1. **Temel Gameplay:**
   - Tek karakter (başlangıçta)
   - 3 temel silah (ateşli, yakın dövüş, fırlatmalı)
   - 5 düşman türü (yavaş, hızlı, tank, range, boss)
   - Basit harita (tek arena, dalga sistemi)

2. **İlerleme Sistemi:**
   - XP & seviye atlama
   - 10 temel yükseltme
   - Dalga bazlı zorluk
   - Offline ilerleme

3. **Kontrol & UI:**
   - Virtual joystick hareket
   - Otomatik ateş (veya dokunma ile ateş)
   - Basit HUD (sağlık, XP, dalga, zaman)
   - Minimalist tasarım
```

### **KADEMELİ İÇERİK PLANI**
```yaml
# Ay 1-3: MVP Fazı
- 1 karakter (ücretsiz)
- 3 silah (başlangıçta açık)
- 5 düşman türü
- 10 yükseltme
- 1 harita (temel arena)
- 30 dalga maksimum

# Ay 4-6: Büyüme Fazı
- +2 karakter (1 ücretsiz, 1 premium)
- +3 silah (2 ücretsiz, 1 premium)
- +3 düşman türü
- +10 yükseltme
- +1 harita (farklı tema)
- 60 dalga maksimum

# Ay 7-9: Ölçek Fazı
- +3 karakter (2 ücretsiz, 1 premium)
- +4 silah (3 ücretsiz, 1 premium)
- +4 düşman türü
- +15 yükseltme
- +2 harita (farklı mekanikler)
- 100 dalga maksimum

# Ay 10-12: Kararlılık Fazı
- +4 karakter (3 ücretsiz, 1 premium)
- +5 silah (4 ücretsiz, 1 premium)
- +5 düşman türü
- +20 yükseltme
- +3 harita (özel mekanikler)
- Sonsuz dalga modu
```

---

## 🎨 **SANAT & GÖRSEL TASARIM**

### **MINIMALIST SANAT STİLİ**
```yaml
# Sanat Stili Seçimi:
1. **Pixel Art (Önerilen):**
   - Düşük maliyet
   - Hızlı üretim
   - Retro çekicilik
   - Asset store'da bol kaynak

2. **Vector/Flat Art:**
   - Modern görünüm
   - Ölçeklenebilir
   - Temiz görünüm
   - Performans dostu

3. **Low Poly 2D:**
   - 3D hissi, 2D performansı
   - Stilize görünüm
   - Orta maliyet

# Renk Paleti:
- Ana renkler: Koyu mavi, turuncu, beyaz
- Düşmanlar: Kırmızı tonları
- Yükseltmeler: Yeşil tonları
- UI: Koyu tema, yüksek kontrast
```

### **ASSET ÜRETİM STRATEJİSİ**
```yaml
# Başlangıç Stratejisi:
1. **Asset Store Kullanımı:**
   - Temel asset'leri satın al: $100-300
   - Ücretsiz asset'ler kullan
   - Custom asset'ler için part-time sanatçı

2. **Part-time Sanatçı:**
   - Saatlik: $15-25/saat
   - Proje bazlı: $500-2,000/proje
   - Remote çalışma
   - 2D pixel art uzmanı

3. **Kendi Üretimi:**
   - Basit asset'leri kendin yap
   - Aseprite veya Photoshop öğren
   - Zamanla geliş
```

### **ANİMASYON & EFECTLER**
```yaml
# Temel Animasyonlar:
- Karakter hareketi (4 yön)
- Silah ateşleme
- Düşman ölümü
- Yükseltme toplama
- UI animasyonları

# Efektler:
- Hit efekti (kırmızı flash)
- Kritik vuruş (sarı flash)
- Level up efekti
- Dalga geçiş efekti

# Performans Optimizasyonu:
- Sprite sheet kullanımı
- Particle sayısını sınırla
- Animasyon pooling
- Gereksiz efektleri kaldır
```

---

## 🔊 **SES & MÜZİK TASARIMI**

### **MINIMAL SES TASARIMI**
```yaml
# Temel Ses Efektleri:
1. **Gameplay Sesleri:**
   - Silah ateşleme (3 farklı)
   - Düşman ölümü (5 farklı)
   - Yükseltme toplama
   - Hasar alma
   - Level up

2. **UI Sesleri:**
   - Buton tıklama
   - Menü geçişi
   - Satın alma
   - Hata sesi

3. **Ambient Sesler:**
   - Arka plan müziği (loop)
   - Dalga geçiş sesi
   - Boss geliş sesi

# Üretim Stratejisi:
- Asset store'dan satın al: $50-100
- Ücretsiz sound pack'ler kullan
- Basit sesleri kendin yap (BFXR gibi araçlarla)
- Part-time ses tasarımcı: $200-500/proje
```

### **MÜZİK STRATEJİSİ**
```yaml
# Müzik Gereksinimleri:
1. **Ana Menü Müziği:**
   - 1-2 dakika loop
   - Motivasyonel, epik
   - Düşük tempolu

2. **Gameplay Müziği:**
   - 3-5 dakika loop
   - Aksiyon odaklı
   - Dalgalara göre intensity artışı

3. **Boss Müziği:**
   - 2-3 dakika loop
   - Yüksek intensity
   - Özel tema

# Kaynaklar:
- Ücretsiz müzik kütüphaneleri
- Royalty-free müzik satın al: $20-50/track
- Müzisyen ile anlaşma: $100-300/track
```

---

## 🎯 **OYUNCU DENEYİMİ (UX)**

### **ONBOARDING & ÖĞRENME**
```yaml
# İlk 5 Dakika Deneyimi:
1. **İlk Açılış (0-30 saniye):**
   - Basit logo gösterimi
   - Hızlı yükleme
   - Ana menüye direkt geçiş

2. **İlk Oyun (30 saniye - 2 dakika):**
   - 3 adımlı tutorial
   - 1. Adım: Hareket (virtual joystick)
   - 2. Adım: Ateş etme (otomatik/dokunma)
   - 3. Adım: Yükseltme toplama
   - İlk dalga kolay (5 düşman)

3. **İlk Başarı (2-5 dakika):**
   - İlk dalgayı geçince ödül
   - Level up animasyonu
   - Yeni yükseltme seçimi
   - Devam etme motivasyonu
```

### **KULLANICI ARAYÜZÜ (UI)**
```yaml
# Ana UI Bileşenleri:
1. **Gameplay HUD:**
   - Sağlık barı (sol üst)
   - XP barı (üst orta)
   - Dalga bilgisi (sağ üst)
   - Zaman/skor (sağ üst)
   - Yükseltme seçimi (alt orta)

2. **Menü Sistemleri:**
   - Ana menü (play, shop, settings, exit)
   - Shop (karakterler, silahlar, yükseltmeler)
   - Settings (ses, kontrol, dil)
   - Pause menüsü (devam, restart, exit)

3. **Ödül Ekranları:**
   - Level up ekranı
   - Dalga tamamlama ekranı
   - Günlük ödül ekranı
   - Başarı ekranı

# UI Tasarım Prensipleri:
- Minimalist (az çoktur)
- Yüksek kontrast (okunabilirlik)
- Büyük butonlar (mobil uyumlu)
- Hızlı erişim (2 tıklama kuralı)
```

### **ERİŞİLEBİLİRLİK**
```yaml
# Erişilebilirlik Özellikleri:
1. **Görsel Erişilebilirlik:**
   - Renk körü modu (opsiyonel)
   - Yüksek kontrast modu
   - Büyük yazı boyutu seçeneği
   - UI ölçeklendirme

2. **İşitsel Erişilebilirlik:**
   - Ses efektleri kapatma
   - Müzik kapatma
   - Titreşim kapatma
   - Görsel uyarılar (ses yerine)

3. **Motor Erişilebilirlik:**
   - Otomatik ateş (manuel gerekmez)
   - Basit kontroller
   - Tek elle oynanabilir
   - Uzun tıklama desteği
```

---

## 📊 **DENGELİLİK & İLERLEME**

### **ZORLUK EĞRİSİ**
```yaml
# Dalga Bazlı Zorluk:
Dalga 1-10 (Öğrenme Fazı):
  - Düşman sayısı: 5-20
  - Düşman sağlığı: 10-30
  - Düşman hasarı: 5-10
  - Yükseltme sıklığı: Her 2 dalgada 1

Dalga 11-30 (Ustalık Fazı):
  - Düşman sayısı: 25-50
  - Düşman sağlığı: 40-80
  - Düşman hasarı: 15-25
  - Yükseltme sıklığı: Her 3 dalgada 1

Dalga 31-60 (Zorluk Fazı):
  - Düşman sayısı: 55-100
  - Düşman sağlığı: 90-150
  - Düşman hasarı: 30-45
  - Yükseltme sıklığı: Her 4 dalgada 1

Dalga 61+ (Sonsuz Zorluk):
  - Düşman sayısı: 100+ (artmaya devam)
  - Düşman sağlığı: 150+ (%10 artış/dalga)
  - Düşman hasarı: 50+ (%5 artış/dalga)
  - Yükseltme sıklığı: Her 5 dalgada 1
```

### **İLERLEME SİSTEMİ**
```yaml
# XP & Level Sistemi:
Level 1-10 (Erken Oyun):
  - XP gereksinimi: 100-1,000
  - Ödüller: Temel yükseltmeler
  - Hedef: 30 dakika oyun süresi

Level 11-30 (Orta Oyun):
  - XP gereksinimi: 1,100-10,000
  - Ödüller: Gelişmiş yükseltmeler
  - Hedef: 5 saat oyun süresi

Level 31-50 (Geç Oyun):
  - XP gereksinimi: 11,000-50,000
  - Ödüller: Efsanevi yükseltmeler
  - Hedef: 20 saat oyun süresi

Level 51+ (Sonsuz Oyun):
  - XP gereksinimi: 60,000+ (artmaya devam)
  - Ödüller: Prestij ödülleri
  - Hedef: 50+ saat oyun süresi

# Yükseltme Sistemi:
Temel Yükseltmeler (10 adet):
  - Hasar artışı (%10-50)
  - Atış hızı artışı (%10-50)
  - Hareket hızı artışı (%10-30)
  - Sağlık artışı (%20-100)
  - Kritik şansı artışı (%5-25)

Gelişmiş Yükseltmeler (10 adet):
  - Alan hasarı
  - Zincirleme vuruş
  - Donma/yavaşlatma
  - Zehir hasarı
  - Yağma şansı

Efsanevi Yükseltmeler (5 adet):
  - Tüm istatistik artışı
  - Özel yetenekler
  - Transformasyon
  - Sonsuz mermi
  - God mod (geçici)
```

---

## 🎪 **OYUN MODLARI**

### **TEMEL MODLAR**
```yaml
# MVP Modları (Başlangıç):
1. **Survival Mode (Ana Mod):**
   - Dalga bazlı hayatta kalma
   - Sonsuz zorluk
   - Skor tablosu
   - Günlük ödüller

2. **Daily Challenge (Günlük):**
   - Günlük değişen kurallar
   - Özel ödüller
   - Global sıralama
   - 24 saat süre

# Ek Modlar (Sonradan Eklenecek):
3. **Time Attack (Zamanlı):**
   - Belirli sürede maksimum dalga
   - Hız odaklı
   - Özel ödüller

4. **Boss Rush (Boss Modu):**
   - Sadece boss düşmanlar
   - Zorlu mücadele
   - Efsanevi ödüller

5. **Endless Mode (Sonsuz):**
   - Sonsuz dalgalar
   - Sürekli artan zorluk
   - Prestij sistemi
```

### **ETKİNLİK SİSTEMİ**
```yaml
# Haftalık Etkinlikler:
1. **Weekend Warrior (Hafta Sonu):**
   - Cuma-Pazar arası
   - 2x XP bonusu
   - Özel ödüller
   - Artan yükseltme şansı

2. **Holiday Events (Tatil):**
   - Özel temalar (Noel, Cadılar Bayramı)
   - Limited-time içerik
   - Özel ödüller
   - 1-2 hafta süre

3. **Community Events (Topluluk):**
   - Topluluk hedefleri
   - Ortak ödüller
   - Özel içerik kilidi
   - 1 hafta süre

# Etkinlik Ödülleri:
- Özel karakter skin'leri
- Özel silah skin'leri
- Premium currency
- Exclusive yükseltmeler
- Bragging rights (başarı rozetleri)
```

---

## 🔧 **TEKNİK GEREKSİNİMLER**

### **PERFORMANS HEDEFLERİ**
```yaml
# FPS & Performans:
- Hedef FPS: 60 FPS (stable)
- Minimum FPS: 30 FPS (low-end cihazlarda)
- Yükleme Süresi: <5 saniye
- Bellek Kullanımı: <200MB

# Cihaz Uyumluluğu:
- Minimum Android: 5.0 (API 21)
- Minimum iOS: 11.0
- Ekran Çözünürlüğü: 720p-4K destek
- Aspect Ratio: 16:9, 18:9, 19.5:9, 20:9

# Network Gereksinimleri:
- Online Özellikler: Cloud save, analytics
- Offline Oynanabilirlik: Tam destek
- Veri Kullanımı: <10MB/saat
- Sync Frequency: Her 5 dakika
```

### **TEST & KALİTE GÜVENCESİ**
```yaml
# Test Stratejisi:
1. **Alpha Testing (İç Test):**
   - Geliştirici testi
   - Temel fonksiyon testi
   - Performans testi
   - 1-2 hafta süre

2. **Beta Testing (Kapalı Beta):**
   - 50-100 testçi
   - Gerçek kullanıcı feedback
   - Bug tespiti
   - 2-4 hafta süre

3. **Soft Launch (Yumuşak Lansman):**
   - 1-2 ülkede lansman
   - Gerçek monetizasyon testi
   - Kullanıcı retention testi
   - 1-2 ay süre

4. **Global Launch (Global Lansman):**
   - Tüm ülkelerde lansman
   - Tam özellik seti
   - Marketing push
   - Sürekli
```

---

## 📈 **VERİ & ANALİTİK**

### **TEMEL ANALİTİK METRİKLERİ**
```yaml
# Kullanıcı Davranışı:
- Session Length (Oturum Süresi)
- Sessions per Day (Günlük Oturum)
- Retention (D1, D7, D30)
- Level Progression (Seviye İlerlemesi)
- Wave Progression (Dalga İlerlemesi)

# Monetizasyon:
- Conversion Rate (Ödeme Oranı)
- ARPU (Ortalama Kullanıcı Geliri)
- ARPDAU (Günlük Aktif Kullanıcı Başı Gelir)
- LTV (Kullanıcı Ömür Boyu Değeri)
- Popular Items (Popüler Ürünler)

# Teknik:
- Crash Rate (Çökme Oranı)
- Load Times (Yükleme Süreleri)
- FPS Distribution (FPS Dağılımı)
- Device Distribution (Cihaz Dağılımı)
- OS Distribution (İşletim Sistemi Dağılımı)
```

### **A/B TESTING STRATEJİSİ**
```yaml
# Test Edilecek Alanlar:
1. **Monetizasyon:**
   - Fiyat noktaları ($0.99 vs $1.99)
   - Bundle değerleri
   - Battle pass fiyatı
   - Currency paketleri

2. **Gameplay:**
   - Zorluk eğrisi
   - Yükseltme değerleri
   - Ödül sıklığı
   - Tutorial uzunluğu

3. **UI/UX:**
   - Buton yerleşimi
   - Shop layout
   - Ödül ekranları
   - Renk şemaları

# Test Süreci:
- Her test: 1-2 hafta
- Sample size: 1,000+ kullanıcı
- Statistical significance: 95%+
- Implement winning variant
```

---

## 🎯 **KRİTİK BAŞARI FAKTÖRLERİ**

### **OYUN TASARIMI KRİTERLERİ**
```yaml
# Must-Have Özellikler:
1. **Addictive Gameplay:**
   - "One more try" hissi
   - Anlamlı ilerleme
   - Ödül döngüsü
   - Skill expression

2. **Fair Monetization:**
   - Pay-to-win yok
   - Değer hissi
   - Görünür ilerleme
   - Adil fiyatlandırma

3. **Performance:**
   - Düşük uçlu cihaz desteği
   - Hızlı yükleme
   - Düşük batarya tüketimi
   - Az veri kullanımı

4. **Polish:**
   - Responsive kontroller
   - Temiz UI
   - Tutarlı sanat stili
   - Minimal bug'lar
```

### **KULLANICI GERİ BİLDİRİMİ**
```yaml
# Feedback Toplama Kanalları:
1. **In-game Feedback:**
   - Rating prompt (4. yıldız+ ise)
   - Bug report butonu
   - Suggestion form
   - Survey pop-up'ları

2. **Community Channels:**
   - Discord server
   - Reddit community
   - Social media (Twitter, Instagram)
   - App store reviews

3. **Direct Communication:**
   - Support email
   - Developer blog
   - Update notes
   - Roadmap sharing

# Feedback İşleme:
- Weekly review (haftalık inceleme)
- Priority sorting (öncelik sıralama)
- Quick fixes (hızlı düzeltmeler)
- Feature requests (özellik istekleri)
```

---

**PLAN SAHİBİ:** Game Designer  
**TASARIM FELSEFESİ:** Simple but deep, fair but profitable  
**BAŞARI TANIMI:** 4.0+ rating, 30%+ D1 retention, 5%+ conversion  
**SONRAKİ ÇEYREK ODAK:** MVP gameplay polish, basic progression system