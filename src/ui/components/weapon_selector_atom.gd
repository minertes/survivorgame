# 🔫 WEAPON SELECTOR ATOM
# Silah seçimi ve yükseltme için atomic bileşen
@tool
class_name WeaponSelectorAtom
extends Control

# === SIGNALS ===
signal weapon_selected(weapon_id: String)
signal weapon_purchased(weapon_id: String)
signal weapon_upgraded(weapon_id: String, new_level: int)
signal weapon_preview_requested(weapon_id: String)

# === CONSTANTS ===
const WEAPONS: Dictionary = {
	"machinegun": {
		"name": "MAKİNELİ TÜFEK",
		"description": "Hızlı ateş, düşük hasar",
		"icon": "⚡",
		"cost": 0,
		"unlocked_by_default": true,
		"base_fire_rate": 0.1,
		"base_damage": 8,
		"upgrade_multipliers": [1.0, 1.2, 1.5, 1.8, 2.2],
		"special": "Rapid Fire"
	},
	"shotgun": {
		"name": "POMPALI TÜFEK",
		"description": "5 mermi, kısa menzil",
		"icon": "💣",
		"cost": 300,
		"unlocked_by_default": false,
		"base_fire_rate": 1.1,
		"base_damage": 15,
		"upgrade_multipliers": [1.0, 1.3, 1.7, 2.2, 2.8],
		"special": "Spread Shot"
	},
	"sniper": {
		"name": "KESKİN NİŞANCI",
		"description": "4× hasar, yavaş ateş",
		"icon": "🎯",
		"cost": 600,
		"unlocked_by_default": false,
		"base_fire_rate": 2.4,
		"base_damage": 40,
		"upgrade_multipliers": [1.0, 1.4, 1.9, 2.5, 3.2],
		"special": "Critical Hit"
	},
	"magic_wand": {
		"name": "SİHİR ASASI",
		"description": "360° mermi, büyü hasarı",
		"icon": "✨",
		"cost": 500,
		"unlocked_by_default": false,
		"base_fire_rate": 1.8,
		"base_damage": 12,
		"upgrade_multipliers": [1.0, 1.25, 1.6, 2.0, 2.5],
		"special": "Homing Projectiles"
	},
	"flamethrower": {
		"name": "ALEV MAKİNESİ",
		"description": "Sürekli hasar, alan etkisi",
		"icon": "🔥",
		"cost": 400,
		"unlocked_by_default": false,
		"base_fire_rate": 0.05,
		"base_damage": 5,
		"upgrade_multipliers": [1.0, 1.3, 1.7, 2.2, 2.8],
		"special": "Burn Damage"
	},
	"rocket_launcher": {
		"name": "ROKET ATAR",
		"description": "Patlama hasarı, alan etkisi",
		"icon": "🚀",
		"cost": 700,
		"unlocked_by_default": false,
		"base_fire_rate": 3.0,
		"base_damage": 60,
		"upgrade_multipliers": [1.0, 1.5, 2.1, 2.8, 3.6],
		"special": "AOE Explosion"
	}
}

const UPGRADE_COSTS: Array = [100, 250, 500, 800]  # Level 1-2, 2-3, 3-4, 4-5

# === PROPERTIES ===
var current_weapon_id: String = "machinegun"
var owned_weapons: Dictionary = {"machinegun": 1}  # weapon_id: level
var player_xp: int = 0

# === UI REFERENCES ===
var _weapon_grid: GridContainer
var _upgrade_panel: Control
var _selected_weapon_info: Control

# === LIFECYCLE ===

func _ready() -> void:
	_build_ui()
	_refresh_display()

# === PUBLIC API ===

func set_player_data(xp: int, owned_weps: Dictionary, selected_wep: String) -> void:
	player_xp = xp
	owned_weapons = owned_weps
	current_weapon_id = selected_wep
	if _weapon_grid != null:
		_refresh_display()

func get_selected_weapon() -> Dictionary:
	return WEAPONS.get(current_weapon_id, WEAPONS["machinegun"])

func get_weapon_level(weapon_id: String) -> int:
	return owned_weapons.get(weapon_id, 0)

func get_weapon_cost(weapon_id: String) -> int:
	return WEAPONS.get(weapon_id, {}).get("cost", 0)

func get_upgrade_cost(weapon_id: String) -> int:
	var current_level = get_weapon_level(weapon_id)
	if current_level >= 5 or current_level == 0:
		return 0
	return UPGRADE_COSTS[current_level - 1]

