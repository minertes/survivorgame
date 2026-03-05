# 🎮 ENTITY BASE CLASS
# Tüm oyun varlıkları bu sınıftan türeyecek
class_name Entity
extends Node2D

# === IDENTIFICATION ===
var entity_id: String = ""
var entity_name: String = "Unnamed Entity"
var entity_type: String = "generic"

# === COMPONENT SYSTEM ===
var components: Array[Component] = []
var component_manager: ComponentManager = null

# === STATE ===
var is_active: bool = true
var is_destroyed: bool = false

# === SIGNALS ===
signal entity_initialized
signal entity_activated
signal entity_deactivated
signal entity_destroyed
signal component_added(component: Component)
signal component_removed(component: Component)

# === LIFECYCLE ===

func _ready() -> void:
	entity_id = _generate_id()
	component_manager = ComponentManager.get_instance()
	_initialize_entity()
	entity_initialized.emit()

func _initialize_entity() -> void:
	# Override edilecek
	pass

func activate() -> void:
	is_active = true
	set_process(true)
	set_physics_process(true)
	set_process_input(true)
	
	# Activate all components
	for component in components:
		if component.is_enabled:
			component.enable()
	
	entity_activated.emit()

func deactivate() -> void:
	is_active = false
	set_process(false)
	set_physics_process(false)
	set_process_input(false)
	
	# Deactivate all components
	for component in components:
		component.disable()
	
	entity_deactivated.emit()

func destroy() -> void:
	if is_destroyed:
		return
	
	is_destroyed = true
	
	# Destroy all components
	if component_manager:
		component_manager.destroy_entity_components(self)
	
	components.clear()
	
	entity_destroyed.emit()
	queue_free()

# === COMPONENT MANAGEMENT ===

func add_component(component: Component) -> Component:
	if not component:
		return null
	
	add_child(component)
	components.append(component)
	
	if component_manager:
		component_manager.attach_component_to_entity(component, self)
	
	component_added.emit(component)
	return component

func remove_component(component: Component) -> bool:
	if not component or not component in components:
		return false
	
	if component_manager:
		component_manager.detach_component_from_entity(component)
	
	components.erase(component)
	remove_child(component)
	
	component_removed.emit(component)
	return true

func get_component(component_type: String) -> Component:
	if component_manager:
		return component_manager.get_first_component_of_type(self, component_type)
	
	# Fallback: local search
	for component in components:
		if component.get_class() == component_type:
			return component
	
	return null

func has_component(component_type: String) -> bool:
	return get_component(component_type) != null

func get_components_of_type(component_type: String) -> Array:
	if component_manager:
		return component_manager.get_entity_components_of_type(self, component_type)
	
	# Fallback: local search
	var result = []
	for component in components:
		if component.get_class() == component_type:
			result.append(component)
	
	return result

func add_components(component_list: Array) -> void:
	for component in component_list:
		if component is Component:
			add_component(component)

# === UTILITIES ===

func _generate_id() -> String:
	var timestamp = Time.get_ticks_msec()
	var random = randi() % 10000
	return "entity_%d_%04d" % [timestamp, random]

func get_component_count() -> int:
	return components.size()

func get_component_types() -> Array:
	var types = []
	for component in components:
		types.append(component.get_class())
	return types

# === TEMPLATE METHODS ===

func update(delta: float) -> void:
	# Override edilecek
	pass

func physics_update(delta: float) -> void:
	# Override edilecek
	pass

func handle_input(event: InputEvent) -> void:
	# Override edilecek
	pass

# === SERIALIZATION ===

func serialize() -> Dictionary:
	var components_data = []
	
	for component in components:
		components_data.append(component.serialize())
	
	return {
		"entity_id": entity_id,
		"entity_name": entity_name,
		"entity_type": entity_type,
		"is_active": is_active,
		"position_x": position.x,
		"position_y": position.y,
		"rotation": rotation,
		"scale_x": scale.x,
		"scale_y": scale.y,
		"components": components_data
	}

func deserialize(data: Dictionary) -> void:
	if "entity_name" in data:
		entity_name = data["entity_name"]
	if "entity_type" in data:
		entity_type = data["entity_type"]
	if "is_active" in data:
		is_active = data["is_active"]
		if is_active:
			activate()
		else:
			deactivate()
	if "position_x" in data and "position_y" in data:
		position = Vector2(data["position_x"], data["position_y"])
	if "rotation" in data:
		rotation = data["rotation"]
	if "scale_x" in data and "scale_y" in data:
		scale = Vector2(data["scale_x"], data["scale_y"])
	
	# Components will be deserialized by ComponentManager

# === DEBUG ===

func _to_string() -> String:
	return "[Entity: %s (%s) - %d components]" % [
		entity_name,
		entity_type,
		components.size()
	]

func print_debug_info() -> void:
	print("=== Entity Debug: %s ===" % entity_name)
	print("ID: %s" % entity_id)
	print("Type: %s" % entity_type)
	print("Active: %s" % str(is_active))
	print("Position: %s" % str(position))
	print("Components (%d):" % components.size())
	
	for i in range(components.size()):
		var component = components[i]
		print("  %d. %s" % [i + 1, component])
