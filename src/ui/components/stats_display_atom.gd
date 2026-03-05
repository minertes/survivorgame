# 📊 STATS DISPLAY ATOM
# Oyuncu istatistiklerini gösteren atomic bileşen
class_name StatsDisplayAtom
extends Control

# === SIGNALS ===
signal stats_updated()

# === PROPERTIES ===
var player_stats: Dictionary = {
	"best_wave": 0,
	"total_kills": 0,
	"total_games": 0,
	"total_xp_earned": 0,
	"total_play_time": 0,
	"accuracy": 0.0,
	"survival_rate": 0.0
}

var character_stats: Dictionary = {
	"selected_character": "male_soldier",
	"character_level": 1,
	"character_xp": 0
}

var weapon_stats: Dictionary = {
	"selected_weapon": "machinegun",
	"weapon_level": 1,
	"total_damage": 0
}

# Backend / GameData ek istatistikler
var economy_stats: Dictionary = {
	"xp_coins": 0,
	"gems": 0,
	"prestige_level": 0,
	"battle_pass_level": 0,
	"login_streak": 0,
	"achievement_count": 0
}

# === UI REFERENCES ===
var _stats_container: VBoxContainer
var _character_stats_panel: Control
var _weapon_stats_panel: Control
var _economy_stats_panel: Control

# === LIFECYCLE ===

func _ready() -> void:
	_build_ui()
	_load_from_gamedata()
	_refresh_display()

# === PUBLIC API ===

func set_player_stats(stats: Dictionary) -> void:
	player_stats = stats
	if _stats_container != null:
		_refresh_display()

func set_character_stats(stats: Dictionary) -> void:
	character_stats = stats
	if _stats_container != null:
		_refresh_display()

func set_weapon_stats(stats: Dictionary) -> void:
	weapon_stats = stats
	if _stats_container != null:
		_refresh_display()

func update_stat(stat_name: String, value) -> void:
	if stat_name in player_stats:
		player_stats[stat_name] = value
	elif stat_name in character_stats:
		character_stats[stat_name] = value
	elif stat_name in weapon_stats:
		weapon_stats[stat_name] = value
	
	if _stats_container != null:
		_refresh_display()
	stats_updated.emit()

func get_all_stats() -> Dictionary:
	return {
		"player": player_stats.duplicate(),
		"character": character_stats.duplicate(),
		"weapon": weapon_stats.duplicate()
	}

## Tab görünür olduğunda GameData'dan yeniden yükle (oyundan dönünce güncel olsun)
func refresh() -> void:
	_load_from_gamedata()
	_refresh_display()

# === PRIVATE METHODS ===

func _build_ui() -> void:
	# Lobby zaten ScrollContainer ile sarıyor; iç içe scroll layout bozuyor
	var margin = MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.custom_minimum_size = Vector2(0, 500)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)
	
	_stats_container = VBoxContainer.new()
	_stats_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stats_container.add_theme_constant_override("separation", 20)
	margin.add_child(_stats_container)
	
	# Başlık
	var title_label = Label.new()
	title_label.text = "📊 İstatistikler"
	title_label.add_theme_font_size_override("font_size", 26)
	title_label.add_theme_color_override("font_color", Color(0.95, 0.85, 1.0))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats_container.add_child(title_label)
	
	# Alt başlık
	var subtitle = Label.new()
	subtitle.text = "Oyuncu ve seçim özeti"
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.7, 0.9))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats_container.add_child(subtitle)
	
	# Karakter istatistikleri paneli
	_character_stats_panel = _create_stats_panel("👤 Karakter")
	_stats_container.add_child(_character_stats_panel)
	
	# Silah istatistikleri paneli
	_weapon_stats_panel = _create_stats_panel("🔫 Silah")
	_stats_container.add_child(_weapon_stats_panel)
	
	# Genel istatistikler paneli
	var general_stats_panel = _create_stats_panel("🎮 Genel oyun")
	_stats_container.add_child(general_stats_panel)
	
	# Para & İlerleme paneli (backend: xp, gems, prestige, battle pass, streak, achievements)
	_economy_stats_panel = _create_stats_panel("💰 Para & İlerleme")
	_stats_container.add_child(_economy_stats_panel)

