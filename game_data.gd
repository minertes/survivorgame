extends Node
# ── GameData: Persistent player data (save/load between sessions) ──────────

# ── Currency ──────────────────────────────────────────────────
const DEFAULT_STARTING_XP := 10000  # Test için varsayılan başlangıç XP
var xp_coins     := 10000   # Oyunda kazanılan XP = para (varsayılan 10000 test için)

# ── Character system (YENİ) ───────────────────────────────────
var selected_character := "male_soldier"   # "male_soldier", "female_soldier", vb.
var owned_characters: Array = ["male_soldier"]  # Sahip olunan karakterler
var character_levels: Dictionary = {}  # character_id → level

# ── Flag / Costume system ──────────────────────────────────────
var equipped_flag  := "turkey"
var owned_flags: Array = ["turkey"]

# ── Weapon system (GÜNCELLENDİ) ────────────────────────────────
var owned_weapons: Dictionary = {"machinegun": 1}  # weapon_id → level (1-5)
var equipped_weapon := "machinegun"  # Seçili silah

# ── Stats ──────────────────────────────────────────────────────
var best_wave      := 0
var total_kills    := 0
var total_games    := 0
var total_xp_earned := 0
var total_play_time := 0  # Saniye cinsinden
var accuracy       := 0.0  # 0.0 - 1.0
var survival_rate  := 0.0  # 0.0 - 1.0

# ── Sound ──────────────────────────────────────────────────────
var sound_enabled := true

# ════════════════════════════════════════════════════════════════
#  KARAKTER VERİSİ (YENİ)
# ════════════════════════════════════════════════════════════════
const CHARACTERS: Dictionary = {
	"male_soldier": {
		"name": "BIG BOSS",
		"description": "Deneyimli asker, yüksek dayanıklılık",
		"cost": 0,
		"unlocked_by_default": true,
		"stats": {
			"health": 160,
			"speed": 1.0,
			"armor": "medium",
			"ability": "Rapid Fire"
		},
		"sprite_row": 0
	},
	"female_soldier": {
		"name": "NIGHT STALKER",
		"description": "Hızlı ve çevik, gizli operasyon uzmanı",
		"cost": 500,
		"unlocked_by_default": false,
		"stats": {
			"health": 120,
			"speed": 1.3,
			"armor": "light",
			"ability": "Stealth Mode"
		},
		"sprite_row": 1
	},
	"heavy_gunner": {
		"name": "HEAVY GUNNER",
		"description": "Ağır zırh, yüksek hasar",
		"cost": 800,
		"unlocked_by_default": false,
		"stats": {
			"health": 200,
			"speed": 0.8,
			"armor": "heavy",
			"ability": "Shield Wall"
		},
		"sprite_row": 2
	}
}

# ════════════════════════════════════════════════════════════════
#  BAYRAK VERİSİ
# ════════════════════════════════════════════════════════════════
const FLAGS: Dictionary = {
	"turkey":      {"name":"Türkiye",    "emoji":"🇹🇷","code":"TR","row_m":4, "row_f":5, "cost":0, "bonus": "+10% XP"},
	"usa":         {"name":"ABD",        "emoji":"🇺🇸","code":"US","row_m":6, "row_f":7, "cost":100, "bonus": "+15% Hasar"},
	"germany":     {"name":"Almanya",    "emoji":"🇩🇪","code":"DE","row_m":8, "row_f":9, "cost":120, "bonus": "+20% Zırh"},
	"japan":       {"name":"Japonya",    "emoji":"🇯🇵","code":"JP","row_m":10,"row_f":11,"cost":150, "bonus": "+25% Hız"},
	"france":      {"name":"Fransa",     "emoji":"🇫🇷","code":"FR","row_m":12,"row_f":13,"cost":180, "bonus": "+30% Can"},
	"uk":          {"name":"İngiltere",  "emoji":"🇬🇧","code":"GB","row_m":14,"row_f":15,"cost":200, "bonus": "+35% Kritik"},
	"brazil":      {"name":"Brezilya",   "emoji":"🇧🇷","code":"BR","row_m":16,"row_f":17,"cost":220, "bonus": "+40% Ateş Hızı"},
	"russia":      {"name":"Rusya",      "emoji":"🇷🇺","code":"RU","row_m":22,"row_f":23,"cost":300, "bonus": "+50% Patlama"},
	"china":       {"name":"Çin",        "emoji":"🇨🇳","code":"CN","row_m":24,"row_f":25,"cost":320, "bonus": "+60% Mermi"},
	"south_korea": {"name":"G.Kore",     "emoji":"🇰🇷","code":"KR","row_m":2, "row_f":3, "cost":350, "bonus": "+70% Teknik"}
}

