extends Node

# Oyun genelinde paylaşılan durum - tüm sahnelerden erişilebilir
# Karakter seçimi tek kaynak: GameData.selected_character (male_soldier, female_soldier, vb.)
var sound_enabled := true

# Faz 7 – Oyun modu ve tema (lobi'den set edilir, main okur)
const MODE_NORMAL := "normal"
const MODE_ENDLESS := "endless"
const MODE_BOSS_RUSH := "boss_rush"
const MODE_DAILY_CHALLENGE := "daily_challenge"
var game_mode: String = MODE_NORMAL
var theme_id: String = "default"
var daily_challenge_seed: int = 0  # Tarih bazlı; main'de RNG ve kurallar için
