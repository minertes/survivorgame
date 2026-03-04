# 🎮 SETTINGS SCREEN ORGANISM
# Atomic Design: Settings screen organism (Panel + Label + Button + ProgressBar + Icon)
# Kompleks UI bölümü: Ayarlar ekranını yönetir
class_name SettingsScreenOrganism
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
@onready var audio_section: PanelAtom = $CenterContainer/VBoxContainer/SectionsContainer/AudioSection
@onready var graphics_section: PanelAtom = $CenterContainer/VBoxContainer/SectionsContainer/GraphicsSection
@onready var controls_section: PanelAtom = $CenterContainer/VBoxContainer/SectionsContainer/ControlsSection
@onready var gameplay_section: PanelAtom = $CenterContainer/VBoxContainer/SectionsContainer/GameplaySection
@onready var master_volume_label: LabelAtom = $CenterContainer/VBoxContainer/SectionsContainer/AudioSection/MasterVolumeLabel
@onready var master_volume_slider: ProgressBarAtom = $CenterContainer/VBoxContainer/SectionsContainer/AudioSection/MasterVolumeSlider
@onready var music_volume_label: LabelAtom = $CenterContainer/VBoxContainer/SectionsContainer/AudioSection/MusicVolumeLabel
@onready var music_volume_slider: ProgressBarAtom = $CenterContainer/VBoxContainer/SectionsContainer/AudioSection/MusicVolumeSlider
@onready var sfx_volume_label: LabelAtom = $CenterContainer/VBoxContainer/SectionsContainer/AudioSection/SFXVolumeLabel
@onready var sfx_volume_slider: ProgressBarAtom = $CenterContainer/VBoxContainer/SectionsContainer/AudioSection/SFXVolumeSlider
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
@onready var fade_tween: Tween = $FadeTween