func can_purchase_weapon(weapon_id: String) -> bool:
	if weapon_id in owned_weapons:
		return false
	var cost = get_weapon_cost(weapon_id)
	return player_xp >= cost

func can_upgrade_weapon(weapon_id: String) -> bool:
	if weapon_id not in owned_weapons:
		return false
	var current_level = owned_weapons[weapon_id]
	if current_level >= 5:
		return false
	var upgrade_cost = get_upgrade_cost(weapon_id)
	return player_xp >= upgrade_cost

# === PRIVATE METHODS ===

func _build_ui() -> void:
	# Ana container (padding ile)
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 12)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(margin)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_theme_constant_override("separation", 10)
	margin.add_child(main_vbox)
	
	# Başlık
	var title_label = Label.new()
	title_label.text = "🔫 Silah Seçimi"
	title_label.add_theme_font_size_override("font_size", 26)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.85))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(title_label)
	
	# Açıklama
	var desc_label = Label.new()
	desc_label.text = "Kartın üzerine tıklayarak seçin veya satın alın"
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color(0.95, 0.75, 0.75))
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(desc_label)
	
	# Silah grid
	_weapon_grid = GridContainer.new()
	_weapon_grid.columns = 2
	_weapon_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_weapon_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_weapon_grid.add_theme_constant_override("h_separation", 22)
	_weapon_grid.add_theme_constant_override("v_separation", 22)
	main_vbox.add_child(_weapon_grid)
	
	# Seçili silah bilgisi paneli
	_selected_weapon_info = _create_selected_weapon_panel()
	_selected_weapon_info.visible = false
	main_vbox.add_child(_selected_weapon_info)

func _refresh_display() -> void:
	if _weapon_grid == null:
		return
	# Temizle
	for child in _weapon_grid.get_children():
		child.queue_free()
	
	# Silah kartlarını oluştur
	for weapon_id in WEAPONS.keys():
		var weapon_card = _create_weapon_card(weapon_id)
		if weapon_card:
			_weapon_grid.add_child(weapon_card)

func _create_weapon_card(weapon_id: String) -> Control:
	var weapon_data = WEAPONS[weapon_id]
	var is_owned = weapon_id in owned_weapons
	var is_selected = weapon_id == current_weapon_id
	var current_level = get_weapon_level(weapon_id) if is_owned else 0
	var can_afford = player_xp >= weapon_data["cost"]
	
	# Kart container (karta tıklanınca seçim)
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(190, 180)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Kart tıklanabilir; hover'da el imleci
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	# Kart stili
	var card_style = StyleBoxFlat.new()
	if is_selected:
		card_style.bg_color = Color(0.8, 0.4, 0.2, 0.3)
		card_style.border_color = Color(1.0, 0.6, 0.3, 0.8)
	elif is_owned:
		card_style.bg_color = Color(0.3, 0.1, 0.1, 0.3)
		card_style.border_color = Color(0.8, 0.3, 0.3, 0.6)
	else:
		card_style.bg_color = Color(0.2, 0.15, 0.15, 0.3)
		card_style.border_color = Color(0.4, 0.3, 0.3, 0.4)
	
	card_style.set_border_width_all(2)
	card_style.set_corner_radius_all(8)
	card.add_theme_stylebox_override("panel", card_style)
	# Kartın tamamına tıklanınca seç/satın al
	card.gui_input.connect(_on_weapon_card_gui_input.bind(weapon_id, is_owned, is_selected, can_afford))
	
	# İçerik (karta tıklanabilsin diye içerik event'i geçirir)
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 4)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(vbox)
	
	# Silah ikonu ve adı
	var title_hbox = HBoxContainer.new()
	title_hbox.add_theme_constant_override("separation", 6)
	title_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(title_hbox)
	
	var icon_label = Label.new()
	icon_label.text = weapon_data["icon"]
	icon_label.add_theme_font_size_override("font_size", 20)
	icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_hbox.add_child(icon_label)
	
	var name_label = Label.new()
	name_label.text = weapon_data["name"]
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", 
		Color(1.0, 0.8, 0.5) if is_selected else Color(1.0, 0.9, 0.9))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_hbox.add_child(name_label)
	
	# Seviye göstergesi (current_level ConfigFile'dan string gelebilir)
	var level_int := int(current_level)
	if is_owned and level_int > 0:
		var level_label = Label.new()
		level_label.text = "★".repeat(level_int) + "☆".repeat(5 - level_int)
		level_label.add_theme_font_size_override("font_size", 12)
		level_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
		level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(level_label)
	
	# İstatistikler
	var stats_text = "⚡ %.1fs  💥 %d" % [weapon_data["base_fire_rate"], weapon_data["base_damage"]]
	var stats_label = Label.new()
	stats_label.text = stats_text
	stats_label.add_theme_font_size_override("font_size", 11)
	stats_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.6))
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(stats_label)
	
	# Özel yetenek
	var special_label = Label.new()
	special_label.text = weapon_data["special"]
	special_label.add_theme_font_size_override("font_size", 10)
	special_label.add_theme_color_override("font_color", Color(0.6, 0.9, 1.0))
	special_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	special_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(special_label)
	
	# Butonlar
	var button_container = HBoxContainer.new()
	button_container.add_theme_constant_override("separation", 4)
	button_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(button_container)
	
	if is_selected:
		var selected_label = Label.new()
		selected_label.text = "✓ SEÇİLİ"
		selected_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		selected_label.add_theme_font_size_override("font_size", 11)
		selected_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
		button_container.add_child(selected_label)
		
		# Yükseltme butonu (eğer seviye < 5)
		if current_level < 5:
			var upgrade_btn = Button.new()
			upgrade_btn.text = "↑ %dXP" % get_upgrade_cost(weapon_id)
			upgrade_btn.add_theme_font_size_override("font_size", 10)
			upgrade_btn.disabled = not can_upgrade_weapon(weapon_id)
			upgrade_btn.pressed.connect(_on_upgrade_weapon.bind(weapon_id))
			_style_button(upgrade_btn, 
				Color(0.8, 0.5, 0.1) if can_upgrade_weapon(weapon_id) else Color(0.4, 0.4, 0.4))
			button_container.add_child(upgrade_btn)
	elif is_owned:
		var select_btn = Button.new()
		select_btn.text = "SEÇ"
		select_btn.add_theme_font_size_override("font_size", 12)
		select_btn.pressed.connect(_on_select_weapon.bind(weapon_id))
		_style_button(select_btn, Color(0.5, 0.2, 0.2))
		button_container.add_child(select_btn)
	else:
		var buy_btn = Button.new()
		buy_btn.text = "%d XP" % weapon_data["cost"]
		buy_btn.add_theme_font_size_override("font_size", 12)
		buy_btn.disabled = not can_afford
		buy_btn.pressed.connect(_on_buy_weapon.bind(weapon_id))
		_style_button(buy_btn, 
			Color(0.7, 0.3, 0.1) if can_afford else Color(0.3, 0.3, 0.3))
		button_container.add_child(buy_btn)
	
	return card

