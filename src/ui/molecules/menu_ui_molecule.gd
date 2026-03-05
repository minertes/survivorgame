# 🎮 MENU UI MOLECULE
# Tüm UI atomic bileşenlerini birleştiren ana molekül
class_name MenuUIMolecule
extends Control

# === SIGNALS ===
signal molecule_initialized()
signal start_button_pressed()
signal sound_settings_pressed()
signal quit_button_pressed()
signal version_info_clicked()
signal component_loaded(component_name: String, success: bool)

# === CONSTANTS ===
const VP := Vector2(720.0, 1280.0)

# === EXPORT VARIABLES ===
@export var show_start_button: bool = true
@export var show_sound_button: bool = true
@export var show_quit_button: bool = true
@export var show_version_info: bool = true
@export var button_spacing: float = 64.0

# === NODE REFERENCES ===
var start_button: Button = null  # Kodla oluşturulacak
var sound_button: Button = null  # Kodla oluşturulacak
var quit_button: Button = null   # Kodla oluşturulacak
var version_label: Label = null  # Kodla oluşturulacak

# === STATE ===
var is_initialized: bool = false
var components_loaded: Dictionary = {}
var button_states: Dictionary = {
	"start": {"enabled": true, "visible": true},
	"sound": {"enabled": true, "visible": true},
	"quit": {"enabled": true, "visible": true}
}

# === LIFECYCLE ===

func _ready() -> void:
	print("MenuUIMolecule: _ready() called")
	_setup_ui()
	_connect_signals()
	_load_game_data()
	is_initialized = true
	molecule_initialized.emit()
	print("MenuUIMolecule: Initialization completed")

# === PUBLIC API ===

func initialize_components() -> void:
	components_loaded = {
		"start_button": start_button != null,
		"sound_button": sound_button != null,
		"quit_button": quit_button != null,
		"version_label": version_label != null
	}
	
	for component in components_loaded:
		component_loaded.emit(component, components_loaded[component])

func set_button_state(button_name: String, enabled: bool, visible: bool = true) -> void:
	if not button_name in button_states:
		push_warning("Unknown button: %s" % button_name)
		return
	
	button_states[button_name] = {"enabled": enabled, "visible": visible}
	_update_button_states()

func set_start_button_text(text: String) -> void:
	if start_button:
		start_button.text = text

func set_sound_button_text(text: String) -> void:
	if sound_button:
		sound_button.text = text

func set_version_text(text: String) -> void:
	if version_label:
		version_label.text = text

func update_sound_button() -> void:
	if not sound_button:
		print("MenuUIMolecule: Sound button not available")
		return
	
	var sound_enabled = true
	if has_node("/root/GameData"):
		var game_data = get_node("/root/GameData")
		sound_enabled = game_data.sound_enabled
		print("MenuUIMolecule: Sound enabled from GameData: %s" % str(sound_enabled))
	else:
		print("MenuUIMolecule: GameData not found, using default")
	
	sound_button.text = "🔊  Ses: Açık" if sound_enabled else "🔇  Ses: Kapalı"
	print("MenuUIMolecule: Sound button text updated")

func fade_in_buttons(duration: float = 0.5) -> void:
	if start_button:
		start_button.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(start_button, "modulate:a", 1.0, duration)
	
	if sound_button:
		sound_button.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_interval(duration * 0.3)
		tween.tween_property(sound_button, "modulate:a", 1.0, duration)

func fade_out_buttons(duration: float = 0.3) -> void:
	if start_button:
		var tween = create_tween()
		tween.tween_property(start_button, "modulate:a", 0.0, duration)
	
	if sound_button:
		var tween = create_tween()
		tween.tween_property(sound_button, "modulate:a", 0.0, duration)

func get_button_position(button_name: String) -> Vector2:
	match button_name:
		"start":
			return Vector2(VP.x / 2.0 - 200.0, 688.0) if start_button else Vector2.ZERO
		"sound":
			return Vector2(VP.x / 2.0 - 130.0, 792.0) if sound_button else Vector2.ZERO
		"quit":
			return Vector2(VP.x / 2.0 - 130.0, 864.0) if quit_button else Vector2.ZERO
		_:
			return Vector2.ZERO

func get_button_size(button_name: String) -> Vector2:
	match button_name:
		"start":
			return Vector2(400, 80)
		"sound":
			return Vector2(260, 56)
		"quit":
			return Vector2(260, 56)
		_:
			return Vector2.ZERO

# === PRIVATE METHODS ===