# ════════════════════════════════════════════════════════════════
#  SİLAH VERİSİ (GÜNCELLENDİ)
# ════════════════════════════════════════════════════════════════
const WEAPONS: Dictionary = {
	"machinegun": {
		"name": "Makineli Tüfek",
		"icon": "⚡",
		"description": "Hızlı ateş, düşük hasar",
		"cost": 0,
		"base_fire_rate": 0.1,
		"base_damage": 8,
		"upgrade_multipliers": [1.0, 1.2, 1.5, 1.8, 2.2],
		"special": "Rapid Fire"
	},
	"shotgun": {
		"name": "Pompalı Tüfek",
		"icon": "💣",
		"description": "5 mermi, kısa menzil",
		"cost": 300,
		"base_fire_rate": 1.1,
		"base_damage": 15,
		"upgrade_multipliers": [1.0, 1.3, 1.7, 2.2, 2.8],
		"special": "Spread Shot"
	},
	"sniper": {
		"name": "Keskin Nişancı",
		"icon": "🎯",
		"description": "4× hasar, yavaş ateş",
		"cost": 600,
		"base_fire_rate": 2.4,
		"base_damage": 40,
		"upgrade_multipliers": [1.0, 1.4, 1.9, 2.5, 3.2],
		"special": "Critical Hit"
	},
	"magic_wand": {
		"name": "Sihir Asası",
		"icon": "✨",
		"description": "360° mermi, büyü hasarı",
		"cost": 500,
		"base_fire_rate": 1.8,
		"base_damage": 12,
		"upgrade_multipliers": [1.0, 1.25, 1.6, 2.0, 2.5],
		"special": "Homing Projectiles"
	}
}

const WEAPON_UPGRADE_COSTS := [100, 250, 500, 800]  # lv1→2, lv2→3, lv3→4, lv4→5

const SAVE_PATH := "user://gamedata.cfg"


func _ready() -> void:
	load_data()
	# Eski sistemi yeni sisteme uyarla
	_migrate_old_data()
	# XP kesin 0 ise bir kez daha zorla (cache/save temizlendiğinde)
	if xp_coins <= 0:
		xp_coins = DEFAULT_STARTING_XP
		save_data()
		print("GameData: XP forced to %d in _ready" % xp_coins)

# ── Yardımcılar ────────────────────────────────────────────────
func get_equipped_weapon() -> String:
	return equipped_weapon

func set_equipped_weapon(wid: String) -> void:
	equipped_weapon = wid
	save_data()

func get_flag_row() -> int:
	var fid := equipped_flag if equipped_flag in FLAGS else "turkey"
	var f: Dictionary = FLAGS[fid]
	
	# Karakter tipine göre row seç
	var char_data = CHARACTERS.get(selected_character, CHARACTERS["male_soldier"])
	if "female" in selected_character:
		return int(f.get("row_f", 5))
	else:
		return int(f.get("row_m", 4))

func get_character_sprite_row() -> int:
	var char_data = CHARACTERS.get(selected_character, CHARACTERS["male_soldier"])
	return char_data.get("sprite_row", 0)

# ── XP / Para ──────────────────────────────────────────────────
func add_xp(amount: int) -> void:
	xp_coins       += amount
	total_xp_earned += amount
	save_data()

func spend_xp(amount: int) -> bool:
	if xp_coins < amount:
		return false
	xp_coins -= amount
	save_data()
	return true

# ── Karakter satın al (YENİ) ───────────────────────────────────
func buy_character(character_id: String) -> bool:
	if character_id in owned_characters:
		return false
	if character_id not in CHARACTERS:
		return false
	var char_data: Dictionary = CHARACTERS[character_id]
	var cost := int(char_data.get("cost", 0))
	if not spend_xp(cost):
		return false
	owned_characters.append(character_id)
	save_data()
	return true

func select_character(character_id: String) -> bool:
	if character_id in owned_characters:
		selected_character = character_id
		save_data()
		return true
	return false

# ── Bayrak satın al ────────────────────────────────────────────
func buy_flag(flag_id: String) -> bool:
	if flag_id in owned_flags:
		return false
	if flag_id not in FLAGS:
		return false
	var fd: Dictionary = FLAGS[flag_id]
	var cost := int(fd.get("cost", 0))
	if not spend_xp(cost):
		return false
	owned_flags.append(flag_id)
	save_data()
	return true

func select_flag(flag_id: String) -> bool:
	if flag_id in owned_flags:
		equipped_flag = flag_id
		save_data()
		return true
	return false

# ── Silah satın al ─────────────────────────────────────────────
func buy_weapon(wid: String) -> bool:
	if wid in owned_weapons:
		return false
	if wid not in WEAPONS:
		return false
	var wd: Dictionary = WEAPONS[wid]
	var cost := int(wd.get("cost", 0))
	if not spend_xp(cost):
		return false
	owned_weapons[wid] = 1
	save_data()
	return true

func select_weapon(wid: String) -> bool:
	if wid in owned_weapons:
		equipped_weapon = wid
		save_data()
		return true
	return false

# ── Silah yükselt ──────────────────────────────────────────────
func upgrade_weapon(wid: String) -> bool:
	if wid not in owned_weapons:
		return false
	var lv := int(owned_weapons.get(wid, 1))
	if lv >= 5:
		return false
	var cost := int(WEAPON_UPGRADE_COSTS[lv - 1])
	if not spend_xp(cost):
		return false
	owned_weapons[wid] = lv + 1
	save_data()
	return true

