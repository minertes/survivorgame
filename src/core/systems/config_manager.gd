# 📁 CONFIG MANAGER
# Data-driven config'leri yöneten merkezi sistem
class_name ConfigManager
extends Node

# === STATIC ACCESS ===
static var instance: ConfigManager = null

# === CONFIG PATHS ===
const CONFIG_DIR = "res://src/data/"
const WEAPONS_CONFIG = "weapons.json"
const ENEMIES_CONFIG = "enemies.json"
const ITEMS_CONFIG = "items.json"
const BALANCE_CONFIG = "balance.json"

# === CACHE ===
var _config_cache: Dictionary = {}           # filename → parsed_data
var _config_watchers: Dictionary = {}        # filename → Array[Callable]
var _file_timestamps: Dictionary = {}        # filename → last_modified

# === SIGNALS ===
signal config_loaded(filename: String, data: Dictionary)
signal config_reloaded(filename: String, data: Dictionary)
signal config_error(filename: String, error: String)

# === LIFECYCLE ===

func _ready() -> void:
	if instance != null:
		push_warning("Multiple ConfigManager instances detected!")
		queue_free()
		return
	
	instance = self
	
	# Temel config dosyalarını yükle
	_preload_essential_configs()
	
	print("ConfigManager initialized")

func _exit_tree() -> void:
	if instance == self:
		instance = null
		print("ConfigManager destroyed")

func _process(delta: float) -> void:
	# Config dosyalarını otomatik reload et (development için)
	_check_config_updates()

# === PUBLIC API ===

func load_config(filename: String, force_reload: bool = false) -> Dictionary:
	if not force_reload and filename in _config_cache:
		return _config_cache[filename].duplicate(true)
	
	var filepath = CONFIG_DIR + filename
	var data = {}
	
	if not FileAccess.file_exists(filepath):
		var error_msg = "Config file not found: %s" % filepath
		push_error(error_msg)
		config_error.emit(filename, error_msg)
		return data
	
	# Dosyayı oku ve parse et
	var file = FileAccess.open(filepath, FileAccess.READ)
	if file == null:
		var error = FileAccess.get_open_error()
		var error_msg = "Failed to open config file: %s (Error: %d)" % [filepath, error]
		push_error(error_msg)
		config_error.emit(filename, error_msg)
		return data
	
	var json_text = file.get_as_text()
	file.close()
	
	# JSON parse et
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	
	if parse_result != OK:
		var error_msg = "Failed to parse JSON: %s (Error: %s)" % [filename, json.get_error_message()]
		push_error(error_msg)
		config_error.emit(filename, error_msg)
		return data
	
	data = json.get_data()
	
	# Cache'e kaydet
	_config_cache[filename] = data.duplicate(true)
	
	# Timestamp'i güncelle
	_update_file_timestamp(filename)
	
	config_loaded.emit(filename, data)
	print("Config loaded: %s (%d entries)" % [filename, data.size()])
	
	return data.duplicate(true)

func save_config(filename: String, data: Dictionary) -> bool:
	var filepath = CONFIG_DIR + filename
	
	# JSON'a çevir
	var json = JSON.new()
	json.stringify(data, "  ", true)  # Indent with 2 spaces
	
	var file = FileAccess.open(filepath, FileAccess.WRITE)
	if file == null:
		var error = FileAccess.get_open_error()
		var error_msg = "Failed to save config file: %s (Error: %d)" % [filepath, error]
		push_error(error_msg)
		config_error.emit(filename, error_msg)
		return false
	
	file.store_string(json.get_data())
	file.close()
	
	# Cache'i güncelle
	_config_cache[filename] = data.duplicate(true)
	_update_file_timestamp(filename)
	
	print("Config saved: %s (%d entries)" % [filename, data.size()])
	return true

func reload_config(filename: String) -> Dictionary:
	# Cache'den kaldır ve yeniden yükle
	if filename in _config_cache:
		_config_cache.erase(filename)
	
	return load_config(filename, true)

