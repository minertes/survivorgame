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

@export var play_sound_on_click: bool = true:
	set(value):
		play_sound_on_click = value
		if is_inside_tree():
			_update_sound_settings()

@export var click_sound_name: String = "button_click":
	set(value):
		click_sound_name = value
		if is_inside_tree():
			_update_sound_settings()

@export var hover_sound_name: String = "hover":
	set(value):
		hover_sound_name = value
		if is_inside_tree():
			_update_sound_settings()

# === NODES ===
@onready var button: Button = $Button
@onready var label: Label = $Button/Label
var hover_tween: Tween
var press_tween: Tween

# === STATE ===
var is_hovered: bool = false
var is_pressed: bool = false
var current_style: Dictionary = {}
var sound_settings_loaded: bool = false

# === EVENTS ===
signal button_pressed
signal button_hovered
signal button_exited
signal button_state_changed(is_disabled: bool)
signal button_sound_played(sound_name: String, sound_type: String)

# === LIFECYCLE ===

func _ready() -> void:
	# Config yükle
	_load_config()
	
	# Signal'leri bağla
	button.pressed.connect(_on_button_pressed)
	button.mouse_entered.connect(_on_mouse_entered)
	button.mouse_exited.connect(_on_mouse_exited)
	
	# Sound settings yükle
	_load_sound_settings()
	
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

func set_sound_enabled(enabled: bool) -> void:
	play_sound_on_click = enabled
	_update_sound_settings()

func set_click_sound(sound_name: String) -> void:
	click_sound_name = sound_name
	_update_sound_settings()

func set_hover_sound(sound_name: String) -> void:
	hover_sound_name = sound_name
	_update_sound_settings()

func load_config(config_id: String) -> void:
	self.config_id = config_id

func get_current_style() -> Dictionary:
	return current_style.duplicate()

func play_click_sound() -> void:
	"""Programatik olarak click sesi oynat"""
	if play_sound_on_click and not is_disabled:
		_play_sound(click_sound_name, "click")

func play_hover_sound() -> void:
	"""Programatik olarak hover sesi oynat"""
	if play_sound_on_click and not is_disabled:
		_play_sound(hover_sound_name, "hover")

# === SOUND MANAGEMENT ===

func _load_sound_settings() -> void:
	# Config'den sound settings yükle
	if not ConfigManager.is_available():
		return
	
	var sound_config = ConfigManager.get_instance().get_config_value("ui.json", "sounds.button", {})
	if not sound_config.is_empty():
		play_sound_on_click = sound_config.get("enabled", true)
		click_sound_name = sound_config.get("click_sound", "button_click")
		hover_sound_name = sound_config.get("hover_sound", "hover")
	
	sound_settings_loaded = true
	_update_sound_settings()

func _update_sound_settings() -> void:
	# Sound settings güncelle
	# Burada AudioSystem ile entegrasyon yapılabilir
	pass

func _play_sound(sound_name: String, sound_type: String) -> void:
	"""Ses efekti oynat"""
	if sound_name.is_empty() or is_disabled:
		return
	
	# EventBus üzerinden AudioSystem'e bildir
	if EventBus.is_available():
		EventBus.emit_now_static("play_ui_sound", {
			"sound_name": sound_name,
			"source": "ButtonAtom",
			"button_id": name,
			"button_text": button_text,
			"sound_type": sound_type
		})
	
	button_sound_played.emit(sound_name, sound_type)

# === CONFIG MANAGEMENT ===

func _load_config() -> void:
	if not ConfigManager.is_available():
		push_warning("ConfigManager not available for ButtonAtom")
		return
	
	var config = ConfigManager.get_instance().get_config_value("ui.json", config_id, {})
	if config.is_empty():
		push_warning("ButtonAtom config not found: %s" % config_id)
		return
	
	current_style = config.duplicate()
	_load_style_config()

func _load_style_config() -> void:
	if not ConfigManager.is_available():
		return
	var style_config = ConfigManager.get_instance().get_config_value("ui.json", "styles." + button_style, {})
	if not style_config.is_empty():
		current_style.merge(style_config, true)
	if is_inside_tree():
		_update_state()

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
	
	# Click sesi oynat
	if play_sound_on_click:
		_play_sound(click_sound_name, "click")
	
	button_pressed.emit()
	
	# EventBus'a bildir
	if EventBus.is_available():
		EventBus.emit_now_static(EventBus.UI_BUTTON_CLICKED, {
			"button_id": name,
			"button_text": button_text,
			"button_style": button_style,
			"sound_played": play_sound_on_click,
			"sound_name": click_sound_name if play_sound_on_click else ""
		})

func _on_mouse_entered() -> void:
	if is_disabled:
		return
	
	is_hovered = true
	
	# Hover sesi oynat
	if play_sound_on_click:
		_play_sound(hover_sound_name, "hover")
	
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
	return "[ButtonAtom: '%s', Style: %s, Disabled: %s, Sound: %s]" % [
		button_text,
		button_style,
		str(is_disabled),
		"ON" if play_sound_on_click else "OFF"
	]

func print_debug_info() -> void:
	print("=== ButtonAtom Debug ===")
	print("Text: %s" % button_text)
	print("Style: %s" % button_style)
	print("Disabled: %s" % str(is_disabled))
	print("Config ID: %s" % config_id)
	print("Play Sound on Click: %s" % str(play_sound_on_click))
	print("Click Sound: %s" % click_sound_name)
	print("Hover Sound: %s" % hover_sound_name)
	print("Sound Settings Loaded: %s" % str(sound_settings_loaded))
	print("Current Style: %s" % str(current_style))
	print("Is Hovered: %s" % str(is_hovered))
	print("Is Pressed: %s" % str(is_pressed))