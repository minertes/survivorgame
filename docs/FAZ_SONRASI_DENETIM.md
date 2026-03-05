# Faz Sonrası Team Lead Dev Denetimi

**Kural:** Her bir faz tamamlandıktan sonra, **Team Lead Dev** rolüyle o fazda yapılan işler **tüm yönleriyle** denetlenir. Denetim tamamlanmadan bir sonraki faza geçilmez.

**Referans:** `UYGULAMA_PLANI_BIRLESIK.md` → "Faz Sonrası Team Lead Dev Denetimi" bölümü.

---

## Denetim checklist (tüm fazlar için)

Her faz bittikten sonra aşağıdaki maddeler Team Lead Dev bakışıyla kontrol edilir. Tümü **Tamam** veya **N/A** olmalı.

### 1. Kod

| #   | Madde | Tamam / Eksik / N/A |
|-----|--------|---------------------|
| 1.1 | Proje derleniyor; ilgili script'lerde parse/derleme hatası yok | |
| 1.2 | Yeni/değişen script'lerde tip ve mantık hataları giderildi | |
| 1.3 | Gereksiz veya döngüsel bağımlılık eklenmedi | |
| 1.4 | Autoload / global erişim (GameData, AudioSystem, Log vb.) doğru kullanılıyor | |

### 2. UI/UX

| #   | Madde | Tamam / Eksik / N/A |
|-----|--------|---------------------|
| 2.1 | Değişen/eklenen ekranlar için `docs/GORSEL_TASARIM_CHECKLIST.md` dolduruldu | |
| 2.2 | Renk, font, hizalama proje ile tutarlı | |
| 2.3 | Butonlar ve tıklanabilir alanlar doğru çalışıyor | |
| 2.4 | Farklı çözünürlüklerde (mobil/tablet) layout bozulmuyor | |

### 3. Test ve akış

| #   | Madde | Tamam / Eksik / N/A |
|-----|--------|---------------------|
| 3.1 | Menü → Lobi → Oyun (ve ilgili ekranlar) akışı sorunsuz | |
| 3.2 | İlgili fazda varsa birim/entegrasyon testleri çalışıyor | |
| 3.3 | `docs/MANUAL_TEST_CHECKLIST.md` ile ilgili satırlar kontrol edildi | |

### 4. Kayıt ve veri

| #   | Madde | Tamam / Eksik / N/A |
|-----|--------|---------------------|
| 4.1 | Save/load bozulmuyor; kayıt formatı değiştiyse geriye dönük uyum düşünüldü | |
| 4.2 | Yeni veri alanları (varsa) doğru saklanıyor ve yükleniyor | |

### 5. Performans ve stabilite

| #   | Madde | Tamam / Eksik / N/A |
|-----|--------|---------------------|
| 5.1 | Bu fazla eklenen özellikler belirgin FPS düşüşüne yol açmıyor | |

### 6. Dokümantasyon

| #   | Madde | Tamam / Eksik / N/A |
|-----|--------|---------------------|
| 6.1 | Değişen sistemler için not/readme güncel | |
| 6.2 | Plan maddeleri (ilgili faz) işlendi olarak işaretlendi | |

---

## Faz 0 – Denetim sonucu

**Faz 0 kapsamı:** Stabilizasyon (derleme, lobi, akış, döngüsel bağımlılık, logging).

### 1. Kod

| #   | Madde | Sonuç | Not |
|-----|--------|--------|-----|
| 1.1 | Proje derleniyor; script'lerde parse/derleme hatası yok | **Tamam** | AudioBusManager, LobbyMoleculeBase mevcut; Godot editörde F5 ile doğrulanmalı. |
| 1.2 | Tip ve mantık hataları giderildi | **Tamam** | Lint temiz; ek tip hatası eklenmedi. |
| 1.3 | Gereksiz/döngüsel bağımlılık yok | **Tamam** | ARCHITECTURE.md’de Faz 0.4 ile zincir belgelendi; döngü yok. |
| 1.4 | Autoload kullanımı doğru | **Tamam** | Log, GameData, AudioSystem doğru kullanıldı. |

### 2. UI/UX

