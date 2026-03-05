# 🎵 AUDIO SETTINGS (MOLECULE)
# Audio ayarlarını yönetir ve persistence sağlar
class_name AudioSettings
extends Node

# === SETTINGS KEYS ===
const SETTINGS_SECTION: String = "audio"
const CONFIG_FILE_PATH: String = "user://audio_settings.cfg"

# Bus isimleri AudioBusCreator ile aynı olmalı (Master, Music, SFX, UI, Voice, ...)
const BUS_NAME_MAP: Dictionary = {
	"master": "Master",
	"music": "Music",
	"sfx": "SFX",
	"ui": "UI",
	"voice": "Voice",
	"ambient": "Ambient",
	"footsteps": "Footsteps",
	"weapons": "Weapons"
}

# === DEFAULT SETTINGS ===
const DEFAULT_SETTINGS: Dictionary = {
	"master_volume": 1.0,      # 0.0 - 1.0
	"music_volume": 0.8,       # 0.0 - 1.0
	"sfx_volume": 0.9,         # 0.0 - 1.0
	"ui_volume": 0.7,          # 0.0 - 1.0
	"voice_volume": 1.0,       # 0.0 - 1.0
	"ambient_volume": 0.6,     # 0.0 - 1.0
	"footsteps_volume": 0.8,   # 0.0 - 1.0
	"weapons_volume": 1.0,     # 0.0 - 1.0
	
	"master_muted": false,
	"music_muted": false,
	"sfx_muted": false,
	"ui_muted": false,
	"voice_muted": false,
	"ambient_muted": false,
	"footsteps_muted": false,
	"weapons_muted": false,
	
	"music_enabled": true,
	"sfx_enabled": true,
	"ui_sounds_enabled": true,
	
	"spatial_audio_enabled": true,
	"dynamic_range_compression": true,
	"reverb_enabled": true,
	
	"output_device": "default",
	"sample_rate": 44100,
	"buffer_size": 1024
}

# === SETTINGS PROPERTIES ===
var current_settings: Dictionary = {}
var is_settings_loaded: bool = false
var config_file: ConfigFile = null

# === DEPENDENCIES ===
var audio_bus_manager: AudioBusManager = null

# === SIGNALS ===
signal settings_loaded(success: bool)
signal settings_saved(success: bool)
signal setting_changed(key: String, old_value, new_value)
signal settings_reset()
signal volume_changed(bus_name: String, volume: float, muted: bool)

# === LIFECYCLE ===

func _ready() -> void:
	print("AudioSettings initializing...")
	
	# Varsayılan ayarları yükle
	current_settings = DEFAULT_SETTINGS.duplicate(true)
	
	# Config dosyasını yükle
	_load_settings()
	
	print("AudioSettings initialized")

func set_audio_bus_manager(bus_manager: AudioBusManager) -> void:
	# AudioBusManager dependency'sini ayarla
	audio_bus_manager = bus_manager
	
	# Ayarları audio bus'lara uygula
	if audio_bus_manager and is_settings_loaded:
		_apply_settings_to_buses()

# === PUBLIC API ===

func get_setting(key: String, default_value = null):
	# Ayarları al
	return current_settings.get(key, default_value)

func set_setting(key: String, value, save_immediately: bool = true) -> bool:
	# Ayarı değiştir
	if not key in current_settings:
		print("Unknown setting key: %s" % key)
		return false
	
	var old_value = current_settings[key]
	
	# Değer aynıysa işlem yapma
	if old_value == value:
		return true
	
	current_settings[key] = value
	
	# Audio bus'lara uygula
	_apply_setting_to_bus(key, value)
	
	# Event gönder
	setting_changed.emit(key, old_value, value)
	
	# Hemen kaydet
	if save_immediately:
		save_settings()
	
	return true

func set_volume(bus_name: String, volume: float, save_immediately: bool = true) -> bool:
	# Volume ayarla
	var key = bus_name.to_lower() + "_volume"
	if not key in current_settings:
		print("Unknown volume bus: %s" % bus_name)
		return false
	
	return set_setting(key, volume, save_immediately)

func set_muted(bus_name: String, muted: bool, save_immediately: bool = true) -> bool:
	# Mute ayarla
	var key = bus_name.to_lower() + "_muted"
	if not key in current_settings:
		print("Unknown mute bus: %s" % bus_name)
		return false
	
	return set_setting(key, muted, save_immediately)

func get_volume(bus_name: String) -> float:
	# Volume al
	var key = bus_name.to_lower() + "_volume"
	return current_settings.get(key, 1.0)

func is_muted(bus_name: String) -> bool:
	# Mute durumunu al
	var key = bus_name.to_lower() + "_muted"
	return current_settings.get(key, false)

func toggle_mute(bus_name: String) -> bool:
	# Mute'u aç/kapa
	var currently_muted = is_muted(bus_name)
	return set_muted(bus_name, not currently_muted)

func save_settings() -> bool:
	# Ayarları kaydet
	if config_file == null:
		config_file = ConfigFile.new()
	
	# Tüm ayarları config'e yaz
	for key in current_settings:
		config_file.set_value(SETTINGS_SECTION, key, current_settings[key])
	
	var error = config_file.save(CONFIG_FILE_PATH)
	var success = error == OK
	
	if success:
		print("Audio settings saved to: %s" % CONFIG_FILE_PATH)
	else:
		print("Failed to save audio settings: %s" % error_string(error))
	
	settings_saved.emit(success)
	return success

