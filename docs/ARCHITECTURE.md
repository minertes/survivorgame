# Faz 6.3.3 – Mimari ve API Notları

## Faz 0 – Stabilizasyon (Uygulandı)

- **0.1 Derleme:** AudioBusManager (`audio_bus_manager.gd`), LobbyMoleculeBase (`lobby_molecule_base.gd`) ve tüm scriptler derlenir.
- **0.2 Lobi:** Lobi ekranı `lobby_molecule.tscn` ile yüklenir; karakter/silah seçimi ve veri `GameData` + `set_player_data`/`get_player_data` ile bağlı.
- **0.3 Akış:** Menü (`menu.tscn`) → Lobi (`lobby.tscn`) → Oyun (`main.tscn`); geçişler `transition_to_scene` / `change_scene_to_file` ile; splash menüde kısa gösterilir, yıldızlı lobi atlanmaz.
- **0.4 Döngüsel bağımlılık:** Menü → MenuScene; Lobi → LobbyMolecule → LobbyMoleculeBase; AudioSystem (wrapper) → AudioSystemMolecule → AudioBusManager. Bu zincirde döngü yok.
- **0.5 Logging:** `Log` (autoload) üzerinden seviyeli log (DEBUG/INFO/WARN/ERROR); `user://logs/game.log` ve `user://logs/error.log` (GameLogger, `log_boot.gd` ile başlatılır).

## Faz 1 – MVP Tamamlama (Uygulandı)

- **1.1 Audio:** SFX (ateş, hasar, ölüm, level up, pickup), UI (click), BGM menü/oyun; ses kalıcılığı `user://audio_settings.cfg`. Pause menüsünde Ses Ayarları (Master/Music/SFX).
- **1.2 UI/UX:** Pause menüsü (Devam, Lobiye Dön, Ana Menü, Ses Ayarları); Game Over (skor, dalga, yeniden dene/lobi); splash menüde; ilk açılışta 5 adımlık tutorial (hareket, ateş, XP, upgrade, hayatta kal).
- **1.3 Denge:** Dalga bantları 1–10 / 11–30 / 31+ (`_get_wave_scale`); boss dalgaları tanımlı; XP, upgrade paneli, dalga tamamlama.

## Faz 2 – Performans ve İçerik (Uygulandı)

- **2.1 Performans:** F9 ile FPS ve bellek göstergesi (2.1.1); mermi havuzu `BulletPool` (2.1.2); asset/Godot import mevcut (2.1.3); ilk yükleme menü splash ile (2.1.4).
- **2.2 İçerik:** 5 düşman türü (Zombi, Koşucu, Dev, İblis, Boss); 3+ silah (mevcut silahlar korunur); 10 upgrade (upgrade_panel STAT_UPGRADES); dalga/skor ve yerel en iyi dalga (GameData.best_wave, wave complete bildirimi).

## Faz 3 – Kayıt, Analitik ve Backend (Uygulandı)

- **3.1 Yerel kayıt:** GameData ile ilerleme (level, XP, karakter/silah, ayarlar) `user://gamedata.cfg` (3.1.1). Checksum ve yedek dosya `user://gamedata_backup.cfg`; bozulma durumunda yedekten yükleme (3.1.2).
- **3.2 Backend:** BackendService (base_url/api_key ile Firebase veya Supabase) (3.2.1); cihaz bazlı anonim kimlik `user://device_id.cfg` (3.2.2); bulut kayıt push/pull, `apply_cloud_data` + yerel `save_data` (3.2.3); güvenlik kuralları backend tarafında (3.2.4).
- **3.3 Analitik:** AnalyticsService – session_start/end, wave_completed, level_up, death; platform ve versiyon; event’ler `user://logs/analytics.log` (3.3.1–3.3.2). CrashReporter – `user://logs/crash_*.txt` ve isteğe bağlı analitik (3.3.3).

## Faz 4 – Mağaza ve Monetizasyon (Uygulandı)

