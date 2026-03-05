# 🎵 AUDIO BUS CREATOR
# Audio bus oluşturma ve yapılandırma
class_name AudioBusCreator
extends Node

# === CONSTANTS ===
const DEFAULT_VOLUME_DB: float = 0.0

# === STATE ===
var bus_configs: Dictionary = {}  # bus_index → bus_config
var bus_names: Dictionary = {}    # bus_name → bus_index

# === SIGNALS ===
signal bus_created(bus_name: String, bus_index: int)
signal bus_layout_changed()

# === PUBLIC API ===

func create_bus(bus_name: String, send_to: String = "Master", index: int = -1) -> int:
	# Yeni audio bus oluştur
	if bus_names.has(bus_name):
		print("Bus already exists: %s" % bus_name)
		return bus_names[bus_name]
	
	var bus_index = index
	if bus_index == -1:
		bus_index = AudioServer.get_bus_count()
		AudioServer.add_bus(bus_index)
	else:
		# Belirli bir index verilmişse, o index'te bus oluştur
		AudioServer.add_bus(bus_index)
	
	AudioServer.set_bus_name(bus_index, bus_name)
	
	# Send ayarla
	if send_to != "Master":
		var send_bus_index = AudioServer.get_bus_index(send_to)
		if send_bus_index != -1:
			AudioServer.set_bus_send(bus_index, send_to)
	
	# Config kaydet
	bus_configs[bus_index] = {
		"name": bus_name,
		"send_to": send_to,
		"volume_db": DEFAULT_VOLUME_DB,
		"muted": false,
		"soloed": false,
		"effects": []
	}
	
	bus_names[bus_name] = bus_index
	
	bus_created.emit(bus_name, bus_index)
	bus_layout_changed.emit()
	
	print("Created audio bus: %s (index: %d)" % [bus_name, bus_index])
	return bus_index

func setup_master_bus() -> void:
	# Master bus'ı kur (her zaman var)
	bus_names["Master"] = 0
	bus_configs[0] = {
		"name": "Master",
		"send_to": "",
		"volume_db": DEFAULT_VOLUME_DB,
		"muted": false,
		"soloed": false,
		"effects": []
	}
	
	print("Master bus setup completed")

func get_bus_index(bus_name: String) -> int:
	# Bus adından index al
	# Case-insensitive arama
	for name in bus_names:
		if name.to_lower() == bus_name.to_lower():
			return bus_names[name]
	return -1

func get_bus_config(bus_name: String) -> Dictionary:
	# Bus konfigürasyonunu al
	var bus_index = get_bus_index(bus_name)
	if bus_index != -1:
		return bus_configs.get(bus_index, {}).duplicate()
	return {}

func update_bus_config(bus_name: String, config: Dictionary) -> void:
	# Bus konfigürasyonunu güncelle
	var bus_index = get_bus_index(bus_name)
	if bus_index != -1:
		bus_configs[bus_index] = config.duplicate()

func remove_bus(bus_name: String) -> bool:
	# Bus'ı kaldır
	var bus_index = get_bus_index(bus_name)
	if bus_index == -1:
		return false
	
	# Bus'ı AudioServer'dan kaldır
	AudioServer.remove_bus(bus_index)
	
	# Config'den kaldır
	bus_configs.erase(bus_index)
	bus_names.erase(bus_name)
	
	# Diğer bus'ların index'lerini güncelle
	var new_bus_names = {}
	for name in bus_names:
		var idx = bus_names[name]
		if idx > bus_index:
			new_bus_names[name] = idx - 1
		else:
			new_bus_names[name] = idx
	
	bus_names = new_bus_names
	
	bus_layout_changed.emit()
	print("Removed bus: %s" % bus_name)
	return true

func get_all_bus_names() -> Array:
	# Tüm bus isimlerini al
	return bus_names.keys()

func get_bus_count() -> int:
	# Bus sayısını al
	return bus_names.size()

func has_bus(bus_name: String) -> bool:
	# Bus var mı?
	return bus_names.has(bus_name)

func clear_all_buses() -> void:
	# Tüm bus'ları temizle (Master hariç)
	var buses_to_remove = []
	for bus_name in bus_names:
		if bus_name != "Master":
			buses_to_remove.append(bus_name)
	
	for bus_name in buses_to_remove:
		remove_bus(bus_name)

# === DEBUG ===

func print_debug_info() -> void:
	print("=== AudioBusCreator ===")
	print("Total Buses: %d" % bus_names.size())
	print("Bus Names: %s" % str(bus_names.keys()))
	
	for bus_name in bus_names:
		var bus_index = bus_names[bus_name]
		var config = bus_configs.get(bus_index, {})
		print("\n%s (Index: %d):" % [bus_name, bus_index])
		print("  Send to: %s" % config.get("send_to", "Master"))
		print("  Volume: %.1f dB" % config.get("volume_db", 0.0))
		print("  Muted: %s" % str(config.get("muted", false)))
		print("  Soloed: %s" % str(config.get("soloed", false)))
		print("  Effects: %d" % config.get("effects", []).size())
