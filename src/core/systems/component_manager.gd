# 🧩 COMPONENT MANAGER
# Component'ları yöneten merkezi sistem
class_name ComponentManager
extends Node

# === STATIC ACCESS ===
static var instance: ComponentManager = null

# === REGISTRY ===
var _components_by_id: Dictionary = {}           # component_id → Component
var _components_by_type: Dictionary = {}         # type → Array[Component]
var _components_by_entity: Dictionary = {}       # entity_id → Array[Component]

# === SIGNALS ===
signal component_registered(component: Component)
signal component_unregistered(component: Component)
signal component_added_to_entity(component: Component, entity: Node)
signal component_removed_from_entity(component: Component, entity: Node)

# === LIFECYCLE ===

func _ready() -> void:
	if instance != null:
		push_warning("Multiple ComponentManager instances detected!")
		queue_free()
		return
	
	instance = self
	print("ComponentManager initialized")

func _exit_tree() -> void:
	if instance == self:
		instance = null
		print("ComponentManager destroyed")

# === PUBLIC API ===

func register_component(component: Component) -> bool:
	if not component or not component.component_id:
		push_error("Invalid component registration attempt")
		return false
	
	if component.component_id in _components_by_id:
		push_warning("Component already registered: %s" % component.component_id)
		return false
	
	# Add to registries
	_components_by_id[component.component_id] = component
	
	var component_type = component.get_class()
	if not component_type in _components_by_type:
		_components_by_type[component_type] = []
	_components_by_type[component_type].append(component)
	
	component_registered.emit(component)
	return true

func unregister_component(component: Component) -> bool:
	if not component or not component.component_id:
		return false
	
	if component.component_id not in _components_by_id:
		return false
	
	# Remove from entity registry if attached
	if component.entity:
		_remove_component_from_entity_registry(component)
	
	# Remove from type registry
	var component_type = component.get_class()
	if component_type in _components_by_type:
		_components_by_type[component_type].erase(component)
		if _components_by_type[component_type].is_empty():
			_components_by_type.erase(component_type)
	
	# Remove from ID registry
	_components_by_id.erase(component.component_id)
	
	component_unregistered.emit(component)
	return true

func attach_component_to_entity(component: Component, entity: Node) -> bool:
	if not component or not entity:
		return false
	
	if not component.component_id in _components_by_id:
		register_component(component)
	
	# Set entity reference
	component.entity = entity
	
	# Add to entity registry
	var entity_id = str(entity.get_instance_id())
	if not entity_id in _components_by_entity:
		_components_by_entity[entity_id] = []
	
	if not component in _components_by_entity[entity_id]:
		_components_by_entity[entity_id].append(component)
	
	component_added_to_entity.emit(component, entity)
	return true

func detach_component_from_entity(component: Component) -> bool:
	if not component or not component.entity:
		return false
	
	_remove_component_from_entity_registry(component)
	component.entity = null
	return true

func get_component_by_id(component_id: String) -> Component:
	return _components_by_id.get(component_id)

func get_components_by_type(component_type: String) -> Array:
	return _components_by_type.get(component_type, []).duplicate()

func get_components_by_entity(entity: Node) -> Array:
	var entity_id = str(entity.get_instance_id())
	return _components_by_entity.get(entity_id, []).duplicate()

func get_entity_components_of_type(entity: Node, component_type: String) -> Array:
	var components = get_components_by_entity(entity)
	var filtered = []
	
	for component in components:
		if component.get_class() == component_type:
			filtered.append(component)
	
	return filtered

func get_first_component_of_type(entity: Node, component_type: String) -> Component:
	var components = get_entity_components_of_type(entity, component_type)
	return components[0] if not components.is_empty() else null

func has_component_of_type(entity: Node, component_type: String) -> bool:
	return get_first_component_of_type(entity, component_type) != null

# === BATCH OPERATIONS ===

func attach_components_to_entity(components: Array, entity: Node) -> void:
	for component in components:
		if component is Component:
			attach_component_to_entity(component, entity)

func detach_all_components_from_entity(entity: Node) -> void:
	var entity_id = str(entity.get_instance_id())
	if entity_id in _components_by_entity:
		for component in _components_by_entity[entity_id].duplicate():
			detach_component_from_entity(component)
		
		_components_by_entity.erase(entity_id)

func destroy_entity_components(entity: Node) -> void:
	var components = get_components_by_entity(entity)
	for component in components:
		component.destroy()
	
	detach_all_components_from_entity(entity)

# === STATIC HELPERS ===

static func get_instance() -> ComponentManager:
	return instance

static func is_available() -> bool:
	return instance != null

# === PRIVATE METHODS ===

func _remove_component_from_entity_registry(component: Component) -> void:
	if not component.entity:
		return
	
	var entity_id = str(component.entity.get_instance_id())
	if entity_id in _components_by_entity:
		_components_by_entity[entity_id].erase(component)
		
		if _components_by_entity[entity_id].is_empty():
			_components_by_entity.erase(entity_id)
	
	component_removed_from_entity.emit(component, component.entity)

# === DEBUG & STATS ===

func get_stats() -> Dictionary:
	return {
		"total_components": _components_by_id.size(),
		"component_types": _components_by_type.size(),
		"entities_with_components": _components_by_entity.size(),
		"registered_types": _components_by_type.keys()
	}

func print_stats() -> void:
	var stats = get_stats()
	print("=== ComponentManager Stats ===")
	print("Total Components: %d" % stats.total_components)
	print("Component Types: %d" % stats.component_types)
	print("Entities with Components: %d" % stats.entities_with_components)
	print("Registered Types: %s" % str(stats.registered_types))

# === SERIALIZATION ===

func serialize_entity_components(entity: Node) -> Dictionary:
	var components_data = []
	var components = get_components_by_entity(entity)
	
	for component in components:
		components_data.append(component.serialize())
	
	return {
		"entity_id": str(entity.get_instance_id()),
		"components": components_data
	}

func deserialize_entity_components(entity: Node, data: Dictionary) -> void:
	if "components" not in data:
		return
	
	# First, clear existing components
	destroy_entity_components(entity)
	
	# Then create and deserialize new components
	for component_data in data["components"]:
		if "type" not in component_data:
			continue
		
		# Create component instance
		var component_class = load("res://src/core/components/%s.gd" % component_data["type"].to_snake_case())
		if not component_class:
			push_warning("Component class not found: %s" % component_data["type"])
			continue
		
		var component = component_class.new()
		component.deserialize(component_data)
		attach_component_to_entity(component, entity)

# === DEBUG ===

func _to_string() -> String:
	return "[ComponentManager: %d components, %d types]" % [
		_components_by_id.size(),
		_components_by_type.size()
	]