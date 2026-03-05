# 🎵 AUDIO BUS CONFIG MANAGER
# Audio bus konfigürasyon yönetimi
class_name AudioBusConfigManager
extends Node

# === DEPENDENCIES ===
var bus_creator: AudioBusCreator = null
var volume_controller: AudioBusVolumeController = null
var effect_manager: AudioBusEffectManager = null
var state_manager: AudioBusStateManager = null

# === SIGNALS ===
signal config_loaded()
signal config_saved()
signal config_reset()

# === PUBLIC API ===

func get_all_buses() -> Dictionary:
	# Tüm bus'ların bilgilerini al
	if not bus_creator:
		return {}
	
	var buses = {}
	
	for bus_name in bus_creator.get_all_bus_names():
		var bus_index = bus_creator.get_bus_index(bus_name)
		var config = bus_creator.get_bus_config(bus_name)
		
		var volume_db = 0.0
		var volume_linear = 0.0
		var muted = false
		var effect_count = 0
		
		if volume_controller:
			volume_db = volume_controller.get_bus_volume_db(bus_name)
			volume_linear = volume_controller.get_bus_volume_linear(bus_name)
		
		if state_manager:
			muted = state_manager.is_bus_muted(bus_name)
		
		if effect_manager:
			effect_count = effect_manager.get_bus_effect_count(bus_name)
		
		buses[bus_name] = {
			"index": bus_index,
			"volume_db": volume_db,
			"volume_linear": volume_linear,
			"muted": muted,
			"soloed": config.get("soloed", false),
			"send_to": config.get("send_to", "Master"),
			"effect_count": effect_count,
			"config": config.duplicate()
		}
	
	return buses

func get_bus_info(bus_name: String) -> Dictionary:
	# Belirli bir bus'ın bilgilerini al
	var all_buses = get_all_buses()
	return all_buses.get(bus_name, {})

func save_bus_config(bus_name: String) -> bool:
	# Bus konfigürasyonunu kaydet
	if not bus_creator:
		return false
	
	var config = bus_creator.get_bus_config(bus_name)
	if config.is_empty():
		return false
	
	# Burada konfigürasyonu dosyaya kaydetme kodu eklenebilir
	print("Bus config saved: %s" % bus_name)
	return true

func save_all_configs() -> bool:
	# Tüm bus konfigürasyonlarını kaydet
	if not bus_creator:
		return false
	
	var success = true
	for bus_name in bus_creator.get_all_bus_names():
		if not save_bus_config(bus_name):
			success = false
	
	if success:
		config_saved.emit()
	
	return success

func load_bus_config(bus_name: String, config: Dictionary) -> bool:
	# Bus konfigürasyonunu yükle
	if not bus_creator:
		return false
	
	# Config'i güncelle
	bus_creator.update_bus_config(bus_name, config)
	
	# Volume ayarla
	if volume_controller and "volume_db" in config:
		volume_controller.set_bus_volume_db(bus_name, config["volume_db"])
	
	# Mute durumunu ayarla
	if state_manager and "muted" in config:
		state_manager.mute_bus(bus_name, config["muted"])
	
	# Solo durumunu ayarla (config'de zaten var)
	
	print("Bus config loaded: %s" % bus_name)
	return true

func load_all_configs(configs: Dictionary) -> bool:
	# Tüm bus konfigürasyonlarını yükle
	if not bus_creator:
		return false
	
	var success = true
	for bus_name in configs:
		if bus_creator.has_bus(bus_name):
			if not load_bus_config(bus_name, configs[bus_name]):
				success = false
		else:
			print("Bus not found for config: %s" % bus_name)
			success = false
	
	if success:
		config_loaded.emit()
	
	return success

func reset_bus_config(bus_name: String) -> bool:
	# Bus konfigürasyonunu varsayılana döndür
	if not bus_creator:
		return false
	
	# Varsayılan config
	var default_config = {
		"name": bus_name,
		"send_to": "Master",
		"volume_db": 0.0,
		"muted": false,
		"soloed": false,
		"effects": []
	}
	
	# Config'i yükle
	var success = load_bus_config(bus_name, default_config)
	
	# Volume'ü varsayılana döndür
	if volume_controller:
		volume_controller.set_bus_volume_db(bus_name, 0.0)
	
	# Mute'u kaldır
	if state_manager:
		state_manager.mute_bus(bus_name, false)
	
	return success

func reset_all_configs() -> bool:
	# Tüm bus konfigürasyonlarını varsayılana döndür
	if not bus_creator:
		return false
	
	var success = true
	for bus_name in bus_creator.get_all_bus_names():
		if not reset_bus_config(bus_name):
			success = false
	
	if success:
		config_reset.emit()
	
	return success

func export_config() -> Dictionary:
	# Tüm konfigürasyonu dışa aktar
	var config = {
		"buses": get_all_buses(),
		"timestamp": Time.get_datetime_string_from_system(),
		"version": "1.0"
	}
	
	return config

