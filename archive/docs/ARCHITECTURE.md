# Faz 6.3.3 – Mimari ve API Notları

## Faz 0 – Stabilizasyon (Uygulandı)

- **0.1 Derleme:** AudioBusManager (`audio_bus_manager.gd`), LobbyMoleculeBase (`lobby_molecule_base.gd`) ve tüm scriptler derlenir.
- **0.2 Lobi:** Lobi ekranı `lobby_molecule.tscn` ile yüklenir; karakter/silah seçimi ve veri `GameData` + `set_player_data`/`get_player_data` ile bağlı.
- **0.3 Akış:** Menü (`menu.tscn`) → Lobi (`lobby.tscn`) → Oyun (`main.tscn`); geçişler `transition_to_scene` / `change_scene_to_file` ile; splash menüde kısa gösterilir, yıldızlı lobi atlanmaz.
- **0.4 Döngüsel bağımlılık:** Menü → MenuScene; Lobi → LobbyMolecule → LobbyMoleculeBase; AudioSystem (wrapper) → AudioSystemMolecule → AudioBusManager. Bu zincirde döngü yok.
- **0.5 Logging:** `Log` (autoload) üzerinden seviyeli log (DEBUG/INFO/WARN/ERROR); `user://logs/game.log` ve `user://logs/error.log` (GameLogger, `log_boot.gd` ile başlatılır).

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

- **Versiyon:** `project.godot` → `config/version`.
- **Export:** Editörde Project → Export ile Android AAB / iOS archive / Desktop preset’leri tanımlanır. CI’da `godot --export-release` için export preset gerekir.
- **Ortam:** `config/default_env.cfg` veya ortam değişkenleri ile backend_url, analytics_enabled ayarlanabilir (Faz 6.2.3).

## Hata Takibi

- **CrashReporter:** `log_crash(message, stack)` ile manuel rapor; dosya + isteğe bağlı analitik.
- **Firebase Crashlytics:** İleride mobil build’e SDK eklenip CrashReporter ile entegre edilebilir; kritik hatalar için uyarı kuralları backend/panelden tanımlanır.