func _create_stats_panel(title: String) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 120)
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.08, 0.16, 0.92)
	panel_style.set_border_width_all(2)
	panel_style.border_color = Color(0.35, 0.25, 0.55, 0.7)
	panel_style.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", panel_style)
	
	var inner_margin = MarginContainer.new()
	inner_margin.add_theme_constant_override("margin_left", 16)
	inner_margin.add_theme_constant_override("margin_right", 16)
	inner_margin.add_theme_constant_override("margin_top", 12)
	inner_margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(inner_margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	inner_margin.add_child(vbox)
	
	# Panel başlığı
	var title_label = Label.new()
	title_label.name = "PanelTitle"
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.add_theme_color_override("font_color", Color(0.9, 0.8, 1.0))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)
	
	# İstatistikler container'ı
	var stats_grid = GridContainer.new()
	stats_grid.name = "StatsGrid"
	stats_grid.columns = 2
	stats_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_grid.add_theme_constant_override("h_separation", 24)
	stats_grid.add_theme_constant_override("v_separation", 10)
	vbox.add_child(stats_grid)
	
	return panel

func _load_from_gamedata() -> void:
	if not is_inside_tree():
		return
	var gd = get_node_or_null("/root/GameData")
	if not gd:
		return
	# Genel oyun istatistikleri (backend ile senkron)
	player_stats["best_wave"] = gd.best_wave
	player_stats["total_kills"] = gd.total_kills
	player_stats["total_games"] = gd.total_games
	player_stats["total_xp_earned"] = gd.total_xp_earned
	player_stats["total_play_time"] = gd.total_play_time
	player_stats["accuracy"] = gd.accuracy
	player_stats["survival_rate"] = gd.survival_rate
	# Karakter
	var char_id: String = gd.selected_character
	var char_data = gd.CHARACTERS.get(char_id, {})
	character_stats["selected_character"] = char_data.get("name", char_id)
	character_stats["character_level"] = gd.character_levels.get(char_id, 1)
	character_stats["character_xp"] = 0  # GameData'da yok
	# Silah
	var weap_id: String = gd.equipped_weapon
	var weap_data = gd.WEAPONS.get(weap_id, {})
	weapon_stats["selected_weapon"] = weap_data.get("name", weap_id)
	weapon_stats["weapon_level"] = gd.owned_weapons.get(weap_id, 1)
	var mults = weap_data.get("upgrade_multipliers", [1.0])
	var base_dmg = weap_data.get("base_damage", 0)
	var lv = weapon_stats["weapon_level"]
	weapon_stats["total_damage"] = int(base_dmg * mults[min(lv - 1, mults.size() - 1)])
	# Para & İlerleme
	economy_stats["xp_coins"] = gd.xp_coins
	economy_stats["gems"] = gd.gems
	economy_stats["prestige_level"] = gd.prestige_level
	economy_stats["battle_pass_level"] = gd.battle_pass_level
	economy_stats["login_streak"] = gd.login_streak
	economy_stats["achievement_count"] = gd.achievement_unlocked.size()

func _refresh_display() -> void:
	if _stats_container == null:
		return
	_update_stats_panel(_character_stats_panel, _get_character_stats_data())
	_update_stats_panel(_weapon_stats_panel, _get_weapon_stats_data())
	var general_panel = _stats_container.get_child(4) if _stats_container.get_child_count() > 4 else null
	if general_panel and general_panel is PanelContainer:
		_update_stats_panel(general_panel, _get_general_stats_data())
	if _economy_stats_panel:
		_update_stats_panel(_economy_stats_panel, _get_economy_stats_data())

func _update_stats_panel(panel: Control, stats_data: Array) -> void:
	if panel == null:
		return
	# Panel: MarginContainer -> VBoxContainer -> [Title, StatsGrid]
	var inner = panel.get_child(0) if panel.get_child_count() > 0 else null
	var vbox = inner.get_child(0) if inner and inner.get_child_count() > 0 else null
	var stats_grid = vbox.get_node_or_null("StatsGrid") as GridContainer if vbox else null
	if not stats_grid:
		return
	
	# Eski istatistikleri temizle
	for child in stats_grid.get_children():
		child.queue_free()
	
	# Yeni istatistikleri ekle
	for stat_item in stats_data:
		var stat_name = stat_item["name"]
		var stat_value = stat_item["value"]
		var stat_color = stat_item.get("color", Color(0.9, 0.9, 0.9))
		
		# İstatistik adı
		var name_label = Label.new()
		name_label.text = stat_name
		name_label.add_theme_font_size_override("font_size", 14)
		name_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.9))
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		stats_grid.add_child(name_label)
		
		# İstatistik değeri
		var value_label = Label.new()
		value_label.text = str(stat_value)
		value_label.add_theme_font_size_override("font_size", 14)
		value_label.add_theme_color_override("font_color", stat_color)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		stats_grid.add_child(value_label)