func load_settings() -> bool:
	# Ayarları yükle
	return _load_settings()

func reset_to_defaults(save_immediately: bool = true) -> void:
	# Varsayılan ayarlara dön
	var old_settings = current_settings.duplicate(true)
	current_settings = DEFAULT_SETTINGS.duplicate(true)
	
	# Audio bus'lara uygula
	if audio_bus_manager:
		_apply_settings_to_buses()
	
	# Değişen ayarları event olarak gönder
	for key in current_settings:
		if current_settings[key] != old_settings.get(key):
			setting_changed.emit(key, old_settings.get(key), current_settings[key])
	
	settings_reset.emit()
	
	# Kaydet
	if save_immediately:
		save_settings()

func get_all_settings() -> Dictionary:
	# Tüm ayarları al
	return current_settings.duplicate(true)

func get_volume_settings() -> Dictionary:
	# Sadece volume ayarlarını al
	var volume_settings = {}
	
	for key in current_settings:
		if key.ends_with("_volume"):
			var bus_name = key.replace("_volume", "").to_upper()
			volume_settings[bus_name] = {
				"volume": current_settings[key],
				"muted": current_settings.get(bus_name.to_lower() + "_muted", false)
			}
	
	return volume_settings

func get_audio_devices() -> Array:
	# Kullanılabilir audio cihazlarını al
	var devices = []
	
	# Godot 4'te audio device listesi yok, placeholder
	devices.append("default")
	devices.append("headphones")
	devices.append("speakers")
	
	return devices

func set_audio_device(device_name: String) -> bool:
	# Audio output device'ını değiştir
	# Not: Godot 4'te bu özellik sınırlı, placeholder
	print("Audio device changed to: %s" % device_name)
	return set_setting("output_device", device_name)

# === PRIVATE METHODS ===

func _load_settings() -> bool:
	# Ayarları yükle
	config_file = ConfigFile.new()
	var error = config_file.load(CONFIG_FILE_PATH)
	
	if error != OK:
		print("No saved audio settings found, using defaults")
		is_settings_loaded = true
		settings_loaded.emit(false)
		return false
	
	# Config'den ayarları yükle
	for key in DEFAULT_SETTINGS:
		var value = config_file.get_value(SETTINGS_SECTION, key, DEFAULT_SETTINGS[key])
		current_settings[key] = value
	
	print("Audio settings loaded from: %s" % CONFIG_FILE_PATH)
	is_settings_loaded = true
	settings_loaded.emit(true)
	
	return true

func _normalize_bus_name(key_prefix: String) -> String:
	# Ayarlardaki anahtardan bus adını al (AudioBusCreator ile aynı yazım)
	return BUS_NAME_MAP.get(key_prefix.to_lower(), key_prefix.capitalize())

func _apply_settings_to_buses() -> void:
	# Tüm ayarları audio bus'lara uygula
	if not audio_bus_manager:
		return
	
	for key in current_settings:
		if key.ends_with("_volume"):
			_apply_setting_to_bus(key, current_settings[key])
		elif key.ends_with("_muted"):
			_apply_setting_to_bus(key, current_settings[key])

func _apply_setting_to_bus(key: String, value) -> void:
	# Tekil ayarı audio bus'a uygula
	if not audio_bus_manager:
		return
	
	if key.ends_with("_volume"):
		var bus_key = key.replace("_volume", "")
		var bus_name = _normalize_bus_name(bus_key)
		var volume_db = linear_to_db(value)
		audio_bus_manager.set_bus_volume_db(bus_name, volume_db)
		var muted = current_settings.get(bus_key + "_muted", false)
		volume_changed.emit(bus_name, value, muted)
	
	elif key.ends_with("_muted"):
		var bus_key = key.replace("_muted", "")
		var bus_name = _normalize_bus_name(bus_key)
		audio_bus_manager.mute_bus(bus_name, value)
		var volume = current_settings.get(bus_key + "_volume", 1.0)
		volume_changed.emit(bus_name, volume, value)
	
	elif key == "spatial_audio_enabled":
		# Spatial audio ayarı (AudioSystem'e event gönder)
		# EventBus.emit_now_static kaldırıldı - AudioSystemMolecule bunu kendi içinde işleyecek
		pass

# === DEBUG ===

func print_settings() -> void:
	print("=== AudioSettings ===")
	print("Settings Loaded: %s" % str(is_settings_loaded))
	print("Config File: %s" % CONFIG_FILE_PATH)
	
	print("\nVolume Settings:")
	var volume_settings = get_volume_settings()
	for bus_name in volume_settings:
		var settings = volume_settings[bus_name]
		print("  %s: %.0f%% %s" % [
			bus_name,
			settings["volume"] * 100,
			"(MUTED)" if settings["muted"] else ""
		])
	
	print("\nOther Settings:")
	for key in current_settings:
		if not key.ends_with("_volume") and not key.ends_with("_muted"):
			print("  %s: %s" % [key, str(current_settings[key])])

func get_settings_info() -> Dictionary:
	return {
		"is_loaded": is_settings_loaded,
		"config_file": CONFIG_FILE_PATH,
		"total_settings": current_settings.size(),
		"volume_settings": get_volume_settings(),
		"audio_devices": get_audio_devices()
	}

func _to_string() -> String:
	return "[AudioSettings: %d settings]" % current_settings.size()