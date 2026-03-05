# 🎵 AUDIO BUS STATE MANAGER
# Audio bus durum yönetimi (mute/solo)
class_name AudioBusStateManager
extends Node

# === DEPENDENCIES ===
var bus_creator: AudioBusCreator = null

# === SIGNALS ===
signal bus_muted(bus_name: String, muted: bool)
signal bus_soloed(bus_name: String, soloed: bool)
signal all_buses_unmuted()

# === PUBLIC API ===

func mute_bus(bus_name: String, muted: bool = true) -> void:
	# Bus'ı sustur/aç
	var bus_index = _get_bus_index(bus_name)
	if bus_index == -1:
		print("Bus not found: %s" % bus_name)
		return
	
	# Bus index'inin geçerli olup olmadığını kontrol et
	if bus_index >= AudioServer.get_bus_count():
		print("Bus index out of bounds: %d (total buses: %d)" % [bus_index, AudioServer.get_bus_count()])
		return
	
	AudioServer.set_bus_mute(bus_index, muted)
	
	# Config güncelle
	_update_bus_mute_config(bus_name, muted)
	
	bus_muted.emit(bus_name, muted)

func solo_bus(bus_name: String, soloed: bool = true) -> void:
	# Bus'ı solo yap/kaldır
	var bus_index = _get_bus_index(bus_name)
	if bus_index == -1:
		return
	
	# Tüm bus'ları mute'la (solo bus hariç)
	for i in range(AudioServer.get_bus_count()):
		var other_bus_name = AudioServer.get_bus_name(i)
		if other_bus_name != bus_name:
			AudioServer.set_bus_mute(i, soloed)
	
	# Solo bus'ı aç
	AudioServer.set_bus_mute(bus_index, false)
	
	# Config güncelle
	_update_bus_solo_config(bus_name, soloed)
	
	bus_soloed.emit(bus_name, soloed)

func is_bus_muted(bus_name: String) -> bool:
	# Bus susturulmuş mu?
	var bus_index = _get_bus_index(bus_name)
	if bus_index == -1:
		return false
	
	return AudioServer.is_bus_mute(bus_index)

func is_bus_soloed(bus_name: String) -> bool:
	# Bus solo mu?
	var bus_index = _get_bus_index(bus_name)
	if bus_index == -1:
		return false
	
	var config = _get_bus_config(bus_name)
	return config.get("soloed", false)

func toggle_mute(bus_name: String) -> bool:
	# Mute'u aç/kapa
	var currently_muted = is_bus_muted(bus_name)
	mute_bus(bus_name, not currently_muted)
	return not currently_muted

func toggle_solo(bus_name: String) -> bool:
	# Solo'yu aç/kapa
	var currently_soloed = is_bus_soloed(bus_name)
	solo_bus(bus_name, not currently_soloed)
	return not currently_soloed

func unmute_all_buses() -> void:
	# Tüm bus'ların susturmasını kaldır
	for i in range(AudioServer.get_bus_count()):
		AudioServer.set_bus_mute(i, false)
		
		# Config güncelle
		_update_all_buses_mute_config(false)
	
	all_buses_unmuted.emit()

func mute_all_buses() -> void:
	# Tüm bus'ları sustur
	for i in range(AudioServer.get_bus_count()):
		AudioServer.set_bus_mute(i, true)
		
		# Config güncelle
		_update_all_buses_mute_config(true)

func mute_all_except(bus_name: String) -> void:
	# Belirtilen bus hariç tüm bus'ları sustur
	var target_bus_index = _get_bus_index(bus_name)
	if target_bus_index == -1:
		return
	
	for i in range(AudioServer.get_bus_count()):
		if i != target_bus_index:
			AudioServer.set_bus_mute(i, true)
		else:
			AudioServer.set_bus_mute(i, false)
	
	# Config güncelle
	_update_all_buses_mute_config(true, bus_name)

