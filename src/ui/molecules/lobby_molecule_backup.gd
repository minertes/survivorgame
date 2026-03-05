# 🏢 LOBBY MOLECULE (BACKUP - class_name kaldırıldı, ana sınıf lobby_molecule.gd)
# Tüm atomic bileşenleri birleştiren ana lobi molekülü
extends Control

# === DEPENDENCIES ===
var character_selector: CharacterSelectorAtom = null
var weapon_selector: WeaponSelectorAtom = null
var flag_selector: FlagSelectorAtom = null
var stats_display: StatsDisplayAtom = null
var currency_display: CurrencyDisplayAtom = null
var tab_navigation: TabNavigationAtom = null

# === PLAYER DATA ===
var player_data: Dictionary = {
	"xp": 0,
	"owned_characters": ["male_soldier"],
	"selected_character": "male_soldier",
	"owned_weapons": {"machinegun": 1},
	"selected_weapon": "machinegun",
	"owned_flags": ["turkey"],
	"selected_flag": "turkey",
	"stats": {
		"best_wave": 0,
		"total_kills": 0,
		"total_games": 0,
		"total_xp_earned": 0,
		"total_play_time": 0,
		"accuracy": 0.0,
		"survival_rate": 0.0
	}
}

# === UI REFERENCES ===
var _content_container: Control
var _play_button: Button
var _back_button: Button
var _header_container: Control

# === STATE ===
var is_initialized: bool = false

# === SIGNALS ===
signal lobby_initialized()
signal player_data_updated()
signal game_start_requested(character_id: String, weapon_id: String, flag_id: String)
signal purchase_made(item_type: String, item_id: String, cost: int)
signal navigation_back()

# === LIFECYCLE ===

func _ready() -> void:
	print("LobbyMolecule initializing...")
	_build_ui()
	_initialize_components()
	is_initialized = true
	lobby_initialized.emit()
	print("LobbyMolecule initialized successfully")

# === PUBLIC API ===

func set_player_data(data: Dictionary) -> void:
	player_data = data
	_refresh_all_components()
	player_data_updated.emit()

func get_player_data() -> Dictionary:
	return player_data.duplicate(true)

func update_player_xp(new_xp: int, animate: bool = true) -> void:
	player_data["xp"] = new_xp
	if currency_display:
		currency_display.set_xp_amount(new_xp, animate)
	_refresh_purchase_abilities()

func add_player_xp(amount: int, animate: bool = true) -> void:
	player_data["xp"] += amount
	player_data["stats"]["total_xp_earned"] += amount
	
	if currency_display:
		currency_display.add_xp(amount, animate)
		if animate:
			currency_display.play_earn_effect(amount)
	
	_refresh_purchase_abilities()
	player_data_updated.emit()

func spend_player_xp(amount: int, animate: bool = true) -> bool:
	if player_data["xp"] < amount:
		return false
	
	player_data["xp"] -= amount
	if currency_display:
		if not currency_display.spend_xp(amount, animate):
			return false
		if animate:
			currency_display.play_spend_effect(amount)
	
	_refresh_purchase_abilities()
	player_data_updated.emit()
	return true

func purchase_character(character_id: String) -> bool:
	var character_cost = character_selector.get_character_cost(character_id)
	if not spend_player_xp(character_cost):
		return false
	
	if not character_id in player_data["owned_characters"]:
		player_data["owned_characters"].append(character_id)
	
	character_selector.set_player_data(
		player_data["xp"],
		player_data["owned_characters"],
		player_data["selected_character"]
	)
	
	purchase_made.emit("character", character_id, character_cost)
	return true

func purchase_weapon(weapon_id: String) -> bool:
	var weapon_cost = weapon_selector.get_weapon_cost(weapon_id)
	if not spend_player_xp(weapon_cost):
		return false
	
	if not weapon_id in player_data["owned_weapons"]:
		player_data["owned_weapons"][weapon_id] = 1
	
	weapon_selector.set_player_data(
		player_data["xp"],
		player_data["owned_weapons"],
		player_data["selected_weapon"]
	)
	
	purchase_made.emit("weapon", weapon_id, weapon_cost)
	return true

func purchase_flag(flag_id: String) -> bool:
	var flag_cost = flag_selector.get_flag_cost(flag_id)
	if not spend_player_xp(flag_cost):
		return false
	
	if not flag_id in player_data["owned_flags"]:
		player_data["owned_flags"].append(flag_id)
	
	flag_selector.set_player_data(
		player_data["xp"],
		player_data["owned_flags"],
		player_data["selected_flag"]
	)
	
	purchase_made.emit("flag", flag_id, flag_cost)
	return true

