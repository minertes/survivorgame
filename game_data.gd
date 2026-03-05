extends Node
# ── GameData: Persistent player data (save/load between sessions) ──────────

# ── Currency ──────────────────────────────────────────────────
const DEFAULT_STARTING_XP := 10000  # Test için varsayılan başlangıç XP
var xp_coins     := 10000   # Oyunda kazanılan XP = para (varsayılan 10000 test için)

# Faz 4.5 – Premium para birimi (gems); client + cloud, harcama kaydı
var gems := 0
var gem_spend_log: Array = []  # {ts, amount, reason, product_id?}; son N kayıt tutulabilir
const GEM_SPEND_LOG_MAX := 200

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

# Faz 1.2.5 – Tutorial: ilk açılışta gösterildi mi
var tutorial_completed := false

# Faz 5.2 – Başarılar: ilerleme ve açılan rozetler
var achievement_progress: Dictionary = {}  # achievement_id -> sayısal değer
var achievement_unlocked: Array = []       # açılan achievement id'leri

# Faz 5.3 – Günlük ödüller: giriş serisi (streak), claim ve saklama
var last_login_ymd: String = ""    # "YYYY-MM-DD"
var login_streak: int = 0          # ardışık gün sayısı
var last_claim_ymd: String = ""    # son claim tarihi
var claimed_day_index: int = -1    # bu streak'te kaçıncı gün claim edildi (0..6 veya 0..27)

# Faz 7.2 – Prestij / meta ilerleme (sonsuz mod)
var prestige_level: int = 0
# Faz 7.1 – Günlük meydan okuma ödülü (günde bir kez)
var daily_challenge_claimed_ymd: String = ""

# Orta vade – Günlük görevler (plan: Daily Quests)
var daily_quests_ymd: String = ""       # Bugünkü görevlerin tarihi
var daily_quests: Array = []            # [{id, type, target, progress, reward_xp, reward_gems, claimed}]

# Orta vade – Battle Pass iskeleti
var battle_pass_season: int = 1
var battle_pass_level: int = 0
var battle_pass_xp: int = 0
var battle_pass_premium: bool = false

# Orta vade – Cosmetic (skin) altyapısı; grafikler sizde hook'lanacak
var character_skin_id: String = "default"
var weapon_skin_id: String = "default"
var owned_character_skins: Array = ["default"]
var owned_weapon_skins: Array = ["default"]

# Orta vade – VIP / abonelik (IAP sonrası set edilir)
var is_vip: bool = false
var vip_expires_at: int = 0             # Unix timestamp

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
	},
	# Faz 7.4 – Ek karakter
	"medic": {
		"name": "COMBAT MEDIC",
		"description": "Can yenileme, orta hasar",
		"cost": 1200,
		"unlocked_by_default": false,
		"stats": {
			"health": 140,
			"speed": 1.1,
			"armor": "medium",
			"ability": "Heal Burst"
		},
		"sprite_row": 3
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
	},
	# Faz 7.4 – Ek silah
	"flamethrower": {
		"name": "Alev Makinesi",
		"icon": "🔥",
		"description": "Sürekli alev, alan hasarı",
		"cost": 900,
		"base_fire_rate": 0.05,
		"base_damage": 6,
		"upgrade_multipliers": [1.0, 1.35, 1.8, 2.3, 2.9],
		"special": "Burn DoT"
	}
}

const WEAPON_UPGRADE_COSTS := [100, 250, 500, 800]  # lv1→2, lv2→3, lv3→4, lv4→5

const SAVE_PATH := "user://gamedata.cfg"
# Faz 3.1.2 – Kayıt bozulmasına karşı yedek dosya
const BACKUP_PATH := "user://gamedata_backup.cfg"


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
	var mult := get_daily_event_xp_multiplier()
	amount = int(amount * mult)
	xp_coins += amount
	total_xp_earned += amount
	save_data()

func spend_xp(amount: int) -> bool:
	if xp_coins < amount:
		return false
	xp_coins -= amount
	save_data()
	return true

