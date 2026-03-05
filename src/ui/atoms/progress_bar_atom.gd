# 🎯 PROGRESS BAR ATOM
# Atomic Design: Temel progress bar component'i
# Tek bir iş yapar: İlerleme durumunu gösterir
class_name ProgressBarAtom
extends Control

# === CONFIG ===
@export var min_value: float = 0.0:
	set(value):
		min_value = value
		if is_inside_tree():
			_update_progress_bar()

@export var max_value: float = 100.0:
	set(value):
		max_value = value
		if is_inside_tree():
			_update_progress_bar()

@export var current_value: float = 50.0:
	set(value):
		current_value = clamp(value, min_value, max_value)
		if is_inside_tree():
			_update_progress_bar()

@export var bar_style: String = "default":
	set(value):
		bar_style = value
		if is_inside_tree():
			_load_style_config()

@export var show_percentage: bool = false:
	set(value):
		show_percentage = value
		if is_inside_tree():
			_update_label()

@export var config_id: String = "progress_bar.default":
	set(value):
		config_id = value
		if is_inside_tree():
			_load_config()

# === NODES ===
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var value_label: Label = $ValueLabel
var update_tween: Tween

# === STATE ===
var current_style: Dictionary = {}
var is_animating: bool = false

# === EVENTS ===
signal value_changed(old_value: float, new_value: float)
signal value_reached_min
signal value_reached_max
signal animation_started
signal animation_completed

# === LIFECYCLE ===

func _ready() -> void:
	# Config yükle
	_load_config()
	
	# Başlangıç durumunu güncelle
	_update_progress_bar()
	_update_label()

# === PUBLIC API ===

func set_value(new_value: float, animate: bool = true) -> void:
	var old_value = current_value
	current_value = clamp(new_value, min_value, max_value)
	
	if animate:
		_animate_value_change(old_value, current_value)
	else:
		_update_progress_bar()
	
	value_changed.emit(old_value, current_value)
	
	# Min/Max event'leri
	if current_value <= min_value:
		value_reached_min.emit()
	if current_value >= max_value:
		value_reached_max.emit()

func set_range(new_min: float, new_max: float) -> void:
	min_value = new_min
	max_value = new_max
	current_value = clamp(current_value, min_value, max_value)
	_update_progress_bar()

func set_style(new_style: String) -> void:
	bar_style = new_style
	_load_style_config()

func set_show_percentage(show: bool) -> void:
	show_percentage = show
	_update_label()

func load_config(config_id: String) -> void:
	self.config_id = config_id

func get_percentage() -> float:
	if max_value - min_value == 0:
		return 0.0
	return (current_value - min_value) / (max_value - min_value) * 100.0

func get_current_style() -> Dictionary:
	return current_style.duplicate()

# === CONFIG MANAGEMENT ===

func _load_config() -> void:
	if not ConfigManager.is_available():
		push_warning("ConfigManager not available for ProgressBarAtom")
		return
	
	var config = ConfigManager.get_instance().get_config_value("ui.json", config_id, {})
	if config.is_empty():
		push_warning("ProgressBarAtom config not found: %s" % config_id)
		return
	
	# Config değerlerini uygula
	if "min_value" in config:
		min_value = config.min_value
	
	if "max_value" in config:
		max_value = config.max_value
	
	if "current_value" in config:
		current_value = config.current_value
	
	if "style" in config:
		bar_style = config.style
	
	if "show_percentage" in config:
		show_percentage = config.show_percentage
	
	# Style config'ini yükle
	_load_style_config()

func _load_style_config() -> void:
	if not ConfigManager.is_available():
		return
	
	var style_path = "atoms.progress_bar." + bar_style
	current_style = ConfigManager.get_instance().get_config_value("ui.json", style_path, {})
	
	if current_style.is_empty():
		push_warning("ProgressBarAtom style not found: %s" % style_path)
		_apply_default_style()
	else:
		_apply_style()

func _apply_default_style() -> void:
	# Varsayılan style
	current_style = {
		"min_size": "200,20",
		"background_color": "#333333",
		"fill_color": "#4CAF50",
		"border_color": "#555555",
		"border_width": 2,
		"corner_radius": 4,
		"label_color": "#FFFFFF",
		"label_font_size": 12
	}
	_apply_style()

