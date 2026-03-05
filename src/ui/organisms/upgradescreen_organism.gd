# 🎮 UPGRADE SCREEN ORGANISM
# Atomic Design: Upgrade screen organism (Panel + Label + WeaponCard + ProgressBar + Button)
# Kompleks UI bölümü: Silah yükseltme ekranını yönetir
class_name UpgradeScreenOrganism
extends Control

# === CONFIG ===
@export var show_title: bool = true:
	set(value):
		show_title = value
		if is_inside_tree():
			_update_title_visibility()

@export var show_stats: bool = true:
	set(value):
		show_stats = value
		if is_inside_tree():
			_update_stats_visibility()

@export var show_weapons: bool = true:
	set(value):
		show_weapons = value
		if is_inside_tree():
			_update_weapons_visibility()

@export var show_background: bool = true:
	set(value):
		show_background = value
		if is_inside_tree():
			_update_background_visibility()

@export var fade_duration: float = 0.3:
	set(value):
		fade_duration = value
		if is_inside_tree():
			_update_animations()

# === NODES ===
@onready var background_panel: PanelAtom = $BackgroundPanel
@onready var title_label: LabelAtom = $CenterContainer/VBoxContainer/TitleLabel
@onready var weapons_container: HBoxContainer = $CenterContainer/VBoxContainer/WeaponsContainer
@onready var stats_panel: PanelAtom = $CenterContainer/VBoxContainer/StatsPanel
@onready var damage_label: LabelAtom = $CenterContainer/VBoxContainer/StatsPanel/DamageLabel
@onready var fire_rate_label: LabelAtom = $CenterContainer/VBoxContainer/StatsPanel/FireRateLabel
@onready var range_label: LabelAtom = $CenterContainer/VBoxContainer/StatsPanel/RangeLabel
@onready var reload_label: LabelAtom = $CenterContainer/VBoxContainer/StatsPanel/ReloadLabel
@onready var damage_bar: ProgressBarAtom = $CenterContainer/VBoxContainer/StatsPanel/DamageBar
@onready var fire_rate_bar: ProgressBarAtom = $CenterContainer/VBoxContainer/StatsPanel/FireRateBar
@onready var range_bar: ProgressBarAtom = $CenterContainer/VBoxContainer/StatsPanel/RangeBar
@onready var reload_bar: ProgressBarAtom = $CenterContainer/VBoxContainer/StatsPanel/ReloadBar
@onready var cost_label: LabelAtom = $CenterContainer/VBoxContainer/CostLabel
@onready var upgrade_button: ButtonAtom = $CenterContainer/VBoxContainer/UpgradeButton
@onready var back_button: ButtonAtom = $CenterContainer/VBoxContainer/BackButton
var fade_tween: Tween

# === STATE ===
var is_initialized: bool = false
var is_fading: bool = false
var current_config: Dictionary = {}
var player_entity: Node = null
var current_weapon_id: String = ""
var selected_weapon_id: String = ""
var weapon_cards: Array = []
var upgrade_costs: Dictionary = {}
var weapon_levels: Dictionary = {}
var max_upgrade_level: int = 10
var cost_multiplier: float = 1.5

# === EVENTS ===
signal upgrade_screen_initialized
signal upgrade_screen_visibility_changed(is_visible: bool)
signal weapon_selected(weapon_id: String)
signal upgrade_initiated(weapon_id: String, cost: int, new_level: int)
signal upgrade_completed(weapon_id: String, new_level: int)
signal back_pressed
signal fade_completed(fade_in: bool)

# === LIFECYCLE ===

func _ready() -> void:
	# Başlangıç durumunu güncelle
	_update_visibility()
	_update_animations()
	
	# Button event'lerini bağla
	_connect_button_events()
	
	# Config yükle
	_load_config()
	
	# EventBus subscription'ları
	_setup_event_bus_subscriptions()
	
	# Weapon card'ları başlat
	_initialize_weapon_cards()
	
	is_initialized = true
	upgrade_screen_initialized.emit()
	
	# Fade in animation
	fade_in()

# === PUBLIC API ===