func get_config_value(filename: String, key_path: String, default = null):
	var data = load_config(filename)
	
	if data.is_empty():
		return default
	
	# Nested key path (e.g., "weapons.pistol.damage")
	var keys = key_path.split(".")
	var current = data
	
	for key in keys:
		if current is Dictionary and key in current:
			current = current[key]
		else:
			return default
	
	return current

func set_config_value(filename: String, key_path: String, value) -> bool:
	var data = load_config(filename)
	
	if data.is_empty():
		return false
	
	# Nested key path
	var keys = key_path.split(".")
	var current = data
	
	# Son key'e kadar ilerle
	for i in range(keys.size() - 1):
		var key = keys[i]
		
		if not key in current or not current[key] is Dictionary:
			current[key] = {}
		
		current = current[key]
	
	# Değeri ata
	var last_key = keys[keys.size() - 1]
	current[last_key] = value
	
	# Kaydet
	return save_config(filename, data)

func watch_config(filename: String, callback: Callable) -> void:
	if not filename in _config_watchers:
		_config_watchers[filename] = []
	
	if not callback in _config_watchers[filename]:
		_config_watchers[filename].append(callback)

func unwatch_config(filename: String, callback: Callable) -> void:
	if filename in _config_watchers and callback in _config_watchers[filename]:
		_config_watchers[filename].erase(callback)

func clear_cache() -> void:
	_config_cache.clear()
	_file_timestamps.clear()
	print("Config cache cleared")

func get_cached_configs() -> Array:
	return _config_cache.keys()

func get_config_stats() -> Dictionary:
	var total_entries = 0
	for filename in _config_cache:
		var data = _config_cache[filename]
		if data is Dictionary:
			total_entries += data.size()
		elif data is Array:
			total_entries += data.size()
	
	return {
		"cached_configs": _config_cache.size(),
		"total_entries": total_entries,
		"watched_files": _config_watchers.size()
	}

# === CONFIG SPECIFICS ===

func get_weapon_config(weapon_id: String) -> Dictionary:
	return get_config_value(WEAPONS_CONFIG, weapon_id, {})

func get_enemy_config(enemy_type: String) -> Dictionary:
	return get_config_value(ENEMIES_CONFIG, enemy_type, {})

func get_item_config(item_id: String) -> Dictionary:
	return get_config_value(ITEMS_CONFIG, item_id, {})

func get_balance_value(key: String, default = null):
	return get_config_value(BALANCE_CONFIG, key, default)

func get_all_weapons() -> Dictionary:
	return load_config(WEAPONS_CONFIG)

func get_all_enemies() -> Dictionary:
	return load_config(ENEMIES_CONFIG)

func get_all_items() -> Dictionary:
	return load_config(ITEMS_CONFIG)

# === STATIC HELPERS ===

static func get_instance() -> ConfigManager:
	return instance

static func is_available() -> bool:
	return instance != null

# === PRIVATE METHODS ===

func _preload_essential_configs() -> void:
	# Temel config dosyalarını yükle
	var essential_configs = [
		WEAPONS_CONFIG,
		ENEMIES_CONFIG,
		ITEMS_CONFIG,
		BALANCE_CONFIG
	]
	
	for config in essential_configs:
		load_config(config)
		
		# Eğer dosya yoksa, template oluştur
		var filepath = CONFIG_DIR + config
		if not FileAccess.file_exists(filepath):
			_create_config_template(config)

func _create_config_template(filename: String) -> void:
	var template_data = {}
	
	match filename:
		WEAPONS_CONFIG:
			template_data = _get_weapons_template()
		ENEMIES_CONFIG:
			template_data = _get_enemies_template()
		ITEMS_CONFIG:
			template_data = _get_items_template()
		BALANCE_CONFIG:
			template_data = _get_balance_template()
		_:
			template_data = {"_comment": "Auto-generated template"}
	
	save_config(filename, template_data)
	print("Created template config: %s" % filename)