func upgrade_weapon(weapon_id: String) -> bool:
	var upgrade_cost = weapon_selector.get_upgrade_cost(weapon_id)
	if not spend_player_xp(upgrade_cost):
		return false
	
	var current_level = player_data["owned_weapons"].get(weapon_id, 0)
	player_data["owned_weapons"][weapon_id] = current_level + 1
	
	weapon_selector.set_player_data(
		player_data["xp"],
		player_data["owned_weapons"],
		player_data["selected_weapon"]
	)
	
	purchase_made.emit("weapon_upgrade", weapon_id, upgrade_cost)
	return true

func select_character(character_id: String) -> void:
	if character_id in player_data["owned_characters"]:
		player_data["selected_character"] = character_id
		character_selector.set_player_data(
			player_data["xp"],
			player_data["owned_characters"],
			player_data["selected_character"]
		)
		player_data_updated.emit()

func select_weapon(weapon_id: String) -> void:
	if weapon_id in player_data["owned_weapons"]:
		player_data["selected_weapon"] = weapon_id
		weapon_selector.set_player_data(
			player_data["xp"],
			player_data["owned_weapons"],
			player_data["selected_weapon"]
		)
		player_data_updated.emit()

func select_flag(flag_id: String) -> void:
	if flag_id in player_data["owned_flags"]:
		player_data["selected_flag"] = flag_id
		flag_selector.set_player_data(
			player_data["xp"],
			player_data["owned_flags"],
			player_data["selected_flag"]
		)
		player_data_updated.emit()

func update_player_stats(new_stats: Dictionary) -> void:
	player_data["stats"] = new_stats
	if stats_display:
		stats_display.set_player_stats(new_stats)
	player_data_updated.emit()

func start_game() -> void:
	game_start_requested.emit(
		player_data["selected_character"],
		player_data["selected_weapon"],
		player_data["selected_flag"]
	)

# === PRIVATE METHODS ===

func _build_ui() -> void:
	# Ana container
	var main_vbox = VBoxContainer.new()
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_theme_constant_override("separation", 0)
	add_child(main_vbox)
	
	# Header (Currency + Back button)
	_header_container = _create_header()
	main_vbox.add_child(_header_container)
	
	# Tab navigasyonu
	tab_navigation = TabNavigationAtom.new()
	tab_navigation.tab_changed.connect(_on_tab_changed)
	main_vbox.add_child(tab_navigation)
	
	# İçerik alanı
	_content_container = Control.new()
	_content_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(_content_container)
	
	# Play butonu
	_play_button = _create_play_button()
	main_vbox.add_child(_play_button)

func _create_header() -> Control:
	var header = PanelContainer.new()
	header.custom_minimum_size = Vector2(0, 60)
	
	var header_style = StyleBoxFlat.new()
	header_style.bg_color = Color(0.06, 0.04, 0.12, 0.95)
	header_style.border_color = Color(0.3, 0.2, 0.5, 0.8)
	header_style.set_border_width_all(0)
	header_style.border_width_bottom = 2
	header.add_theme_stylebox_override("panel", header_style)
	
	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 20)
	header.add_child(hbox)
	
	# Back button
	_back_button = Button.new()
	_back_button.text = "◀ GERİ"
	_back_button.custom_minimum_size = Vector2(100, 40)
	_back_button.add_theme_font_size_override("font_size", 16)
	_back_button.add_theme_color_override("font_color", Color(0.8, 0.7, 1.0))
	_back_button.pressed.connect(_on_back_pressed)
	_style_button(_back_button, Color(0.15, 0.1, 0.25))
	hbox.add_child(_back_button)
	
	# Currency display
	currency_display = CurrencyDisplayAtom.new()
	currency_display.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(currency_display)
	
	return header

func _create_play_button() -> Button:
	var button = Button.new()
	button.text = "🎮 OYUNA BAŞLA"
	button.custom_minimum_size = Vector2(0, 70)
	button.add_theme_font_size_override("font_size", 24)
	button.add_theme_color_override("font_color", Color(0.95, 1.0, 0.95))
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.5, 0.12)
	style.set_corner_radius_all(10)
	style.border_color = Color(0.4, 0.9, 0.4, 0.8)
	style.set_border_width_all(2)
	button.add_theme_stylebox_override("normal", style)
	
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.18, 0.7, 0.18)
	hover_style.set_corner_radius_all(10)
	button.add_theme_stylebox_override("hover", hover_style)
	
	button.pressed.connect(_on_play_pressed)
	return button

func _initialize_components() -> void:
	# Atomic bileşenleri oluştur
	character_selector = CharacterSelectorAtom.new()
	weapon_selector = WeaponSelectorAtom.new()
	flag_selector = FlagSelectorAtom.new()
	stats_display = StatsDisplayAtom.new()
	
	# Signal'leri bağla
	character_selector.character_selected.connect(_on_character_selected)
	character_selector.character_purchased.connect(_on_character_purchased)
	
	weapon_selector.weapon_selected.connect(_on_weapon_selected)
	weapon_selector.weapon_purchased.connect(_on_weapon_purchased)
	weapon_selector.weapon_upgraded.connect(_on_weapon_upgraded)
	
	flag_selector.flag_selected.connect(_on_flag_selected)
	flag_selector.flag_purchased.connect(_on_flag_purchased)
	
	# Başlangıç verilerini yükle
	_refresh_all_components()
	
	# İlk tab'i göster
	_show_tab_content(TabNavigationAtom.Tab.CHARACTER)

