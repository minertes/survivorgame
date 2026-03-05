# 🎮 SETTINGS SCREEN ORGANISM (MODULAR)
# Atomic Design: Settings screen organism using modular components
# Modüler bileşenler kullanan ayarlar ekranı organizması
class_name SettingsScreenOrganism
extends SettingsScreenBase

# === NODES ===
@onready var audio_settings_organism: AudioSettingsOrganism = $CenterContainer/VBoxContainer/SectionsContainer/AudioSettingsOrganism
@onready var graphics_section: GraphicsSettingsSection = $CenterContainer/VBoxContainer/SectionsContainer/GraphicsSection
@onready var controls_section: ControlsSettingsSection = $CenterContainer/VBoxContainer/SectionsContainer/ControlsSection
@onready var gameplay_section: GameplaySettingsSection = $CenterContainer/VBoxContainer/SectionsContainer/GameplaySection

# === STATE ===
var current_settings: Dictionary = {
	"audio": {},
	"graphics": {},
	"controls": {},
	"gameplay": {}
}

var default_settings: Dictionary = {}

# === EVENTS ===
signal setting_changed(section: String, key: String, value)

# === LIFECYCLE ===

func _ready() -> void:
	# Temel sınıfın ready fonksiyonunu çağır
	super._ready()
	
	# Bileşen sinyallerini bağla
	_connect_component_signals()
	
	# Varsayılan ayarları yükle
	_load_default_settings()
	
	# Mevcut ayarları yükle
	_load_current_settings()
	
	# UI'yi güncelle
	_update_all_displays()

# === PUBLIC API ===

func set_setting(section: String, key: String, value) -> void:
	if not section in current_settings:
		current_settings[section] = {}
	
	current_settings[section][key] = value
	settings_changed = true
	
	# İlgili bileşene bildir
	_update_component_setting(section, key, value)
	
	# Event emit
	setting_changed.emit(section, key, value)
	
	# Save button state
	_update_save_button_state()

func get_setting(section: String, key: String, default = null):
	if section in current_settings and key in current_settings[section]:
		return current_settings[section][key]
	return default

func get_all_settings() -> Dictionary:
	# Tüm bileşenlerden ayarları topla
	_collect_all_settings()
	return current_settings.duplicate(true)

func save_settings() -> void:
	print("SettingsScreen: Saving all settings...")
	
	# Tüm ayarları topla
	_collect_all_settings()
	
	# Audio settings'leri kaydet
	if audio_settings_organism:
		audio_settings_organism.save_settings()
	
	# Ayarları uygula
	_apply_all_settings()
	
	settings_changed = false
	_update_save_button_state()
	
	# Event emit
	settings_saved.emit(current_settings.duplicate(true))
	
	print("Settings saved successfully")

func reset_settings() -> void:
	print("SettingsScreen: Resetting all settings to defaults")
	
	# Tüm bileşenleri reset et
	if audio_settings_organism:
		audio_settings_organism.reset_to_defaults()
	
	if graphics_section:
		graphics_section.reset_to_defaults()
	
	if controls_section:
		controls_section.reset_to_defaults()
	
	if gameplay_section:
		gameplay_section.reset_to_defaults()
	
	# Ayarları topla
	_collect_all_settings()
	settings_changed = true
	_update_save_button_state()
	
	# Event emit
	settings_reset.emit()

# === PRIVATE METHODS ===

func _connect_component_signals() -> void:
	# AudioSettingsOrganism
	if audio_settings_organism:
		if audio_settings_organism.has_signal("audio_setting_changed"):
			audio_settings_organism.audio_setting_changed.connect(_on_audio_setting_changed)
		if audio_settings_organism.has_signal("audio_test_requested"):
			audio_settings_organism.audio_test_requested.connect(_on_audio_test_requested)
	
	# GraphicsSettingsSection
	if graphics_section:
		if graphics_section.has_signal("setting_changed"):
			graphics_section.setting_changed.connect(_on_graphics_setting_changed)
		if graphics_section.has_signal("graphics_settings_updated"):
			graphics_section.graphics_settings_updated.connect(_on_graphics_settings_updated)
	
	# ControlsSettingsSection
	if controls_section:
		if controls_section.has_signal("setting_changed"):
			controls_section.setting_changed.connect(_on_controls_setting_changed)
		if controls_section.has_signal("controls_settings_updated"):
			controls_section.controls_settings_updated.connect(_on_controls_settings_updated)
	
	# GameplaySettingsSection
	if gameplay_section:
		if gameplay_section.has_signal("setting_changed"):
			gameplay_section.setting_changed.connect(_on_gameplay_setting_changed)
		if gameplay_section.has_signal("gameplay_settings_updated"):
			gameplay_section.gameplay_settings_updated.connect(_on_gameplay_settings_updated)