# ── Gems (Faz 4.5) ─────────────────────────────────────────────
func add_gems(amount: int, reason: String = "iap", product_id: String = "") -> void:
	if amount <= 0:
		return
	gems += amount
	save_data()

func spend_gems(amount: int, reason: String = "spend", product_id: String = "") -> bool:
	if gems < amount or amount <= 0:
		return false
	gems -= amount
	var entry := {
		"ts": Time.get_unix_time_from_system(),
		"amount": amount,
		"reason": reason,
		"product_id": product_id
	}
	gem_spend_log.append(entry)
	while gem_spend_log.size() > GEM_SPEND_LOG_MAX:
		gem_spend_log.pop_front()
	save_data()
	return true

# ── Karakter satın al (YENİ) ───────────────────────────────────
func buy_character(character_id: String) -> bool:
	if character_id in owned_characters:
		return false
	if character_id not in CHARACTERS:
		return false
	var char_data: Dictionary = CHARACTERS[character_id]
	var cost: int = int(char_data.get("cost", 0))
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
	var cost: int = int(fd.get("cost", 0))
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
	var cost: int = int(wd.get("cost", 0))
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
	var lv: int = int(owned_weapons.get(wid, 1))
	if lv >= 5:
		return false
	var cost := int(WEAPON_UPGRADE_COSTS[lv - 1])
	if not spend_xp(cost):
		return false
	owned_weapons[wid] = lv + 1
	update_daily_quest_progress("upgrade_weapon", 1)
	save_data()
	return true

func get_weapon_level(wid: String) -> int:
	return owned_weapons.get(wid, 0)

# Faz 3.2.3 – Buluttan çekilen veriyi uygula (son yazma kazanır veya merge)
func apply_cloud_data(data: Dictionary) -> void:
	if data.get("xp_coins") != null:
		xp_coins = int(data.xp_coins)
	if data.get("selected_character") != null:
		selected_character = str(data.selected_character)
	if data.get("owned_characters") != null:
		owned_characters = data.owned_characters
	if data.get("owned_weapons") != null:
		owned_weapons = data.owned_weapons
	if data.get("equipped_weapon") != null:
		equipped_weapon = str(data.equipped_weapon)
	if data.get("equipped_flag") != null:
		equipped_flag = str(data.equipped_flag)
	if data.get("owned_flags") != null:
		owned_flags = data.owned_flags
	if data.get("best_wave") != null:
		best_wave = int(data.best_wave)
	if data.get("total_kills") != null:
		total_kills = int(data.total_kills)
	if data.get("total_games") != null:
		total_games = int(data.total_games)
	if data.get("sound_enabled") != null:
		sound_enabled = bool(data.sound_enabled)
	if data.get("gems") != null:
		gems = int(data.gems)
	if data.get("gem_spend_log") != null:
		gem_spend_log = data.gem_spend_log
	if data.get("achievement_unlocked") != null:
		achievement_unlocked = data.achievement_unlocked
	if data.get("last_login_ymd") != null:
		last_login_ymd = str(data.last_login_ymd)
	if data.get("login_streak") != null:
		login_streak = int(data.login_streak)
	if data.get("last_claim_ymd") != null:
		last_claim_ymd = str(data.last_claim_ymd)
	if data.get("claimed_day_index") != null:
		claimed_day_index = int(data.claimed_day_index)
	if data.get("prestige_level") != null:
		prestige_level = int(data.prestige_level)
	if data.get("daily_challenge_claimed_ymd") != null:
		daily_challenge_claimed_ymd = str(data.daily_challenge_claimed_ymd)
	if data.get("daily_quests_ymd") != null:
		daily_quests_ymd = str(data.daily_quests_ymd)
	if data.get("daily_quests") != null:
		daily_quests = data.daily_quests
	if data.get("battle_pass_season") != null:
		battle_pass_season = int(data.battle_pass_season)
	if data.get("battle_pass_level") != null:
		battle_pass_level = int(data.battle_pass_level)
	if data.get("battle_pass_xp") != null:
		battle_pass_xp = int(data.battle_pass_xp)
	if data.get("battle_pass_premium") != null:
		battle_pass_premium = bool(data.battle_pass_premium)
	if data.get("character_skin_id") != null:
		character_skin_id = str(data.character_skin_id)
	if data.get("weapon_skin_id") != null:
		weapon_skin_id = str(data.weapon_skin_id)
	if data.get("owned_character_skins") != null:
		owned_character_skins = data.owned_character_skins
	if data.get("owned_weapon_skins") != null:
		owned_weapon_skins = data.owned_weapon_skins
	if data.get("is_vip") != null:
		is_vip = bool(data.is_vip)
	if data.get("vip_expires_at") != null:
		vip_expires_at = int(data.vip_expires_at)
	save_data()

