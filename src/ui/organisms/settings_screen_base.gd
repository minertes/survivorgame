# 🎮 SETTINGS SCREEN BASE
# Atomic Design: Settings screen base class
# Temel ayarlar ekranı işlevselliği
class_name SettingsScreenBase
extends Control

# === CONFIG ===
@export var show_title: bool = true
@export var show_sections: bool = true
@export var show_background: bool = true
@export var fade_duration: float = 0.3

# === NODES ===
@onready var background_panel: Panel = $BackgroundPanel
@onready var title_label: Label = $CenterContainer/VBoxContainer/TitleLabel
@onready var sections_container: TabContainer = $CenterContainer/VBoxContainer/SectionsContainer
@onready var save_button: Button = $CenterContainer/VBoxContainer/SaveButton
@onready var reset_button: Button = $CenterContainer/VBoxContainer/ResetButton
@onready var back_button: Button = $CenterContainer/VBoxContainer/BackButton

# === STATE ===
var is_initialized: bool = false
var is_fading: bool = false
var settings_changed: bool = false

# === EVENTS ===
signal settings_screen_initialized
signal settings_screen_visibility_changed(is_visible: bool)
signal settings_saved(settings: Dictionary)
signal settings_reset
signal back_pressed
signal fade_completed(fade_in: bool)

# === LIFECYCLE ===

func _ready() -> void:
	# Başlangıç durumunu güncelle
	_update_visibility()
	
	# Button event'lerini bağla
	_connect_button_events()
	
	is_initialized = true
	settings_screen_initialized.emit()
	
	# Fade in animation
	fade_in()

# === PUBLIC API ===

func fade_in() -> void:
	if is_fading:
		return
	
	is_fading = true
	visible = true
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	
	modulate = Color.TRANSPARENT
	tween.tween_property(self, "modulate", Color.WHITE, fade_duration)
	tween.tween_callback(func(): 
		is_fading = false
		fade_completed.emit(true)
	)

func fade_out() -> void:
	if is_fading:
		return
	
	is_fading = true
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN)
	
	tween.tween_property(self, "modulate", Color.TRANSPARENT, fade_duration)
	tween.tween_callback(func(): 
		visible = false
		is_fading = false
		fade_completed.emit(false)
	)

func show_settings_screen() -> void:
	visible = true
	settings_screen_visibility_changed.emit(true)

func hide_settings_screen() -> void:
	visible = false
	settings_screen_visibility_changed.emit(false)

func toggle_settings_screen() -> void:
	visible = not visible
	settings_screen_visibility_changed.emit(visible)

func set_title(text: String) -> void:
	if title_label:
		title_label.text = text

func set_background_color(color: Color) -> void:
	if background_panel:
		var stylebox = background_panel.get_theme_stylebox("panel").duplicate()
		stylebox.bg_color = color
		background_panel.add_theme_stylebox_override("panel", stylebox)

func set_save_button_text(text: String) -> void:
	if save_button:
		save_button.text = text

func set_reset_button_text(text: String) -> void:
	if reset_button:
		reset_button.text = text

func set_back_button_text(text: String) -> void:
	if back_button:
		back_button.text = text

func are_settings_changed() -> bool:
	return settings_changed

func mark_settings_changed(changed: bool = true) -> void:
	settings_changed = changed
	_update_save_button_state()

# === PRIVATE METHODS ===

func _update_visibility() -> void:
	if title_label:
		title_label.visible = show_title
	
	if sections_container:
		sections_container.visible = show_sections
	
	if background_panel:
		background_panel.visible = show_background

func _connect_button_events() -> void:
	if save_button:
		save_button.pressed.connect(_on_save_button_pressed)
	
	if reset_button:
		reset_button.pressed.connect(_on_reset_button_pressed)
	
	if back_button:
		back_button.pressed.connect(_on_back_button_pressed)

func _update_save_button_state() -> void:
	if save_button:
		save_button.disabled = not settings_changed

# === EVENT HANDLERS ===

func _on_save_button_pressed() -> void:
	print("Settings saved")
	settings_saved.emit({})
	settings_changed = false
	_update_save_button_state()

func _on_reset_button_pressed() -> void:
	print("Settings reset")
	settings_reset.emit()
	settings_changed = false
	_update_save_button_state()

func _on_back_button_pressed() -> void:
	print("Back pressed")
	back_pressed.emit()

# === DEBUG ===

func _to_string() -> String:
	return "[SettingsScreenBase: Initialized: %s, Visible: %s, Fading: %s, Settings Changed: %s]" % [
		str(is_initialized),
		str(visible),
		str(is_fading),
		str(settings_changed)
	]

func print_debug_info() -> void:
	print("=== SettingsScreenBase Debug ===")
	print("Is Initialized: %s" % str(is_initialized))
	print("Is Visible: %s" % str(visible))
	print("Is Fading: %s" % str(is_fading))
	print("Show Title: %s" % str(show_title))
	print("Show Sections: %s" % str(show_sections))
	print("Show Background: %s" % str(show_background))
	print("Fade Duration: %.2f" % fade_duration)
	print("Settings Changed: %s" % str(settings_changed))