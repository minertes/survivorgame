# 🎵 AUDIO SETTINGS ORGANISM
# Atomic Design: Organism (VolumeControlMolecule x 4 + PanelAtom)
# Audio ayarları için organizma: Master, Music, SFX, UI volume kontrolleri
class_name AudioSettingsOrganism
extends PanelAtom

# === CONFIG ===
@export var show_title: bool = true:
	set(value):
		show_title = value
		if is_inside_tree():
			_update_title_visibility()

@export var default_volumes: Dictionary = {
	"master": 80,
	"music": 70,
	"sfx": 90,
	"ui": 70
}:
	set(value):
		default_volumes = value
		if is_inside_tree():
			_apply_default_volumes()

@export var show_test_buttons: bool = true:
	set(value):
		show_test_buttons = value
		if is_inside_tree():
			_update_test_buttons_visibility()

# === NODES ===
@onready var title_label: LabelAtom = $VBoxContainer/TitleLabel
@onready var master_volume_control: VolumeControlMolecule = $VBoxContainer/MasterVolumeControl
@onready var music_volume_control: VolumeControlMolecule = $VBoxContainer/MusicVolumeControl
@onready var sfx_volume_control: VolumeControlMolecule = $VBoxContainer/SFXVolumeControl
@onready var ui_volume_control: VolumeControlMolecule = $VBoxContainer/UIVolumeControl
@onready var test_buttons_container: HBoxContainer = $VBoxContainer/TestButtonsContainer
@onready var test_sfx_button: ButtonAtom = $VBoxContainer/TestButtonsContainer/TestSFXButton
@onready var test_music_button: ButtonAtom = $VBoxContainer/TestButtonsContainer/TestMusicButton
@onready var test_ui_button: ButtonAtom = $VBoxContainer/TestButtonsContainer/TestUIButton

# === STATE ===
var is_initialized: bool = false
var current_settings: Dictionary = {}
var settings_changed: bool = false

# === EVENTS ===
signal audio_settings_initialized
signal audio_setting_changed(bus_name: String, volume: int, muted: bool)
signal audio_settings_saved(settings: Dictionary)
signal audio_test_requested(test_type: String)

# === LIFECYCLE ===

func _ready() -> void:
	# Başlangıç değerlerini ayarla
	_initialize_components()
	
	# Event bağlantıları
	_connect_events()
	
	# UI'yi güncelle
	_update_ui()
	
	# Default settings'i kaydet
	_save_current_settings()
	
	is_initialized = true
	audio_settings_initialized.emit()

# === PUBLIC API ===

func set_volume(bus_name: String, volume: int) -> void:
	"""Belirli bir bus için volume ayarla"""
	var control = _get_volume_control(bus_name)
	if control:
		control.set_volume(volume)
		settings_changed = true

func get_volume(bus_name: String) -> int:
	"""Belirli bir bus için volume değerini al"""
	var control = _get_volume_control(bus_name)
	if control:
		return control.get_volume()
	return 0

func toggle_mute(bus_name: String, force_state: Variant = null) -> void:
	"""Belirli bir bus için mute/unmute toggle"""
	var control = _get_volume_control(bus_name)
	if control and control.has_method("toggle_mute"):
		control.toggle_mute(force_state)
		settings_changed = true

func is_muted(bus_name: String) -> bool:
	"""Belirli bir bus muted mı?"""
	var control = _get_volume_control(bus_name)
	if control:
		return control.is_volume_muted()
	return false

func set_title(text: String) -> void:
	"""Title text'ini ayarla"""
	if title_label:
		title_label.set_text(text)

func set_default_volumes(volumes: Dictionary) -> void:
	"""Default volume değerlerini ayarla"""
	default_volumes = volumes
	_apply_default_volumes()

func reset_to_defaults() -> void:
	"""Tüm ayarları default değerlere döndür"""
	# Her bir volume control'ü reset et
	for bus_name in ["master", "music", "sfx", "ui"]:
		var control = _get_volume_control(bus_name)
		if control:
			var default_volume = default_volumes.get(bus_name, 80)
			control.set_volume(default_volume)
			control.toggle_mute(false)
	
	settings_changed = true
	_save_current_settings()

func save_settings() -> Dictionary:
	"""Current settings'i kaydet ve döndür"""
	_save_current_settings()
	settings_changed = false
	audio_settings_saved.emit(current_settings.duplicate(true))
	return current_settings.duplicate(true)

func load_settings(settings: Dictionary) -> void:
	"""Saved settings'i yükle"""
	if not settings.is_empty():
		# Volume settings'leri yükle
		for bus_name in ["master", "music", "sfx", "ui"]:
			var control = _get_volume_control(bus_name)
			if control and bus_name in settings:
				var bus_settings = settings[bus_name]
				if "volume" in bus_settings:
					control.set_volume(bus_settings.volume)
				if "muted" in bus_settings:
					control.toggle_mute(bus_settings.muted)
		
		_save_current_settings()
		settings_changed = false

func get_all_settings() -> Dictionary:
	"""Tüm audio settings'leri al"""
	return current_settings.duplicate(true)

func are_settings_changed() -> bool:
	"""Settings değişti mi?"""
	return settings_changed

