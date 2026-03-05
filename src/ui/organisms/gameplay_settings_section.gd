# 🎮 GAMEPLAY SETTINGS SECTION
# Oyun ayarları bölümü
class_name GameplaySettingsSection
extends Control

# === NODES ===
@onready var sensitivity_label: Label = $SensitivityLabel
@onready var sensitivity_slider: HSlider = $SensitivitySlider
@onready var sensitivity_value_label: Label = $SensitivityValueLabel

# === STATE ===
var current_settings: Dictionary = {
	"mouse_sensitivity": 50,
	"show_damage_numbers": true,
	"show_hit_indicators": true
}

# === EVENTS ===
signal setting_changed(key: String, value)
signal gameplay_settings_updated(settings: Dictionary)

# === LIFECYCLE ===

func _ready() -> void:
	_setup_ui()
	_connect_signals()
	_update_display()

# === PUBLIC API ===

func load_settings(settings: Dictionary) -> void:
	if "mouse_sensitivity" in settings:
		current_settings["mouse_sensitivity"] = settings["mouse_sensitivity"]
	if "show_damage_numbers" in settings:
		current_settings["show_damage_numbers"] = settings["show_damage_numbers"]
	if "show_hit_indicators" in settings:
		current_settings["show_hit_indicators"] = settings["show_hit_indicators"]
	
	_update_display()

func save_settings() -> Dictionary:
	return current_settings.duplicate()

func reset_to_defaults() -> void:
	current_settings = {
		"mouse_sensitivity": 50,
		"show_damage_numbers": true,
		"show_hit_indicators": true
	}
	_update_display()
	setting_changed.emit("mouse_sensitivity", 50)
	setting_changed.emit("show_damage_numbers", true)
	setting_changed.emit("show_hit_indicators", true)

func get_current_settings() -> Dictionary:
	return current_settings.duplicate()

# === PRIVATE METHODS ===

func _setup_ui() -> void:
	if sensitivity_label:
		sensitivity_label.text = "Fare Hassasiyeti:"
	
	if sensitivity_slider:
		sensitivity_slider.min_value = 10
		sensitivity_slider.max_value = 100
		sensitivity_slider.step = 5
		sensitivity_slider.value = current_settings["mouse_sensitivity"]

func _connect_signals() -> void:
	if sensitivity_slider:
		sensitivity_slider.value_changed.connect(_on_sensitivity_changed)

func _update_display() -> void:
	if sensitivity_slider:
		sensitivity_slider.value = current_settings["mouse_sensitivity"]
	
	if sensitivity_value_label:
		sensitivity_value_label.text = str(int(current_settings["mouse_sensitivity"]))

# === EVENT HANDLERS ===

func _on_sensitivity_changed(value: float) -> void:
	current_settings["mouse_sensitivity"] = int(value)
	_update_display()
	setting_changed.emit("mouse_sensitivity", current_settings["mouse_sensitivity"])
	gameplay_settings_updated.emit(current_settings.duplicate())

# === DEBUG ===

func print_debug_info() -> void:
	print("=== GameplaySettingsSection Debug ===")
	print("Current Settings: %s" % str(current_settings))
	print("UI Elements:")
	print("  Sensitivity Slider: %s" % ("Loaded" if sensitivity_slider else "Not Loaded"))
	print("  Sensitivity Value Label: %s" % ("Loaded" if sensitivity_value_label else "Not Loaded"))