func fade_in() -> void:
	if is_fading:
		return
	
	is_fading = true
	visible = true
	
	if fade_tween:
		fade_tween.kill()
	
	fade_tween = create_tween()
	fade_tween.set_trans(Tween.TRANS_CUBIC)
	fade_tween.set_ease(Tween.EASE_OUT)
	
	modulate = Color.TRANSPARENT
	fade_tween.tween_property(self, "modulate", Color.WHITE, fade_duration)
	fade_tween.tween_callback(func(): 
		is_fading = false
		fade_completed.emit(true)
	)

func fade_out() -> void:
	if is_fading:
		return
	
	is_fading = true
	
	if fade_tween:
		fade_tween.kill()
	
	fade_tween = create_tween()
	fade_tween.set_trans(Tween.TRANS_CUBIC)
	fade_tween.set_ease(Tween.EASE_IN)
	
	fade_tween.tween_property(self, "modulate", Color.TRANSPARENT, fade_duration)
	fade_tween.tween_callback(func(): 
		visible = false
		is_fading = false
		fade_completed.emit(false)
	)

func show_upgrade_screen() -> void:
	visible = true
	upgrade_screen_visibility_changed.emit(true)

func hide_upgrade_screen() -> void:
	visible = false
	upgrade_screen_visibility_changed.emit(false)

func toggle_upgrade_screen() -> void:
	visible = not visible
	upgrade_screen_visibility_changed.emit(visible)

func set_player_entity(player: Node) -> void:
	player_entity = player
	_update_player_stats()

func set_current_weapon(weapon_id: String) -> void:
	current_weapon_id = weapon_id
	_select_weapon(weapon_id)

func set_weapon_level(weapon_id: String, level: int) -> void:
	weapon_levels[weapon_id] = clamp(level, 1, max_upgrade_level)
	_update_weapon_card(weapon_id)

func set_max_upgrade_level(level: int) -> void:
	max_upgrade_level = max(1, level)

func set_cost_multiplier(multiplier: float) -> void:
	cost_multiplier = max(1.0, multiplier)

func set_title(text: String) -> void:
	if title_label:
		title_label.set_text(text)

func set_background_color(color: Color) -> void:
	if background_panel:
		background_panel.set_background_color(color)

func set_upgrade_button_text(text: String) -> void:
	if upgrade_button:
		upgrade_button.set_text(text)

func set_back_button_text(text: String) -> void:
	if back_button:
		back_button.set_text(text)

func set_upgrade_button_style(style: String) -> void:
	if upgrade_button:
		upgrade_button.set_style(style)

func set_back_button_style(style: String) -> void:
	if back_button:
		back_button.set_style(style)

func reload_config() -> void:
	_load_config()

func calculate_upgrade_cost(weapon_id: String, current_level: int) -> int:
	if current_level >= max_upgrade_level:
		return -1  # Max level reached
	
	var base_cost = 100
	var cost = int(base_cost * pow(cost_multiplier, current_level - 1))
	upgrade_costs[weapon_id] = cost
	return cost

func can_upgrade(weapon_id: String) -> bool:
	if not weapon_id in weapon_levels:
		return false
	
	var current_level = weapon_levels[weapon_id]
	if current_level >= max_upgrade_level:
		return false
	
	# Burada player'ın yeterli kaynağı olup olmadığı kontrol edilebilir
	return true

func perform_upgrade(weapon_id: String) -> bool:
	if not can_upgrade(weapon_id):
		return false
	
	var current_level = weapon_levels[weapon_id]
	var cost = calculate_upgrade_cost(weapon_id, current_level)
	
	if cost <= 0:
		return false
	
	# Burada player kaynakları azaltılabilir
	
	var new_level = current_level + 1
	weapon_levels[weapon_id] = new_level
	
	# EventBus'a bildir
	if EventBus.is_available():
		EventBus.emit_now_static("weapon_upgraded", {
			"weapon_id": weapon_id,
			"old_level": current_level,
			"new_level": new_level,
			"cost": cost
		})
	
	upgrade_completed.emit(weapon_id, new_level)
	
	# UI'yi güncelle
	_update_weapon_card(weapon_id)
	_update_upgrade_button()
	
	return true

# === CONFIG MANAGEMENT ===

func _load_config() -> void:
	if not ConfigManager.is_available():
		push_warning("ConfigManager not available")
		return
	
	var config = ConfigManager.get_instance().get_config_value("ui.json", "screens.upgrade_screen", {})
	current_config = config
	
	# Apply config
	_apply_config(config)

