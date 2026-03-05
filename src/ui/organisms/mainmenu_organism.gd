# 🎮 MAIN MENU ORGANISM
# Atomic Design: Main Menu organism (Panel + Label + Button + Icon)
# Kompleks UI bölümü: Ana menü ekranını yönetir
class_name MainMenuOrganism
extends Control

# === CONFIG ===
@export var show_title: bool = true:
	set(value):
		show_title = value
		if is_inside_tree():
			_update_title_visibility()

@export var show_buttons: bool = true:
	set(value):
		show_buttons = value
		if is_inside_tree():
			_update_buttons_visibility()

@export var show_background: bool = true:
	set(value):
		show_background = value
		if is_inside_tree():
			_update_background_visibility()

@export var show_logo: bool = true:
	set(value):
		show_logo = value
		if is_inside_tree():
			_update_logo_visibility()

@export var fade_duration: float = 0.3:
	set(value):
		fade_duration = value
		if is_inside_tree():
			_update_animations()

# === NODES ===
@onready var background_panel: PanelAtom = $BackgroundPanel
@onready var title_label: LabelAtom = $CenterContainer/VBoxContainer/TitleLabel
@onready var logo_icon: IconAtom = $CenterContainer/VBoxContainer/LogoIcon
@onready var start_button: ButtonAtom = $CenterContainer/VBoxContainer/ButtonContainer/StartButton
@onready var settings_button: ButtonAtom = $CenterContainer/VBoxContainer/ButtonContainer/SettingsButton
@onready var quit_button: ButtonAtom = $CenterContainer/VBoxContainer/ButtonContainer/QuitButton
@onready var version_label: LabelAtom = $BottomRight/VersionLabel
var fade_tween: Tween

# === STATE ===
var is_initialized: bool = false
var is_fading: bool = false
var current_config: Dictionary = {}
var button_states: Dictionary = {
	"start": {"enabled": true, "visible": true},
	"settings": {"enabled": true, "visible": true},
	"quit": {"enabled": true, "visible": true}
}

# === EVENTS ===
signal menu_initialized
signal menu_visibility_changed(is_visible: bool)
signal start_game_pressed
signal settings_pressed
signal quit_pressed
signal button_state_changed(button_name: String, is_enabled: bool)
signal fade_completed(fade_in: bool)

# === LIFECYCLE ===

func _ready() -> void:
	# Başlangıç durumunu güncelle
	_update_visibility()
	_update_animations()
	
	# Button event'lerini bağla
	_connect_button_events()
	
	# Config yükle
	_load_config()
	
	# EventBus subscription'ları
	_setup_event_bus_subscriptions()
	
	# Version bilgisini güncelle
	_update_version_info()
	
	is_initialized = true
	menu_initialized.emit()
	
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

func show_menu() -> void:
	visible = true
	menu_visibility_changed.emit(true)

func hide_menu() -> void:
	visible = false
	menu_visibility_changed.emit(false)

func toggle_menu() -> void:
	visible = not visible
	menu_visibility_changed.emit(visible)

func set_button_state(button_name: String, is_enabled: bool, is_visible: bool = true) -> void:
	if not button_name in button_states:
		push_warning("Unknown button: %s" % button_name)
		return
	
	button_states[button_name].enabled = is_enabled
	button_states[button_name].visible = is_visible
	
	_update_button_states()
	button_state_changed.emit(button_name, is_enabled)

func set_title(text: String) -> void:
	if title_label:
		title_label.set_text(text)

func set_logo(icon_path: String) -> void:
	if logo_icon and logo_icon.has_method("set_icon_from_path"):
		logo_icon.set_icon_from_path(icon_path)

func set_background_color(color: Color) -> void:
	if background_panel:
		background_panel.set_background_color(color)

func set_button_text(button_name: String, text: String) -> void:
	var button = _get_button_by_name(button_name)
	if button:
		button.set_text(text)

func set_button_style(button_name: String, style: String) -> void:
	var button = _get_button_by_name(button_name)
	if button:
		button.set_style(style)

func reload_config() -> void:
	_load_config()

# === CONFIG MANAGEMENT ===

func _load_config() -> void:
	if not ConfigManager.is_available():
		push_warning("ConfigManager not available")
		return
	
	var config = ConfigManager.get_instance().get_config_value("ui.json", "screens.main_menu", {})
	current_config = config
	
	# Apply config
	_apply_config(config)

func _apply_config(config: Dictionary) -> void:
	# Title
	if config.has("title"):
		set_title(config.title)
	
	# Logo
	if config.has("logo_path"):
		set_logo(config.logo_path)
	
	# Background
	if config.has("background_color"):
		var color = Color(config.background_color)
		set_background_color(color)
	
	# Buttons
	if config.has("buttons"):
		var buttons_config = config.buttons
		
		if buttons_config.has("start"):
			var start_config = buttons_config.start
			if start_config.has("text"):
				set_button_text("start", start_config.text)
			if start_config.has("style"):
				set_button_style("start", start_config.style)
			if start_config.has("enabled"):
				set_button_state("start", start_config.enabled)
		
		if buttons_config.has("settings"):
			var settings_config = buttons_config.settings
			if settings_config.has("text"):
				set_button_text("settings", settings_config.text)
			if settings_config.has("style"):
				set_button_style("settings", settings_config.style)
			if settings_config.has("enabled"):
				set_button_state("settings", settings_config.enabled)
		
		if buttons_config.has("quit"):
			var quit_config = buttons_config.quit
			if quit_config.has("text"):
				set_button_text("quit", quit_config.text)
			if quit_config.has("style"):
				set_button_style("quit", quit_config.style)
			if quit_config.has("enabled"):
				set_button_state("quit", quit_config.enabled)
	
	# Visibility
	if config.has("show_title"):
		show_title = config.show_title
	if config.has("show_logo"):
		show_logo = config.show_logo
	if config.has("show_background"):
		show_background = config.show_background
	if config.has("show_buttons"):
		show_buttons = config.show_buttons
	
	# Animation
	if config.has("fade_duration"):
		fade_duration = config.fade_duration