func get_weapon_level(wid: String) -> int:
	return owned_weapons.get(wid, 0)

# ── Stats güncelle ─────────────────────────────────────────────
func record_game(wave: int, kills: int, play_time: int, shots_fired: int, shots_hit: int) -> void:
	total_games += 1
	total_kills += kills
	total_play_time += play_time
	
	if wave > best_wave:
		best_wave = wave
	
	# İsabet oranını güncelle
	if shots_fired > 0:
		var new_accuracy = float(shots_hit) / shots_fired
		accuracy = (accuracy * (total_games - 1) + new_accuracy) / total_games
	
	# Hayatta kalma oranını güncelle (basit versiyon)
	if wave > 5:  # 5. dalgadan sonra hayatta kaldı say
		survival_rate = (survival_rate * (total_games - 1) + 1.0) / total_games
	else:
		survival_rate = (survival_rate * (total_games - 1) + 0.0) / total_games
	
	save_data()

# ── Eski veriyi yeni sisteme uyarla ────────────────────────────
func _migrate_old_data() -> void:
	# Eski selected_character değerini yeni sisteme uyarla
	if selected_character == "male":
		selected_character = "male_soldier"
	elif selected_character == "female":
		selected_character = "female_soldier"
	
	# Eski owned_weapons'ı kontrol et
	if owned_weapons.is_empty():
		owned_weapons["machinegun"] = 1
	
	# Eski equipped_weapon değerlerini birleştir
	if equipped_weapon == "":
		equipped_weapon = "machinegun"
	
	# Varsayılan karakteri owned_characters'a ekle
	if not "male_soldier" in owned_characters:
		owned_characters.append("male_soldier")
	
	save_data()

# ════════════════════════════════════════════════════════════════
#  SAVE / LOAD
# ════════════════════════════════════════════════════════════════
func save_data() -> void:
	var cfg := ConfigFile.new()
	
	# Player data
	cfg.set_value("player", "xp_coins",            xp_coins)
	cfg.set_value("player", "selected_character",  selected_character)
	cfg.set_value("player", "owned_characters",    owned_characters)
	cfg.set_value("player", "character_levels",    character_levels)
	cfg.set_value("player", "equipped_flag",       equipped_flag)
	cfg.set_value("player", "owned_flags",         owned_flags)
	cfg.set_value("player", "owned_weapons",       owned_weapons)
	cfg.set_value("player", "equipped_weapon",     equipped_weapon)
	cfg.set_value("player", "sound_enabled",       sound_enabled)
	
	# Stats
	cfg.set_value("stats",  "best_wave",           best_wave)
	cfg.set_value("stats",  "total_kills",         total_kills)
	cfg.set_value("stats",  "total_games",         total_games)
	cfg.set_value("stats",  "total_xp_earned",     total_xp_earned)
	cfg.set_value("stats",  "total_play_time",     total_play_time)
	cfg.set_value("stats",  "accuracy",            accuracy)
	cfg.set_value("stats",  "survival_rate",       survival_rate)
	
	cfg.save(SAVE_PATH)

func load_data() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		print("No saved data found, using defaults (including %d XP for testing)" % DEFAULT_STARTING_XP)
		xp_coins = DEFAULT_STARTING_XP
		return
	
	# Player data (xp_coins sayı olarak oku; 0 veya eksikse varsayılan ver)
	var loaded_xp = cfg.get_value("player", "xp_coins", DEFAULT_STARTING_XP)
	xp_coins = int(loaded_xp) if loaded_xp != null else DEFAULT_STARTING_XP
	if xp_coins <= 0:
		xp_coins = DEFAULT_STARTING_XP
		save_data()
	selected_character = cfg.get_value("player", "selected_character", "male_soldier")
	owned_characters   = cfg.get_value("player", "owned_characters",   ["male_soldier"])
	character_levels   = cfg.get_value("player", "character_levels",   {})
	equipped_flag      = cfg.get_value("player", "equipped_flag",      "turkey")
	owned_flags        = cfg.get_value("player", "owned_flags",        ["turkey"])
	owned_weapons      = cfg.get_value("player", "owned_weapons",      {"machinegun": 1})
	equipped_weapon    = cfg.get_value("player", "equipped_weapon",    "machinegun")
	sound_enabled      = cfg.get_value("player", "sound_enabled",      true)
	
	# Stats
	best_wave          = cfg.get_value("stats",  "best_wave",          0)
	total_kills        = cfg.get_value("stats",  "total_kills",        0)
	total_games        = cfg.get_value("stats",  "total_games",        0)
	total_xp_earned    = cfg.get_value("stats",  "total_xp_earned",   0)
	total_play_time    = cfg.get_value("stats",  "total_play_time",   0)
	accuracy           = cfg.get_value("stats",  "accuracy",          0.0)
	survival_rate      = cfg.get_value("stats",  "survival_rate",     0.0)
	
	# XP 0 veya negatifse tekrar zorla (ikinci kontrol)
	if xp_coins <= 0:
		xp_coins = DEFAULT_STARTING_XP
		save_data()
		print("Game data: XP was 0, set to %d and saved" % xp_coins)
	
	print("Game data loaded successfully")