func _apply_config(config: Dictionary) -> void:
	# Title
	if config.has("title"):
		set_title(config.title)
	
	# Background
	if config.has("background_color"):
		var color = Color(config.background_color)
		set_background_color(color)
	
	# Buttons
	if config.has("upgrade_button_text"):
		set_upgrade_button_text(config.upgrade_button_text)
	
	if config.has("back_button_text"):
		set_back_button_text(config.back_button_text)
	
	if config.has("upgrade_button_style"):
		set_upgrade_button_style(config.upgrade_button_style)
	
	if config.has("back_button_style"):
		set_back_button_style(config.back_button_style)
	
	# Stats
	if config.has("stat_labels"):
		# Stat label'larını güncelle
		pass
	
	# Upgrade settings
	if config.has("cost_multiplier"):
		set_cost_multiplier(config.cost_multiplier)
	
	if config.has("max_upgrade_level"):
		set_max_upgrade_level(config.max_upgrade_level)
	
	# Visibility
	if config.has("show_title"):
		show_title = config.show_title
	if config.has("show_stats"):
		show_stats = config.show_stats
	if config.has("show_background"):
		show_background = config.show_background
	
	# Animation
	if config.has("fade_duration"):
		fade_duration = config.fade_duration

# === WEAPON MANAGEMENT ===

func _initialize_weapon_cards() -> void:
	if not is_inside_tree():
		return
	
	# Weapon card'larını temizle
	for child in weapons_container.get_children():
		child.queue_free()
	
	weapon_cards.clear()
	
	# Örnek weapon ID'leri (gerçek projede config'den yüklenecek)
	var weapon_ids = ["pistol", "shotgun", "rifle"]
	
	for weapon_id in weapon_ids:
		var weapon_card = WeaponCardMolecule.new()
		weapon_card.name = "%sCard" % weapon_id.capitalize()
		weapon_card.load_weapon(weapon_id)
		weapon_card.card_clicked.connect(_on_weapon_card_clicked.bind(weapon_id))
		
		weapons_container.add_child(weapon_card)
		weapon_cards.append(weapon_card)
		
		# Başlangıç level'ı
		weapon_levels[weapon_id] = 1
	
	# İlk weapon'ı seç
	if not weapon_ids.is_empty():
		_select_weapon(weapon_ids[0])

func _select_weapon(weapon_id: String) -> void:
	selected_weapon_id = weapon_id
	
	# Tüm card'ların seçim durumunu güncelle
	for weapon_card in weapon_cards:
		var card_weapon_id = weapon_card.get_weapon_id()
		weapon_card.set_selected(card_weapon_id == weapon_id)
	
	# Stats'ı güncelle
	_update_weapon_stats(weapon_id)
	
	# Upgrade button'ı güncelle
	_update_upgrade_button()
	
	weapon_selected.emit(weapon_id)

func _update_weapon_card(weapon_id: String) -> void:
	for weapon_card in weapon_cards:
		if weapon_card.get_weapon_id() == weapon_id:
			# Card'ı güncelle (örneğin level bilgisi ekle)
			var weapon_data = weapon_card.get_weapon_data()
			var level = weapon_levels.get(weapon_id, 1)
			
			# Weapon name'e level ekle
			var level_text = " (Lv.%d)" % level
			if "name" in weapon_data:
				weapon_card.set_show_name(true)
				# Burada weapon_card'ın name'ini güncelleme metodu olmalı
			break