# Faz 5.3 – Günlük ödül: state ve claim
func _get_today_ymd() -> String:
	var d := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [d.year, d.month, d.day]

func get_daily_reward_state() -> Dictionary:
	var today := _get_today_ymd()
	var can_claim := false
	var streak := login_streak
	var day_index := claimed_day_index
	var reward_xp := 50
	var reward_gems := 0
	if last_claim_ymd.is_empty():
		can_claim = true
		day_index = 0
		reward_xp = 50 + streak * 10
	elif last_claim_ymd == today:
		day_index = claimed_day_index
		reward_xp = 50 + streak * 10
	else:
		var last_ts := _ymd_to_unix(last_claim_ymd)
		var today_ts := _ymd_to_unix(today)
		var diff_days := int((today_ts - last_ts) / 86400)
		if diff_days == 1:
			can_claim = true
			streak = login_streak + 1
			day_index = (claimed_day_index + 1) % 7
			reward_xp = 50 + streak * 10
			if day_index == 6:
				reward_gems = 5
		elif diff_days > 1:
			can_claim = true
			streak = 1
			day_index = 0
			reward_xp = 50
		else:
			day_index = claimed_day_index
			reward_xp = 50 + streak * 10
	return {"can_claim": can_claim, "streak": streak, "day_index": day_index, "reward_xp": reward_xp, "reward_gems": reward_gems, "today": today}

func _ymd_to_unix(ymd: String) -> int:
	var parts := ymd.split("-")
	if parts.size() != 3:
		return 0
	var d: Dictionary = Time.get_datetime_dict_from_datetime_string(ymd + "T12:00:00", false)
	return Time.get_unix_time_from_datetime_dict(d)

func claim_daily_reward() -> Dictionary:
	var state = get_daily_reward_state()
	if not state.can_claim:
		return {"success": false, "reason": "already_claimed"}
	var today := _get_today_ymd()
	var new_streak: int = state.streak
	var new_day_index: int = state.day_index
	if last_claim_ymd.is_empty():
		new_streak = 1
		new_day_index = 0
	elif last_claim_ymd != today:
		var last_ts := _ymd_to_unix(last_claim_ymd)
		var today_ts := _ymd_to_unix(today)
		var diff_days := int((today_ts - last_ts) / 86400)
		if diff_days == 1:
			new_streak = login_streak + 1
			new_day_index = (claimed_day_index + 1) % 7
		else:
			new_streak = 1
			new_day_index = 0
	last_claim_ymd = today
	login_streak = new_streak
	claimed_day_index = new_day_index
	add_xp(state.reward_xp)
	if state.reward_gems > 0:
		add_gems(state.reward_gems, "daily_reward", "")
	save_data()
	return {"success": true, "xp": state.reward_xp, "gems": state.reward_gems, "streak": new_streak}

# Faz 7.1 – Günlük meydan okuma tohumu (tarih bazlı, her gün aynı)
func get_daily_challenge_seed() -> int:
	var d := Time.get_date_dict_from_system()
	var ymd := "%04d%02d%02d" % [d.year, d.month, d.day]
	return ymd.hash()