func _create_selected_weapon_panel() -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 120)
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.05, 0.05, 0.8)
	panel_style.set_border_width_all(2)
	panel_style.border_color = Color(0.8, 0.4, 0.2, 0.6)
	panel_style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", panel_style)
	
	return panel

func _style_button(button: Button, color: Color) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(4)
	button.add_theme_stylebox_override("normal", style)
	
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(color.r + 0.1, color.g + 0.1, color.b + 0.1)
	hover_style.set_corner_radius_all(4)
	button.add_theme_stylebox_override("hover", hover_style)

func _on_weapon_card_gui_input(event: InputEvent, weapon_id: String, is_owned: bool, is_selected: bool, can_afford: bool) -> void:
	if not event is InputEventMouseButton:
		return
	var ev = event as InputEventMouseButton
	if ev.button_index != MOUSE_BUTTON_LEFT or not ev.pressed:
		return
	if is_selected:
		return
	if is_owned:
		_on_select_weapon(weapon_id)
	else:
		if can_afford:
			_on_buy_weapon(weapon_id)

func _on_select_weapon(weapon_id: String) -> void:
	current_weapon_id = weapon_id
	weapon_selected.emit(weapon_id)
	_refresh_display()

func _on_buy_weapon(weapon_id: String) -> void:
	if can_purchase_weapon(weapon_id):
		weapon_purchased.emit(weapon_id)

func _on_upgrade_weapon(weapon_id: String) -> void:
	if can_upgrade_weapon(weapon_id):
		var current_level = owned_weapons[weapon_id]
		var new_level = current_level + 1
		weapon_upgraded.emit(weapon_id, new_level)

func _on_preview_weapon(weapon_id: String) -> void:
	weapon_preview_requested.emit(weapon_id)

# === DEBUG ===
func print_debug_info() -> void:
	print("=== WeaponSelectorAtom ===")
	print("Selected: %s" % current_weapon_id)
	print("Owned: %s" % owned_weapons)
	print("XP: %d" % player_xp)
	print("Weapons: %d" % WEAPONS.size())