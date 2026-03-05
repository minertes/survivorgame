# 🎮 SETTINGS SCREEN ORGANISM (BACKUP)
# Atomic Design: Settings screen organism - yedek sürüm
class_name SettingsScreenOrganismBackup
extends Control

# === CONFIG ===
@export var show_title: bool = true:
	set(value):
		show_title = value
		if is_inside_tree():
			_update_title_visibility()

@export var show_sections: bool = true:
	set(value):
		show_sections = value
		if is_inside_tree():
			_update_sections_visibility()

@export var show_background: bool = true:
	set(value):
		show_background = value
		if is_inside_tree():
			_update_background_visibility()

@export var fade_duration: float = 0.3:
	set(value):
		fade_duration = value
		if is_inside_tree():
			_update_animations()

# === NODES ===
@onready var background_panel: PanelAtom = $BackgroundPanel
@onready var title_label: LabelAtom = $CenterContainer/VBoxContainer/TitleLabel
@onready var sections_container: TabContainer = $CenterContainer/VBoxContainer/SectionsContainer
@onready var audio_settings_organism: AudioSettingsOrganism = $CenterContainer/VBoxContainer/SectionsContainer/AudioSettingsOrganism
@onready var graphics_section: PanelAtom = $CenterContainer/VBoxContainer/SectionsContainer/GraphicsSection
@onready var controls_section: PanelAtom = $CenterContainer/VBoxContainer/SectionsContainer/ControlsSection
@onready var gameplay_section: PanelAtom = $CenterContainer/VBoxContainer/SectionsContainer/GameplaySection
@onready var quality_label: LabelAtom = $CenterContainer/VBoxContainer/SectionsContainer/GraphicsSection/QualityLabel
@onready var quality_dropdown: ButtonAtom = $CenterContainer/VBoxContainer/SectionsContainer/GraphicsSection/QualityDropdown
@onready var resolution_label: LabelAtom = $CenterContainer/VBoxContainer/SectionsContainer/GraphicsSection/ResolutionLabel
@onready var resolution_dropdown: ButtonAtom = $CenterContainer/VBoxContainer/SectionsContainer/GraphicsSection/ResolutionDropdown
@onready var vsync_label: LabelAtom = $CenterContainer/VBoxContainer/SectionsContainer/GraphicsSection/VSyncLabel
@onready var vsync_toggle: ButtonAtom = $CenterContainer/VBoxContainer/SectionsContainer/GraphicsSection/VSyncToggle
@onready var keybind_container: VBoxContainer = $CenterContainer/VBoxContainer/SectionsContainer/ControlsSection/KeybindContainer
@onready var sensitivity_label: LabelAtom = $CenterContainer/VBoxContainer/SectionsContainer/GameplaySection/SensitivityLabel
@onready var sensitivity_slider: ProgressBarAtom = $CenterContainer/VBoxContainer/SectionsContainer/GameplaySection/SensitivitySlider
@onready var save_button: ButtonAtom = $CenterContainer/VBoxContainer/SaveButton
@onready var reset_button: ButtonAtom = $CenterContainer/VBoxContainer/ResetButton
@onready var back_button: ButtonAtom = $CenterContainer/VBoxContainer/BackButton
var fade_tween = null  # create_tween() ile runtime'da oluşturulur (Tween)

# === STATE ===
var is_initialized: bool = false
var is_fading: bool = false
var current_config: Dictionary = {}
var settings_changed: bool = false
var current_settings: Dictionary = {
	"audio": {
		"master_volume": 80,
		"music_volume": 70,
		"sfx_volume": 90,
		"ui_volume": 70
	},
	"graphics": {
		"quality": "medium",
		"resolution": "1920x1080",
		"vsync": true
	},
	"controls": {
		"move_up": "W",
		"move_down": "S",
		"move_left": "A",
		"move_right": "D",
		"shoot": "MOUSE_LEFT",
		"reload": "R",
		"interact": "E"
	},
	"gameplay": {
		"mouse_sensitivity": 50,
		"show_damage_numbers": true,
		"show_hit_indicators": true
	}
}
var default_settings: Dictionary = {}
var available_qualities: Array = ["low", "medium", "high", "ultra"]
var available_resolutions: Array = ["1920x1080", "1600x900", "1366x768", "1280x720"]
var keybind_buttons: Dictionary = {}

# === EVENTS ===
signal settings_screen_initialized
signal settings_screen_visibility_changed(is_visible: bool)
signal setting_changed(section: String, key: String, value)
signal settings_saved(settings: Dictionary)
signal settings_reset
signal back_pressed
signal fade_completed(fade_in: bool)