func _setup_ui() -> void:
	# Start butonu
	if show_start_button:
		start_button = Button.new()
		start_button.name = "StartButton"  # İsim ekle
		start_button.text = "▶  OYUNA BAŞLA"
		start_button.size = Vector2(400, 80)
		start_button.position = Vector2(VP.x / 2.0 - 200.0, 688.0)
		start_button.add_theme_font_size_override("font_size", 30)
		start_button.add_theme_color_override("font_color", Color(0.95, 1.0, 0.95))
		
		var sty_s := StyleBoxFlat.new()
		sty_s.bg_color = Color(0.10, 0.44, 0.12)
		sty_s.set_corner_radius_all(14)
		sty_s.border_color = Color(0.30, 0.88, 0.36, 0.88)
		sty_s.set_border_width_all(2)
		start_button.add_theme_stylebox_override("normal", sty_s)
		
		var sty_sh := StyleBoxFlat.new()
		sty_sh.bg_color = Color(0.18, 0.62, 0.20)
		sty_sh.set_corner_radius_all(14)
		sty_sh.border_color = Color(0.48, 1.0, 0.52, 1.0)
		sty_sh.set_border_width_all(2)
		start_button.add_theme_stylebox_override("hover", sty_sh)
		
		var sty_sp := StyleBoxFlat.new()
		sty_sp.bg_color = Color(0.06, 0.30, 0.08)
		sty_sp.set_corner_radius_all(14)
		start_button.add_theme_stylebox_override("pressed", sty_sp)
		
		add_child(start_button)
	
	# Ses butonu
	if show_sound_button:
		sound_button = Button.new()
		sound_button.name = "SoundButton"  # İsim ekle
		sound_button.text = "🔊  Ses: Açık"
		sound_button.size = Vector2(260, 56)
		sound_button.position = Vector2(VP.x / 2.0 - 130.0, 792.0)
		sound_button.add_theme_font_size_override("font_size", 20)
		sound_button.add_theme_color_override("font_color", Color(0.80, 0.87, 1.0))
		
		var sty_snd := StyleBoxFlat.new()
		sty_snd.bg_color = Color(0.08, 0.10, 0.26)
		sty_snd.set_corner_radius_all(10)
		sty_snd.border_color = Color(0.28, 0.42, 0.82, 0.65)
		sty_snd.set_border_width_all(2)
		sound_button.add_theme_stylebox_override("normal", sty_snd)
		
		var sty_sndh := StyleBoxFlat.new()
		sty_sndh.bg_color = Color(0.14, 0.20, 0.44)
		sty_sndh.set_corner_radius_all(10)
		sound_button.add_theme_stylebox_override("hover", sty_sndh)
		
		add_child(sound_button)
	
	# Çıkış butonu (tıklanabilsin diye mouse_filter ve focus)
	if show_quit_button:
		quit_button = Button.new()
		quit_button.name = "QuitButton"
		quit_button.text = "🚪  Çıkış"
		quit_button.size = Vector2(260, 56)
		quit_button.position = Vector2(VP.x / 2.0 - 130.0, 864.0)
		quit_button.mouse_filter = Control.MOUSE_FILTER_STOP
		quit_button.focus_mode = Control.FOCUS_ALL
		quit_button.add_theme_font_size_override("font_size", 20)
		quit_button.add_theme_color_override("font_color", Color(1.0, 0.85, 0.85))
		
		var sty_q := StyleBoxFlat.new()
		sty_q.bg_color = Color(0.32, 0.12, 0.12)
		sty_q.set_corner_radius_all(10)
		sty_q.border_color = Color(0.72, 0.28, 0.28, 0.75)
		sty_q.set_border_width_all(2)
		quit_button.add_theme_stylebox_override("normal", sty_q)
		
		var sty_qh := StyleBoxFlat.new()
		sty_qh.bg_color = Color(0.48, 0.18, 0.18)
		sty_qh.set_corner_radius_all(10)
		quit_button.add_theme_stylebox_override("hover", sty_qh)
		
		add_child(quit_button)
	
	# Sürüm bilgisi
	if show_version_info:
		version_label = Label.new()
		version_label.name = "VersionLabel"  # İsim ekle
		version_label.text = "v0.1  Beta Build"
		version_label.add_theme_font_size_override("font_size", 12)
		version_label.add_theme_color_override("font_color", Color(0.28, 0.28, 0.40))
		version_label.position = Vector2(12, VP.y - 26)
		add_child(version_label)

func _connect_signals() -> void:
	if start_button:
		start_button.pressed.connect(_on_start_button_pressed)
	
	if sound_button:
		sound_button.pressed.connect(_on_sound_button_pressed)
	
	if quit_button:
		quit_button.pressed.connect(_on_quit_button_pressed)
	
	if version_label:
		version_label.gui_input.connect(_on_version_label_gui_input)

func _load_game_data() -> void:
	# Ses durumunu güncelle
	update_sound_button()

func _update_button_states() -> void:
	if start_button:
		start_button.visible = show_start_button and button_states.start.visible
		start_button.disabled = not button_states.start.enabled
	
	if sound_button:
		sound_button.visible = show_sound_button and button_states.sound.visible
		sound_button.disabled = not button_states.sound.enabled
	
	if quit_button:
		quit_button.visible = show_quit_button and button_states.quit.visible
		quit_button.disabled = not button_states.quit.enabled

# === EVENT HANDLERS ===

func _on_start_button_pressed() -> void:
	print("MenuUIMolecule: Start button pressed")
	start_button_pressed.emit()

func _on_sound_button_pressed() -> void:
	print("MenuUIMolecule: Sound button pressed")
	sound_settings_pressed.emit()

func _on_quit_button_pressed() -> void:
	print("MenuUIMolecule: Quit button pressed")
	quit_button_pressed.emit()
	# Önce pencere kapatma bildirimi, sonra çıkış (Godot dokümantasyonu)
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()

func _on_version_label_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			version_info_clicked.emit()

# === DEBUG ===

func print_debug_info() -> void:
	print("=== MenuUIMolecule ===")
	print("Initialized: %s" % str(is_initialized))
	print("Show Start Button: %s" % str(show_start_button))
	print("Show Sound Button: %s" % str(show_sound_button))
	print("Show Version Info: %s" % str(show_version_info))
	print("Button Spacing: %.1f" % button_spacing)
	print("Components Loaded:")
	for component in components_loaded:
		print("  %s: %s" % [component, str(components_loaded[component])])
	print("Button States:")
	for button_name in button_states:
		var state = button_states[button_name]
		print("  %s: enabled=%s, visible=%s" % [button_name, str(state.enabled), str(state.visible)])