# === STATE ===
var is_initialized: bool = false
var is_fading: bool = false
var current_config: Dictionary = {}
var settings_changed: bool = false
var current_settings: Dictionary = {
	"audio": {
		"master_volume": 80,
		"music_volume": 70,
		"sfx_volume": 90
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
	# Title
	if config.has("title"):
		set_title(config.title)
	
	# Background
	if config.has("background_color"):
		var color = Color(config.background_color)
		set_background_color(color)
	
	# Buttons
	if config.has("save_button_text"):
		set_save_button_text(config.save_button_text)
	
	if config.has("reset_button_text"):
		set_reset_button_text(config.reset_button_text)
	
	if config.has("back_button_text"):
		set_back_button_text(config.back_button_text)
	
	# Sections
	if config.has("sections"):
		# Sections visibility'yi güncelle
		pass
	
	# Default values
	if config.has("default_volume"):
		current_settings.audio.master_volume = config.default_volume
	
	if config.has("default_quality"):
		current_settings.graphics.quality = config.default_quality
	
	# Available options
	if config.has("available_resolutions"):
		available_resolutions = config.available_resolutions
	
	if config.has("keybind_presets"):
		# Keybind preset'leri
		pass
	
	# Visibility
	if config.has("show_title"):
		show_title = config.show_title
	if config.has("show_sections"):
		show_sections = config.show_sections
	if config.has("show_background"):
		show_background = config.show_background
	
	# Animation
	if config.has("fade_duration"):
		fade_duration = config.fade_duration

# === SETTINGS MANAGEMENT ===

func _apply_settings() -> void:
	# Audio settings
	_apply_audio_settings()
	
	# Graphics settings
	_apply_graphics_settings()
	
	# Gameplay settings
	_apply_gameplay_settings()

func _apply_audio_settings() -> void:
	var audio = current_settings.audio
	
	# Master volume
	var master_volume = audio.get("master_volume", 80) / 100.0
	# AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(master_volume))
	
	# Music volume
	var music_volume = audio.get("music_volume", 70) / 100.0
	# AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(music_volume))
	
	# SFX volume
	var sfx_volume = audio.get("sfx_volume", 90) / 100.0
	# AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(sfx_volume))

func _apply_graphics_settings() -> void:
	var graphics = current_settings.graphics
	
	# Quality
	var quality = graphics.get("quality", "medium")
	match quality:
		"low":
			# Low quality settings
			pass
		"medium":
			# Medium quality settings
			pass
		"high":
			# High quality settings
			pass
		"ultra":
			# Ultra quality settings
			pass
	
	# Resolution
	var resolution = graphics.get("resolution", "1920x1080")
	var parts = resolution.split("x")
	if parts.size() == 2:
		var width = int(parts[0])
		var height = int(parts[1])
		# DisplayServer.window_set_size(Vector2i(width, height))
	
	# VSync
	var vsync = graphics.get("vsync", true)
	# DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)

func _apply_gameplay_settings() -> void:
	var gameplay = current_settings.gameplay
	
	# Mouse sensitivity
	var sensitivity = gameplay.get("mouse_sensitivity", 50) / 100.0
	# Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# Input.set_mouse_sensitivity(sensitivity)
	
	# Gameplay options
	var show_damage_numbers = gameplay.get("show_damage_numbers", true)
	var show_hit_indicators = gameplay.get("show_hit_indicators", true)
	
	# Bu ayarlar EventBus üzerinden diğer sistemlere bildirilebilir
	if EventBus.is_available():
		EventBus.emit_now_static("gameplay_settings_changed", {
			"show_damage_numbers": show_damage_numbers,
			"show_hit_indicators": show_hit_indicators
		})

func _update_settings_display() -> void:
	# Audio section
	var audio = current_settings.audio
	master_volume_slider.set_value(audio.get("master_volume", 80))
	music_volume_slider.set_value(audio.get("music_volume", 70))
	sfx_volume_slider.set_value(audio.get("sfx_volume", 90))
	
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
		"audio":
			match key:
				"master_volume":
					master_volume_slider.set_value(value)
				"music_volume":
					music_volume_slider.set_value(value)
				"sfx_volume":
					sfx_volume_slider.set_value(value)
		
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
	if not is_inside_tree():
		return
	
	# Keybind container'ı temizle
	for child in keybind_container.get_children():
		child.queue_free()
	
	keybind_buttons.clear()
	
	# Keybind butonlarını oluştur
	var controls = current_settings.controls
	
	for action in controls.keys():
		var keybind_row = HBoxContainer.new()
		keybind_row.name = "%sRow" % action.capitalize()
		
		var action_label = LabelAtom.new()
		action_label.name = "%sLabel" % action.capitalize()
		action_label.set_text(action.replace("_", " ").capitalize() + ":")
		
		var keybind_button = ButtonAtom.new()
		keybind_button.name = "%sButton" % action.capitalize()
		keybind_button.set_text(str(controls[action]))
		keybind_button.button_pressed.connect(_on_keybind_button_pressed.bind(action, keybind_button))
		
		keybind_row.add_child(action_label)
		keybind_row.add_child(keybind_button)
		keybind_container.add_child(keybind_row)
		
		keybind_buttons[action] = keybind_button

func _start_keybind_listening(action: String, button: ButtonAtom) -> void:
	print("SettingsScreen: Listening for keybind for action: %s" % action)
	
	button.set_text("Press any key...")
	button.set_disabled(true)
	
	# Burada key input listening implemente edilebilir
	# Şimdilik mock implementation
	await get_tree().create_timer(2.0).timeout
	
	# Mock key press
	var new_key = "SPACE"  # Örnek olarak SPACE
	current_settings.controls[action] = new_key
	button.set_text(new_key)
	button.set_disabled(false)
	
	settings_changed = true
	save_button.set_disabled(false)
	
	# EventBus'a bildir
	if EventBus.is_available():
		EventBus.emit_now_static("keybind_changed", {
			"action": action,
			"key": new_key
		})

# === VISIBILITY MANAGEMENT ===

func _update_visibility() -> void:
	if not is_inside_tree():
		return
	
	_update_title_visibility()
	_update_sections_visibility()
	_update_background_visibility()

func _update_title_visibility() -> void:
	if not is_inside_tree():
		return
	
	if title_label:
		title_label.visible = show_title

func _update_sections_visibility() -> void:
	if not is_inside_tree():
		return
	
	if sections_container:
		sections_container.visible = show_sections

func _update_background_visibility() -> void:
	if not is_inside_tree():
		return
	
	if background_panel:
		background_panel.visible = show_background

func _update_animations() -> void:
	# Animation settings güncellenebilir
	pass

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
	if master_volume_slider:
		master_volume_slider.value_changed.connect(_on_master_volume_changed)
	if music_volume_slider:
		music_volume_slider.value_changed.connect(_on_music_volume_changed)
	if sfx_volume_slider:
		sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)
	if sensitivity_slider:
		sensitivity_slider.value_changed.connect(_on_sensitivity_changed)

# === EVENT BUS INTEGRATION ===

func _setup_event_bus_subscriptions() -> void:
	if not EventBus.is_available():
		return
	
	# Game state events
	EventBus.subscribe_static(EventBus.GAME_PAUSED, _on_game_paused)
	EventBus.subscribe_static(EventBus.GAME_RESUMED, _on_game_resumed)
	
	# UI events
	EventBus.subscribe_static(EventBus.UI_SHOW, _on_ui_show)
	EventBus.subscribe_static(EventBus.UI_HIDE, _on_ui_hide)
	
	# Config events
	EventBus.subscribe_static("config_changed", _on_config_changed)

func _remove_event_bus_subscriptions() -> void:
	if not EventBus.is_available():
		return
	
	EventBus.get_instance().unsubscribe_all_for_object(self)

# === EVENT HANDLERS ===

func _on_save_button_pressed() -> void:
	print("SettingsScreen: Save button pressed")
	
	# EventBus'a bildir
	if EventBus.is_available():
		EventBus.emit_now_static(EventBus.UI_BUTTON_CLICKED, {
			"component": "SettingsScreen",
			"button": "save",
			"action": "save_settings"
		})
	
	save_settings()

func _on_reset_button_pressed() -> void:
	print("SettingsScreen: Reset button pressed")
	
	# EventBus'a bildir
	if EventBus.is_available():
		EventBus.emit_now_static(EventBus.UI_BUTTON_CLICKED, {
			"component": "SettingsScreen",
			"button": "reset",
			"action": "reset_settings"
		})
	
	reset_settings()

func _on_back_button_pressed() -> void:
	print("SettingsScreen: Back button pressed")
	
	# EventBus'a bildir
	if EventBus.is_available():
		EventBus.emit_now_static(EventBus.UI_BUTTON_CLICKED, {
			"component": "SettingsScreen",
			"button": "back",
			"action": "go_back"
		})
	
	back_pressed.emit()

func _on_quality_dropdown_pressed() -> void:
	print("SettingsScreen: Quality dropdown pressed")
	
	# Quality seçeneklerini döngüle
	var current_quality = current_settings.graphics.get("quality", "medium")
	var current_index = available_qualities.find(current_quality)
	var next_index = (current_index + 1) % available_qualities.size()
	var next_quality = available_qualities[next_index]
	
	set_setting("graphics", "quality", next_quality)

func _on_resolution_dropdown_pressed() -> void:
	print("SettingsScreen: Resolution dropdown pressed")
	
	# Resolution seçeneklerini döngüle
	var current_resolution = current_settings.graphics.get("resolution", "1920x1080")
	var current_index = available_resolutions.find(current_resolution)
	var next_index = (current_index + 1) % available_resolutions.size()
	var next_resolution = available_resolutions[next_index]
	
	set_setting("graphics", "resolution", next_resolution)

func _on_vsync_toggle_pressed() -> void:
	print("SettingsScreen: VSync toggle pressed")
	
	var current_vsync = current_settings.graphics.get("vsync", true)
	var next_vsync = not current_vsync
	
	set_setting("graphics", "vsync", next_vsync)

func _on_keybind_button_pressed(action: String, button: ButtonAtom) -> void:
	print("SettingsScreen: Keybind button pressed for action: %s" % action)
	_start_keybind_listening(action, button)

func _on_master_volume_changed(value: float) -> void:
	set_setting("audio", "master_volume", int(value))

func _on_music_volume_changed(value: float) -> void:
	set_setting("audio", "music_volume", int(value))

func _on_sfx_volume_changed(value: float) -> void:
	set_setting("audio", "sfx_volume", int(value))

func _on_sensitivity_changed(value: float) -> void:
	set_setting("gameplay", "mouse_sensitivity", int(value))

func _on_game_paused(event: EventBus.Event) -> void:
	# Oyun durduğunda settings screen'i göster
	fade_in()

func _on_game_resumed(event: EventBus.Event) -> void:
	# Oyun devam ettiğinde settings screen'i gizle
	fade_out()

func _on_ui_show(event: EventBus.Event) -> void:
	var component = event.data.get("component", "")
	if component == "SettingsScreen":
		show_settings_screen()

func _on_ui_hide(event: EventBus.Event) -> void:
	var component = event.data.get("component", "")
	if component == "SettingsScreen":
		hide_settings_screen()

func _on_config_changed(event: EventBus.Event) -> void:
	var config_file = event.data.get("file", "")
	if config_file == "ui.json":
		reload_config()

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