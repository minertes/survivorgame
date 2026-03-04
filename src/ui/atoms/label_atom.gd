# 🎯 LABEL ATOM
# Atomic Design: Temel label component'i
# Tek bir iş yapar: Metin gösterir
class_name LabelAtom
extends Control

# === CONFIG ===
@export var label_text: String = "Label":
	set(value):
		label_text = value
		if is_inside_tree():
			_update_text()

@export var label_style: String = "default":
	set(value):
		label_style = value
		if is_inside_tree():
			_load_style_config()

@export var is_auto_size: bool = true:
	set(value):
		is_auto_size = value
		if is_inside_tree():
			_update_size_mode()

@export var config_id: String = "label.default":
	set(value):
		config_id = value
		if is_inside_tree():
			_load_config()

# === NODES ===
@onready var label: Label = $Label

# === STATE ===
var current_style: Dictionary = {}

# === EVENTS ===
signal text_changed(new_text: String)
signal style_changed(new_style: String)

# === LIFECYCLE ===

func _ready() -> void:
	# Config yükle
	_load_config()
	
	# Başlangıç durumunu güncelle
	_update_text()
	_update_size_mode()

# === PUBLIC API ===

func set_text(new_text: String) -> void:
	label_text = new_text
	_update_text()
	text_changed.emit(new_text)

func set_style(new_style: String) -> void:
	label_style = new_style
	_load_style_config()
	style_changed.emit(new_style)

func set_auto_size(auto_size: bool) -> void:
	is_auto_size = auto_size
	_update_size_mode()

func load_config(config_id: String) -> void:
	self.config_id = config_id

func get_current_style() -> Dictionary:
	return current_style.duplicate()

func get_text() -> String:
	return label_text

# === CONFIG MANAGEMENT ===

func _load_config() -> void:
	if not ConfigManager.is_available():
		push_warning("ConfigManager not available for LabelAtom")
		return
	
	var config = ConfigManager.get_instance().get_config_value("ui.json", config_id, {})
	if config.is_empty():
		push_warning("LabelAtom config not found: %s" % config_id)
		return
	
	# Config değerlerini uygula
	if "text" in config:
		label_text = config.text
	
	if "style" in config:
		label_style = config.style
	
	if "auto_size" in config:
		is_auto_size = config.auto_size
	
	# Style config'ini yükle
	_load_style_config()

func _load_style_config() -> void:
	if not ConfigManager.is_available():
		return
	
	var style_path = "atoms.label." + label_style
	current_style = ConfigManager.get_instance().get_config_value("ui.json", style_path, {})
	
	if current_style.is_empty():
		push_warning("LabelAtom style not found: %s" % style_path)
		_apply_default_style()
	else:
		_apply_style()

func _apply_default_style() -> void:
	# Varsayılan style
	current_style = {
		"font_size": 16,
		"color": "#FFFFFF",
		"shadow": true,
		"shadow_color": "#000000",
		"shadow_offset": "1,1",
		"bold": false,
		"italic": false
	}
	_apply_style()

func _apply_style() -> void:
	if not is_inside_tree():
		return
	
	# Font size
	var font_size = current_style.get("font_size", 16)
	label.add_theme_font_size_override("font_size", font_size)
	
	# Text color
	var text_color = _parse_color(current_style.get("color", "#FFFFFF"))
	label.add_theme_color_override("font_color", text_color)
	
	# Shadow
	var has_shadow = current_style.get("shadow", true)
	if has_shadow:
		var shadow_color = _parse_color(current_style.get("shadow_color", "#000000"))
		var shadow_offset_str = current_style.get("shadow_offset", "1,1")
		var offset_parts = shadow_offset_str.split(",")
		
		if offset_parts.size() == 2:
			var shadow_offset = Vector2(float(offset_parts[0]), float(offset_parts[1]))
			
			# Shadow effect için Label settings
			label.add_theme_constant_override("shadow_offset_x", int(shadow_offset.x))
			label.add_theme_constant_override("shadow_offset_y", int(shadow_offset.y))
			label.add_theme_color_override("font_shadow_color", shadow_color)
	
	# Font style (bold/italic)
	var is_bold = current_style.get("bold", false)
	var is_italic = current_style.get("italic", false)
	
	# Not: Godot 4'te font style override'ları biraz farklı
	# Şimdilik sadece bold/italic flag'leri tutuyoruz

# === STATE MANAGEMENT ===

func _update_text() -> void:
	if not is_inside_tree():
		return
	
	label.text = label_text

func _update_size_mode() -> void:
	if not is_inside_tree():
		return
	
	if is_auto_size:
		label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	else:
		label.size_flags_horizontal = Control.SIZE_FILL
		label.size_flags_vertical = Control.SIZE_FILL

# === UTILITY ===

func _parse_color(color_str: String) -> Color:
	if color_str.begins_with("#"):
		return Color(color_str)
	return Color(color_str)

# === DEBUG ===

func _to_string() -> String:
	var text_preview = label_text
	if text_preview.length() > 20:
		text_preview = text_preview.substr(0, 17) + "..."
	
	return "[LabelAtom: '%s', Style: %s, AutoSize: %s]" % [
		text_preview,
		label_style,
		str(is_auto_size)
	]

func print_debug_info() -> void:
	print("=== LabelAtom Debug ===")
	print("Text: %s" % label_text)
	print("Style: %s" % label_style)
	print("Auto Size: %s" % str(is_auto_size))
	print("Config ID: %s" % config_id)
	print("Current Style: %s" % str(current_style))
	print("Text Length: %d" % label_text.length())