func _refresh_all_components() -> void:
	if not is_initialized:
		return
	
	# Currency display
	if currency_display:
		currency_display.set_xp_amount(player_data["xp"], false)
	
	# Character selector
	if character_selector:
		character_selector.set_player_data(
			player_data["xp"],
			player_data["owned_characters"],
			player_data["selected_character"]
		)
	
	# Weapon selector
	if weapon_selector:
		weapon_selector.set_player_data(
			player_data["xp"],
			player_data["owned_weapons"],
			player_data["selected_weapon"]
		)
	
	# Flag selector
	if flag_selector:
		flag_selector.set_player_data(
			player_data["xp"],
			player_data["owned_flags"],
			player_data["selected_flag"]
		)
	
	# Stats display
	if stats_display:
		stats_display.set_player_stats(player_data["stats"])
		stats_display.set_character_stats({
			"selected_character": player_data["selected_character"],
			"character_level": 1,
			"character_xp": 0
		})
		stats_display.set_weapon_stats({
			"selected_weapon": player_data["selected_weapon"],
			"weapon_level": player_data["owned_weapons"].get(player_data["selected_weapon"], 1),
			"total_damage": 0
		})

func _refresh_purchase_abilities() -> void:
	if character_selector:
		character_selector.set_player_data(
			player_data["xp"],
			player_data["owned_characters"],
			player_data["selected_character"]
		)
	
	if weapon_selector:
		weapon_selector.set_player_data(
			player_data["xp"],
			player_data["owned_weapons"],
			player_data["selected_weapon"]
		)
	
	if flag_selector:
		flag_selector.set_player_data(
			player_data["xp"],
			player_data["owned_flags"],
			player_data["selected_flag"]
		)

func _show_tab_content(tab_index: int) -> void:
	# Mevcut içeriği temizle
	for child in _content_container.get_children():
		child.queue_free()
	
	# Yeni içeriği göster
	match tab_index:
		TabNavigationAtom.Tab.CHARACTER:
			if character_selector:
				_content_container.add_child(character_selector)
		
		TabNavigationAtom.Tab.WEAPON:
			if weapon_selector:
				_content_container.add_child(weapon_selector)
		
		TabNavigationAtom.Tab.FLAG:
			if flag_selector:
				_content_container.add_child(flag_selector)
		
		TabNavigationAtom.Tab.STATS:
			if stats_display:
				_content_container.add_child(stats_display)
		
		TabNavigationAtom.Tab.SETTINGS:
			# Settings tab'i için placeholder
			var settings_label = Label.new()
			settings_label.text = "⚙️ AYARLAR (Yakında...)"
			settings_label.add_theme_font_size_override("font_size", 24)
			settings_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
			settings_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			settings_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			settings_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			settings_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
			_content_container.add_child(settings_label)

func _style_button(button: Button, color: Color) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(6)
	button.add_theme_stylebox_override("normal", style)
	
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(color.r + 0.1, color.g + 0.1, color.b + 0.1)
	hover_style.set_corner_radius_all(6)
	button.add_theme_stylebox_override("hover", hover_style)

# === SIGNAL HANDLERS ===

func _on_tab_changed(tab_index: int, tab_name: String) -> void:
	print("Tab changed to: %s" % tab_name)
	_show_tab_content(tab_index)

func _on_back_pressed() -> void:
	navigation_back.emit()

func _on_play_pressed() -> void:
	start_game()

func _on_character_selected(character_id: String) -> void:
	select_character(character_id)

func _on_character_purchased(character_id: String) -> void:
	purchase_character(character_id)

func _on_weapon_selected(weapon_id: String) -> void:
	select_weapon(weapon_id)

func _on_weapon_purchased(weapon_id: String) -> void:
	purchase_weapon(weapon_id)

func _on_weapon_upgraded(weapon_id: String, new_level: int) -> void:
	upgrade_weapon(weapon_id)

func _on_flag_selected(flag_id: String) -> void:
	select_flag(flag_id)

func _on_flag_purchased(flag_id: String) -> void:
	purchase_flag(flag_id)

# === DEBUG ===
func print_debug_info() -> void:
	print("=== LobbyMolecule ===")
	print("Initialized: %s" % str(is_initialized))
	print("Player XP: %d" % player_data["xp"])
	print("Selected Character: %s" % player_data["selected_character"])
	print("Selected Weapon: %s" % player_data["selected_weapon"])
	print("Selected Flag: %s" % player_data["selected_flag"])
	print("Owned Characters: %s" % player_data["owned_characters"])
	print("Owned Weapons: %s" % player_data["owned_weapons"])
	print("Owned Flags: %s" % player_data["owned_flags"])