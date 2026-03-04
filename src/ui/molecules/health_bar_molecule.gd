# 🎯 HEALTH BAR MOLECULE
# Atomic Design: Health bar molecule (ProgressBar + Label + Icon)
# Belirli bir fonksiyonu var: Can durumunu gösterir
class_name HealthBarMolecule
extends Control

# === CONFIG ===
@export var show_label: bool = true:
	set(value):
		show_label = value
		if is_inside_tree():
			_update_label_visibility()

@export var show_icon: bool = true:
	set(value):
		show_icon = value
		if is_inside_tree():
			_update_icon_visibility()

@export var label_format: String = "{current}/{max}":
	set(value):
		label_format = value
		if is_inside_tree():
			_update_label_text()

@export var update_interval: float = 0.1:
	set(value):
		update_interval = value
		if is_inside_tree():
			_update_timer()

@export var config_id: String = "molecules.health_bar":
	set(value):
		config_id = value
		if is_inside_tree():
			_load_config()

# === NODES ===
@onready var progress_bar: ProgressBarAtom = $ProgressBar
@onready var health_label: LabelAtom = $HealthLabel
@onready var health_icon: IconAtom = $HealthIcon
@onready var update_timer: Timer = $UpdateTimer

# === STATE ===
var current_health: float = 100.0
var max_health: float = 100.0
var bound_entity: Node = null
var bound_component: Node = null

# === EVENTS ===
signal health_changed(old_health: float, new_health: float)
signal max_health_changed(old_max: float, new_max: float)
signal health_percentage_changed(percentage: float)
signal entity_bound(entity: Node)
signal entity_unbound

# === LIFECYCLE ===

func _ready() -> void:
	# Config yükle
	_load_config()
	
	# Başlangıç durumunu güncelle
	_update_display()
	_update_label_visibility()
	_update_icon_visibility()
	_update_timer()
	
	# Timer'ı başlat
	update_timer.timeout.connect(_on_update_timer_timeout)

# === PUBLIC API ===

func set_health(health: float, max_hp: float = -1.0) -> void:
	var old_health = current_health
	var old_max = max_health
	
	current_health = clamp(health, 0.0, max_health)
	if max_hp >= 0:
		max_health = max(max_hp, 1.0)
		current_health = clamp(current_health, 0.0, max_health)
	
	_update_display()
	
	# Event'leri emit et
	if old_health != current_health:
		health_changed.emit(old_health, current_health)
	
	if old_max != max_health:
		max_health_changed.emit(old_max, max_health)
	
	var percentage = (current_health / max_health) * 100.0
	health_percentage_changed.emit(percentage)

func bind_to_entity(entity: Node) -> void:
	# Önceki bağlantıyı temizle
	_unbind_from_entity()
	
	bound_entity = entity
	
	# HealthComponent'i ara
	if entity.has_method("get_component"):
		bound_component = entity.get_component("HealthComponent")
	elif entity.has_node("HealthComponent"):
		bound_component = entity.get_node("HealthComponent")
	
	if bound_component:
		# Signal'leri bağla
		if bound_component.has_signal("health_changed"):
			bound_component.health_changed.connect(_on_bound_health_changed)
		
		if bound_component.has_signal("max_health_changed"):
			bound_component.max_health_changed.connect(_on_bound_max_health_changed)
		
		# Başlangıç değerlerini al
		if bound_component.has_method("get_current_health"):
			current_health = bound_component.get_current_health()
		elif "current_health" in bound_component:
			current_health = bound_component.current_health
		
		if bound_component.has_method("get_max_health"):
			max_health = bound_component.get_max_health()
		elif "max_health" in bound_component:
			max_health = bound_component.max_health
		
		_update_display()
		entity_bound.emit(entity)
	else:
		push_warning("HealthBarMolecule: Entity has no HealthComponent")
		bound_entity = null

func unbind_from_entity() -> void:
	_unbind_from_entity()
	entity_unbound.emit()

func set_show_label(show: bool) -> void:
	show_label = show
	_update_label_visibility()

func set_show_icon(show: bool) -> void:
	show_icon = show
	_update_icon_visibility()

func set_label_format(format: String) -> void:
	label_format = format
	_update_label_text()

func load_config(config_id: String) -> void:
	self.config_id = config_id

