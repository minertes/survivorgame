# 🎯 WEAPON CARD MOLECULE
# Atomic Design: Weapon card molecule (Icon + Name + Stats)
# Belirli bir fonksiyonu var: Silah bilgilerini gösterir
class_name WeaponCardMolecule
extends Control

# === CONFIG ===
@export var show_name: bool = true:
	set(value):
		show_name = value
		if is_inside_tree():
			_update_name_visibility()

@export var show_stats: bool = true:
	set(value):
		show_stats = value
		if is_inside_tree():
			_update_stats_visibility()

@export var show_icon: bool = true:
	set(value):
		show_icon = value
		if is_inside_tree():
			_update_icon_visibility()

@export var config_id: String = "molecules.weapon_card":
	set(value):
		config_id = value
		if is_inside_tree():
			_load_config()

# === NODES ===
@onready var weapon_icon: IconAtom = $WeaponIcon
@onready var weapon_name_label: LabelAtom = $WeaponName
@onready var stats_container: PanelAtom = $StatsContainer
@onready var damage_label: LabelAtom = $StatsContainer/DamageLabel
@onready var fire_rate_label: LabelAtom = $StatsContainer/FireRateLabel
@onready var range_label: LabelAtom = $StatsContainer/RangeLabel

# === STATE ===
var weapon_id: String = ""
var weapon_data: Dictionary = {}
var is_selected: bool = false
var is_unlocked: bool = true

# === EVENTS ===
signal weapon_data_loaded(weapon_id: String, data: Dictionary)
signal weapon_selected(weapon_id: String)
signal weapon_deselected(weapon_id: String)
signal card_clicked

# === LIFECYCLE ===

func _ready() -> void:
	# Config yükle
	_load_config()
	
	# Başlangıç durumunu güncelle
	_update_visibility()
	
	# Click event'ini bağla
	gui_input.connect(_on_gui_input)

# === PUBLIC API ===

func load_weapon(weapon_id: String) -> void:
	self.weapon_id = weapon_id
	
	if not ConfigManager.is_available():
		push_warning("ConfigManager not available for WeaponCardMolecule")
		return
	
	# Weapon config'ini yükle
	weapon_data = ConfigManager.get_instance().get_weapon_config(weapon_id)
	
	if weapon_data.is_empty():
		push_warning("WeaponCardMolecule: Weapon config not found: %s" % weapon_id)
		return
	
	# UI'yi güncelle
	_update_display()
	
	weapon_data_loaded.emit(weapon_id, weapon_data)

func set_selected(selected: bool) -> void:
	is_selected = selected
	_update_selection_state()

func set_unlocked(unlocked: bool) -> void:
	is_unlocked = unlocked
	_update_unlock_state()

func set_show_name(show: bool) -> void:
	show_name = show
	_update_name_visibility()

func set_show_stats(show: bool) -> void:
	show_stats = show
	_update_stats_visibility()

func set_show_icon(show: bool) -> void:
	show_icon = show
	_update_icon_visibility()

func load_config(config_id: String) -> void:
	self.config_id = config_id

func get_weapon_id() -> String:
	return weapon_id

func get_weapon_data() -> Dictionary:
	return weapon_data.duplicate()

func is_weapon_loaded() -> bool:
	return not weapon_data.is_empty()

# === CONFIG MANAGEMENT ===

func _load_config() -> void:
	if not ConfigManager.is_available():
		push_warning("ConfigManager not available for WeaponCardMolecule")
		return
	
	var config = ConfigManager.get_instance().get_config_value("ui.json", config_id, {})
	if config.is_empty():
		push_warning("WeaponCardMolecule config not found: %s" % config_id)
		return
	
	# Config değerlerini uygula
	if "show_name" in config:
		show_name = config.show_name
	
	if "show_stats" in config:
		show_stats = config.show_stats
	
	if "show_icon" in config:
		show_icon = config.show_icon
	
	# Icon size'ı ayarla
	if "icon_size" in config:
		var size_str = str(config.icon_size)
		if "," in size_str:
			var parts = size_str.split(",")
			if parts.size() == 2:
				var icon_size = Vector2(float(parts[0]), float(parts[1]))
				weapon_icon.set_icon_size(icon_size)