- **4.1 IAP:** IAPService (store plugin soyutlaması; editörde test simülasyonu).
- **4.2 Ürün konfig:** PRODUCTS (gems paketleri, starter_pack, character_pack, weapon_bundle, cosmetic_set).
- **4.3 Satın alma:** start_purchase → doğrula → ödül; purchase_completed; bulut push.
- **4.4 Reklam:** AdService (consent, rewarded_video, interstitial stub).
- **4.5 Premium para:** GameData.gems, gem_spend_log; yerel + cloud; shop sahnesi.

## Faz 5 – Sosyal ve Canlı Ops (Uygulandı)

- **5.1 Liderlik tablosu:** LeaderboardService – günlük/haftalık skor gönderme ve listeleme; BackendService base_url ile; backend yokken yerel fallback (kendi skorun). Menü → Liderlik & Başarılar → social_ops.tscn (Günlük/Haftalık sekmeleri).
- **5.2 Başarılar:** AchievementsService – tanımlı rozetler (ACHIEVEMENTS), ilerleme takibi (get_progress), achievement_unlocked sinyali; MenuScene’de kısa bildirim; social_ops’te Başarılar sekmesi.
- **5.3 Günlük ödüller:** GameData – login_streak, last_login_ymd, get_daily_reward_state(), claim_daily_reward(); menü açılışta on_login_tick() (streak/yarın kontrolü); social_ops’te Günlük sekmesi (seri, Bugünkü ödülü al).
- **5.4 Basit sosyal:** ShareService – share_score(wave, kills) panoya kopyalama; Game Over ekranında “Skoru Paylaş” butonu; daily quest “Skoru paylaş” ilerlemesi.

## Faz 6 – Kalite, Test ve Operasyon (Uygulandı)

