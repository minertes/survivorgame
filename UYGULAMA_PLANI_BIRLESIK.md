# Survivor Game – Birleşik Uygulama Planı

**Amaç:** Tüm planlardaki geliştirme maddelerini tek bir sıralı uygulama planında toplamak. Personel/maaş/pazarlama bütçesi bu dokümanda yok; sadece teknik ve ürün geliştirme adımları var.

**Kaynak planlar:** REALISTIC_20K_PLAN (DeepSeek), production_ready_plan.md, ENTERPRISE_HAZIRLIK_PLANI.md, ENTERPRISE_BACKEND_PLANI.md, **OYUN_TASARIMI_GELIR_MODELI_PLANI.md**, survivor_game_tracker.md. Referans planlar kökü sade tutmak için `archive/` altında (örn. archive/REALISTIC_20K_PLAN/, archive/ENTERPRISE_*.md, archive/production_ready_plan.md). Ana plan kuralları: `docs/PLANLAR_VE_KURALLAR.md` ve `.cursor/rules/ana-plan.mdc`.

**Birlikte geliştirilen plan:** Oyun tasarımı, gelir modeli, karakter/silah/düşman tasarımı ve içerik roadmap’i **OYUN_TASARIMI_GELIR_MODELI_PLANI.md** içinde tanımlıdır; uygulama adımları bu Birleşik Plan’da Faz 0–7 ile eşleştirilir. İki plan birlikte güncellenir (bakınız: [Oyun Tasarımı Planı ile Eşleşme](#oyun-tasarımı--gelir-planı-ile-eşleşme)).

**Mevcut durum (tracker):** FAZ 0–7 tamamlandı (MVP + post-MVP içerik ve modlar).

**Teknoloji:** Godot 4.x (proje 4.6), GDScript. Backend başlangıç: Firebase veya Supabase (minimal maliyet); mikroservisler sonraki aşamaya bırakıldı.

---

## Faz 0: Stabilizasyon (Oyunu Ayağa Kaldırma)

**✅ UYGULANDI (ilk uygulama turu)** – Derleme düzeltmeleri, lobi veri akışı, Log entegrasyonu.

Bu maddeler bitmeden diğer fazlara geçilmemeli.

| # | Madde | Açıklama | Kaynak |
|---|--------|----------|--------|
| 0.1 | Derleme hatalarını gider | AudioBusManager, LobbyMoleculeBase ve tüm script derleme hatalarını kaldır | ENTERPRISE_HAZIRLIK |
| 0.2 | Lobi ekranını çalıştır | Karakter/silah seçimi ekranı açılsın, veri doğru bağlansın | ENTERPRISE_HAZIRLIK |
| 0.3 | Oyun başlatma akışını düzelt | Menü → Lobi → Oyun sahnesi geçişleri doğru çalışsın, yıldızlı ekrana atlama olmasın | ENTERPRISE_HAZIRLIK |
| 0.4 | Döngüsel bağımlılıkları çöz | Bağımlılık grafiğini çıkar, circular dependency’leri kaldır | ENTERPRISE_HAZIRLIK |
| 0.5 | Temel logging ekle | Debug için seviyeli (DEBUG/INFO/WARN/ERROR) log; mümkünse dosyaya yazım (user://logs) | ENTERPRISE_HAZIRLIK |

**Tamamlanma kriteri:** Oyun sorunsuz açılıyor, lobi ve oyun sahnesi akışı çalışıyor, derleme hatası yok.

---

## Faz 1: MVP Tamamlama (Polish & Eksik Sistemler)

**✅ UYGULANDI** – Müzik menü/oyun, splash, dalga bantları ve boss dalgası eklendi; ses kalıcılığı mevcut (user://audio_settings.cfg).

### 1.1 Audio Sistemi (%85 → %100)

| # | Madde | Açıklama | Kaynak |
|---|--------|----------|--------|
| 1.1.1 | Gerçek ses dosyalarını entegre et | SFX (ateş, hasar, ölüm, level up, pickup) ve UI (tıklama, hover) için gerçek/placeholder’dan kalıcı sesler | production_ready, 20K |
| 1.1.2 | Arka plan müziği | Menü ve gameplay için en az birer loop; ses seviyesi ayarlarına bağlı | 20K Game Design |
| 1.1.3 | Ses ayarları kalıcılığı | Master/Music/SFX/UI volume SaveSystem veya Config ile saklansın | production_ready |
| 1.1.4 | Opsiyonel: Uzamsal (spatial) ses | Özellikle 3D/2D positional efektler için; MVP’de basit tutulabilir | production_ready |

### 1.2 UI/UX Polish (%95 → %100)

| # | Madde | Açıklama | Kaynak |
|---|--------|----------|--------|
| 1.2.1 | Ayarlar ekranını tamamla | Ses, grafik (kalite/çözünürlük), kontroller (tuş/joystick) tek ekranda | production_ready, 20K |
| 1.2.2 | Pause menüsünü iyileştir | Devam, yeniden başlat, ayarlar, ana menü; mobil uyumlu butonlar | 20K Technical Implementation |
| 1.2.3 | Game Over ekranı | Skor, dalga, süre; yeniden dene / ana menü | 20K |
| 1.2.4 | Yükleme / splash ekranı | Açılışta kısa yükleme veya logo; gerekiyorsa progress | production_ready |
| 1.2.5 | Tutorial / yardım | İlk açılışta 3–5 adımlık kısa öğretici (hareket, ateş, upgrade toplama) | 20K Game Design |

### 1.3 Oyun Dengesi ve İlerleme (%80 → %100)

| # | Madde | Açıklama | Kaynak |
|---|--------|----------|--------|
| 1.3.1 | Düşman ölçeklendirme | Dalga bazlı can/hasar/ sayı artışı; 1–10, 11–30, 31+ dalga bandları | 20K Game Design |
| 1.3.2 | Silah dengesi | Hasar, atış hızı, menzil; en az 3 silah dengeli olsun. Mevcut silah sayısı fazlaysa korunur. | production_ready |
| 1.3.3 | Zorluk eğrisi | İlk 5 dakikada öğrenme, sonra kademeli zorlaşma; boss dalgaları tanımlı olsun | 20K |
| 1.3.4 | Ödül sistemi | XP, health pickup, upgrade seçimi; dalga tamamlama ödülleri net olsun | 20K |

**Faz 1 tamamlanma kriteri:** Ses %100 kullanılır, tüm temel ekranlar ve ayarlar çalışır, denge oynanabilir ve tutarlı.

---

## Faz 2: Performans ve İçerik

**UYGULANDI** – F9 FPS/bellek, mermi havuzu, 5 düşman türü, 3+ silah (mevcut korundu), 10 upgrade, dalga/skor ve yerel en iyi dalga.

### 2.1 Performans

| # | Madde | Açıklama | Kaynak |
|---|--------|----------|--------|
| 2.1.1 | Bellek ve FPS profilini al | Godot profiler ile heap, FPS; düşük uç cihaz hedefi (örn. 30 FPS min) | 20K Technical Development |
| 2.1.2 | Nesne havuzlama (object pooling) | Mermi, düşman, efekt gibi sık spawn/despawn edilen nesneler için pool | 20K Technical Implementation, production_ready |
| 2.1.3 | Asset optimizasyonu | Texture/atlas, ses sıkıştırma; gereksiz yükleme kaldırma | 20K Backend/Performance |
| 2.1.4 | Yükleme süresi | Hedef ilk yükleme <5 sn; gerekirse async yükleme/placeholder | 20K |

### 2.2 İçerik (MVP Kapsamında)

| # | Madde | Açıklama | Kaynak |
|---|--------|----------|--------|
| 2.2.1 | En az 5 düşman türü | Örn: basic, fast, tank, ranged, boss; farklı davranış ve istatistik | 20K Game Design |
| 2.2.2 | En az 3 silah | Farklı atış pattern’i (tek atım, tarama, alan hasarı vb.). Mevcut projede daha fazla silah varsa olduğu gibi bırakılır; özellik downgrade edilmez. | 20K |
| 2.2.3 | En az 10 upgrade | Hasar, atış hızı, hareket, can, kritik vb.; seviye/stack sınırı net | 20K |
| 2.2.4 | Dalga/skor sistemi | Dalga numarası, skor, wave complete ekranı; mümkünse yerel high score | 20K |

**Faz 2 tamamlanma kriteri:** Hedef cihazlarda 30–60 FPS, yükleme süresi kabul edilebilir, MVP içerik sayıları karşılanmış.

---

## Faz 3: Kayıt, Analitik ve Backend (Minimal)

**UYGULANDI** – GameData save/load + checksum + yedek; BackendService (cihaz ID, bulut kayıt push/pull); AnalyticsService (session, wave, level_up, death); CrashReporter (user://logs/crash_*.txt).

Personel/maaş dışı; sadece teknik altyapı.

### 3.1 Yerel Kayıt ve Ayarlar

| # | Madde | Açıklama | Kaynak |
|---|--------|----------|--------|
| 3.1.1 | SaveSystem ile ilerleme kaydı | Level, XP, açılan karakter/silah, ayarlar; user:// veya OS-specific path | 20K Technical Implementation |
| 3.1.2 | Çakışma ve bütünlük | Kayıt bozulmasına karşı basit checksum veya yedek dosya | 20K Backend |

### 3.2 Backend Başlangıç (Firebase veya Supabase)

| # | Madde | Açıklama | Kaynak |
|---|--------|----------|--------|
| 3.2.1 | Backend seçimi ve proje | Firebase **veya** Supabase projesi; Godot 4.x için uyumlu SDK/plugin | 20K Backend Architecture |
| 3.2.2 | Anonim kimlik doğrulama | E-posta zorunlu olmadan oyun içi kimlik; cihaz bazlı ID ile başlanabilir | 20K Backend |
| 3.2.3 | Cloud save (bulut kayıt) | İlerleme verisini Firestore/Supabase’e yazma/okuma; “son yazma kazanır” veya basit merge | 20K Backend, ENTERPRISE_BACKEND (basit model) |
| 3.2.4 | Güvenlik kuralları | Kullanıcı sadece kendi verisini okusun/yazsın; admin için ayrı kural (ileride) | 20K Backend |

### 3.3 Analitik (Sadece Geliştirme Odaklı)

| # | Madde | Açıklama | Kaynak |
|---|--------|----------|--------|
| 3.3.1 | Temel event’ler | session_start/end, wave_completed, level_up, death; platform ve versiyon bilgisi | 20K Backend Analytics |
| 3.3.2 | Firebase Analytics veya eşdeğer | Ücretsiz kotayla başla; event’leri client’tan gönder | 20K |
| 3.3.3 | Çökme raporlama | Firebase Crashlytics veya benzeri; production’da crash log’ları toplama | ENTERPRISE_HAZIRLIK |

**Faz 3 tamamlanma kriteri:** Yerel kayıt güvenilir; isteğe bağlı bulut kayıt ve temel analitik/crash raporu çalışıyor.

---

## Faz 4: Mağaza ve Monetizasyon Altyapısı

**UYGULANDI** – IAPService (ürün konfig, test satın alma); AdService (consent, rewarded/interstitial stub); gems + gem_spend_log (yerel + bulut); shop sahnesi.

Sadece teknik entegrasyon; fiyat/kampanya kararları bu listede yok.

| # | Madde | Açıklama | Kaynak |
|---|--------|----------|--------|
| 4.1 | IAP eklentisi | Godot IAP veya resmi/güvenilir store plugin; Google Play + Apple App Store | 20K Technical Development |
| 4.2 | Ürün konfigürasyonu | En az bir test ürünü (örn. “gems paketi”); store’da tanımlı | 20K |
| 4.3 | Satın alma akışı | Başlat → doğrula → ödül; receipt validation (server-side tercih edilir) | 20K Backend, ENTERPRISE_BACKEND |
| 4.4 | Reklam entegrasyonu (opsiyonel) | Ödüllü video ve/veya interstitial; sıklık sınırı ve kullanıcı onayı (GDPR/CCPA) | 20K Monetization |
| 4.5 | Premium para birimi (in-game) | Gems/coins tutarı client + cloud’da tutulsun; harcama kaydı | 20K |

**Faz 4 tamamlanma kriteri:** Test ortamında IAP ve isteğe bağlı reklam çalışıyor; para birimi tutarlı saklanıyor.

---

## Faz 5: Sosyal ve Canlı Ops

**✅ UYGULANDI** – Liderlik tablosu (günlük/haftalık), başarılar (rozetler + bildirim), günlük ödül (streak + claim), skor paylaşımı (panoya).

| # | Madde | Açıklama | Kaynak |
|---|--------|----------|--------|
| 5.1 | Liderlik tablosu | Günlük/haftalık skor; Firebase/Supabase’te güvenli yazım (sadece kendi skoru) | 20K Backend |
| 5.2 | Başarılar (achievements) | Tanımlı rozetler; ilerleme takibi ve bildirim | 20K Technical Development |
| 5.3 | Günlük ödüller | Giriş serisi (streak), takvim ödülü; claim mantığı ve saklama | 20K |
| 5.4 | Basit sosyal | Paylaşım (skor/ekran); isteğe bağlı arkadaş listesi (backend’de minimal model) | 20K |

**Faz 5 tamamlanma kriteri:** Liderlik tablosu ve başarılar oyunda görünür ve çalışır; günlük ödül verilir.

---

## Faz 6: Kalite, Test ve Operasyon

**✅ UYGULANDI** – Birim/entegrasyon testleri (ci/test_runner, ci/integration_test), GitHub Actions CI (test + export), ortam config (EnvConfig, default_env.cfg), loglama/CrashReporter, ARCHITECTURE.md.

Personel sayısı/maaş yok; sadece süreç ve araçlar.

### 6.1 Test

| # | Madde | Açıklama | Kaynak |
|---|--------|----------|--------|
| 6.1.1 | Birim test altyapısı | GUT veya Godot Unit Test; CI’da çalışacak şekilde | ENTERPRISE_HAZIRLIK |
| 6.1.2 | Kritik modüller için testler | SaveSystem, WaveManager, UpgradeSystem, basit combat | 20K Technical Development |
| 6.1.3 | Entegrasyon testleri | Menü → Lobi → Oyun → Kayıt/Yükleme akışı | ENTERPRISE_HAZIRLIK |
| 6.1.4 | Manuel test senaryoları | Checklist: tüm ekranlar, ses, kayıt, IAP (sandbox) | production_ready |

### 6.2 CI/CD ve Dağıtım

| # | Madde | Açıklama | Kaynak |
|---|--------|----------|--------|
| 6.2.1 | CI pipeline | GitHub Actions (veya GitLab CI); test + lint; Godot export’u (headless mümkünse) | ENTERPRISE_HAZIRLIK, 20K |
| 6.2.2 | Build betimlemesi | Debug/Release, Android AAB + iOS archive; versiyonlama (version string) | 20K Technical Implementation |
| 6.2.3 | Ortam ayrımı | Dev/Staging/Prod için config (API URL, analytics açık/kapalı) | ENTERPRISE_HAZIRLIK |

### 6.3 İzleme ve Dokümantasyon

| # | Madde | Açıklama | Kaynak |
|---|--------|----------|--------|
| 6.3.1 | Yapılandırılmış loglama | Seviye, dosyaya yazma, production’da ERROR’ların toplanması (mevcut logging’i genişlet) | ENTERPRISE_HAZIRLIK |
| 6.3.2 | Hata takibi | Crashlytics veya eşdeğer; kritik hatalar için uyarı | ENTERPRISE_HAZIRLIK |
| 6.3.3 | Mimari/API notları | Ana sistemler ve EventBus kullanımı; deployment ve “nasıl çalıştırılır” | ENTERPRISE_HAZIRLIK |

**Faz 6 tamamlanma kriteri:** CI’da testler koşuyor, tekrarlanabilir build alınabiliyor, hata/crash izlenebiliyor.

---

## Denetim ve Onay Süreçleri (Uygulandı)

UI/UX ve görsel değişikliklerin kalite kontrolü için aşağıdaki süreç **her yeni ekran, mağaza, lobi veya öne çıkan UI güncellemesinde** uygulanır.

### Rol ve Sorumluluklar

| Rol | Sorumluluk |
|-----|------------|
| **Görsel Tasarım Denetimi** | Renk, font, hizalama, boşluk, responsive; “görsel rezalet” önleme. |
| **Frontend Lead (veya atanacak kişi)** | UI/UX ve frontend değişikliklerinin merge veya release öncesi onayı. |

### Denetleme Sırası

1. **Görsel tasarım checklist** doldurulur → `docs/GORSEL_TASARIM_CHECKLIST.md`
2. **Frontend lead onayı** alınır (PR/issue üzerinde veya dokümanda işaretlenir)
3. Teknik merge / release yapılır

### Nerede Tanımlı

- **Süreç detayı:** `docs/DENETIM_ONAY_SURECI.md`
- **Ekran/ekran bazlı checklist:** `docs/GORSEL_TASARIM_CHECKLIST.md`

Bu maddeler Faz 6 ile birlikte uygulanır; yeni UI çıktısı olan her iş paketinde denetim adımları takip edilir.

---

## Faz Sonrası Team Lead Dev Denetimi (Uygulandı)

**Kural:** Her bir faz tamamlandıktan sonra, **Team Lead Dev** rolüyle o fazda yapılan işler **tüm yönleriyle** denetlenir. Denetim tamamlanmadan bir sonraki faza geçilmez.

### Denetim kapsamı (tüm yönler)

| Yön | Kontrol |
|-----|--------|
| **Kod** | Derleme hatası yok, tip/script hataları giderildi, gereksiz bağımlılık yok |
| **UI/UX** | Görsel checklist (ilgili ekranlar), tutarlılık, responsive |
| **Test** | İlgili testler var/çalışıyor; manuel akış (menü→lobi→oyun) sorunsuz |
| **Kayıt/veri** | Save/load bozulmuyor; yeni alanlar varsa geriye dönük uyum |
| **Performans** | Belirgin FPS düşüşü veya sızıntı yok |
| **Dokümantasyon** | Değişen sistemler için not/readme güncel; plan maddeleri işlendi olarak işaretlendi |

### Akış

1. Faz tamamlanma kriteri sağlandı → 2. **Faz Sonrası Denetim** çalıştır (`docs/FAZ_SONRASI_DENETIM.md`) → 3. Tüm maddeler geçtiyse bir sonraki faza geç.

**Detaylı checklist:** `docs/FAZ_SONRASI_DENETIM.md`

---

## Faz 7: İçerik Genişletme ve Oyun Modları (Post-MVP)

**✅ UYGULANDI** – Günlük meydan okuma (tohum + ödül), Sonsuz mod + Prestij, Boss Rush, 4 karakter + 5 silah, 4 tema (Mezarlık/Orman/Çöl/Cehennem).

MVP yayında veya soft launch sonrası.

| # | Madde | Açıklama | Kaynak |
|---|--------|----------|--------|
| 7.1 | Günlük meydan okuma | Günlük değişen kurallar/tohum; özel ödüller | 20K Game Design |
| 7.2 | Sonsuz/sonsuz dalga modu | Prestij veya benzeri meta ilerleme | 20K |
| 7.3 | Boss Rush modu | Sadece boss dalgaları | 20K |
| 7.4 | Ek karakterler ve silahlar | Kademeli açılacak içerik; balance ile birlikte | 20K Game Design |
| 7.5 | Yeni haritalar/temalar | Farklı arena veya görsel tema | 20K |

---

## Oyun Tasarımı & Gelir Planı ile Eşleşme

**OYUN_TASARIMI_GELIR_MODELI_PLANI.md** ile bu Birleşik Plan birlikte geliştirilir. Aşağıdaki eşleşme uygulama sırasında referans alınır.

| Birleşik Plan (Faz / Madde) | Oyun Tasarımı Planı bölümü |
|-----------------------------|----------------------------|
| Faz 1 – UI/UX, ses, denge | Core Gameplay Loop, Grafik & UI Tasarımı, Wave Design |
| Faz 2 – İçerik (düşman, silah, upgrade) | Düşman & Boss Tasarımı, Silah & Item Sistemi, Güçlendirme (Power-ups) |
| Faz 3 – Kayıt, backend, analitik | (teknik altyapı; gelir planı KPI'lar için veri) |
| Faz 4 – IAP, reklam, para birimi | Gelir Modeli (IAP, Rewarded Ads, Battle Pass, VIP) |
| Faz 5 – Liderlik, başarılar, günlük ödül | Player Retention (Daily Login, Quests, Events), Social & Competitive (Leaderboards) |
| Faz 6 – Test, CI/CD, denetim | (kalite süreçleri) |
| Faz 7 – Modlar, ek içerik | Content Roadmap (Season 1–4), Karakter/Silah/Cosmetics |

**Kullanım:** Yeni özellik veya ekran geliştirirken önce Oyun Tasarımı planında ilgili bölüm (karakter sınıfları, silah kategorileri, ekran tasarımı, monetization tabloları vb.) kontrol edilir; Birleşik Plan'daki faz/madde ile birlikte uygulanır. Oyun Tasarımı planında değişiklik yapıldığında ilgili Faz maddeleri de gözden geçirilir.

---

## Yapılan Güncellemeler ve Standartlar

- **Motor:** Planlarda Godot 4.2 geçiyordu; proje 4.6 kullanıyor. Tüm maddeler “Godot 4.x” olarak geçerli.
- **Backend:** 20K planına uygun “minimal backend” seçildi: Firebase veya Supabase. Enterprise mikroservis mimarisi bu planda ertelendi; ihtiyaç artınca Faz 3 genişletilebilir.
- **Gizlilik:** GDPR/CCPA uyumu (veri toplama bildirimi, silme/erişim) analitik ve IAP/reklam ile birlikte düşünülecek; store guideline’ları (Apple/Google) dikkate alınacak.
- **Mobil:** Hedef 60 FPS (üst), düşük uçta 30 FPS; yükleme <5 sn; bellek <200 MB hedefi korundu.

---

## Uygulama Sırası (Özet)

1. **Faz 0** – Stabilizasyon (0.1–0.5)  
2. **Faz 1** – Audio %100, UI polish, denge (1.1–1.3)  
3. **Faz 2** – Performans, MVP içerik (2.1–2.2)  
4. **Faz 3** – Save, cloud, analitik (3.1–3.3)  
5. **Faz 4** – IAP, reklam, para birimi (4.1–4.5)  
6. **Faz 5** – Liderlik, başarılar, günlük ödül (5.1–5.4)  
7. **Faz 6** – Test, CI/CD, loglama, dokümantasyon (6.1–6.3)  
8. **Denetim** – Görsel tasarım checklist + Frontend lead onayı (her UI değişikliğinde)  
9. **Faz 7** – Ek modlar ve içerik (7.1–7.5)

Her faz için “tamamlanma kriteri” sağlandıktan sonra **Faz Sonrası Team Lead Dev Denetimi** yapılır (`docs/FAZ_SONRASI_DENETIM.md`); denetim tamamlanmadan bir sonraki faza geçilmez. UI/Frontend değişikliklerinde `docs/DENETIM_ONAY_SURECI.md` ve `docs/GORSEL_TASARIM_CHECKLIST.md` kullanılır. Oyun tasarımı ve gelir modeli kararları **OYUN_TASARIMI_GELIR_MODELI_PLANI.md** ile senkron tutulur.