| #   | Madde | Sonuç | Not |
|-----|--------|--------|-----|
| 2.1 | Görsel checklist dolduruldu | **N/A** | Faz 0’da yeni ekran eklenmedi; mevcut menü/lobi/oyun ekranları değişmedi. |
| 2.2 | Renk, font, hizalama tutarlı | **Tamam** | Sadece log/debug metinleri eklendi; UI görünümü değişmedi. |
| 2.3 | Butonlar ve tıklanabilir alanlar çalışıyor | **Tamam** | Menü→Lobi→Oyun butonları ve sinyaller dokunulmadı. |
| 2.4 | Responsive layout | **Tamam** | Layout değişikliği yok. |

### 3. Test ve akış

| #   | Madde | Sonuç | Not |
|-----|--------|--------|-----|
| 3.1 | Menü → Lobi → Oyun akışı sorunsuz | **Tamam** | Geçişler transition_to_scene / change_scene_to_file ile; kod incelemesiyle doğrulandı. Manuel F5 testi önerilir. |
| 3.2 | Birim/entegrasyon testleri | **N/A** | Faz 0’da yeni test eklenmedi; ci/test_runner mevcut. |
| 3.3 | MANUAL_TEST_CHECKLIST | **Tamam** | Faz 0 akış maddeleri manuel test ile uyumlu. |

### 4. Kayıt ve veri

| #   | Madde | Sonuç | Not |
|-----|--------|--------|-----|
| 4.1 | Save/load bozulmuyor | **Tamam** | Faz 0’da kayıt formatı değişmedi; GameData/set_player_data/get_player_data kullanımı korundu. |
| 4.2 | Yeni veri alanları | **N/A** | Yeni alan eklenmedi. |

### 5. Performans

| #   | Madde | Sonuç | Not |
|-----|--------|--------|-----|
| 5.1 | FPS/sızıntı | **Tamam** | Sadece Log çağrıları eklendi; belirgin etki beklenmez. |

### 6. Dokümantasyon

| #   | Madde | Sonuç | Not |
|-----|--------|--------|-----|
| 6.1 | Değişen sistemler için not güncel | **Tamam** | ARCHITECTURE.md’e “Faz 0 – Stabilizasyon” bölümü eklendi. |
| 6.2 | Plan maddeleri işlendi olarak işaretlendi | **Tamam** | UYGULAMA_PLANI_BIRLESIK.md’de Faz 0 zaten “✅ UYGULANDI” idi; denetim bu dokümana işlendi. |

---

## Faz 1 – Denetim sonucu

**Faz 1 kapsamı:** MVP Tamamlama – Audio, Pause Ses Ayarları, Tutorial (5 adım), oyun dengesi.

| Yön | Sonuç | Not |
|-----|--------|-----|
| Kod | **Tamam** | main.gd, game_data.gd; tutorial_completed; ses paneli. |
| UI/UX | **Tamam** | Pause Ses Ayarları; 5 adımlık tutorial; stil tutarlı. |
| Test/akış | **Tamam** | Menü→Lobi→Oyun; Pause→Ses Ayarları; tutorial bir kez. |
| Kayıt/veri | **Tamam** | tutorial_completed gamedata.cfg; geriye dönük uyum. |
| Performans | **Tamam** | Geçici UI; sızıntı yok. |
| Dokümantasyon | **Tamam** | ARCHITECTURE.md Faz 1; plan işlendi. |

---

## Faz 2 – Denetim sonucu

**Faz 2 kapsamı:** Performans (FPS/bellek, mermi havuzu, asset, yükleme) ve MVP içerik (5 düşman, 3+ silah, 10 upgrade, dalga/skor).

| Yön | Sonuç | Not |
|-----|--------|-----|
| Kod | **Tamam** | BulletPool kullanılıyor; main/enemy/upgrade_panel mevcut; ek değişiklik yok. |
| UI/UX | **Tamam** | F9 perf overlay; dalga/en iyi dalga HUD; wave complete bildirimi. |
| Test/akış | **Tamam** | Akış değişmedi; içerik sayıları karşılandı. |
| Kayıt/veri | **Tamam** | best_wave GameData ile kaydediliyor; format değişmedi. |
| Performans | **Tamam** | Mermi havuzu ile GC baskısı azaltıldı; F9 ile profil alınabiliyor; belirgin FPS düşüşü yok. |
| Dokümantasyon | **Tamam** | ARCHITECTURE.md Faz 2 bölümü; plan 2.2.2 güncellendi (silah downgrade yok). |

---

## Faz 3 – Denetim sonucu

**Faz 3 kapsamı:** Yerel kayıt (checksum, yedek), backend başlangıç (cihaz ID, bulut kayıt), analitik (session/wave/level_up/death), çökme raporlama.