func _update_weapon_stats(weapon_id: String) -> void:
	if not ConfigManager.is_available():
		return
	
	var weapon_data = ConfigManager.get_instance().get_weapon_config(weapon_id)
	if weapon_data.is_empty():
		return
	
	var level = weapon_levels.get(weapon_id, 1)
	
	# Stats'ı hesapla (level'a göre scale)
	var damage = weapon_data.get("damage", 10.0) * (1.0 + (level - 1) * 0.2)
	var fire_rate = weapon_data.get("fire_rate", 1.0) * (1.0 + (level - 1) * 0.1)
	var range_val = weapon_data.get("range", 100.0) * (1.0 + (level - 1) * 0.15)
	var reload = weapon_data.get("reload_speed", 2.0) * (1.0 - (level - 1) * 0.05)
	
	# Labels'ı güncelle
	damage_label.set_text("Damage: %.1f" % damage)
	fire_rate_label.set_text("Fire Rate: %.1f/s" % (1.0 / fire_rate))
	range_label.set_text("Range: %.0f" % range_val)
	reload_label.set_text("Reload: %.1fs" % reload)
	
	# Progress bar'ları güncelle (normalize edilmiş değerler)
	var max_damage = weapon_data.get("damage", 10.0) * (1.0 + (max_upgrade_level - 1) * 0.2)
	var max_fire_rate = weapon_data.get("fire_rate", 1.0) * (1.0 + (max_upgrade_level - 1) * 0.1)
	var max_range = weapon_data.get("range", 100.0) * (1.0 + (max_upgrade_level - 1) * 0.15)
	var min_reload = weapon_data.get("reload_speed", 2.0) * (1.0 - (max_upgrade_level - 1) * 0.05)
	
	damage_bar.set_value(damage / max_damage * 100.0)
	fire_rate_bar.set_value((1.0 / fire_rate) / (1.0 / max_fire_rate) * 100.0)
	range_bar.set_value(range_val / max_range * 100.0)
	reload_bar.set_value((min_reload / reload) * 100.0)
	
	# Cost'ı güncelle
	var cost = calculate_upgrade_cost(weapon_id, level)
	if cost > 0:
		cost_label.set_text("Upgrade Cost: %d" % cost)
		cost_label.visible = true
	else:
		cost_label.set_text("MAX LEVEL REACHED")
		cost_label.visible = true

func _update_player_stats() -> void:
	if not player_entity:
		return
	
	# Burada player stat'larını güncelle
	# Örneğin: player'ın mevcut kaynaklarını göster
	pass

func _update_upgrade_button() -> void:
	if not upgrade_button:
		return
	
	var can_upgrade_current = can_upgrade(selected_weapon_id)
	upgrade_button.set_disabled(not can_upgrade_current)
	
	if can_upgrade_current:
		var level = weapon_levels.get(selected_weapon_id, 1)
		var cost = calculate_upgrade_cost(selected_weapon_id, level)
		upgrade_button.set_text("UPGRADE (Cost: %d)" % cost)
	else:
		upgrade_button.set_text("MAX LEVEL")

# === VISIBILITY MANAGEMENT ===

func _update_visibility() -> void:
	if not is_inside_tree():
		return
	
	_update_title_visibility()
	_update_stats_visibility()
	_update_weapons_visibility()
	_update_background_visibility()

func _update_title_visibility() -> void:
	if not is_inside_tree():
		return
	
	if title_label:
		title_label.visible = show_title

func _update_stats_visibility() -> void:
	if not is_inside_tree():
		return
	
	if stats_panel:
		stats_panel.visible = show_stats

func _update_weapons_visibility() -> void:
	if not is_inside_tree():
		return
	
	if weapons_container:
		weapons_container.visible = show_weapons

func _update_background_visibility() -> void:
	if not is_inside_tree():
		return
	
	if background_panel:
		background_panel.visible = show_background

func _update_animations() -> void:
	# Animation settings güncellenebilir
	pass

# === BUTTON MANAGEMENT ===

func _connect_button_events() -> void:
	if upgrade_button:
		upgrade_button.button_pressed.connect(_on_upgrade_button_pressed)
	if back_button:
		back_button.button_pressed.connect(_on_back_button_pressed)

# === EVENT BUS INTEGRATION ===

func _setup_event_bus_subscriptions() -> void:
	if not EventBus.is_available():
		return
	
	# Game state events
	EventBus.subscribe_static(EventBus.GAME_PAUSED, _on_game_paused)
	EventBus.subscribe_static(EventBus.GAME_RESUMED, _on_game_resumed)
	
	# Player events
	EventBus.subscribe_static(EventBus.PLAYER_STATS_CHANGED, _on_player_stats_changed)
	EventBus.subscribe_static("player_resources_changed", _on_player_resources_changed)
	
	# UI events
	EventBus.subscribe_static(EventBus.UI_SHOW, _on_ui_show)
	EventBus.subscribe_static(EventBus.UI_HIDE, _on_ui_hide)
	
	# Config events
	EventBus.subscribe_static("config_changed", _on_config_changed)