func get_muted_buses() -> Array:
	# Susturulmuş bus'ları al
	var muted_buses = []
	
	for i in range(AudioServer.get_bus_count()):
		if AudioServer.is_bus_mute(i):
			var bus_name = AudioServer.get_bus_name(i)
			muted_buses.append(bus_name)
	
	return muted_buses

func get_unmuted_buses() -> Array:
	# Susturulmamış bus'ları al
	var unmuted_buses = []
	
	for i in range(AudioServer.get_bus_count()):
		if not AudioServer.is_bus_mute(i):
			var bus_name = AudioServer.get_bus_name(i)
			unmuted_buses.append(bus_name)
	
	return unmuted_buses

func is_any_bus_muted() -> bool:
	# Herhangi bir bus susturulmuş mu?
	for i in range(AudioServer.get_bus_count()):
		if AudioServer.is_bus_mute(i):
			return true
	return false

func is_any_bus_soloed() -> bool:
	# Herhangi bir bus solo mu?
	if not bus_creator:
		return false
	
	for bus_name in bus_creator.get_all_bus_names():
		if is_bus_soloed(bus_name):
			return true
	return false

func reset_all_states() -> void:
	# Tüm bus durumlarını sıfırla
	unmute_all_buses()
	
	# Solo durumlarını sıfırla
	if bus_creator:
		for bus_name in bus_creator.get_all_bus_names():
			_update_bus_solo_config(bus_name, false)

# === PRIVATE METHODS ===

func _get_bus_index(bus_name: String) -> int:
	# Bus index'ini al (önce bus_creator, yoksa AudioServer ile case-insensitive ara)
	if bus_creator:
		var idx = bus_creator.get_bus_index(bus_name)
		if idx != -1:
			return idx
	var want = bus_name.to_lower()
	for i in range(AudioServer.get_bus_count()):
		if AudioServer.get_bus_name(i).to_lower() == want:
			return i
	return -1

func _get_bus_config(bus_name: String) -> Dictionary:
	# Bus config'ini al
	if bus_creator:
		return bus_creator.get_bus_config(bus_name)
	return {}

func _update_bus_mute_config(bus_name: String, muted: bool) -> void:
	# Bus mute config'ini güncelle
	if not bus_creator:
		return
	
	var config = bus_creator.get_bus_config(bus_name)
	if config.is_empty():
		return
	
	config["muted"] = muted
	bus_creator.update_bus_config(bus_name, config)

func _update_bus_solo_config(bus_name: String, soloed: bool) -> void:
	# Bus solo config'ini güncelle
	if not bus_creator:
		return
	
	var config = bus_creator.get_bus_config(bus_name)
	if config.is_empty():
		return
	
	config["soloed"] = soloed
	bus_creator.update_bus_config(bus_name, config)

func _update_all_buses_mute_config(muted: bool, except_bus: String = "") -> void:
	# Tüm bus'ların mute config'ini güncelle
	if not bus_creator:
		return
	
	for bus_name in bus_creator.get_all_bus_names():
		if bus_name == except_bus:
			continue
		
		var config = bus_creator.get_bus_config(bus_name)
		if not config.is_empty():
			config["muted"] = muted
			bus_creator.update_bus_config(bus_name, config)

# === DEBUG ===

func print_debug_info() -> void:
	print("=== AudioBusStateManager ===")
	print("Bus Creator: %s" % ("Available" if bus_creator else "Not Available"))
	
	print("\nBus States:")
	for i in range(AudioServer.get_bus_count()):
		var bus_name = AudioServer.get_bus_name(i)
		var muted = AudioServer.is_bus_mute(i)
		var soloed = is_bus_soloed(bus_name)
		print("  %s: Muted=%s, Soloed=%s" % [bus_name, str(muted), str(soloed)])
	
	print("\nMuted Buses: %s" % str(get_muted_buses()))
	print("Unmuted Buses: %s" % str(get_unmuted_buses()))
	print("Any Bus Muted: %s" % str(is_any_bus_muted()))
	print("Any Bus Soloed: %s" % str(is_any_bus_soloed()))