# Faz 7.2 – Prestij bonusu (% hasar/can artışı)
func get_prestige_bonus() -> float:
	return 1.0 + prestige_level * 0.02

# Prestij yapılabilir mi (en az bir kez dalga 30’a ulaşılmış olmalı)
func can_do_prestige() -> bool:
	return best_wave >= 30

# Prestij yap: seviye artar, bonus kalıcı uygulanır (skor sıfırlanmaz)
func do_prestige() -> bool:
	if not can_do_prestige():
		return false
	prestige_level += 1
	save_data()
	return true

# Faz 7.1 – Günlük meydan okuma ödülü (dalga 5+ tamamlanınca bir kez/gün)
func can_claim_daily_challenge_reward() -> bool:
	return daily_challenge_claimed_ymd != _get_today_ymd()

func claim_daily_challenge_reward(wave_reached: int) -> Dictionary:
	var today := _get_today_ymd()
	if daily_challenge_claimed_ymd == today:
		return {"success": false, "reason": "already_claimed"}
	if wave_reached < 5:
		return {"success": false, "reason": "need_wave_5"}
	daily_challenge_claimed_ymd = today
	var bonus_xp := 200 + wave_reached * 15
	var bonus_gems := 3
	add_xp(bonus_xp)
	add_gems(bonus_gems, "daily_challenge", "")
	save_data()
	return {"success": true, "xp": bonus_xp, "gems": bonus_gems}

# Girişte çağrılır (menü açıldığında): son giriş tarihini güncelle, streak kontrolü
func on_login_tick() -> void:
	var today := _get_today_ymd()
	if last_login_ymd != today:
		if not last_login_ymd.is_empty():
			var last_ts := _ymd_to_unix(last_login_ymd)
			var today_ts := _ymd_to_unix(today)
			var diff_days := int((today_ts - last_ts) / 86400)
			if diff_days > 1:
				login_streak = 0
		last_login_ymd = today
		_refresh_daily_quests_if_new_day()
		save_data()

# ── Günlük görevler (orta vade) ─────────────────────────────────
const DAILY_QUEST_TYPES := {
	"play_games": {"name": "3 oyun oyna", "target": 3, "reward_xp": 80, "reward_gems": 0},
	"kill_enemies": {"name": "100 düşman öldür", "target": 100, "reward_xp": 100, "reward_gems": 1},
	"reach_wave": {"name": "Dalga 10'a ulaş", "target": 10, "reward_xp": 120, "reward_gems": 1},
	"upgrade_weapon": {"name": "1 silah yükselt", "target": 1, "reward_xp": 60, "reward_gems": 0},
	"share_score": {"name": "Skoru paylaş", "target": 1, "reward_xp": 50, "reward_gems": 0}
}

func _refresh_daily_quests_if_new_day() -> void:
	var today := _get_today_ymd()
	if daily_quests_ymd == today and daily_quests.size() > 0:
		return
	daily_quests_ymd = today
	var types := DAILY_QUEST_TYPES.keys()
	var seed_val := today.hash()
	daily_quests.clear()
	var chosen: Array = []
	for _attempt in 20:
		if chosen.size() >= 3:
			break
		var idx := (seed_val + _attempt * 31) % types.size()
		if idx < 0:
			idx += types.size()
		var qt: String = types[idx]
		if qt not in chosen:
			chosen.append(qt)
	for i in range(chosen.size()):
		var qt: String = chosen[i]
		var def: Dictionary = DAILY_QUEST_TYPES[qt]
		daily_quests.append({
			"id": "dq_%s_%d" % [qt, i],
			"type": qt,
			"name": def.name,
			"target": def.target,
			"progress": 0,
			"reward_xp": def.reward_xp,
			"reward_gems": def.reward_gems,
			"claimed": false
		})
	save_data()

func get_daily_quests() -> Array:
	if daily_quests_ymd != _get_today_ymd():
		_refresh_daily_quests_if_new_day()
	return daily_quests