func _remove_event_bus_subscriptions() -> void:
	if not EventBus.is_available():
		return
	
	EventBus.get_instance().unsubscribe_all_for_object(self)

# === EVENT HANDLERS ===

func _on_upgrade_button_pressed() -> void:
	print("UpgradeScreen: Upgrade button pressed for weapon: %s" % selected_weapon_id)
	
	var current_level = weapon_levels.get(selected_weapon_id, 1)
	var cost = calculate_upgrade_cost(selected_weapon_id, current_level)
	
	# EventBus'a bildir
	if EventBus.is_available():
		EventBus.emit_now_static(EventBus.UI_BUTTON_CLICKED, {
			"component": "UpgradeScreen",
			"button": "upgrade",
			"weapon_id": selected_weapon_id,
			"current_level": current_level,
			"cost": cost
		})
	
	upgrade_initiated.emit(selected_weapon_id, cost, current_level + 1)
	
	# Upgrade'ı gerçekleştir
	perform_upgrade(selected_weapon_id)

func _on_back_button_pressed() -> void:
	print("UpgradeScreen: Back button pressed")
	
	# EventBus'a bildir
	if EventBus.is_available():
		EventBus.emit_now_static(EventBus.UI_BUTTON_CLICKED, {
			"component": "UpgradeScreen",
			"button": "back",
			"action": "go_back"
		})
	
	back_pressed.emit()

func _on_weapon_card_clicked(weapon_id: String) -> void:
	print("UpgradeScreen: Weapon card clicked: %s" % weapon_id)
	_select_weapon(weapon_id)

func _on_game_paused(event: EventBus.Event) -> void:
	# Oyun durduğunda upgrade screen'i göster
	fade_in()

func _on_game_resumed(event: EventBus.Event) -> void:
	# Oyun devam ettiğinde upgrade screen'i gizle
	fade_out()

func _on_player_stats_changed(event: EventBus.Event) -> void:
	# Player stat'ları değiştiğinde güncelle
	_update_player_stats()

func _on_player_resources_changed(event: EventBus.Event) -> void:
	# Player kaynakları değiştiğinde upgrade button'ı güncelle
	_update_upgrade_button()

func _on_ui_show(event: EventBus.Event) -> void:
	var component = event.data.get("component", "")
	if component == "UpgradeScreen":
		show_upgrade_screen()

func _on_ui_hide(event: EventBus.Event) -> void:
	var component = event.data.get("component", "")
	if component == "UpgradeScreen":
		hide_upgrade_screen()

func _on_config_changed(event: EventBus.Event) -> void:
	var config_file = event.data.get("file", "")
	if config_file == "ui.json":
		reload_config()

# === CLEANUP ===

func _exit_tree() -> void:
	_remove_event_bus_subscriptions()

# === DEBUG ===

func _to_string() -> String:
	return "[UpgradeScreenOrganism: Initialized: %s, Visible: %s, Fading: %s, Selected Weapon: %s]" % [
		str(is_initialized),
		str(visible),
		str(is_fading),
		selected_weapon_id
	]

func print_debug_info() -> void:
	print("=== UpgradeScreenOrganism Debug ===")
	print("Is Initialized: %s" % str(is_initialized))
	print("Is Visible: %s" % str(visible))
	print("Is Fading: %s" % str(is_fading))
	print("Show Title: %s" % str(show_title))
	print("Show Stats: %s" % str(show_stats))
	print("Show Weapons: %s" % str(show_weapons))
	print("Show Background: %s" % str(show_background))
	print("Fade Duration: %.2f" % fade_duration)
	print("Selected Weapon: %s" % selected_weapon_id)
	print("Current Weapon: %s" % current_weapon_id)
	print("Weapon Levels: %s" % str(weapon_levels))
	print("Upgrade Costs: %s" % str(upgrade_costs))
	print("Max Upgrade Level: %d" % max_upgrade_level)
	print("Cost Multiplier: %.2f" % cost_multiplier)
	print("Player Entity: %s" % ("Set" if player_entity else "Not Set"))
	print("Current Config Keys: %s" % str(current_config.keys()))