# 🎯 BUTTON ATOM
# Atomic Design: Temel buton component'i
# Tek bir iş yapar: Kullanıcı etkileşimini yönetir
class_name ButtonAtom
extends Control

# === CONFIG ===
@export var button_text: String = "Button":
	set(value):
		button_text = value
		if is_inside_tree():
			_update_label()

@export var button_style: String = "default":
	set(value):
		button_style = value
		if is_inside_tree():
			_load_style_config()

@export var is_disabled: bool = false:
	set(value):
		is_disabled = value
		if is_inside_tree():
			_update_state()

@export var config_id: String = "button.default":
	set(value):
		config_id = value
		if is_inside_tree():
			_load_config()

# === NODES ===
@onready var button: Button = $Button
@onready var label: Label = $Button/Label
@onready var hover_tween: Tween = $HoverTween
@onready var press_tween: Tween = $PressTween

# === STATE ===
var is_hovered: bool = false
var is_pressed: bool = false
var current_style: Dictionary = {}

# === EVENTS ===
signal button_pressed
signal button_hovered
signal button_exited
signal button_state_changed(is_disabled: bool)

# === LIFECYCLE ===

func _ready() -> void:
	# Config yükle
	_load_config()
	
	# Signal'leri bağla
	button.pressed.connect(_on_button_pressed)
	button.mouse_entered.connect(_on_mouse_entered)
	button.mouse_exited.connect(_on_mouse_exited)
	
	# Başlangıç durumunu güncelle
	_update_state()
	_update_label()

# === PUBLIC API ===

func set_text(new_text: String) -> void:
	button_text = new_text
	_update_label()

func set_style(new_style: String) -> void:
	button_style = new_style
	_load_style_config()

func set_disabled(disabled: bool) -> void:
	is_disabled = disabled
	_update_state()
	button_state_changed.emit(disabled)

func load_config(config_id: String) -> void:
	self.config_id = config_id

func get_current_style() -> Dictionary:
	return current_style.duplicate()

# === CONFIG MANAGEMENT ===

func _load_config() -> void:
	if not ConfigManager.is_available():
		push_warning("ConfigManager not available for ButtonAtom")
		return
	
	var config = ConfigManager.get_instance().get_config_value("ui.json", config_id, {})
	if config.is_empty():
		push_warning("ButtonAtom config not found: %s" % config_id)
		return
	
	# Config değerlerini uygula
	if "text" in config:
		button_text = config.text
	
	if "style" in config:
		button_style = config.style
	
	if "disabled" in config:
		is_disabled = config.disabled
	
	# Style config'ini yükle
	_load_style_config()

func _load_style_config() -> void:
	if not ConfigManager.is_available():
		return
	
	var style_path = "atoms.button." + button_style
	current_style = ConfigManager.get_instance().get_config_value("ui.json", style_path, {})
	
	if current_style.is_empty():
		push_warning("ButtonAtom style not found: %s" % style_path)
		_apply_default_style()
	else:
		_apply_style()

func _apply_default_style() -> void:
	# Varsayılan style
	current_style = {
		"background_color": "#4CAF50",
		"text_color": "#FFFFFF",
		"hover_color": "#45A049",
		"pressed_color": "#3D8B40",
		"disabled_color": "#666666",
		"font_size": 16,
		"corner_radius": 8,
		"min_size": "80,40"
	}
	_apply_style()