func update_daily_quest_progress(quest_type: String, delta: int = 1) -> void:
	if daily_quests_ymd != _get_today_ymd():
		_refresh_daily_quests_if_new_day()
	for q in daily_quests:
		if q.type == quest_type and not q.claimed:
			q.progress = mini(q.progress + delta, q.target)
	save_data()

func claim_daily_quest(quest_id: String) -> Dictionary:
	for q in daily_quests:
		if q.id == quest_id and q.progress >= q.target and not q.claimed:
			q.claimed = true
			add_xp(q.reward_xp)
			if q.reward_gems > 0:
				add_gems(q.reward_gems, "daily_quest", quest_id)
			save_data()
			return {"success": true, "xp": q.reward_xp, "gems": q.reward_gems}
	return {"success": false}

# ── Battle Pass iskeleti (orta vade) ───────────────────────────
const BATTLE_PASS_XP_PER_LEVEL := 500
const BATTLE_PASS_MAX_LEVEL := 30

func add_battle_pass_xp(amount: int) -> void:
	if amount <= 0:
		return
	battle_pass_xp += amount
	while battle_pass_level < BATTLE_PASS_MAX_LEVEL and battle_pass_xp >= BATTLE_PASS_XP_PER_LEVEL:
		battle_pass_xp -= BATTLE_PASS_XP_PER_LEVEL
		battle_pass_level += 1
	save_data()

func get_battle_pass_reward_for_level(lv: int, is_premium: bool) -> Dictionary:
	# Slot tanımı; grafik/gerçek ödül siz ekleyebilirsiniz
	if is_premium:
		return {"type": "premium", "level": lv, "xp": 100 + lv * 10, "gems": 5 if lv % 5 == 0 else 0}
	return {"type": "free", "level": lv, "xp": 50 + lv * 5, "gems": 0}

# ── Cosmetic / Skin (orta vade) ────────────────────────────────
func set_character_skin(skin_id: String) -> bool:
	if skin_id in owned_character_skins:
		character_skin_id = skin_id
		save_data()
		return true
	return false

func set_weapon_skin(skin_id: String) -> bool:
	if skin_id in owned_weapon_skins:
		weapon_skin_id = skin_id
		save_data()
		return true
	return false

func unlock_character_skin(skin_id: String) -> void:
	if skin_id not in owned_character_skins:
		owned_character_skins.append(skin_id)
		save_data()

func unlock_weapon_skin(skin_id: String) -> void:
	if skin_id not in owned_weapon_skins:
		owned_weapon_skins.append(skin_id)
		save_data()

# ── VIP (orta vade; IAP sonrası set edilir) ─────────────────────
func set_vip(expires_unix: int) -> void:
	is_vip = expires_unix > Time.get_unix_time_from_system()
	vip_expires_at = expires_unix
	save_data()

func is_vip_active() -> bool:
	if not is_vip:
		return false
	if vip_expires_at > 0 and Time.get_unix_time_from_system() >= vip_expires_at:
		is_vip = false
		save_data()
		return false
	return true

# ── Günlük etkinlik çarpanı (double XP saati vb.) ───────────────
func get_daily_event_xp_multiplier() -> float:
	var now: Dictionary = Time.get_time_dict_from_system()
	var hour: int = now.hour
	# Örnek: 19:00–20:00 arası 2x XP (grafik/bildirim sizde)
	if hour == 19:
		return 2.0
	return 1.0