func _apply_style() -> void:
	if not is_inside_tree():
		return
	
	# Minimum size
	var min_size_str = current_style.get("min_size", "200,20")
	var min_size_parts = min_size_str.split(",")
	if min_size_parts.size() == 2:
		var min_width = float(min_size_parts[0])
		var min_height = float(min_size_parts[1])
		custom_minimum_size = Vector2(min_width, min_height)
		progress_bar.custom_minimum_size = Vector2(min_width, min_height)
	
	# Background style
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = _parse_color(current_style.get("background_color", "#333333"))
	bg_style.border_color = _parse_color(current_style.get("border_color", "#555555"))
	bg_style.border_width_left = current_style.get("border_width", 2)
	bg_style.border_width_top = current_style.get("border_width", 2)
	bg_style.border_width_right = current_style.get("border_width", 2)
	bg_style.border_width_bottom = current_style.get("border_width", 2)
	bg_style.corner_radius_top_left = current_style.get("corner_radius", 4)
	bg_style.corner_radius_top_right = current_style.get("corner_radius", 4)
	bg_style.corner_radius_bottom_left = current_style.get("corner_radius", 4)
	bg_style.corner_radius_bottom_right = current_style.get("corner_radius", 4)
	
	# Fill style
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = _parse_color(current_style.get("fill_color", "#4CAF50"))
	fill_style.corner_radius_top_left = current_style.get("corner_radius", 4)
	fill_style.corner_radius_top_right = current_style.get("corner_radius", 4)
	fill_style.corner_radius_bottom_left = current_style.get("corner_radius", 4)
	fill_style.corner_radius_bottom_right = current_style.get("corner_radius", 4)
	
	# ProgressBar'a uygula
	progress_bar.add_theme_stylebox_override("background", bg_style)
	progress_bar.add_theme_stylebox_override("fill", fill_style)
	
	# Label style
	var label_color = _parse_color(current_style.get("label_color", "#FFFFFF"))
	var label_font_size = current_style.get("label_font_size", 12)
	
	value_label.add_theme_color_override("font_color", label_color)
	value_label.add_theme_font_size_override("font_size", label_font_size)

# === STATE MANAGEMENT ===

func _update_progress_bar() -> void:
	if not is_inside_tree():
		return
	
	progress_bar.min_value = min_value
	progress_bar.max_value = max_value
	progress_bar.value = current_value

func _update_label() -> void:
	if not is_inside_tree():
		return
	
	if show_percentage:
		var percentage = get_percentage()
		value_label.text = "%.1f%%" % percentage
	else:
		value_label.text = "%d/%d" % [int(current_value), int(max_value)]
	
	value_label.visible = show_percentage

# === ANIMATIONS ===

func _animate_value_change(from_value: float, to_value: float) -> void:
	if update_tween and update_tween.is_valid():
		update_tween.kill()
	
	is_animating = true
	animation_started.emit()
	
	update_tween = create_tween()
	update_tween.tween_method(_set_animated_value, from_value, to_value, 0.3)
	update_tween.set_ease(Tween.EASE_OUT)
	update_tween.set_trans(Tween.TRANS_CUBIC)
	
	await update_tween.finished
	is_animating = false
	animation_completed.emit()

func _set_animated_value(value: float) -> void:
	progress_bar.value = value
	current_value = value
	
	# Label'ı güncelle
	if show_percentage:
		var percentage = get_percentage()
		value_label.text = "%.1f%%" % percentage
	else:
		value_label.text = "%d/%d" % [int(value), int(max_value)]

# === UTILITY ===

func _parse_color(color_str: String) -> Color:
	if color_str.begins_with("#"):
		return Color(color_str)
	return Color(color_str)

# === DEBUG ===

func _to_string() -> String:
	return "[ProgressBarAtom: %.1f/%.1f (%.1f%%), Style: %s]" % [
		current_value,
		max_value,
		get_percentage(),
		bar_style
	]

func print_debug_info() -> void:
	print("=== ProgressBarAtom Debug ===")
	print("Value: %.1f/%.1f" % [current_value, max_value])
	print("Percentage: %.1f%%" % get_percentage())
	print("Style: %s" % bar_style)
	print("Show Percentage: %s" % str(show_percentage))
	print("Config ID: %s" % config_id)
	print("Current Style: %s" % str(current_style))
	print("Is Animating: %s" % str(is_animating))