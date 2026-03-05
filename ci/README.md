# Faz 6 – Test altyapısı

## Yerel test çalıştırma

Godot 4.x (4.6 önerilir) kurulu ve `godot` komutu PATH’te ise:

```bash
# Proje kökünde
cd path/to/survivorgame

# Birim testleri (GameData save/load, wave_scale, para birimi)
godot --headless --path . res://ci/test_runner.tscn --quit-after 5

# Entegrasyon testleri (sahne varlığı, autoload’lar, record_game)
godot --headless --path . res://ci/integration_test.tscn --quit-after 5
```

Çıkış kodu: **0** = tüm testler geçti, **1** = en az bir hata.

## Windows’ta Godot PATH’te değilse

Godot’u indirip bir klasöre koyduysanız, tam yolu kullanın:

```powershell
$godot = "C:\Users\miner\Downloads\Godot_v4.6.1-stable_win64.exe"  # kendi yolunuz
cd c:\Users\miner\Documents\survivorgame
$env:GODOT_DISABLE_LEAK_CHECKS = "1"
& $godot --headless --path . res://ci/test_runner.tscn --quit-after 5
& $godot --headless --path . res://ci/integration_test.tscn --quit-after 5
```

Veya `run_tests.bat` / `run_tests.ps1` scriptini kullanın (Godot yolunu içinde düzenleyin).

## CI (GitHub Actions)

`main` veya `master`’a push/PR’da `.github/workflows/godot-ci.yml` çalışır:

1. **test:** Import → unit testler → entegrasyon testleri  
2. **build-export:** `export_presets.cfg` varsa Linux export (preset "Linux/X11")

## Test kapsamı

| Test | İçerik |
|------|--------|
| **test_runner.gd** | GameData save/load, wave_scale(1/10), is_boss_wave(9/10), add_gems/spend_gems |
| **integration_test.gd** | menu.tscn, lobby.tscn, main.tscn varlığı; GameData/BackendService autoload; record_game ile istatistik güncellemesi |