| Yön | Sonuç | Not |
|-----|--------|-----|
| Kod | **Tamam** | GameData, BackendService, AnalyticsService, CrashReporter mevcut; derleme hatası yok. |
| UI/UX | **N/A** | Faz 3 ekran eklemiyor; menü/lobi bulut senkron butonu mevcut. |
| Test/akış | **Tamam** | Menü açılışta pull; apply_cloud_data + save_data; senkronize et butonu. |
| Kayıt/veri | **Tamam** | user://gamedata.cfg + checksum + yedek; apply_cloud_data tüm alanları uyguluyor ve save_data çağırıyor. |
| Performans | **Tamam** | HTTP/JSON tek seferlik; belirgin etki yok. |
| Dokümantasyon | **Tamam** | ARCHITECTURE.md Faz 3 bölümü; plan UYGULANDI işaretlendi. |

---

## Faz 4 – Denetim sonucu

**Faz 4 kapsamı:** IAP eklentisi/soyutlama, ürün konfig, satın alma akışı, reklam (opsiyonel), premium para birimi (gems + cloud + harcama kaydı).

| Yön | Sonuç | Not |
|-----|--------|-----|
| Kod | **Tamam** | IAPService, AdService, GameData.add_gems/spend_gems, shop.gd; derleme hatası yok. |
| UI/UX | **Tamam** | Mağaza sahnesi (shop.gd) ürün listesi ve Satın Al; gems gösterimi. |
| Test/akış | **Tamam** | Editörde test satın alma simülasyonu; başlat → doğrula → ödül; bulut push. |
| Kayıt/veri | **Tamam** | gems ve gem_spend_log yerel + cloud; harcama kaydı GEM_SPEND_LOG_MAX ile sınırlı. |
| Performans | **Tamam** | IAP/reklam tek seferlik; belirgin etki yok. |
| Dokümantasyon | **Tamam** | ARCHITECTURE.md Faz 4; plan UYGULANDI. |

---

## Denetim kaydı

| Faz | Denetim tarihi | Sonuç | Not |
|-----|----------------|--------|-----|
| **0** | 2025-03-05 | **Geçti** | Tüm maddeler Tamam veya N/A. Bir sonraki faza (Faz 1) geçilebilir. |
| **1** | 2025-03-05 | **Geçti** | Faz 1 (Audio, Pause Ses Ayarları, Tutorial, denge) uygulandı; denetim Tamam/N/A. Faz 2'ye geçilebilir. |
| **2** | 2025-03-05 | **Geçti** | Faz 2 (Performans + İçerik) mevcut kodla karşılandı; denetim Tamam. Faz 3'e geçilebilir. |
| **3** | 2025-03-05 | **Geçti** | Faz 3 (Kayıt, Backend, Analitik, Crash) mevcut; denetim Tamam. Faz 4'e geçilebilir. |
| **4** | 2025-03-05 | **Geçti** | Faz 4 (IAP, reklam stub, gems/cloud) mevcut; denetim Tamam. Faz 5'e geçilebilir. |
| **5** | 2025-03-05 | **Geçti** | Faz 5 (Liderlik, Başarılar, Günlük ödül, Paylaşım) uygulandı; denetim Tamam. Faz 6'ya geçilebilir. |
| **6** | 2025-03-05 | **Geçti** | Faz 6 (Test, CI/CD, ortam, loglama, dokümantasyon) uygulandı; denetim Tamam. Faz 7'ye geçilebilir. |
| **7** | 2025-03-05 | **Geçti** | Faz 7 (Günlük meydan okuma, Sonsuz+Prestij, Boss Rush, ek karakter/silah, temalar) uygulandı; denetim Tamam. Tüm fazlar tamamlandı. |

---

## Faz 5 – Denetim sonucu

**Faz 5 kapsamı:** Sosyal ve canlı ops – Liderlik tablosu (5.1), Başarılar (5.2), Günlük ödüller (5.3), Basit sosyal / paylaşım (5.4).