func get_health_percentage() -> float:
	if max_health == 0:
		return 0.0
	return (current_health / max_health) * 100.0

func get_bound_entity() -> Node:
	return bound_entity

func get_bound_component() -> Node:
	return bound_component

# === CONFIG MANAGEMENT ===

func _load_config() -> void:
	if not ConfigManager.is_available():
		push_warning("ConfigManager not available for HealthBarMolecule")
		return
	
	var config = ConfigManager.get_instance().get_config_value("ui.json", config_id, {})
	if config.is_empty():
		push_warning("HealthBarMolecule config not found: %s" % config_id)
		return
	
	# Config değerlerini uygula
	if "show_label" in config:
		show_label = config.show_label
	
	if "show_icon" in config:
		show_icon = config.show_icon
	
	if "label_format" in config:
		label_format = config.label_format
	
	if "update_interval" in config:
		update_interval = config.update_interval
	
	# Icon path'i ayarla
	if "icon_path" in config and config.icon_path:
		var texture = load(config.icon_path)
		if texture:
			health_icon.set_icon(texture)
	
	# ProgressBar style'ını ayarla
	progress_bar.set_style("health")

# === STATE MANAGEMENT ===

func _update_display() -> void:
	if not is_inside_tree():
		return
	
	# ProgressBar'ı güncelle
	progress_bar.set_value(current_health, true)
	progress_bar.set_range(0.0, max_health)
	
	# Label'ı güncelle
	_update_label_text()

func _update_label_text() -> void:
	if not is_inside_tree():
		return
	
	var formatted_text = label_format.format({
		"current": int(current_health),
		"max": int(max_health),
		"percentage": "%.1f" % get_health_percentage(),
		"percentage_int": int(get_health_percentage())
	})
	
	health_label.set_text(formatted_text)

func _update_label_visibility() -> void:
	if not is_inside_tree():
		return
	
	health_label.visible = show_label

func _update_icon_visibility() -> void:
	if not is_inside_tree():
		return
	
	health_icon.visible = show_icon

func _update_timer() -> void:
	if not is_inside_tree():
		return
	
	update_timer.wait_time = update_interval
	if update_interval > 0:
		update_timer.start()
	else:
		update_timer.stop()

# === EVENT HANDLERS ===

func _on_bound_health_changed(old_value: float, new_value: float) -> void:
	set_health(new_value)

func _on_bound_max_health_changed(old_value: float, new_value: float) -> void:
	set_health(current_health, new_value)

func _on_update_timer_timeout() -> void:
	if bound_entity and bound_component:
		# Entity'den güncel health değerini al
		if bound_component.has_method("get_current_health"):
			var new_health = bound_component.get_current_health()
			if new_health != current_health:
				set_health(new_health)
		
		if bound_component.has_method("get_max_health"):
			var new_max = bound_component.get_max_health()
			if new_max != max_health:
				set_health(current_health, new_max)

func _unbind_from_entity() -> void:
	if bound_component:
		# Signal bağlantılarını kes
		if bound_component.has_signal("health_changed"):
			bound_component.health_changed.disconnect(_on_bound_health_changed)
		
		if bound_component.has_signal("max_health_changed"):
			bound_component.max_health_changed.disconnect(_on_bound_max_health_changed)
	
	bound_entity = null
	bound_component = null

# === DEBUG ===

func _to_string() -> String:
	var bound_info = "Unbound"
	if bound_entity:
		bound_info = bound_entity.name
	
	return "[HealthBarMolecule: %.1f/%.1f (%.1f%%), Bound: %s]" % [
		current_health,
		max_health,
		get_health_percentage(),
		bound_info
	]

func print_debug_info() -> void:
	print("=== HealthBarMolecule Debug ===")
	print("Health: %.1f/%.1f" % [current_health, max_health])
	print("Percentage: %.1f%%" % get_health_percentage())
	print("Show Label: %s" % str(show_label))
	print("Show Icon: %s" % str(show_icon))
	print("Label Format: %s" % label_format)
	print("Update Interval: %.2f" % update_interval)
	print("Config ID: %s" % config_id)
	print("Bound Entity: %s" % (bound_entity.name if bound_entity else "None"))
	print("Bound Component: %s" % (bound_component.name if bound_component else "None"))