extends Node
# ── GameData: Persistent player data (save/load between sessions) ──────────

# ── Currency ──────────────────────────────────────────────────
var xp_coins     := 0      # Oyunda kazanılan XP = para

# ── Character selection ────────────────────────────────────────
var selected_character := "male"   # "male" | "female"

# ── Flag / Costume system ──────────────────────────────────────
# Her bayrak → farklı karakter görünümü (sprite row)
var equipped_flag  := "turkey"
var owned_flags: Array = ["turkey"]

# ── Weapon system ──────────────────────────────────────────────
# owned_weapons: { weapon_id: level }  level 1-5
var owned_weapons: Dictionary = {}
var equipped_weapon_male   := "machinegun"
var equipped_weapon_female := "machinegun"

# ── Stats ──────────────────────────────────────────────────────
var best_wave      := 0
var total_kills    := 0
var total_games    := 0
var total_xp_earned := 0

# ── Sound ──────────────────────────────────────────────────────
var sound_enabled := true

# ════════════════════════════════════════════════════════════════
#  BAYRAK VERİSİ  (id → name, emoji, row_male, row_female, cost)
# ════════════════════════════════════════════════════════════════
# Sprite sheet: 28 satır × 24 sütun (FRAME_W=16, FRAME_H=24)
# Her bayrak için erkek ve kadın row_index değerleri var.
const FLAGS: Dictionary = {
	"turkey":      {"name":"Türkiye",    "emoji":"🇹🇷","code":"TR","row_m":4, "row_f":5, "cost":0},
	"usa":         {"name":"ABD",        "emoji":"🇺🇸","code":"US","row_m":6, "row_f":7, "cost":100},
	"germany":     {"name":"Almanya",    "emoji":"🇩🇪","code":"DE","row_m":8, "row_f":9, "cost":120},
	"japan":       {"name":"Japonya",    "emoji":"🇯🇵","code":"JP","row_m":10,"row_f":11,"cost":150},
	"france":      {"name":"Fransa",     "emoji":"🇫🇷","code":"FR","row_m":12,"row_f":13,"cost":180},
	"uk":          {"name":"İngiltere",  "emoji":"🇬🇧","code":"GB","row_m":14,"row_f":15,"cost":200},
	"brazil":      {"name":"Brezilya",   "emoji":"🇧🇷","code":"BR","row_m":16,"row_f":17,"cost":220},
	"spain":       {"name":"İspanya",    "emoji":"🇪🇸","code":"ES","row_m":18,"row_f":19,"cost":250},
	"italy":       {"name":"İtalya",     "emoji":"🇮🇹","code":"IT","row_m":20,"row_f":21,"cost":280},
	"russia":      {"name":"Rusya",      "emoji":"🇷🇺","code":"RU","row_m":22,"row_f":23,"cost":300},
	"china":       {"name":"Çin",        "emoji":"🇨🇳","code":"CN","row_m":24,"row_f":25,"cost":320},
	"south_korea": {"name":"G.Kore",     "emoji":"🇰🇷","code":"KR","row_m":2, "row_f":3, "cost":350},
	"mexico":      {"name":"Meksika",    "emoji":"🇲🇽","code":"MX","row_m":26,"row_f":27,"cost":380},
	"india":       {"name":"Hindistan",  "emoji":"🇮🇳","code":"IN","row_m":1, "row_f":2, "cost":400},
	"canada":      {"name":"Kanada",     "emoji":"🇨🇦","code":"CA","row_m":3, "row_f":4, "cost":420},
	"australia":   {"name":"Avustralya", "emoji":"🇦🇺","code":"AU","row_m":5, "row_f":6, "cost":450},
	"argentina":   {"name":"Arjantin",   "emoji":"🇦🇷","code":"AR","row_m":7, "row_f":8, "cost":480},
	"netherlands": {"name":"Hollanda",   "emoji":"🇳🇱","code":"NL","row_m":9, "row_f":10,"cost":500},
	"portugal":    {"name":"Portekiz",   "emoji":"🇵🇹","code":"PT","row_m":11,"row_f":12,"cost":520},
	"sweden":      {"name":"İsveç",      "emoji":"🇸🇪","code":"SE","row_m":13,"row_f":14,"cost":600},
}

