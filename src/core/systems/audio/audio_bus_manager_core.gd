# 🎵 AUDIO BUS MANAGER CORE
# Audio bus yöneticisi temel sınıfı
class_name AudioBusManagerCore
extends Node

# === COMPONENT REFERENCES ===
var bus_creator: AudioBusCreator = null
var volume_controller: AudioBusVolumeController = null
var effect_manager: AudioBusEffectManager = null
var state_manager: AudioBusStateManager = null
var config_manager: AudioBusConfigManager = null

# === SIGNALS ===
signal bus_created(bus_name: String, bus_index: int)
signal bus_volume_changed(bus_name: String, volume_db: float, linear_volume: float)
signal bus_muted(bus_name: String, muted: bool)
signal bus_soloed(bus_name: String, soloed: bool)
signal bus_layout_changed()
signal system_initialized()

# === STATE ===
var is_initialized: bool = false

# === LIFECYCLE ===

func _ready() -> void:
	print("AudioBusManagerCore initializing...")
	
	# Bileşenleri oluştur
	_create_components()
	
	# Varsayılan bus'ları oluştur
	_setup_default_buses()
	
	is_initialized = true
	system_initialized.emit()
	print("AudioBusManagerCore initialized")

# === PUBLIC API ===

func create_bus(bus_name: String, send_to: String = "Master", index: int = -1) -> int:
	if bus_creator:
		return bus_creator.create_bus(bus_name, send_to, index)
	return -1

func set_bus_volume_db(bus_name: String, volume_db: float) -> void:
	if volume_controller:
		volume_controller.set_bus_volume_db(bus_name, volume_db)

func set_bus_volume_linear(bus_name: String, linear_volume: float) -> void:
	if volume_controller:
		volume_controller.set_bus_volume_linear(bus_name, linear_volume)

func get_bus_volume_db(bus_name: String) -> float:
	if volume_controller:
		return volume_controller.get_bus_volume_db(bus_name)
	return 0.0

func get_bus_volume_linear(bus_name: String) -> float:
	if volume_controller:
		return volume_controller.get_bus_volume_linear(bus_name)
	return 0.0

func mute_bus(bus_name: String, muted: bool = true) -> void:
	if state_manager:
		state_manager.mute_bus(bus_name, muted)

func solo_bus(bus_name: String, soloed: bool = true) -> void:
	if state_manager:
		state_manager.solo_bus(bus_name, soloed)

func is_bus_muted(bus_name: String) -> bool:
	if state_manager:
		return state_manager.is_bus_muted(bus_name)
	return false

func is_bus_soloed(bus_name: String) -> bool:
	if state_manager:
		return state_manager.is_bus_soloed(bus_name)
	return false

func add_bus_effect(bus_name: String, effect: AudioEffect) -> void:
	if effect_manager:
		effect_manager.add_bus_effect(bus_name, effect)

func remove_bus_effect(bus_name: String, effect_index: int) -> void:
	if effect_manager:
		effect_manager.remove_bus_effect(bus_name, effect_index)

func get_bus_effects(bus_name: String) -> Array:
	if effect_manager:
		return effect_manager.get_bus_effects(bus_name)
	return []

func get_all_buses() -> Dictionary:
	if config_manager:
		return config_manager.get_all_buses()
	return {}

func reset_all_volumes() -> void:
	if volume_controller:
		volume_controller.reset_all_volumes()

func unmute_all_buses() -> void:
	if state_manager:
		state_manager.unmute_all_buses()

# === PRIVATE METHODS ===

func _create_components() -> void:
	print("Creating audio bus components...")
	
	# Bus creator
	bus_creator = AudioBusCreator.new()
	bus_creator.name = "AudioBusCreator"
	add_child(bus_creator)
	
	# Volume controller
	volume_controller = AudioBusVolumeController.new()
	volume_controller.name = "AudioBusVolumeController"
	add_child(volume_controller)
	
	# Effect manager
	effect_manager = AudioBusEffectManager.new()
	effect_manager.name = "AudioBusEffectManager"
	add_child(effect_manager)
	
	# State manager
	state_manager = AudioBusStateManager.new()
	state_manager.name = "AudioBusStateManager"
	add_child(state_manager)
	
	# Config manager
	config_manager = AudioBusConfigManager.new()
	config_manager.name = "AudioBusConfigManager"
	add_child(config_manager)
	
	print("Audio bus components created")

func _setup_default_buses() -> void:
	print("Setting up default buses...")
	
	if bus_creator:
		# Master bus (her zaman var)
		bus_creator.setup_master_bus()
		
		# Diğer bus'ları oluştur
		bus_creator.create_bus("Music", "Master", 1)
		bus_creator.create_bus("SFX", "Master", 2)
		bus_creator.create_bus("UI", "Master", 3)
		bus_creator.create_bus("Voice", "Master", 4)
		bus_creator.create_bus("Ambient", "Master", 5)
		bus_creator.create_bus("Footsteps", "SFX", 6)
		bus_creator.create_bus("Weapons", "SFX", 7)
		
		# Varsayılan efektleri ekle
		if effect_manager:
			effect_manager.setup_default_effects()
	
	print("Default buses setup completed")

# === DEBUG ===

func print_bus_info() -> void:
	print("=== AudioBusManagerCore Info ===")
	print("Initialized: %s" % str(is_initialized))
	print("Components:")
	print("  Bus Creator: %s" % ("Available" if bus_creator else "Not Available"))
	print("  Volume Controller: %s" % ("Available" if volume_controller else "Not Available"))
	print("  Effect Manager: %s" % ("Available" if effect_manager else "Not Available"))
	print("  State Manager: %s" % ("Available" if state_manager else "Not Available"))
	print("  Config Manager: %s" % ("Available" if config_manager else "Not Available"))
	
	if config_manager:
		var buses = config_manager.get_all_buses()
		print("\nTotal Buses: %d" % buses.size())
		
		for bus_name in buses:
			var bus_info = buses[bus_name]
			print("\n%s (Index: %d):" % [bus_name, bus_info["index"]])
			print("  Volume: %.1f dB (%.0f%%)" % [bus_info["volume_db"], bus_info["volume_linear"] * 100])
			print("  Muted: %s" % str(bus_info["muted"]))
			print("  Soloed: %s" % str(bus_info["soloed"]))
			print("  Send to: %s" % bus_info["send_to"])
			print("  Effects: %d" % bus_info["effect_count"])

func get_system_info() -> Dictionary:
	var info = {
		"initialized": is_initialized,
		"components": {
			"bus_creator": bus_creator != null,
			"volume_controller": volume_controller != null,
			"effect_manager": effect_manager != null,
			"state_manager": state_manager != null,
			"config_manager": config_manager != null
		}
	}
	
	if config_manager:
		info["buses"] = config_manager.get_all_buses()
		info["total_buses"] = AudioServer.get_bus_count()
	
	return info

func _to_string() -> String:
	var bus_count = 0
	if config_manager:
		var buses = config_manager.get_all_buses()
		bus_count = buses.size()
	
	return "[AudioBusManagerCore: %d buses, Initialized: %s]" % [bus_count, str(is_initialized)]