func _apply_style() -> void:
	if not is_inside_tree():
		return
	
	# Renkleri uygula
	var bg_color = _parse_color(current_style.get("background_color", "#4CAF50"))
	var text_color = _parse_color(current_style.get("text_color", "#FFFFFF"))
	var hover_color = _parse_color(current_style.get("hover_color", "#45A049"))
	var pressed_color = _parse_color(current_style.get("pressed_color", "#3D8B40"))
	var disabled_color = _parse_color(current_style.get("disabled_color", "#666666"))
	
	# StyleBox oluştur
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = bg_color
	normal_style.corner_radius_top_left = current_style.get("corner_radius", 8)
	normal_style.corner_radius_top_right = current_style.get("corner_radius", 8)
	normal_style.corner_radius_bottom_left = current_style.get("corner_radius", 8)
	normal_style.corner_radius_bottom_right = current_style.get("corner_radius", 8)
	
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = hover_color
	
	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = pressed_color
	
	var disabled_style = normal_style.duplicate()
	disabled_style.bg_color = disabled_color
	
	# Button'a uygula
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_stylebox_override("disabled", disabled_style)
	
	# Font size
	var font_size = current_style.get("font_size", 16)
	label.add_theme_font_size_override("font_size", font_size)
	
	# Text color
	label.add_theme_color_override("font_color", text_color)
	label.add_theme_color_override("font_disabled_color", disabled_color)
	
	# Minimum size
	var min_size_str = current_style.get("min_size", "80,40")
	var min_size_parts = min_size_str.split(",")
	if min_size_parts.size() == 2:
		var min_width = float(min_size_parts[0])
		var min_height = float(min_size_parts[1])
		custom_minimum_size = Vector2(min_width, min_height)
		button.custom_minimum_size = Vector2(min_width, min_height)

# === STATE MANAGEMENT ===

func _update_state() -> void:
	if not is_inside_tree():
		return
	
	button.disabled = is_disabled
	
	if is_disabled:
		button.focus_mode = Control.FOCUS_NONE
		_modulate_to(Color(0.5, 0.5, 0.5, 0.7), 0.2)
	else:
		button.focus_mode = Control.FOCUS_ALL
		_modulate_to(Color.WHITE, 0.2)

func _update_label() -> void:
	if not is_inside_tree():
		return
	
	label.text = button_text

# === ANIMATIONS ===

func _modulate_to(target_color: Color, duration: float) -> void:
	if hover_tween and hover_tween.is_valid():
		hover_tween.kill()
	
	hover_tween = create_tween()
	hover_tween.tween_property(self, "modulate", target_color, duration)
	hover_tween.set_ease(Tween.EASE_IN_OUT)
	hover_tween.set_trans(Tween.TRANS_CUBIC)

func _animate_press() -> void:
	if press_tween and press_tween.is_valid():
		press_tween.kill()
	
	press_tween = create_tween()
	
	# Press animation
	press_tween.tween_property(button, "scale", Vector2(0.95, 0.95), 0.05)
	press_tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)
	
	press_tween.set_ease(Tween.EASE_IN_OUT)
	press_tween.set_trans(Tween.TRANS_CUBIC)

# === EVENT HANDLERS ===

func _on_button_pressed() -> void:
	if is_disabled:
		return
	
	_animate_press()
	button_pressed.emit()
	
	# EventBus'a bildir
	if EventBus.is_available():
		EventBus.emit_now_static(EventBus.UI_BUTTON_CLICKED, {
			"button_id": name,
			"button_text": button_text,
			"button_style": button_style
		})

func _on_mouse_entered() -> void:
	if is_disabled:
		return
	
	is_hovered = true
	button_hovered.emit()
	
	# Hover animation
	_modulate_to(Color(1.1, 1.1, 1.1, 1.0), 0.1)

func _on_mouse_exited() -> void:
	is_hovered = false
	button_exited.emit()
	
	# Reset animation
	_modulate_to(Color.WHITE, 0.1)

# === UTILITY ===

func _parse_color(color_str: String) -> Color:
	if color_str.begins_with("#"):
		return Color(color_str)
	return Color(color_str)

# === DEBUG ===

func _to_string() -> String:
	return "[ButtonAtom: '%s', Style: %s, Disabled: %s]" % [
		button_text,
		button_style,
		str(is_disabled)
	]

func print_debug_info() -> void:
	print("=== ButtonAtom Debug ===")
	print("Text: %s" % button_text)
	print("Style: %s" % button_style)
	print("Disabled: %s" % str(is_disabled))
	print("Config ID: %s" % config_id)
	print("Current Style: %s" % str(current_style))
	print("Is Hovered: %s" % str(is_hovered))
	print("Is Pressed: %s" % str(is_pressed))