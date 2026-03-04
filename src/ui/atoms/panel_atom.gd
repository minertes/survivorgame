# 🎯 PANEL ATOM
# Atomic Design: Temel panel container component'i
# Tek bir iş yapar: İçerik için container sağlar
class_name PanelAtom
extends Control

# === CONFIG ===
@export var panel_style: String = "default":
	set(value):
		panel_style = value
		if is_inside_tree():
			_load_style_config()

@export var padding_all: int = 10:
	set(value):
		padding_all = value
		if is_inside_tree():
			_update_padding()

@export var padding_left: int = -1:
	set(value):
		padding_left = value
		if is_inside_tree():
			_update_padding()

@export var padding_top: int = -1:
	set(value):
		padding_top = value
		if is_inside_tree():
			_update_padding()

@export var padding_right: int = -1:
	set(value):
		padding_right = value
		if is_inside_tree():
			_update_padding()

@export var padding_bottom: int = -1:
	set(value):
		padding_bottom = value
		if is_inside_tree():
			_update_padding()

@export var config_id: String = "panel.default":
	set(value):
		config_id = value
		if is_inside_tree():
			_load_config()

# === NODES ===
@onready var container: Container = $Container

# === STATE ===
var current_style: Dictionary = {}

# === EVENTS ===
signal style_changed(new_style: String)
signal padding_changed
signal child_added(child: Control)
signal child_removed(child: Control)

# === LIFECYCLE ===

func _ready() -> void:
	# Config yükle
	_load_config()
	
	# Başlangıç durumunu güncelle
	_update_padding()
	
	# Child signal'lerini bağla
	child_entered_tree.connect(_on_child_entered)
	child_exiting_tree.connect(_on_child_exiting)

# === PUBLIC API ===

func set_style(new_style: String) -> void:
	panel_style = new_style
	_load_style_config()
	style_changed.emit(new_style)

func set_padding_all(padding: int) -> void:
	padding_all = padding
	padding_left = -1
	padding_top = -1
	padding_right = -1
	padding_bottom = -1
	_update_padding()

func set_padding_individual(left: int, top: int, right: int, bottom: int) -> void:
	padding_left = left
	padding_top = top
	padding_right = right
	padding_bottom = bottom
	padding_all = -1
	_update_padding()

func add_child_atom(child: Control) -> void:
	container.add_child(child)
	child_added.emit(child)

func remove_child_atom(child: Control) -> void:
	container.remove_child(child)
	child_removed.emit(child)

func clear_children() -> void:
	for child in container.get_children():
		container.remove_child(child)
		child_removed.emit(child)

func get_children_atoms() -> Array:
	return container.get_children()

func load_config(config_id: String) -> void:
	self.config_id = config_id

func get_current_style() -> Dictionary:
	return current_style.duplicate()

# === CONFIG MANAGEMENT ===

func _load_config() -> void:
	if not ConfigManager.is_available():
		push_warning("ConfigManager not available for PanelAtom")
		return
	
	var config = ConfigManager.get_instance().get_config_value("ui.json", config_id, {})
	if config.is_empty():
		push_warning("PanelAtom config not found: %s" % config_id)
		return
	
	# Config değerlerini uygula
	if "style" in config:
		panel_style = config.style
	
	if "padding" in config:
		var padding_str = str(config.padding)
		if "," in padding_str:
			var parts = padding_str.split(",")
			if parts.size() == 4:
				padding_left = int(parts[0])
				padding_top = int(parts[1])
				padding_right = int(parts[2])
				padding_bottom = int(parts[3])
				padding_all = -1
			elif parts.size() == 1:
				padding_all = int(parts[0])
		else:
			padding_all = int(padding_str)
	
	# Style config'ini yükle
	_load_style_config()

func _load_style_config() -> void:
	if not ConfigManager.is_available():
		return
	
	var style_path = "atoms.panel." + panel_style
	current_style = ConfigManager.get_instance().get_config_value("ui.json", style_path, {})
	
	if current_style.is_empty():
		push_warning("PanelAtom style not found: %s" % style_path)
		_apply_default_style()
	else:
		_apply_style()