func _get_weapons_template() -> Dictionary:
	return {
		"pistol": {
			"name": "Pistol",
			"damage": 10.0,
			"fire_rate": 0.5,
			"range": 300.0,
			"projectile_speed": 500.0,
			"magazine_size": 12,
			"reload_time": 1.5,
			"unlock_level": 1,
			"cost": 100
		},
		"shotgun": {
			"name": "Shotgun",
			"damage": 25.0,
			"fire_rate": 1.0,
			"range": 150.0,
			"projectile_speed": 400.0,
			"magazine_size": 6,
			"reload_time": 2.0,
			"unlock_level": 3,
			"cost": 300
		}
	}

func _get_enemies_template() -> Dictionary:
	return {
		"basic": {
			"name": "Basic Zombie",
			"health": 50.0,
			"speed": 150.0,
			"damage": 10.0,
			"attack_range": 40.0,
			"detection_range": 250.0,
			"experience": 10,
			"score": 10
		},
		"fast": {
			"name": "Fast Zombie",
			"health": 30.0,
			"speed": 250.0,
			"damage": 8.0,
			"attack_range": 30.0,
			"detection_range": 350.0,
			"experience": 15,
			"score": 15
		}
	}

func _get_items_template() -> Dictionary:
	return {
		"health_pack": {
			"name": "Health Pack",
			"heal_amount": 25.0,
			"duration": 0.0,
			"rarity": "common",
			"spawn_weight": 10
		},
		"speed_boost": {
			"name": "Speed Boost",
			"speed_multiplier": 1.5,
			"duration": 10.0,
			"rarity": "uncommon",
			"spawn_weight": 5
		}
	}

func _get_balance_template() -> Dictionary:
	return {
		"player": {
			"base_health": 100.0,
			"base_speed": 300.0,
			"experience_per_level": 100,
			"level_up_health_bonus": 20.0,
			"level_up_speed_bonus": 10.0
		},
		"game": {
			"max_enemies_on_screen": 50,
			"enemy_spawn_interval": 2.0,
			"item_spawn_interval": 5.0,
			"wave_duration": 60.0,
			"wave_enemy_multiplier": 1.2
		}
	}

func _update_file_timestamp(filename: String) -> void:
	var filepath = CONFIG_DIR + filename
	if FileAccess.file_exists(filepath):
		var file = FileAccess.open(filepath, FileAccess.READ)
		if file:
			_file_timestamps[filename] = file.get_modified_time(filepath)
			file.close()

func _check_config_updates() -> void:
	# Development için: dosya değişikliklerini otomatik tespit et
	for filename in _config_watchers:
		var filepath = CONFIG_DIR + filename
		
		if not FileAccess.file_exists(filepath):
			continue
		
		var file = FileAccess.open(filepath, FileAccess.READ)
		if not file:
			continue
		
		var current_timestamp = file.get_modified_time(filepath)
		file.close()
		
		var last_timestamp = _file_timestamps.get(filename, 0)
		
		if current_timestamp > last_timestamp:
			print("Config file changed: %s, reloading..." % filename)
			var new_data = reload_config(filename)
			
			# Watcher'lara haber ver
			if filename in _config_watchers:
				for callback in _config_watchers[filename]:
					if callback.is_valid():
						callback.call(new_data)

# === DEBUG ===

func _to_string() -> String:
	var stats = get_config_stats()
	return "[ConfigManager: %d configs, %d entries]" % [
		stats.cached_configs,
		stats.total_entries
	]

func print_stats() -> void:
	var stats = get_config_stats()
	print("=== ConfigManager Stats ===")
	print("Cached Configs: %d" % stats.cached_configs)
	print("Total Entries: %d" % stats.total_entries)
	print("Watched Files: %d" % stats.watched_files)
	print("Cached Files: %s" % str(get_cached_configs()))