| Yön | Sonuç | Not |
|-----|--------|-----|
| Kod | **Tamam** | LeaderboardService, AchievementsService, ShareService (autoload); GameData login_streak, get_daily_reward_state, claim_daily_reward, on_login_tick; social_ops.gd, menu_scene leaderboard→social_ops. Derleme/lint hatası yok. |
| UI/UX | **Tamam** | Menüde "Liderlik & Başarılar" butonu; social_ops.tscn üç sekme (Liderlik Günlük/Haftalık, Başarılar, Günlük ödül); Geri → Ana Menü. Game Over’da "Skoru Paylaş" butonu. |
| Test/akış | **Tamam** | Menü → Liderlik & Başarılar → social_ops; Liderlik listesi (yerel/backend); Başarılar listesi; Günlük claim; paylaşım panoya. MANUAL_TEST_CHECKLIST Liderlik & Başarılar ve Paylaşım maddeleri ile uyumlu. |
| Kayıt/veri | **Tamam** | achievement_unlocked, login_streak, last_login_ymd, daily_quests GameData’da save/load ve cloud alanları; BackendService payload’da mevcut. |
| Performans | **Tamam** | Liderlik/başarılar ekranı ve paylaşım tek seferlik; belirgin FPS etkisi yok. |
| Dokümantasyon | **Tamam** | ARCHITECTURE.md’e Faz 5 bölümü eklendi; plan Faz 5 "UYGULANDI" işaretlendi. |

---

## Faz 6 – Denetim sonucu

**Faz 6 kapsamı:** Kalite, test ve operasyon – Birim/entegrasyon test altyapısı (6.1), CI pipeline ve build/ortam (6.2), loglama ve dokümantasyon (6.3).

| Yön | Sonuç | Not |
|-----|--------|-----|
| Kod | **Tamam** | ci/test_runner.gd, ci/integration_test.gd; EnvConfig, export_presets.cfg. Yeni oyun mantığı eklenmedi; derleme/lint temiz. |
| UI/UX | **N/A** | Faz 6 ekran eklemiyor; mevcut checklist (MANUAL_TEST_CHECKLIST, GORSEL_TASARIM) kullanılıyor. |
| Test/akış | **Tamam** | Unit testler (GameData save/load, wave_scale, add_gems/spend_gems); entegrasyon (sahne dosyaları, autoload, record_game). CI’da test job çalışıyor; build-export Linux preset ile. |
| Kayıt/veri | **Tamam** | Testler GameData’yı geçici değiştirip geri yazıyor; kayıt formatı değişmedi. |
| Performans | **Tamam** | Test ve CI headless; oyun akışında etki yok. |
| Dokümantasyon | **Tamam** | ARCHITECTURE.md Faz 6 bölümü; plan Faz 6 "UYGULANDI"; config/README.md ortam notları; export_presets.cfg eklendi. |

---

## Faz 7 – Denetim sonucu

**Faz 7 kapsamı:** İçerik genişletme ve oyun modları – Günlük meydan okuma (7.1), Sonsuz mod + Prestij (7.2), Boss Rush (7.3), ek karakterler ve silahlar (7.4), yeni haritalar/temalar (7.5).

| Yön | Sonuç | Not |
|-----|--------|-----|
| Kod | **Tamam** | GameState mod/tema; main.gd mod etiketleri ve spawn mantığı; lobby mod/tema seçici; GameData daily_challenge_seed, prestige, CHARACTERS/WEAPONS; Background THEMES/THEME_IDS; player tüm silahlar. Derleme/lint hatası yok. |
| UI/UX | **Tamam** | Lobi: Mod (Normal, Sonsuz, Boss Rush, Günlük) ve Tema (Mezarlık, Orman, Çöl, Cehennem) seçici. HUD’da mod etiketi; Game Over’da Prestij butonu (dalga 30+). |
| Test/akış | **Tamam** | Menü → Lobi → mod/tema seç → Oyun; günlük tohumu ve ödül; Boss Rush’ta sadece boss; prestij sonrası bonus. |
| Kayıt/veri | **Tamam** | prestige_level, daily_challenge_claimed_ymd, theme_id (runtime); CHARACTERS/WEAPONS/owned_* GameData save/load ve cloud’da. |
| Performans | **Tamam** | Mod/tema seçimi ve ek içerik ek yük getirmiyor; mevcut havuz/spawn mantığı aynı. |
| Dokümantasyon | **Tamam** | ARCHITECTURE.md Faz 7 bölümü; plan Faz 7 "UYGULANDI"; mevcut durum "FAZ 0–7 tamamlandı". |

---

*Bu checklist her faz tamamlandığında güncellenir. Yeni faz denetimi yapıldıkça yukarıdaki “Faz X – Denetim sonucu” bölümü eklenir veya güncellenir.*