func _apply_default_style() -> void:
	# Varsayılan style
	current_style = {
		"background_color": "#1A1A1A",
		"border_color": "#333333",
		"border_width": 2,
		"corner_radius": 8,
		"padding": "10"
	}
	_apply_style()

func _apply_style() -> void:
	if not is_inside_tree():
		return
	
	# Background style
	var panel_stylebox = StyleBoxFlat.new()
	panel_stylebox.bg_color = _parse_color(current_style.get("background_color", "#1A1A1A"))
	panel_stylebox.border_color = _parse_color(current_style.get("border_color", "#333333"))
	panel_stylebox.border_width_left = current_style.get("border_width", 2)
	panel_stylebox.border_width_top = current_style.get("border_width", 2)
	panel_stylebox.border_width_right = current_style.get("border_width", 2)
	panel_stylebox.border_width_bottom = current_style.get("border_width", 2)
	panel_stylebox.corner_radius_top_left = current_style.get("corner_radius", 8)
	panel_stylebox.corner_radius_top_right = current_style.get("corner_radius", 8)
	panel_stylebox.corner_radius_bottom_left = current_style.get("corner_radius", 8)
	panel_stylebox.corner_radius_bottom_right = current_style.get("corner_radius", 8)
	
	# Panel'a uygula
	add_theme_stylebox_override("panel", panel_stylebox)
	
	# Padding'i config'den al
	var padding_str = current_style.get("padding", "10")
	if "," in padding_str:
		var parts = padding_str.split(",")
		if parts.size() == 4:
			padding_left = int(parts[0])
			padding_top = int(parts[1])
			padding_right = int(parts[2])
			padding_bottom = int(parts[3])
			padding_all = -1
		elif parts.size() == 1:
			padding_all = int(parts[0])
	else:
		padding_all = int(padding_str)
	
	_update_padding()

# === STATE MANAGEMENT ===

func _update_padding() -> void:
	if not is_inside_tree():
		return
	
	if padding_all >= 0:
		# Tüm padding'ler aynı
		container.add_theme_constant_override("margin_left", padding_all)
		container.add_theme_constant_override("margin_top", padding_all)
		container.add_theme_constant_override("margin_right", padding_all)
		container.add_theme_constant_override("margin_bottom", padding_all)
	else:
		# Bireysel padding'ler
		if padding_left >= 0:
			container.add_theme_constant_override("margin_left", padding_left)
		if padding_top >= 0:
			container.add_theme_constant_override("margin_top", padding_top)
		if padding_right >= 0:
			container.add_theme_constant_override("margin_right", padding_right)
		if padding_bottom >= 0:
			container.add_theme_constant_override("margin_bottom", padding_bottom)
	
	padding_changed.emit()

# === EVENT HANDLERS ===

func _on_child_entered(node: Node) -> void:
	if node is Control and node.get_parent() == container:
		child_added.emit(node)

func _on_child_exiting(node: Node) -> void:
	if node is Control and node.get_parent() == container:
		child_removed.emit(node)

# === UTILITY ===

func _parse_color(color_str: String) -> Color:
	if color_str.begins_with("#"):
		return Color(color_str)
	return Color(color_str)

# === DEBUG ===

func _to_string() -> String:
	var child_count = container.get_child_count()
	return "[PanelAtom: Style: %s, Children: %d, Padding: %s]" % [
		panel_style,
		child_count,
		_get_padding_string()
	]

func _get_padding_string() -> String:
	if padding_all >= 0:
		return str(padding_all)
	else:
		return "%d,%d,%d,%d" % [padding_left, padding_top, padding_right, padding_bottom]

func print_debug_info() -> void:
	print("=== PanelAtom Debug ===")
	print("Style: %s" % panel_style)
	print("Padding: %s" % _get_padding_string())
	print("Config ID: %s" % config_id)
	print("Current Style: %s" % str(current_style))
	print("Child Count: %d" % container.get_child_count())
	print("Children: %s" % str(container.get_children()))