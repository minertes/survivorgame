# 🎯 ICON ATOM
# Atomic Design: Temel icon component'i
# Tek bir iş yapar: İkon gösterir
class_name IconAtom
extends Control

# === CONFIG ===
@export var icon_texture: Texture2D = null:
	set(value):
		icon_texture = value
		if is_inside_tree():
			_update_icon()

@export var icon_size: Vector2 = Vector2(32, 32):
	set(value):
		icon_size = value
		if is_inside_tree():
			_update_size()

@export var icon_color: Color = Color.WHITE:
	set(value):
		icon_color = value
		if is_inside_tree():
			_update_color()

@export var is_tint_enabled: bool = true:
	set(value):
		is_tint_enabled = value
		if is_inside_tree():
			_update_color()

@export var config_id: String = "":
	set(value):
		config_id = value
		if is_inside_tree():
			_load_config()

# === NODES ===
@onready var texture_rect: TextureRect = $TextureRect
var _color_tween: Tween

# === STATE ===
var original_color: Color = Color.WHITE

# === EVENTS ===
signal icon_changed(new_texture: Texture2D)
signal size_changed(new_size: Vector2)
signal color_changed(new_color: Color)
signal tint_toggled(is_enabled: bool)

# === LIFECYCLE ===

func _ready() -> void:
	# Config yükle
	if config_id:
		_load_config()
	
	# Başlangıç durumunu güncelle
	_update_icon()
	_update_size()
	_update_color()
	
	original_color = icon_color

# === PUBLIC API ===

func set_icon(new_texture: Texture2D) -> void:
	icon_texture = new_texture
	_update_icon()
	icon_changed.emit(new_texture)

func set_icon_from_path(path: String) -> void:
	"""Dosya yolundan Texture2D yükleyip ikon ayarla"""
	if path.is_empty():
		return
	var tex := load(path) as Texture2D
	if tex:
		set_icon(tex)

func set_icon_size(new_size: Vector2) -> void:
	icon_size = new_size
	_update_size()
	size_changed.emit(new_size)

func set_color(new_color: Color, animate: bool = false) -> void:
	if animate:
		_animate_color_change(icon_color, new_color)
	else:
		icon_color = new_color
		_update_color()
	
	color_changed.emit(new_color)

func set_tint_enabled(enabled: bool) -> void:
	is_tint_enabled = enabled
	_update_color()
	tint_toggled.emit(enabled)

func reset_color() -> void:
	set_color(original_color, true)

func load_config(config_id: String) -> void:
	self.config_id = config_id

func get_icon() -> Texture2D:
	return icon_texture

func get_icon_size() -> Vector2:
	return icon_size

func get_color() -> Color:
	return icon_color

# === CONFIG MANAGEMENT ===

func _load_config() -> void:
	if not config_id or not ConfigManager.is_available():
		return
	
	var config = ConfigManager.get_instance().get_config_value("ui.json", config_id, {})
	if config.is_empty():
		push_warning("IconAtom config not found: %s" % config_id)
		return
	
	# Config değerlerini uygula
	if "texture_path" in config and config.texture_path:
		var texture = load(config.texture_path)
		if texture:
			icon_texture = texture
	
	if "size" in config:
		var size_str = str(config.size)
		if "," in size_str:
			var parts = size_str.split(",")
			if parts.size() == 2:
				icon_size = Vector2(float(parts[0]), float(parts[1]))
	
	if "color" in config:
		icon_color = _parse_color(config.color)
		original_color = icon_color
	
	if "tint_enabled" in config:
		is_tint_enabled = config.tint_enabled

# === STATE MANAGEMENT ===

func _update_icon() -> void:
	if not is_inside_tree():
		return
	
	texture_rect.texture = icon_texture

func _update_size() -> void:
	if not is_inside_tree():
		return
	
	custom_minimum_size = icon_size
	texture_rect.custom_minimum_size = icon_size
	texture_rect.size = icon_size

func _update_color() -> void:
	if not is_inside_tree():
		return
	
	if is_tint_enabled:
		texture_rect.modulate = icon_color
	else:
		texture_rect.modulate = Color.WHITE

# === ANIMATIONS ===

func _animate_color_change(from_color: Color, to_color: Color) -> void:
	if _color_tween and _color_tween.is_valid():
		_color_tween.kill()
	
	_color_tween = create_tween()
	_color_tween.tween_method(_set_animated_color, from_color, to_color, 0.3)
	_color_tween.set_ease(Tween.EASE_IN_OUT)
	_color_tween.set_trans(Tween.TRANS_CUBIC)

func _set_animated_color(color: Color) -> void:
	icon_color = color
	_update_color()

func pulse_color(pulse_color: Color, duration: float = 0.5) -> void:
	if _color_tween and _color_tween.is_valid():
		_color_tween.kill()
	
	var original = icon_color
	
	_color_tween = create_tween()
	_color_tween.tween_method(_set_animated_color, original, pulse_color, duration / 2)
	_color_tween.tween_method(_set_animated_color, pulse_color, original, duration / 2)
	
	_color_tween.set_ease(Tween.EASE_IN_OUT)
	_color_tween.set_trans(Tween.TRANS_CUBIC)

# === UTILITY ===

func _parse_color(color_str: String) -> Color:
	if color_str.begins_with("#"):
		return Color(color_str)
	return Color(color_str)

# === DEBUG ===

func _to_string() -> String:
	var texture_name = "None"
	if icon_texture:
		texture_name = icon_texture.resource_path.get_file()
	
	return "[IconAtom: %s, Size: %s, Color: %s]" % [
		texture_name,
		str(icon_size),
		str(icon_color)
	]

func print_debug_info() -> void:
	print("=== IconAtom Debug ===")
	print("Texture: %s" % (icon_texture.resource_path if icon_texture else "None"))
	print("Size: %s" % str(icon_size))
	print("Color: %s" % str(icon_color))
	print("Tint Enabled: %s" % str(is_tint_enabled))
	print("Config ID: %s" % config_id)
	print("Original Color: %s" % str(original_color))