# ════════════════════════════════════════════════════════════════
#  SİLAH VERİSİ  (id → name, icon, desc, cost, max_level)
# ════════════════════════════════════════════════════════════════
const WEAPONS: Dictionary = {
	"sword":      {"name":"Kılıç",          "icon":"⚔️", "desc":"Yakın dövüş. Geniş menzil.",   "cost":0,   "base_fire":0.65},
	"bow":        {"name":"Yay",            "icon":"🏹", "desc":"Uzak mesafe ok.",               "cost":0,   "base_fire":0.55},
	"pistol":     {"name":"Tabanca",        "icon":"🔫", "desc":"Dengeli mermi.",                "cost":150, "base_fire":0.50},
	"shotgun":    {"name":"Pompalı",        "icon":"💣", "desc":"5 pellet, kısa menzil.",        "cost":300, "base_fire":1.10},
	"machinegun": {"name":"Makineli",       "icon":"⚡", "desc":"Sürekli ateş, düşük hasar.",   "cost":400, "base_fire":0.10},
	"magic":      {"name":"Sihir",          "icon":"✨", "desc":"360° mermi.",                  "cost":500, "base_fire":1.80},
	"sniper":     {"name":"Keskin Nişancı", "icon":"🎯", "desc":"4× hasar, yavaş ateş.",        "cost":600, "base_fire":2.40},
}

const WEAPON_UPGRADE_COSTS := [0, 100, 250, 500, 800]  # lv1→2, lv2→3, lv3→4, lv4→5

const SAVE_PATH := "user://gamedata.cfg"


func _ready() -> void:
	load_data()
	# Kayıt yoksa başlangıç silahlarını ekle
	if owned_weapons.is_empty():
		owned_weapons["machinegun"] = 1


# ── Yardımcılar ────────────────────────────────────────────────
func get_equipped_weapon() -> String:
	if selected_character == "male":
		return equipped_weapon_male
	return equipped_weapon_female


func set_equipped_weapon(wid: String) -> void:
	if selected_character == "male":
		equipped_weapon_male = wid
	else:
		equipped_weapon_female = wid
	save_data()


func get_flag_row() -> int:
	var fid := equipped_flag if equipped_flag in FLAGS else "turkey"
	var f: Dictionary = FLAGS[fid]
	if selected_character == "male":
		return int(f.get("row_m", 4))
	return int(f.get("row_f", 5))


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


# ── Stats güncelle ─────────────────────────────────────────────
func record_game(wave: int, kills: int) -> void:
	total_games += 1
	total_kills += kills
	if wave > best_wave:
		best_wave = wave
	save_data()


# ════════════════════════════════════════════════════════════════
#  SAVE / LOAD
# ════════════════════════════════════════════════════════════════
func save_data() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("player", "xp_coins",            xp_coins)
	cfg.set_value("player", "selected_character",  selected_character)
	cfg.set_value("player", "equipped_flag",       equipped_flag)
	cfg.set_value("player", "owned_flags",         owned_flags)
	cfg.set_value("player", "owned_weapons",       owned_weapons)
	cfg.set_value("player", "equipped_weapon_male",   equipped_weapon_male)
	cfg.set_value("player", "equipped_weapon_female", equipped_weapon_female)
	cfg.set_value("player", "sound_enabled",       sound_enabled)
	cfg.set_value("stats",  "best_wave",           best_wave)
	cfg.set_value("stats",  "total_kills",         total_kills)
	cfg.set_value("stats",  "total_games",         total_games)
	cfg.set_value("stats",  "total_xp_earned",     total_xp_earned)
	cfg.save(SAVE_PATH)


func load_data() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	xp_coins           = cfg.get_value("player", "xp_coins",           0)
	selected_character = cfg.get_value("player", "selected_character", "male")
	equipped_flag      = cfg.get_value("player", "equipped_flag",      "turkey")
	owned_flags        = cfg.get_value("player", "owned_flags",        ["turkey"])
	owned_weapons      = cfg.get_value("player", "owned_weapons",      {"machinegun":1})
	equipped_weapon_male   = cfg.get_value("player", "equipped_weapon_male",   "machinegun")
	equipped_weapon_female = cfg.get_value("player", "equipped_weapon_female", "machinegun")
	sound_enabled      = cfg.get_value("player", "sound_enabled",      true)
	best_wave          = cfg.get_value("stats",  "best_wave",          0)
	total_kills        = cfg.get_value("stats",  "total_kills",        0)
	total_games        = cfg.get_value("stats",  "total_games",        0)
	total_xp_earned    = cfg.get_value("stats",  "total_xp_earned",   0)