# === LIFECYCLE ===

func _ready() -> void:
	# Başlangıç durumunu güncelle
	_update_visibility()
	_update_animations()
	
	# Button event'lerini bağla
	_connect_button_events()
	
	# Slider event'lerini bağla
	_connect_slider_events()
	
	# Config yükle
	_load_config()
	
	# EventBus subscription'ları
	_setup_event_bus_subscriptions()
	
	# Default settings'i kaydet
	default_settings = current_settings.duplicate(true)
	
	# Keybind butonlarını başlat
	_initialize_keybind_buttons()
	
	# Audio settings'i yükle
	_load_audio_settings()
	
	# UI'yi güncelle
	_update_settings_display()
	
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
	
	if fade_tween:
		fade_tween.kill()
	
	fade_tween = create_tween()
	fade_tween.set_trans(Tween.TRANS_CUBIC)
	fade_tween.set_ease(Tween.EASE_OUT)
	
	modulate = Color.TRANSPARENT
	fade_tween.tween_property(self, "modulate", Color.WHITE, fade_duration)
	fade_tween.tween_callback(func(): 
		is_fading = false
		fade_completed.emit(true)
	)

func fade_out() -> void:
	if is_fading:
		return
	
	is_fading = true
	
	if fade_tween:
		fade_tween.kill()
	
	fade_tween = create_tween()
	fade_tween.set_trans(Tween.TRANS_CUBIC)
	fade_tween.set_ease(Tween.EASE_IN)
	
	fade_tween.tween_property(self, "modulate", Color.TRANSPARENT, fade_duration)
	fade_tween.tween_callback(func(): 
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

func set_setting(section: String, key: String, value) -> void:
	if not section in current_settings:
		current_settings[section] = {}
	
	current_settings[section][key] = value
	settings_changed = true
	
	# UI'yi güncelle
	_update_setting_display(section, key, value)
	
	# Event emit
	setting_changed.emit(section, key, value)
	
	# EventBus'a bildir
	if EventBus.is_available():
		EventBus.emit_now_static("setting_changed", {
			"section": section,
			"key": key,
			"value": value,
			"settings_changed": settings_changed
		})

func get_setting(section: String, key: String, default = null):
	if section in current_settings and key in current_settings[section]:
		return current_settings[section][key]
	return default

func get_all_settings() -> Dictionary:
	return current_settings.duplicate(true)

func save_settings() -> void:
	# Burada settings'leri persistent storage'a kaydet
	print("SettingsScreen: Saving settings...")
	
	# Audio settings'leri kaydet
	_save_audio_settings()
	
	# EventBus'a bildir
	if EventBus.is_available():
		EventBus.emit_now_static("settings_saving", {
			"settings": current_settings.duplicate(true)
		})
	
	# Settings'leri uygula
	_apply_settings()
	
	settings_changed = false
	settings_saved.emit(current_settings.duplicate(true))
	
	# EventBus'a bildir
	if EventBus.is_available():
		EventBus.emit_now_static("settings_saved", {
			"settings": current_settings.duplicate(true)
		})

func reset_settings() -> void:
	print("SettingsScreen: Resetting settings to defaults")
	
	# Default settings'e dön
	current_settings = default_settings.duplicate(true)
	settings_changed = true
	
	# Audio settings'i reset et
	if audio_settings_organism:
		audio_settings_organism.reset_to_defaults()
		_save_audio_settings()
	
	# UI'yi güncelle
	_update_settings_display()
	
	settings_reset.emit()
	
	# EventBus'a bildir
	if EventBus.is_available():
		EventBus.emit_now_static("settings_reset", {
			"settings": current_settings.duplicate(true)
		})

func set_title(text: String) -> void:
	if title_label:
		title_label.set_text(text)

func set_background_color(color: Color) -> void:
	if background_panel:
		background_panel.set_background_color(color)

func set_save_button_text(text: String) -> void:
	if save_button:
		save_button.set_text(text)

func set_reset_button_text(text: String) -> void:
	if reset_button:
		reset_button.set_text(text)

func set_back_button_text(text: String) -> void:
	if back_button:
		back_button.set_text(text)

func set_save_button_style(style: String) -> void:
	if save_button:
		save_button.set_style(style)

func set_reset_button_style(style: String) -> void:
	if reset_button:
		reset_button.set_style(style)

func set_back_button_style(style: String) -> void:
	if back_button:
		back_button.set_style(style)

func reload_config() -> void:
	_load_config()

func are_settings_changed() -> bool:
	return settings_changed

# === AUDIO SETTINGS MANAGEMENT ===

func _load_audio_settings() -> void:
	# Audio settings'leri current_settings'den yükle
	if audio_settings_organism:
		var audio_settings = current_settings.get("audio", {})
		audio_settings_organism.load_settings(audio_settings)
		
		# Audio settings organism event'lerini bağla
		audio_settings_organism.audio_setting_changed.connect(_on_audio_setting_changed)
		audio_settings_organism.audio_test_requested.connect(_on_audio_test_requested)

func _save_audio_settings() -> void:
	# Audio settings'leri kaydet
	if audio_settings_organism:
		var saved_audio_settings = audio_settings_organism.save_settings()
		current_settings["audio"] = saved_audio_settings

func _on_audio_setting_changed(bus_name: String, volume: int, muted: bool) -> void:
	# Audio setting değişti
	settings_changed = true
	
	# Current settings'i güncelle
	if not "audio" in current_settings:
		current_settings["audio"] = {}
	
	current_settings["audio"][bus_name.to_lower() + "_volume"] = volume
	current_settings["audio"][bus_name.to_lower() + "_muted"] = muted
	
	# Event emit
	setting_changed.emit("audio", bus_name.to_lower() + "_volume", volume)
	setting_changed.emit("audio", bus_name.to_lower() + "_muted", muted)
	
	# Save button state
	save_button.set_disabled(not settings_changed)

func _on_audio_test_requested(test_type: String) -> void:
	# Audio test isteği
	print("SettingsScreen: Audio test requested: %s" % test_type)
	
	# EventBus'a bildir
	if EventBus.is_available():
		EventBus.emit_now_static("play_test_sound", {
			"sound_type": test_type,
			"source": "SettingsScreen"
		})

# === CONFIG MANAGEMENT ===

func _load_config() -> void:
	if not ConfigManager.is_available():
		push_warning("ConfigManager not available")
		return
	
	var config = ConfigManager.get_instance().get_config_value("ui.json", "screens.settings_screen", {})
	current_config = config
	
	# Apply config
	_apply_config(config)

func _apply_config(config: Dictionary) -> void:
	pass  # Config uygulama - mevcut kod

# === SETTINGS MANAGEMENT ===

func _apply_settings() -> void:
	# Audio settings
	_apply_audio_settings()
	
	# Graphics settings
	_apply_graphics_settings()
	
	# Gameplay settings
	_apply_gameplay_settings()

func _apply_audio_settings() -> void:
	# Audio settings'leri AudioSystem'e uygula
	var audio = current_settings.audio
	
	# Master volume
	var master_volume = audio.get("master_volume", 80) / 100.0
	var master_muted = audio.get("master_muted", false)
	
	# Music volume
	var music_volume = audio.get("music_volume", 70) / 100.0
	var music_muted = audio.get("music_muted", false)
	
	# SFX volume
	var sfx_volume = audio.get("sfx_volume", 90) / 100.0
	var sfx_muted = audio.get("sfx_muted", false)
	
	# UI volume
	var ui_volume = audio.get("ui_volume", 70) / 100.0
	var ui_muted = audio.get("ui_muted", false)
	
	# EventBus üzerinden AudioSystem'e bildir
	if EventBus.is_available():
		EventBus.emit_now_static("apply_audio_settings", {
			"master": {"volume": master_volume, "muted": master_muted},
			"music": {"volume": music_volume, "muted": music_muted},
			"sfx": {"volume": sfx_volume, "muted": sfx_muted},
			"ui": {"volume": ui_volume, "muted": ui_muted}
		})

func _apply_graphics_settings() -> void:
	pass  # Graphics ayarları uygulama

func _apply_gameplay_settings() -> void:
	pass  # Gameplay ayarları uygulama

func _update_settings_display() -> void:
	# Graphics section
	var graphics = current_settings.graphics
	quality_dropdown.set_text(graphics.get("quality", "medium").capitalize())
	resolution_dropdown.set_text(graphics.get("resolution", "1920x1080"))
	vsync_toggle.set_text("ON" if graphics.get("vsync", true) else "OFF")
	
	# Gameplay section
	var gameplay = current_settings.gameplay
	sensitivity_slider.set_value(gameplay.get("mouse_sensitivity", 50))
	
	# Save button state
	save_button.set_disabled(not settings_changed)

func _update_setting_display(section: String, key: String, value) -> void:
	match section:
		"graphics":
			match key:
				"quality":
					quality_dropdown.set_text(str(value).capitalize())
				"resolution":
					resolution_dropdown.set_text(str(value))
				"vsync":
					vsync_toggle.set_text("ON" if value else "OFF")
		
		"gameplay":
			match key:
				"mouse_sensitivity":
					sensitivity_slider.set_value(value)
	
	# Save button state
	save_button.set_disabled(not settings_changed)

# === KEYBIND MANAGEMENT ===

func _initialize_keybind_buttons() -> void:
	pass  # TODO: implement

func _start_keybind_listening(action: String, button: ButtonAtom) -> void:
	pass  # TODO: implement

# === VISIBILITY MANAGEMENT ===

func _update_visibility() -> void:
	pass  # TODO: implement

func _update_title_visibility() -> void:
	pass  # TODO: implement

func _update_sections_visibility() -> void:
	pass  # TODO: implement

func _update_background_visibility() -> void:
	pass  # TODO: implement

func _update_animations() -> void:
	pass  # TODO: implement

# === BUTTON & SLIDER MANAGEMENT ===

func _connect_button_events() -> void:
	if save_button:
		save_button.button_pressed.connect(_on_save_button_pressed)
	if reset_button:
		reset_button.button_pressed.connect(_on_reset_button_pressed)
	if back_button:
		back_button.button_pressed.connect(_on_back_button_pressed)
	if quality_dropdown:
		quality_dropdown.button_pressed.connect(_on_quality_dropdown_pressed)
	if resolution_dropdown:
		resolution_dropdown.button_pressed.connect(_on_resolution_dropdown_pressed)
	if vsync_toggle:
		vsync_toggle.button_pressed.connect(_on_vsync_toggle_pressed)

func _connect_slider_events() -> void:
	if sensitivity_slider:
		sensitivity_slider.value_changed.connect(_on_sensitivity_changed)

# === EVENT BUS INTEGRATION ===

func _setup_event_bus_subscriptions() -> void:
	pass  # TODO: implement

func _remove_event_bus_subscriptions() -> void:
	pass  # TODO: implement

# === EVENT HANDLERS ===

func _on_save_button_pressed() -> void:
	pass  # TODO: implement

func _on_reset_button_pressed() -> void:
	pass  # TODO: implement

func _on_back_button_pressed() -> void:
	pass  # TODO: implement

func _on_quality_dropdown_pressed() -> void:
	pass  # TODO: implement

func _on_resolution_dropdown_pressed() -> void:
	pass  # TODO: implement

func _on_vsync_toggle_pressed() -> void:
	pass  # TODO: implement

func _on_keybind_button_pressed(action: String, button: ButtonAtom) -> void:
	pass  # TODO: implement

func _on_sensitivity_changed(value: float) -> void:
	set_setting("gameplay", "mouse_sensitivity", int(value))

func _on_game_paused(event: EventBus.Event) -> void:
	pass  # TODO: implement

func _on_game_resumed(event: EventBus.Event) -> void:
	pass  # TODO: implement

func _on_ui_show(event: EventBus.Event) -> void:
	pass  # TODO: implement

func _on_ui_hide(event: EventBus.Event) -> void:
	pass  # TODO: implement

func _on_config_changed(event: EventBus.Event) -> void:
	pass  # TODO: implement

# === CLEANUP ===

func _exit_tree() -> void:
	_remove_event_bus_subscriptions()

# === DEBUG ===

func _to_string() -> String:
	return "[SettingsScreenOrganism: Initialized: %s, Visible: %s, Fading: %s, Settings Changed: %s]" % [
		str(is_initialized),
		str(visible),
		str(is_fading),
		str(settings_changed)
	]

func print_debug_info() -> void:
	print("=== SettingsScreenOrganism Debug ===")
	print("Is Initialized: %s" % str(is_initialized))
	print("Is Visible: %s" % str(visible))
	print("Is Fading: %s" % str(is_fading))
	print("Show Title: %s" % str(show_title))
	print("Show Sections: %s" % str(show_sections))
	print("Show Background: %s" % str(show_background))
	print("Fade Duration: %.2f" % fade_duration)
	print("Settings Changed: %s" % str(settings_changed))
	print("Current Settings:")
	for section in current_settings:
		print("  %s: %s" % [section, str(current_settings[section])])
	print("Available Qualities: %s" % str(available_qualities))
	print("Available Resolutions: %s" % str(available_resolutions))
	print("Keybind Buttons: %d" % keybind_buttons.size())
	print("Current Config Keys: %s" % str(current_config.keys()))
	
	# Audio settings organism info
	if audio_settings_organism:
		print("\nAudioSettingsOrganism:")
		audio_settings_organism.print_debug_info()