# === VISIBILITY MANAGEMENT ===

func _update_visibility() -> void:
	if not is_inside_tree():
		return
	
	_update_title_visibility()
	_update_logo_visibility()
	_update_background_visibility()
	_update_buttons_visibility()

func _update_title_visibility() -> void:
	if not is_inside_tree():
		return
	
	if title_label:
		title_label.visible = show_title

func _update_logo_visibility() -> void:
	if not is_inside_tree():
		return
	
	if logo_icon:
		logo_icon.visible = show_logo

func _update_background_visibility() -> void:
	if not is_inside_tree():
		return
	
	if background_panel:
		background_panel.visible = show_background

func _update_buttons_visibility() -> void:
	if not is_inside_tree():
		return
	
	if start_button:
		start_button.visible = show_buttons and button_states.start.visible
	if settings_button:
		settings_button.visible = show_buttons and button_states.settings.visible
	if quit_button:
		quit_button.visible = show_buttons and button_states.quit.visible

func _update_button_states() -> void:
	if not is_inside_tree():
		return
	
	if start_button:
		start_button.set_disabled(not button_states.start.enabled)
	if settings_button:
		settings_button.set_disabled(not button_states.settings.enabled)
	if quit_button:
		quit_button.set_disabled(not button_states.quit.enabled)

func _update_animations() -> void:
	# Animation settings güncellenebilir
	pass

func _update_version_info() -> void:
	if version_label:
		# Basit version bilgisi
		version_label.set_text("v1.0.0-alpha")

# === BUTTON MANAGEMENT ===

func _connect_button_events() -> void:
	if start_button:
		start_button.button_pressed.connect(_on_start_button_pressed)
	if settings_button:
		settings_button.button_pressed.connect(_on_settings_button_pressed)
	if quit_button:
		quit_button.button_pressed.connect(_on_quit_button_pressed)

func _get_button_by_name(button_name: String) -> ButtonAtom:
	match button_name:
		"start":
			return start_button
		"settings":
			return settings_button
		"quit":
			return quit_button
		_:
			return null

# === EVENT BUS INTEGRATION ===

func _setup_event_bus_subscriptions() -> void:
	if not EventBus.is_available():
		return
	
	# Game state events
	EventBus.subscribe_static(EventBus.GAME_STARTED, _on_game_started)
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

func _on_start_button_pressed() -> void:
	print("MainMenu: Start button pressed")
	
	# EventBus'a bildir
	if EventBus.is_available():
		EventBus.emit_now_static(EventBus.UI_BUTTON_CLICKED, {
			"component": "MainMenu",
			"button": "start",
			"action": "start_game"
		})
	
	start_game_pressed.emit()

func _on_settings_button_pressed() -> void:
	print("MainMenu: Settings button pressed")
	
	# EventBus'a bildir
	if EventBus.is_available():
		EventBus.emit_now_static(EventBus.UI_BUTTON_CLICKED, {
			"component": "MainMenu",
			"button": "settings",
			"action": "open_settings"
		})
	
	settings_pressed.emit()

func _on_quit_button_pressed() -> void:
	print("MainMenu: Quit button pressed")
	
	# EventBus'a bildir
	if EventBus.is_available():
		EventBus.emit_now_static(EventBus.UI_BUTTON_CLICKED, {
			"component": "MainMenu",
			"button": "quit",
			"action": "quit_game"
		})
	
	quit_pressed.emit()

func _on_game_started(event: EventBus.Event) -> void:
	# Oyun başladığında menüyü gizle
	fade_out()

func _on_game_paused(event: EventBus.Event) -> void:
	# Oyun durduğunda menüyü göster
	fade_in()

func _on_game_resumed(event: EventBus.Event) -> void:
	# Oyun devam ettiğinde menüyü gizle
	fade_out()

func _on_ui_show(event: EventBus.Event) -> void:
	var component = event.data.get("component", "")
	if component == "MainMenu":
		show_menu()

func _on_ui_hide(event: EventBus.Event) -> void:
	var component = event.data.get("component", "")
	if component == "MainMenu":
		hide_menu()

func _on_config_changed(event: EventBus.Event) -> void:
	var config_file = event.data.get("file", "")
	if config_file == "ui.json":
		reload_config()

# === CLEANUP ===

func _exit_tree() -> void:
	_remove_event_bus_subscriptions()

# === DEBUG ===

func _to_string() -> String:
	return "[MainMenuOrganism: Initialized: %s, Visible: %s, Fading: %s]" % [
		str(is_initialized),
		str(visible),
		str(is_fading)
	]

func print_debug_info() -> void:
	print("=== MainMenuOrganism Debug ===")
	print("Is Initialized: %s" % str(is_initialized))
	print("Is Visible: %s" % str(visible))
	print("Is Fading: %s" % str(is_fading))
	print("Show Title: %s" % str(show_title))
	print("Show Logo: %s" % str(show_logo))
	print("Show Background: %s" % str(show_background))
	print("Show Buttons: %s" % str(show_buttons))
	print("Fade Duration: %.2f" % fade_duration)
	print("Button States:")
	for button_name in button_states:
		var state = button_states[button_name]
		print("  %s: enabled=%s, visible=%s" % [button_name, str(state.enabled), str(state.visible)])
	print("Current Config Keys: %s" % str(current_config.keys()))