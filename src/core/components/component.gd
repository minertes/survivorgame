# 🎯 COMPONENT BASE CLASS
# Tüm component'lar bu sınıftan türeyecek
class_name Component
extends Node

# Component kimliği (otomatik atanır)
var component_id: String = ""

# Bağlı olduğu entity
var entity: Node = null

# Component etkin mi?
var is_enabled: bool = true

# Component önceliği (update sırası)
var priority: int = 0

# Signal'ler
signal component_initialized
signal component_enabled
signal component_disabled
signal component_destroyed

# === LIFECYCLE ===

func _ready() -> void:
	component_id = _generate_id()
	_initialize()
	component_initialized.emit()

func _initialize() -> void:
	# Override edilecek
	pass

func enable() -> void:
	is_enabled = true
	set_process(true)
	set_physics_process(true)
	set_process_input(true)
	component_enabled.emit()

func disable() -> void:
	is_enabled = false
	set_process(false)
	set_physics_process(false)
	set_process_input(false)
	component_disabled.emit()

func destroy() -> void:
	component_destroyed.emit()
	queue_free()

# === UTILITIES ===

func _generate_id() -> String:
	var timestamp = Time.get_ticks_msec()
	var random = randi() % 10000
	return "comp_%d_%04d" % [timestamp, random]

func get_entity_component(component_type: String) -> Component:
	if not entity:
		return null
	
	for child in entity.get_children():
		if child is Component and child.get_class() == component_type:
			return child as Component
	
	return null

func has_entity_component(component_type: String) -> bool:
	return get_entity_component(component_type) != null

# === DEBUG ===

func _to_string() -> String:
	return "[Component: %s]" % component_id

# === TEMPLATE METHODS (Override these) ===

# Called every frame when enabled
func update(delta: float) -> void:
	pass

# Called every physics frame when enabled  
func physics_update(delta: float) -> void:
	pass

# Handle input when enabled
func handle_input(event: InputEvent) -> void:
	pass

# Serialize component data for saving
func serialize() -> Dictionary:
	return {
		"component_id": component_id,
		"type": get_class(),
		"is_enabled": is_enabled,
		"priority": priority
	}

# Deserialize component data from save
func deserialize(data: Dictionary) -> void:
	if "is_enabled" in data:
		is_enabled = data["is_enabled"]
		if is_enabled:
			enable()
		else:
			disable()
	
	if "priority" in data:
		priority = data["priority"]