# === STATE MANAGEMENT ===

func _update_display() -> void:
	if not is_inside_tree():
		return
	
	# Weapon name
	if "name" in weapon_data:
		weapon_name_label.set_text(weapon_data.name)
	
	# Weapon icon (simülasyon - gerçek projede asset path'leri kullan)
	# weapon_icon.set_icon(load(weapon_data.get("icon_path", "")))
	
	# Stats
	if "damage" in weapon_data:
		damage_label.set_text("Damage: %.1f" % weapon_data.damage)
	
	if "fire_rate" in weapon_data:
		fire_rate_label.set_text("Fire Rate: %.1f/s" % (1.0 / weapon_data.fire_rate))
	
	if "range" in weapon_data:
		range_label.set_text("Range: %.0f" % weapon_data.range)
	
	# Unlock durumunu güncelle
	if "unlock_level" in weapon_data:
		# Burada unlock kontrolü yapılabilir
		pass

func _update_visibility() -> void:
	_update_name_visibility()
	_update_stats_visibility()
	_update_icon_visibility()

func _update_name_visibility() -> void:
	if not is_inside_tree():
		return
	
	weapon_name_label.visible = show_name

func _update_stats_visibility() -> void:
	if not is_inside_tree():
		return
	
	stats_container.visible = show_stats

func _update_icon_visibility() -> void:
	if not is_inside_tree():
		return
	
	weapon_icon.visible = show_icon

func _update_selection_state() -> void:
	if not is_inside_tree():
		return
	
	if is_selected:
		# Seçili durumda highlight
		modulate = Color(1.2, 1.2, 1.2, 1.0)
		weapon_selected.emit(weapon_id)
	else:
		# Normal durum
		modulate = Color.WHITE
		weapon_deselected.emit(weapon_id)

func _update_unlock_state() -> void:
	if not is_inside_tree():
		return
	
	if is_unlocked:
		# Açık durum
		modulate = Color.WHITE
		mouse_filter = MOUSE_FILTER_PASS
	else:
		# Kilitli durum
		modulate = Color(0.5, 0.5, 0.5, 0.7)
		mouse_filter = MOUSE_FILTER_IGNORE

# === EVENT HANDLERS ===

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if is_unlocked:
				# Card click event'i
				card_clicked.emit()
				
				# EventBus'a bildir
				if EventBus.is_available():
					EventBus.emit_now_static(EventBus.UI_BUTTON_CLICKED, {
						"component": "WeaponCardMolecule",
						"weapon_id": weapon_id,
						"weapon_name": weapon_data.get("name", "Unknown")
					})
				
				# Seçili durumu değiştir
				set_selected(true)

# === DEBUG ===

func _to_string() -> String:
	var weapon_name = weapon_data.get("name", "Unknown") if not weapon_data.is_empty() else "Not Loaded"
	return "[WeaponCardMolecule: %s (%s), Selected: %s, Unlocked: %s]" % [
		weapon_name,
		weapon_id,
		str(is_selected),
		str(is_unlocked)
	]

func print_debug_info() -> void:
	print("=== WeaponCardMolecule Debug ===")
	print("Weapon ID: %s" % weapon_id)
	print("Weapon Name: %s" % weapon_data.get("name", "Unknown"))
	print("Show Name: %s" % str(show_name))
	print("Show Stats: %s" % str(show_stats))
	print("Show Icon: %s" % str(show_icon))
	print("Config ID: %s" % config_id)
	print("Is Selected: %s" % str(is_selected))
	print("Is Unlocked: %s" % str(is_unlocked))
	print("Weapon Data: %s" % str(weapon_data))