# ── Stats güncelle ─────────────────────────────────────────────
func record_game(wave: int, kills: int, play_time: int, shots_fired: int, shots_hit: int) -> void:
	total_games += 1
	total_kills += kills
	total_play_time += play_time
	
	if wave > best_wave:
		best_wave = wave
	
	# Günlük görev ilerlemesi
	update_daily_quest_progress("play_games", 1)
	update_daily_quest_progress("kill_enemies", kills)
	if wave >= 10:
		update_daily_quest_progress("reach_wave", 1)
	
	# Battle Pass XP (oyun başı + dalga/kill bonusu)
	add_battle_pass_xp(50 + wave * 5 + kills)
	
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
#  SAVE / LOAD (Faz 3.1.1–3.1.2: checksum + yedek)
# ════════════════════════════════════════════════════════════════
func save_data() -> void:
	# Yedek: mevcut kayıt varsa önce yedekle
	if FileAccess.file_exists(SAVE_PATH):
		_copy_file(SAVE_PATH, BACKUP_PATH)

	var cfg := ConfigFile.new()
	# Player data
	cfg.set_value("player", "xp_coins",            xp_coins)
	cfg.set_value("player", "selected_character",  selected_character)
	cfg.set_value("player", "owned_characters",    owned_characters)
	cfg.set_value("player", "character_levels",     character_levels)
	cfg.set_value("player", "equipped_flag",       equipped_flag)
	cfg.set_value("player", "owned_flags",         owned_flags)
	cfg.set_value("player", "owned_weapons",       owned_weapons)
	cfg.set_value("player", "equipped_weapon",     equipped_weapon)
	cfg.set_value("player", "sound_enabled",       sound_enabled)
	cfg.set_value("player", "tutorial_completed", tutorial_completed)
	cfg.set_value("player", "gems",                gems)
	cfg.set_value("player", "gem_spend_log",       gem_spend_log)
	cfg.set_value("player", "achievement_unlocked", achievement_unlocked)
	cfg.set_value("player", "last_login_ymd",      last_login_ymd)
	cfg.set_value("player", "login_streak",        login_streak)
	cfg.set_value("player", "last_claim_ymd",      last_claim_ymd)
	cfg.set_value("player", "claimed_day_index",   claimed_day_index)
	cfg.set_value("player", "prestige_level",      prestige_level)
	cfg.set_value("player", "daily_challenge_claimed_ymd", daily_challenge_claimed_ymd)
	cfg.set_value("player", "daily_quests_ymd",   daily_quests_ymd)
	cfg.set_value("player", "daily_quests",       daily_quests)
	cfg.set_value("player", "battle_pass_season", battle_pass_season)
	cfg.set_value("player", "battle_pass_level",  battle_pass_level)
	cfg.set_value("player", "battle_pass_xp",     battle_pass_xp)
	cfg.set_value("player", "battle_pass_premium", battle_pass_premium)
	cfg.set_value("player", "character_skin_id", character_skin_id)
	cfg.set_value("player", "weapon_skin_id",     weapon_skin_id)
	cfg.set_value("player", "owned_character_skins", owned_character_skins)
	cfg.set_value("player", "owned_weapon_skins", owned_weapon_skins)
	cfg.set_value("player", "is_vip",             is_vip)
	cfg.set_value("player", "vip_expires_at",     vip_expires_at)
	# Stats
	cfg.set_value("stats",  "best_wave",           best_wave)
	cfg.set_value("stats",  "total_kills",         total_kills)
	cfg.set_value("stats",  "total_games",         total_games)
	cfg.set_value("stats",  "total_xp_earned",     total_xp_earned)
	cfg.set_value("stats",  "total_play_time",     total_play_time)
	cfg.set_value("stats",  "accuracy",            accuracy)
	cfg.set_value("stats",  "survival_rate",       survival_rate)

	var checksum := _compute_save_checksum(cfg)
	cfg.set_value("meta", "checksum", checksum)
	cfg.save(SAVE_PATH)


func _compute_save_checksum(cfg: ConfigFile) -> String:
	var parts: PackedStringArray = []
	for section in ["player", "stats"]:
		if not cfg.has_section(section):
			continue
		for key in cfg.get_section_keys(section):
			var val = cfg.get_value(section, key, null)
			parts.append("%s.%s=%s" % [section, key, str(val)])
	parts.sort()
	var joined := "".join(parts)
	return joined.sha256_text().left(32)