func play_test_sound(sound_type: String) -> void:
	"""Test sesi oynat"""
	audio_test_requested.emit(sound_type)
	
	# EventBus üzerinden AudioSystem'e test sesi isteği gönder
	if EventBus.is_available():
		EventBus.emit_now_static("play_test_sound", {
			"sound_type": sound_type,
			"volume_percent": get_volume("sfx" if sound_type == "sfx" else "ui")
		})

# === PRIVATE METHODS ===

func _initialize_components() -> void:
	# Title visibility
	_update_title_visibility()
	
	# Volume control'leri başlat
	_initialize_volume_controls()
	
	# Test buttons visibility
	_update_test_buttons_visibility()

func _initialize_volume_controls() -> void:
	# Her bir volume control'ü başlat
	var controls = {
		"master": master_volume_control,
		"music": music_volume_control,
		"sfx": sfx_volume_control,
		"ui": ui_volume_control
	}
	
	for bus_name in controls:
		var control = controls[bus_name]
		if control:
			# Bus name ayarla
			control.bus_name = bus_name.capitalize()
			
			# Label text ayarla
			var label_text = bus_name.capitalize() + " Volume"
			control.label_text = label_text
			
			# Default volume ayarla
			var default_volume = default_volumes.get(bus_name, 80)
			control.default_volume = default_volume
			control.set_volume(default_volume)

func _connect_events() -> void:
	# Volume control event'lerini bağla
	var controls = [master_volume_control, music_volume_control, sfx_volume_control, ui_volume_control]
	for control in controls:
		if control:
			control.volume_changed.connect(_on_volume_changed)
			control.mute_toggled.connect(_on_mute_toggled)
	
	# Test button event'lerini bağla
	if test_sfx_button:
		test_sfx_button.button_pressed.connect(_on_test_sfx_button_pressed)
	if test_music_button:
		test_music_button.button_pressed.connect(_on_test_music_button_pressed)
	if test_ui_button:
		test_ui_button.button_pressed.connect(_on_test_ui_button_pressed)

func _update_ui() -> void:
	# Tüm UI bileşenlerini güncelle
	_update_title_visibility()
	_update_test_buttons_visibility()

func _update_title_visibility() -> void:
	# Title visibility
	if title_label:
		title_label.visible = show_title

func _update_test_buttons_visibility() -> void:
	# Test buttons visibility
	if test_buttons_container:
		test_buttons_container.visible = show_test_buttons

func _apply_default_volumes() -> void:
	# Default volume'leri uygula
	for bus_name in default_volumes:
		var control = _get_volume_control(bus_name)
		if control:
			control.default_volume = default_volumes[bus_name]

func _get_volume_control(bus_name: String) -> VolumeControlMolecule:
	"""Bus name'e göre volume control component'ini al"""
	match bus_name.to_lower():
		"master":
			return master_volume_control
		"music":
			return music_volume_control
		"sfx":
			return sfx_volume_control
		"ui":
			return ui_volume_control
		_:
			return null

func _save_current_settings() -> void:
	"""Current settings'leri kaydet"""
	current_settings = {}
	
	var buses = ["master", "music", "sfx", "ui"]
	for bus_name in buses:
		var control = _get_volume_control(bus_name)
		if control:
			current_settings[bus_name] = {
				"volume": control.get_volume(),
				"muted": control.is_volume_muted(),
				"bus_name": control.bus_name
			}

# === EVENT HANDLERS ===

func _on_volume_changed(volume: int, bus_name: String) -> void:
	# Volume değişti
	settings_changed = true
	audio_setting_changed.emit(bus_name, volume, false)
	
	# Current settings'i güncelle
	_save_current_settings()

func _on_mute_toggled(is_muted: bool, bus_name: String) -> void:
	# Mute state değişti
	settings_changed = true
	audio_setting_changed.emit(bus_name, 
		_get_volume_control(bus_name.to_lower()).get_volume() if not is_muted else 0,
		is_muted
	)
	
	# Current settings'i güncelle
	_save_current_settings()

func _on_test_sfx_button_pressed() -> void:
	# Test SFX button'a tıklandı
	play_test_sound("sfx")

func _on_test_music_button_pressed() -> void:
	# Test Music button'a tıklandı
	play_test_sound("music")

func _on_test_ui_button_pressed() -> void:
	# Test UI button'a tıklandı
	play_test_sound("ui")

# === DEBUG ===

func _to_string() -> String:
	return "[AudioSettingsOrganism: Initialized: %s, Settings Changed: %s]" % [
		str(is_initialized),
		str(settings_changed)
	]

func print_debug_info() -> void:
	print("=== AudioSettingsOrganism Debug ===")
	print("Is Initialized: %s" % str(is_initialized))
	print("Show Title: %s" % str(show_title))
	print("Show Test Buttons: %s" % str(show_test_buttons))
	print("Settings Changed: %s" % str(settings_changed))
	print("Default Volumes: %s" % str(default_volumes))
	print("\nCurrent Settings:")
	for bus_name in current_settings:
		var settings = current_settings[bus_name]
		print("  %s: %d%% %s" % [
			bus_name.capitalize(),
			settings.volume,
			"(MUTED)" if settings.muted else ""
		])
	
	# Volume control states
	print("\nVolume Control States:")
	var controls = {
		"Master": master_volume_control,
		"Music": music_volume_control,
		"SFX": sfx_volume_control,
		"UI": ui_volume_control
	}
	
	for name in controls:
		var control = controls[name]
		if control:
			print("  %s: %s" % [name, str(control)])