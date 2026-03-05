# 🎮 GRAPHICS SETTINGS SECTION
# Grafik ayarları bölümü
class_name GraphicsSettingsSection
extends Control

# === NODES ===
@onready var quality_label: Label = $QualityLabel
@onready var quality_dropdown: Button = $QualityDropdown
@onready var resolution_label: Label = $ResolutionLabel
@onready var resolution_dropdown: Button = $ResolutionDropdown
@onready var vsync_label: Label = $VSyncLabel
@onready var vsync_toggle: Button = $VSyncToggle

# === STATE ===
var current_settings: Dictionary = {
	"quality": "medium",
	"resolution": "1920x1080",
	"vsync": true
}

var available_qualities: Array = ["low", "medium", "high", "ultra"]
var available_resolutions: Array = ["1920x1080", "1600x900", "1366x768", "1280x720"]

# === EVENTS ===
signal setting_changed(key: String, value)
signal graphics_settings_updated(settings: Dictionary)

# === LIFECYCLE ===

func _ready() -> void:
	_setup_ui()
	_connect_signals()
	_update_display()

# === PUBLIC API ===

func load_settings(settings: Dictionary) -> void:
	if "quality" in settings:
		current_settings["quality"] = settings["quality"]
	if "resolution" in settings:
		current_settings["resolution"] = settings["resolution"]
	if "vsync" in settings:
		current_settings["vsync"] = settings["vsync"]
	
	_update_display()

func save_settings() -> Dictionary:
	return current_settings.duplicate()

func reset_to_defaults() -> void:
	current_settings = {
		"quality": "medium",
		"resolution": "1920x1080",
		"vsync": true
	}
	_update_display()
	setting_changed.emit("quality", "medium")
	setting_changed.emit("resolution", "1920x1080")
	setting_changed.emit("vsync", true)

func get_current_settings() -> Dictionary:
	return current_settings.duplicate()

# === PRIVATE METHODS ===

func _setup_ui() -> void:
	if quality_label:
		quality_label.text = "Kalite:"
	
	if resolution_label:
		resolution_label.text = "Çözünürlük:"
	
	if vsync_label:
		vsync_label.text = "VSync:"

func _connect_signals() -> void:
	if quality_dropdown:
		quality_dropdown.pressed.connect(_on_quality_dropdown_pressed)
	
	if resolution_dropdown:
		resolution_dropdown.pressed.connect(_on_resolution_dropdown_pressed)
	
	if vsync_toggle:
		vsync_toggle.pressed.connect(_on_vsync_toggle_pressed)

func _update_display() -> void:
	if quality_dropdown:
		quality_dropdown.text = current_settings["quality"].capitalize()
	
	if resolution_dropdown:
		resolution_dropdown.text = current_settings["resolution"]
	
	if vsync_toggle:
		vsync_toggle.text = "AÇIK" if current_settings["vsync"] else "KAPALI"

func _show_quality_menu() -> void:
	# Basit bir quality seçim menüsü
	print("Quality options: %s" % str(available_qualities))
	# Burada daha gelişmiş bir menü implemente edilebilir

func _show_resolution_menu() -> void:
	# Basit bir resolution seçim menüsü
	print("Resolution options: %s" % str(available_resolutions))
	# Burada daha gelişmiş bir menü implemente edilebilir

# === EVENT HANDLERS ===

func _on_quality_dropdown_pressed() -> void:
	_show_quality_menu()
	# Geçici: quality'yi değiştir
	var current_index = available_qualities.find(current_settings["quality"])
	var next_index = (current_index + 1) % available_qualities.size()
	current_settings["quality"] = available_qualities[next_index]
	_update_display()
	setting_changed.emit("quality", current_settings["quality"])
	graphics_settings_updated.emit(current_settings.duplicate())

func _on_resolution_dropdown_pressed() -> void:
	_show_resolution_menu()
	# Geçici: resolution'ı değiştir
	var current_index = available_resolutions.find(current_settings["resolution"])
	var next_index = (current_index + 1) % available_resolutions.size()
	current_settings["resolution"] = available_resolutions[next_index]
	_update_display()
	setting_changed.emit("resolution", current_settings["resolution"])
	graphics_settings_updated.emit(current_settings.duplicate())

func _on_vsync_toggle_pressed() -> void:
	current_settings["vsync"] = not current_settings["vsync"]
	_update_display()
	setting_changed.emit("vsync", current_settings["vsync"])
	graphics_settings_updated.emit(current_settings.duplicate())

# === DEBUG ===

func print_debug_info() -> void:
	print("=== GraphicsSettingsSection Debug ===")
	print("Current Settings: %s" % str(current_settings))
	print("Available Qualities: %s" % str(available_qualities))
	print("Available Resolutions: %s" % str(available_resolutions))
	print("UI Elements:")
	print("  Quality Dropdown: %s" % ("Loaded" if quality_dropdown else "Not Loaded"))
	print("  Resolution Dropdown: %s" % ("Loaded" if resolution_dropdown else "Not Loaded"))
	print("  VSync Toggle: %s" % ("Loaded" if vsync_toggle else "Not Loaded"))