func _copy_file(src: String, dst: String) -> void:
	var f := FileAccess.open(src, FileAccess.READ)
	if f == null:
		return
	var buf := f.get_buffer(f.get_length())
	f.close()
	var w := FileAccess.open(dst, FileAccess.WRITE)
	if w == null:
		return
	w.store_buffer(buf)
	w.close()

func load_data() -> void:
	var loaded := _load_from_file(SAVE_PATH)
	if not loaded.success:
		# Yedekten dene (Faz 3.1.2)
		if FileAccess.file_exists(BACKUP_PATH):
			loaded = _load_from_file(BACKUP_PATH)
			if loaded.success:
				print("Game data loaded from backup (main file missing or corrupted)")
				save_data()
		if not loaded.success:
			print("No saved data found, using defaults (including %d XP for testing)" % DEFAULT_STARTING_XP)
			xp_coins = DEFAULT_STARTING_XP
			return

	var cfg: ConfigFile = loaded.cfg
	# Player data
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
	tutorial_completed = cfg.get_value("player", "tutorial_completed",  false)
	gems               = cfg.get_value("player", "gems",               0)
	gem_spend_log      = cfg.get_value("player", "gem_spend_log",      [])
	achievement_unlocked = cfg.get_value("player", "achievement_unlocked", [])
	last_login_ymd    = cfg.get_value("player", "last_login_ymd",       "")
	login_streak      = cfg.get_value("player", "login_streak",        0)
	last_claim_ymd    = cfg.get_value("player", "last_claim_ymd",       "")
	claimed_day_index = cfg.get_value("player", "claimed_day_index",   -1)
	prestige_level    = cfg.get_value("player", "prestige_level",       0)
	daily_challenge_claimed_ymd = cfg.get_value("player", "daily_challenge_claimed_ymd", "")
	daily_quests_ymd   = cfg.get_value("player", "daily_quests_ymd",   "")
	daily_quests       = cfg.get_value("player", "daily_quests",       [])
	battle_pass_season = cfg.get_value("player", "battle_pass_season", 1)
	battle_pass_level  = cfg.get_value("player", "battle_pass_level",  0)
	battle_pass_xp     = cfg.get_value("player", "battle_pass_xp",     0)
	battle_pass_premium= cfg.get_value("player", "battle_pass_premium", false)
	character_skin_id  = cfg.get_value("player", "character_skin_id", "default")
	weapon_skin_id     = cfg.get_value("player", "weapon_skin_id",     "default")
	owned_character_skins = cfg.get_value("player", "owned_character_skins", ["default"])
	owned_weapon_skins = cfg.get_value("player", "owned_weapon_skins", ["default"])
	is_vip             = cfg.get_value("player", "is_vip",             false)
	vip_expires_at     = cfg.get_value("player", "vip_expires_at",     0)
	# Stats
	best_wave          = cfg.get_value("stats",  "best_wave",          0)
	total_kills        = cfg.get_value("stats",  "total_kills",        0)
	total_games        = cfg.get_value("stats",  "total_games",        0)
	total_xp_earned    = cfg.get_value("stats",  "total_xp_earned",   0)
	total_play_time    = cfg.get_value("stats",  "total_play_time",    0)
	accuracy           = cfg.get_value("stats",  "accuracy",          0.0)
	survival_rate      = cfg.get_value("stats",  "survival_rate",     0.0)

	if xp_coins <= 0:
		xp_coins = DEFAULT_STARTING_XP
		save_data()
		print("Game data: XP was 0, set to %d and saved" % xp_coins)

	print("Game data loaded successfully")


func _load_from_file(path: String) -> Dictionary:
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return {"success": false, "cfg": null}
	# Bütünlük: meta.checksum ile doğrula (Faz 3.1.2)
	var stored_checksum: String = cfg.get_value("meta", "checksum", "")
	if stored_checksum.is_empty():
		return {"success": true, "cfg": cfg}
	var expected := _compute_save_checksum(cfg)
	if expected != stored_checksum:
		return {"success": false, "cfg": null}
	return {"success": true, "cfg": cfg}