func _load_default_settings() -> void:
	# Varsayılan ayarları oluştur
	default_settings = {
		"audio": {},
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

func _load_current_settings() -> void:
	# Burada persistent storage'dan ayarları yükle
	# Şimdilik varsayılan ayarları kullan
	current_settings = default_settings.duplicate(true)
	
	# Bileşenlere yükle
	if audio_settings_organism:
		audio_settings_organism.load_settings(current_settings["audio"])
	
	if graphics_section:
		graphics_section.load_settings(current_settings["graphics"])
	
	if controls_section:
		controls_section.load_settings(current_settings["controls"])
	
	if gameplay_section:
		gameplay_section.load_settings(current_settings["gameplay"])

func _collect_all_settings() -> void:
	# Tüm bileşenlerden ayarları topla
	if audio_settings_organism:
		current_settings["audio"] = audio_settings_organism.save_settings()
	
	if graphics_section:
		current_settings["graphics"] = graphics_section.save_settings()
	
	if controls_section:
		current_settings["controls"] = controls_section.save_settings()
	
	if gameplay_section:
		current_settings["gameplay"] = gameplay_section.save_settings()

func _update_all_displays() -> void:
	# Tüm bileşenlerin display'ini güncelle
	if graphics_section:
		graphics_section.load_settings(current_settings["graphics"])
	
	if controls_section:
		controls_section.load_settings(current_settings["controls"])
	
	if gameplay_section:
		gameplay_section.load_settings(current_settings["gameplay"])

func _update_component_setting(section: String, key: String, value) -> void:
	# İlgili bileşene ayarı bildir
	match section:
		"audio":
			if audio_settings_organism:
				# AudioSettingsOrganism kendi iç yapısını yönetir
				pass
		"graphics":
			if graphics_section:
				var settings = graphics_section.get_current_settings()
				settings[key] = value
				graphics_section.load_settings(settings)
		"controls":
			if controls_section:
				var settings = controls_section.get_current_settings()
				settings[key] = value
				controls_section.load_settings(settings)
		"gameplay":
			if gameplay_section:
				var settings = gameplay_section.get_current_settings()
				settings[key] = value
				gameplay_section.load_settings(settings)

func _apply_all_settings() -> void:
	# Tüm ayarları uygula
	print("Applying all settings...")
	
	# Graphics settings
	_apply_graphics_settings()
	
	# Gameplay settings
	_apply_gameplay_settings()

func _apply_graphics_settings() -> void:
	var graphics = current_settings["graphics"]
	print("Applying graphics settings: %s" % str(graphics))
	
	# Burada grafik ayarlarını uygula
	# Örneğin: çözünürlük, kalite, vsync

func _apply_gameplay_settings() -> void:
	var gameplay = current_settings["gameplay"]
	print("Applying gameplay settings: %s" % str(gameplay))
	
	# Burada oyun ayarlarını uygula
	# Örneğin: fare hassasiyeti

# === EVENT HANDLERS (Override) ===

func _on_save_button_pressed() -> void:
	save_settings()

func _on_reset_button_pressed() -> void:
	reset_settings()

# === COMPONENT EVENT HANDLERS ===

func _on_audio_setting_changed(bus_name: String, volume: int, muted: bool) -> void:
	settings_changed = true
	_update_save_button_state()
	
	# Current settings'i güncelle
	if not "audio" in current_settings:
		current_settings["audio"] = {}
	
	current_settings["audio"][bus_name.to_lower() + "_volume"] = volume
	current_settings["audio"][bus_name.to_lower() + "_muted"] = muted
	
	# Event emit
	setting_changed.emit("audio", bus_name.to_lower() + "_volume", volume)
	setting_changed.emit("audio", bus_name.to_lower() + "_muted", muted)

func _on_audio_test_requested(test_type: String) -> void:
	print("Audio test requested: %s" % test_type)
	# Audio test sesi çal

func _on_graphics_setting_changed(key: String, value) -> void:
	settings_changed = true
	_update_save_button_state()
	
	# Current settings'i güncelle
	if not "graphics" in current_settings:
		current_settings["graphics"] = {}
	
	current_settings["graphics"][key] = value
	
	# Event emit
	setting_changed.emit("graphics", key, value)

func _on_graphics_settings_updated(settings: Dictionary) -> void:
	current_settings["graphics"] = settings.duplicate()

func _on_controls_setting_changed(key: String, value) -> void:
	settings_changed = true
	_update_save_button_state()
	
	# Current settings'i güncelle
	if not "controls" in current_settings:
		current_settings["controls"] = {}
	
	current_settings["controls"][key] = value
	
	# Event emit
	setting_changed.emit("controls", key, value)

func _on_controls_settings_updated(settings: Dictionary) -> void:
	current_settings["controls"] = settings.duplicate()

func _on_gameplay_setting_changed(key: String, value) -> void:
	settings_changed = true
	_update_save_button_state()
	
	# Current settings'i güncelle
	if not "gameplay" in current_settings:
		current_settings["gameplay"] = {}
	
	current_settings["gameplay"][key] = value
	
	# Event emit
	setting_changed.emit("gameplay", key, value)

func _on_gameplay_settings_updated(settings: Dictionary) -> void:
	current_settings["gameplay"] = settings.duplicate()

# === DEBUG ===

func print_debug_info() -> void:
	super.print_debug_info()
	
	print("\n=== SettingsScreenOrganism (Modular) Debug ===")
	print("Current Settings:")
	for section in current_settings:
		print("  %s: %s" % [section, str(current_settings[section])])
	
	print("\nComponent Status:")
	print("  AudioSettingsOrganism: %s" % ("Loaded" if audio_settings_organism else "Not Loaded"))
	print("  GraphicsSettingsSection: %s" % ("Loaded" if graphics_section else "Not Loaded"))
	print("  ControlsSettingsSection: %s" % ("Loaded" if controls_section else "Not Loaded"))
	print("  GameplaySettingsSection: %s" % ("Loaded" if gameplay_section else "Not Loaded"))
	
	# Bileşen debug bilgileri
	if audio_settings_organism and audio_settings_organism.has_method("print_debug_info"):
		print("\nAudioSettingsOrganism:")
		audio_settings_organism.print_debug_info()
	
	if graphics_section:
		print("\nGraphicsSettingsSection:")
		graphics_section.print_debug_info()
	
	if controls_section:
		print("\nControlsSettingsSection:")
		controls_section.print_debug_info()
	
	if gameplay_section:
		print("\nGameplaySettingsSection:")
		gameplay_section.print_debug_info()