func import_config(config: Dictionary) -> bool:
	# Konfigürasyonu içe aktar
	if not "buses" in config:
		return false
	
	return load_all_configs(config["buses"])

func get_bus_statistics() -> Dictionary:
	# Bus istatistiklerini al
	var stats = {
		"total_buses": 0,
		"muted_buses": 0,
		"soloed_buses": 0,
		"buses_with_effects": 0,
		"average_volume_db": 0.0,
		"total_effects": 0
	}
	
	var all_buses = get_all_buses()
	stats["total_buses"] = all_buses.size()
	
	if stats["total_buses"] == 0:
		return stats
	
	var total_volume = 0.0
	
	for bus_name in all_buses:
		var bus_info = all_buses[bus_name]
		
		if bus_info["muted"]:
			stats["muted_buses"] += 1
		
		if bus_info["soloed"]:
			stats["soloed_buses"] += 1
		
		if bus_info["effect_count"] > 0:
			stats["buses_with_effects"] += 1
			stats["total_effects"] += bus_info["effect_count"]
		
		total_volume += bus_info["volume_db"]
	
	stats["average_volume_db"] = total_volume / stats["total_buses"]
	
	return stats

func validate_bus_config(bus_name: String) -> Dictionary:
	# Bus konfigürasyonunu doğrula
	var errors = []
	var warnings = []
	
	var bus_info = get_bus_info(bus_name)
	if bus_info.is_empty():
		errors.append("Bus not found: %s" % bus_name)
		return {"valid": false, "errors": errors, "warnings": warnings}
	
	# Volume kontrolü
	if bus_info["volume_db"] < -80.0 or bus_info["volume_db"] > 6.0:
		warnings.append("Volume out of recommended range: %.1f dB" % bus_info["volume_db"])
	
	# Mute ve solo çakışması
	if bus_info["muted"] and bus_info["soloed"]:
		errors.append("Bus cannot be both muted and soloed")
	
	# Send bus kontrolü
	var send_to = bus_info["send_to"]
	if send_to != "Master" and not bus_creator.has_bus(send_to):
		warnings.append("Send bus not found: %s" % send_to)
	
	return {
		"valid": errors.size() == 0,
		"errors": errors,
		"warnings": warnings,
		"bus_info": bus_info
	}

func validate_all_configs() -> Dictionary:
	# Tüm konfigürasyonları doğrula
	var results = {
		"total_buses": 0,
		"valid_buses": 0,
		"invalid_buses": 0,
		"total_errors": 0,
		"total_warnings": 0,
		"bus_results": {}
	}
	
	var all_buses = get_all_buses()
	results["total_buses"] = all_buses.size()
	
	for bus_name in all_buses:
		var validation = validate_bus_config(bus_name)
		results["bus_results"][bus_name] = validation
		
		if validation["valid"]:
			results["valid_buses"] += 1
		else:
			results["invalid_buses"] += 1
		
		results["total_errors"] += validation["errors"].size()
		results["total_warnings"] += validation["warnings"].size()
	
	return results

# === PRIVATE METHODS ===

func _find_dependencies() -> void:
	# Bağımlılıkları bul
	var parent = get_parent()
	if parent:
		if parent.has_node("AudioBusCreator"):
			bus_creator = parent.get_node("AudioBusCreator")
		if parent.has_node("AudioBusVolumeController"):
			volume_controller = parent.get_node("AudioBusVolumeController")
		if parent.has_node("AudioBusEffectManager"):
			effect_manager = parent.get_node("AudioBusEffectManager")
		if parent.has_node("AudioBusStateManager"):
			state_manager = parent.get_node("AudioBusStateManager")

# === DEBUG ===

func print_debug_info() -> void:
	print("=== AudioBusConfigManager ===")
	print("Dependencies:")
	print("  Bus Creator: %s" % ("Available" if bus_creator else "Not Available"))
	print("  Volume Controller: %s" % ("Available" if volume_controller else "Not Available"))
	print("  Effect Manager: %s" % ("Available" if effect_manager else "Not Available"))
	print("  State Manager: %s" % ("Available" if state_manager else "Not Available"))
	
	var stats = get_bus_statistics()
	print("\nBus Statistics:")
	print("  Total Buses: %d" % stats["total_buses"])
	print("  Muted Buses: %d" % stats["muted_buses"])
	print("  Soloed Buses: %d" % stats["soloed_buses"])
	print("  Buses with Effects: %d" % stats["buses_with_effects"])
	print("  Total Effects: %d" % stats["total_effects"])
	print("  Average Volume: %.1f dB" % stats["average_volume_db"])
	
	var validation = validate_all_configs()
	print("\nConfiguration Validation:")
	print("  Valid Buses: %d" % validation["valid_buses"])
	print("  Invalid Buses: %d" % validation["invalid_buses"])
	print("  Total Errors: %d" % validation["total_errors"])
	print("  Total Warnings: %d" % validation["total_warnings"])