func _get_character_stats_data() -> Array:
	return [
		{"name": "Seçili Karakter", "value": character_stats.get("selected_character", "N/A"), "color": Color(0.6, 0.8, 1.0)},
		{"name": "Karakter Seviyesi", "value": "LV %d" % character_stats.get("character_level", 1), "color": Color(1.0, 0.9, 0.3)},
		{"name": "Karakter XP", "value": "%d XP" % character_stats.get("character_xp", 0), "color": Color(0.8, 0.6, 1.0)},
		{"name": "Toplam Oyun", "value": player_stats.get("total_games", 0), "color": Color(0.7, 0.9, 0.7)},
		{"name": "Hayatta Kalma Oranı", "value": "%.1f%%" % (player_stats.get("survival_rate", 0.0) * 100), "color": Color(0.3, 1.0, 0.3)}
	]

func _get_weapon_stats_data() -> Array:
	return [
		{"name": "Seçili Silah", "value": weapon_stats.get("selected_weapon", "N/A"), "color": Color(1.0, 0.7, 0.7)},
		{"name": "Silah Seviyesi", "value": "LV %d" % weapon_stats.get("weapon_level", 1), "color": Color(1.0, 0.8, 0.4)},
		{"name": "Toplam Hasar", "value": "%d" % weapon_stats.get("total_damage", 0), "color": Color(1.0, 0.5, 0.5)},
		{"name": "İsabet Oranı", "value": "%.1f%%" % (player_stats.get("accuracy", 0.0) * 100), "color": Color(0.8, 0.8, 0.4)},
		{"name": "En İyi Dalga", "value": player_stats.get("best_wave", 0), "color": Color(1.0, 0.9, 0.2)}
	]

func _get_general_stats_data() -> Array:
	var play_time_sec = player_stats.get("total_play_time", 0)
	var total_min = int(play_time_sec / 60)
	var hours = int(total_min / 60)
	var minutes = total_min % 60
	
	return [
		{"name": "Toplam Öldürme", "value": player_stats.get("total_kills", 0), "color": Color(1.0, 0.6, 0.6)},
		{"name": "Toplam Kazanılan XP", "value": player_stats.get("total_xp_earned", 0), "color": Color(1.0, 0.9, 0.3)},
		{"name": "Toplam Oyun Süresi", "value": "%d:%02d" % [hours, minutes], "color": Color(0.6, 0.8, 1.0)},
		{"name": "Ortalama Dalga", "value": "%.1f" % (float(player_stats.get("best_wave", 0)) / max(1, player_stats.get("total_games", 1))), "color": Color(0.8, 0.6, 1.0)},
		{"name": "Ortalama Öldürme/Oyun", "value": "%.1f" % (float(player_stats.get("total_kills", 0)) / max(1, player_stats.get("total_games", 1))), "color": Color(0.7, 0.9, 0.7)}
	]

func _get_economy_stats_data() -> Array:
	return [
		{"name": "XP (Para)", "value": economy_stats.get("xp_coins", 0), "color": Color(1.0, 0.9, 0.3)},
		{"name": "Gems", "value": economy_stats.get("gems", 0), "color": Color(0.6, 0.8, 1.0)},
		{"name": "Prestij Seviyesi", "value": economy_stats.get("prestige_level", 0), "color": Color(0.9, 0.7, 1.0)},
		{"name": "Battle Pass", "value": "LV %d" % economy_stats.get("battle_pass_level", 0), "color": Color(0.8, 0.6, 1.0)},
		{"name": "Giriş Serisi", "value": economy_stats.get("login_streak", 0), "color": Color(0.3, 1.0, 0.5)},
		{"name": "Açılan Başarılar", "value": economy_stats.get("achievement_count", 0), "color": Color(1.0, 0.8, 0.4)}
	]

func _create_stat_row(stat_name: String, stat_value, color: Color = Color(0.9, 0.9, 0.9)) -> Control:
	var row = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# İstatistik adı
	var name_label = Label.new()
	name_label.text = stat_name
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.9))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	
	# İstatistik değeri
	var value_label = Label.new()
	value_label.text = str(stat_value)
	value_label.add_theme_font_size_override("font_size", 14)
	value_label.add_theme_color_override("font_color", color)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value_label)
	
	return row

# === DEBUG ===
func print_debug_info() -> void:
	print("=== StatsDisplayAtom ===")
	print("Player Stats: %s" % player_stats)
	print("Character Stats: %s" % character_stats)
	print("Weapon Stats: %s" % weapon_stats)