- **6.1 Test:** Birim test `ci/test_runner.gd` + `ci/test_runner.tscn` (GameData save/load, wave_scale, para birimi); entegrasyon `ci/integration_test.gd` (sahne varlığı, autoload'lar, record_game). CI headless: `godot --headless --path . res://ci/test_runner.tscn --quit-after 5`. Manuel: `docs/MANUAL_TEST_CHECKLIST.md`.
- **6.2 CI/CD:** `.github/workflows/godot-ci.yml` – test job (unit + integration), build-export (Linux preset "Linux/X11", `export_presets.cfg`). Versiyon: `project.godot` config/version. Ortam: `config/default_env.cfg` + EnvConfig; `config/README.md`.
- **6.3 İzleme/dokümantasyon:** Log (log_boot.gd, logger.gd), EnvConfig log seviyesi; CrashReporter (user://logs/crash_*.txt); mimari bu dosya.

## Faz 7 – İçerik Genişletme ve Oyun Modları (Uygulandı)

- **7.1 Günlük meydan okuma:** GameState.MODE_DAILY_CHALLENGE; GameData.get_daily_challenge_seed() (tarih tohumu); main’de damage_mult 1.5x; dalga 5+ tamamlanınca claim_daily_challenge_reward (XP + elmas). Lobi mod seçici: "Günlük".
- **7.2 Sonsuz mod:** GameState.MODE_ENDLESS; dalga sınırsız. Prestij: GameData.prestige_level, get_prestige_bonus(), can_do_prestige() (best_wave >= 30), do_prestige(); Game Over’da "Prestij yap" butonu; player’da prestige_mult hasar/can.
- **7.3 Boss Rush:** GameState.MODE_BOSS_RUSH; main._get_enemy_type() her zaman boss (tip 4); HUD "Boss Rush · N".
- **7.4 Ek karakterler ve silahlar:** GameData.CHARACTERS (4: male_soldier, female_soldier, heavy_gunner, medic); WEAPONS (5: machinegun, shotgun, sniper, magic_wand, flamethrower). Lobi/menü karakter ve silah seçimi; player._apply_weapon tüm silahları destekler.
- **7.5 Yeni haritalar/temalar:** Background.THEMES (4: Mezarlık, Karanlık Orman, Çöl, Cehennem); THEME_IDS; GameState.theme_id; lobi tema seçici (Mezarlık, Orman, Çöl, Cehennem); main’de background.set_theme_by_id(gs.theme_id).

## Nasıl Çalıştırılır

- **Editör:** Godot 4.x ile projeyi açın, F5 veya Play ile `res://menu.tscn` çalışır.
- **Komut satırı (headless test):**
  ```bash
  godot --headless --path . res://ci/test_runner.tscn --quit-after 5
  ```
- **Sürüm:** `project.godot` içinde `config/version="1.0.0"`.

## Ana Sistemler

| Sistem | Açıklama | Konum |
|--------|----------|--------|
| **GameData** | Kalıcı oyuncu verisi (XP, elmas, karakter, silah, bayrak, istatistikler, başarılar, günlük ödül). Save/Load `user://gamedata.cfg`, checksum + yedek. | `game_data.gd` (autoload) |
| **BackendService** | Bulut kayıt (push/pull), cihaz ID, anonim kimlik. Base URL ve API key ile Firebase/Supabase. | `src/core/systems/backend_service.gd` |
| **AnalyticsService** | session_start/end, wave_completed, level_up, death, purchase; log dosyası + ileride backend. | `src/core/systems/analytics_service.gd` |
| **CrashReporter** | Çökme mesajını `user://logs/crash_*.txt` ve isteğe bağlı analitik event. | `src/core/systems/crash_reporter.gd` |
| **IAPService** | Ürün tanımları, satın alma akışı (test/gerçek), GameData.add_gems. | `src/core/systems/iap_service.gd` |
| **LeaderboardService** | Skor gönderme (günlük/haftalık), liderlik listesi (backend veya yerel). | `src/core/systems/leaderboard_service.gd` |
| **AchievementsService** | Başarı tanımları, ilerleme, unlock sinyali. | `src/core/systems/achievements_service.gd` |
| **ShareService** | Skor metnini panoya kopyalama. | `src/core/systems/share_service.gd` |
| **Log** | Seviyeli log (DEBUG/INFO/WARN/ERROR/FATAL); `user://logs/game.log` ve ERROR+ için `error.log`. | `src/core/utils/log_boot.gd` + `logger.gd` |

## EventBus Kullanımı

- **EventBus** (`src/core/systems/event_bus.gd`): Global event iletişimi. `emit(type, data)`, `subscribe(type, callable)`. Öncelik ve kuyruk ile.
- Oyun akışında menü/lobi/oyun geçişleri sahne değiştirme ile; EventBus isteğe bağlı olarak UI/gameplay olayları için kullanılır.

## Sahne Akışı

1. **menu.tscn** → Başla → **lobby.tscn** → Oyna → **main.tscn** (oyun).
2. Menüden: Mağaza → **shop.tscn**; Liderlik & Başarılar → **social_ops.tscn**.
3. Oyun bitti: Yeniden Oyna (reload), Lobiye Dön (lobby), Skoru Paylaş (panoya).

## Dağıtım ve Build

- **Versiyon:** `project.godot` → `config/version` (Faz 6.2.2).
- **Export:** `export_presets.cfg` – preset "Linux/X11" → `builds/linux.x86_64`; CI’da `godot --export-release "Linux/X11"`. Android AAB / iOS editörde ek preset ile tanımlanır.
- **Ortam:** `config/default_env.cfg` + EnvConfig (Faz 6.2.3); backend_url, analytics_enabled, log_level.

## Hata Takibi

- **CrashReporter:** `log_crash(message, stack)` ile manuel rapor; dosya + isteğe bağlı analitik.
- **Firebase Crashlytics:** İleride mobil build’e SDK eklenip CrashReporter ile entegre edilebilir; kritik hatalar için uyarı kuralları backend/panelden tanımlanır.
