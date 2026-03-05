# 🎵 AUDIO BUS MANAGER (MODULAR)
# Modüler bileşenlerle audio bus yöneticisi
class_name AudioBusManager
extends AudioBusManagerCore

# === CONSTANTS ===
const MIN_VOLUME_DB: float = -80.0
const MAX_VOLUME_DB: float = 6.0

# === PUBLIC API (Extended) ===

func get_bus_index(bus_name: String) -> int:
	# Bus index'ini al (case-insensitive)
	if bus_creator:
		return bus_creator.get_bus_index(bus_name)
	return -1

func get_bus_name(bus_index: int) -> String:
	# Bus index'inden ad al
	if bus_creator:
		return bus_creator.get_bus_name(bus_index)
	return ""

func get_bus_config(bus_name: String) -> Dictionary:
	# Bus konfigürasyonunu al
	if bus_creator:
		return bus_creator.get_bus_config(bus_name)
	return {}

func update_bus_config(bus_name: String, config: Dictionary) -> void:
	# Bus konfigürasyonunu güncelle
	if bus_creator:
		bus_creator.update_bus_config(bus_name, config)

func remove_bus(bus_name: String) -> bool:
	# Bus'ı kaldır
	if bus_creator:
		return bus_creator.remove_bus(bus_name)
	return false

func get_all_bus_names() -> Array:
	# Tüm bus isimlerini al
	if bus_creator:
		return bus_creator.get_all_bus_names()
	return []

func get_bus_count() -> int:
	# Bus sayısını al
	if bus_creator:
		return bus_creator.get_bus_count()
	return 0

func has_bus(bus_name: String) -> bool:
	# Bus var mı?
	if bus_creator:
		return bus_creator.has_bus(bus_name)
	return false

func clear_all_buses() -> void:
	# Tüm bus'ları temizle (Master hariç)
	if bus_creator:
		bus_creator.clear_all_buses()

func get_bus_effect(bus_name: String, effect_index: int) -> AudioEffect:
	# Belirli bir efekti al
	if effect_manager:
		return effect_manager.get_bus_effect(bus_name, effect_index)
	return null

func clear_bus_effects(bus_name: String) -> void:
	# Bus'ın tüm efektlerini temizle
	if effect_manager:
		effect_manager.clear_bus_effects(bus_name)

func has_bus_effects(bus_name: String) -> bool:
	# Bus'ın efekti var mı?
	if effect_manager:
		return effect_manager.has_bus_effects(bus_name)
	return false

func get_bus_effect_count(bus_name: String) -> int:
	# Bus'ın efekt sayısını al
	if effect_manager:
		return effect_manager.get_bus_effect_count(bus_name)
	return 0

func toggle_mute(bus_name: String) -> bool:
	# Mute'u aç/kapa
	if state_manager:
		return state_manager.toggle_mute(bus_name)
	return false

func toggle_solo(bus_name: String) -> bool:
	# Solo'yu aç/kapa
	if state_manager:
		return state_manager.toggle_solo(bus_name)
	return false

func mute_all_buses() -> void:
	# Tüm bus'ları sustur
	if state_manager:
		state_manager.mute_all_buses()

func mute_all_except(bus_name: String) -> void:
	# Belirtilen bus hariç tüm bus'ları sustur
	if state_manager:
		state_manager.mute_all_except(bus_name)

func get_muted_buses() -> Array:
	# Susturulmuş bus'ları al
	if state_manager:
		return state_manager.get_muted_buses()
	return []

func get_unmuted_buses() -> Array:
	# Susturulmamış bus'ları al
	if state_manager:
		return state_manager.get_unmuted_buses()
	return []

func is_any_bus_muted() -> bool:
	# Herhangi bir bus susturulmuş mu?
	if state_manager:
		return state_manager.is_any_bus_muted()
	return false

func is_any_bus_soloed() -> bool:
	# Herhangi bir bus solo mu?
	if state_manager:
		return state_manager.is_any_bus_soloed()
	return false

func reset_all_states() -> void:
	# Tüm bus durumlarını sıfırla
	if state_manager:
		state_manager.reset_all_states()

func get_bus_info(bus_name: String) -> Dictionary:
	# Belirli bir bus'ın bilgilerini al
	if config_manager:
		return config_manager.get_bus_info(bus_name)
	return {}

func save_bus_config(bus_name: String) -> bool:
	# Bus konfigürasyonunu kaydet
	if config_manager:
		return config_manager.save_bus_config(bus_name)
	return false

func save_all_configs() -> bool:
	# Tüm bus konfigürasyonlarını kaydet
	if config_manager:
		return config_manager.save_all_configs()
	return false

func load_bus_config(bus_name: String, config: Dictionary) -> bool:
	# Bus konfigürasyonunu yükle
	if config_manager:
		return config_manager.load_bus_config(bus_name, config)
	return false

func load_all_configs(configs: Dictionary) -> bool:
	# Tüm bus konfigürasyonlarını yükle
	if config_manager:
		return config_manager.load_all_configs(configs)
	return false

func reset_bus_config(bus_name: String) -> bool:
	# Bus konfigürasyonunu varsayılana döndür
	if config_manager:
		return config_manager.reset_bus_config(bus_name)
	return false

func reset_all_configs() -> bool:
	# Tüm bus konfigürasyonlarını varsayılana döndür
	if config_manager:
		return config_manager.reset_all_configs()
	return false

func export_config() -> Dictionary:
	# Tüm konfigürasyonu dışa aktar
	if config_manager:
		return config_manager.export_config()
	return {}

func import_config(config: Dictionary) -> bool:
	# Konfigürasyonu içe aktar
	if config_manager:
		return config_manager.import_config(config)
	return false

func get_bus_statistics() -> Dictionary:
	# Bus istatistiklerini al
	if config_manager:
		return config_manager.get_bus_statistics()
	return {}

func validate_bus_config(bus_name: String) -> Dictionary:
	# Bus konfigürasyonunu doğrula
	if config_manager:
		return config_manager.validate_bus_config(bus_name)
	return {"valid": false, "errors": ["Config manager not available"], "warnings": []}

func validate_all_configs() -> Dictionary:
	# Tüm konfigürasyonları doğrula
	if config_manager:
		return config_manager.validate_all_configs()
	return {
		"total_buses": 0,
		"valid_buses": 0,
		"invalid_buses": 0,
		"total_errors": 0,
		"total_warnings": 0,
		"bus_results": {}
	}

# === DEBUG (Extended) ===

func print_bus_info() -> void:
	super.print_bus_info()
	
	print("\n=== AudioBusManager (Extended) ===")
	print("Extended Methods Available: Yes")
	
	if bus_creator:
		print("\nBus Creator Methods:")
		print("  get_all_bus_names(): %d buses" % bus_creator.get_all_bus_names().size())
		print("  get_bus_count(): %d" % bus_creator.get_bus_count())
	
	if state_manager:
		print("\nState Manager Methods:")
		print("  get_muted_buses(): %d buses" % state_manager.get_muted_buses().size())
		print("  is_any_bus_muted(): %s" % str(state_manager.is_any_bus_muted()))
	
	if config_manager:
		print("\nConfig Manager Methods:")
		var stats = config_manager.get_bus_statistics()
		print("  get_bus_statistics(): %d total buses" % stats["total_buses"])

func _to_string() -> String:
	var base_str = super._to_string()
	var extended_info = " [Extended API Available]"
	return base_str + extended_info