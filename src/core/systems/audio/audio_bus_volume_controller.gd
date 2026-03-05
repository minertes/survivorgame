# 🎵 AUDIO BUS VOLUME CONTROLLER
# Audio bus volume kontrolü
class_name AudioBusVolumeController
extends Node

# === CONSTANTS ===
const MIN_VOLUME_DB: float = -80.0  # Minimum volume (mute)
const MAX_VOLUME_DB: float = 6.0    # Maximum volume
const DEFAULT_VOLUME_DB: float = 0.0  # Default volume

# === DEPENDENCIES ===
var bus_creator: AudioBusCreator = null

# === STATE ===
var volume_cache: Dictionary = {}  # bus_index → volume_db

# === SIGNALS ===
signal bus_volume_changed(bus_name: String, volume_db: float, linear_volume: float)

# === LIFECYCLE ===

func _ready() -> void:
	# Bağımlılıkları bul
	_find_dependencies()
	
	# Volume cache'i initialize et
	_initialize_volume_cache()

# === PUBLIC API ===

func set_bus_volume_db(bus_name: String, volume_db: float) -> void:
	# Bus volume'ünü dB cinsinden ayarla
	var bus_index = _get_bus_index(bus_name)
	if bus_index == -1:
		return
	
	var clamped_volume = clamp(volume_db, MIN_VOLUME_DB, MAX_VOLUME_DB)
	AudioServer.set_bus_volume_db(bus_index, clamped_volume)
	
	# Cache güncelle
	volume_cache[bus_index] = clamped_volume
	
	var linear_volume = db_to_linear(clamped_volume)
	bus_volume_changed.emit(bus_name, clamped_volume, linear_volume)

func set_bus_volume_linear(bus_name: String, linear_volume: float) -> void:
	# Bus volume'ünü linear (0-1) cinsinden ayarla
	var volume_db = linear_to_db(clamp(linear_volume, 0.0, 1.0))
	set_bus_volume_db(bus_name, volume_db)

func get_bus_volume_db(bus_name: String) -> float:
	# Bus volume'ünü dB cinsinden al
	var bus_index = _get_bus_index(bus_name)
	if bus_index == -1:
		return 0.0
	
	return AudioServer.get_bus_volume_db(bus_index)

func get_bus_volume_linear(bus_name: String) -> float:
	# Bus volume'ünü linear (0-1) cinsinden al
	var volume_db = get_bus_volume_db(bus_name)
	return db_to_linear(volume_db)

func get_cached_volume_db(bus_name: String) -> float:
	# Cache'den volume değerini al
	var bus_index = _get_bus_index(bus_name)
	if bus_index == -1:
		return 0.0
	
	return volume_cache.get(bus_index, DEFAULT_VOLUME_DB)

func reset_all_volumes() -> void:
	# Tüm bus'ların volume'ünü varsayılana döndür
	if not bus_creator:
		return
	
	for bus_name in bus_creator.get_all_bus_names():
		set_bus_volume_db(bus_name, DEFAULT_VOLUME_DB)

func fade_bus_volume(bus_name: String, target_volume_db: float, duration: float = 1.0) -> void:
	# Bus volume'ünü fade ile değiştir
	var bus_index = _get_bus_index(bus_name)
	if bus_index == -1:
		return
	
	var current_volume = get_bus_volume_db(bus_name)
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(
		_set_bus_volume_db_direct.bind(bus_index),
		current_volume,
		target_volume_db,
		duration
	)

func set_master_volume_db(volume_db: float) -> void:
	# Master volume ayarla
	set_bus_volume_db("Master", volume_db)

func set_music_volume_db(volume_db: float) -> void:
	# Music volume ayarla
	set_bus_volume_db("Music", volume_db)

func set_sfx_volume_db(volume_db: float) -> void:
	# SFX volume ayarla
	set_bus_volume_db("SFX", volume_db)

func set_ui_volume_db(volume_db: float) -> void:
	# UI volume ayarla
	set_bus_volume_db("UI", volume_db)

func set_voice_volume_db(volume_db: float) -> void:
	# Voice volume ayarla
	set_bus_volume_db("Voice", volume_db)

func get_master_volume_db() -> float:
	# Master volume al
	return get_bus_volume_db("Master")

func get_music_volume_db() -> float:
	# Music volume al
	return get_bus_volume_db("Music")

func get_sfx_volume_db() -> float:
	# SFX volume al
	return get_bus_volume_db("SFX")

func get_ui_volume_db() -> float:
	# UI volume al
	return get_bus_volume_db("UI")

func get_voice_volume_db() -> float:
	# Voice volume al
	return get_bus_volume_db("Voice")

# === PRIVATE METHODS ===

func _find_dependencies() -> void:
	# Bağımlılıkları bul
	var parent = get_parent()
	if parent and parent.has_node("AudioBusCreator"):
		bus_creator = parent.get_node("AudioBusCreator")

func _initialize_volume_cache() -> void:
	# Volume cache'ini initialize et
	if not bus_creator:
		return
	
	for bus_name in bus_creator.get_all_bus_names():
		var bus_index = bus_creator.get_bus_index(bus_name)
		if bus_index != -1:
			volume_cache[bus_index] = AudioServer.get_bus_volume_db(bus_index)

func _get_bus_index(bus_name: String) -> int:
	# Bus index'ini al (önce bus_creator, yoksa AudioServer ile case-insensitive ara)
	if bus_creator:
		var idx = bus_creator.get_bus_index(bus_name)
		if idx != -1:
			return idx
	# Yedek: AudioServer üzerinden ara (bus_creator henüz hazır olmayabilir)
	var want = bus_name.to_lower()
	for i in range(AudioServer.get_bus_count()):
		if AudioServer.get_bus_name(i).to_lower() == want:
			return i
	return -1

func _set_bus_volume_db_direct(volume_db: float, bus_index: int) -> void:
	# Doğrudan bus volume ayarla (tween için)
	var clamped_volume = clamp(volume_db, MIN_VOLUME_DB, MAX_VOLUME_DB)
	AudioServer.set_bus_volume_db(bus_index, clamped_volume)
	volume_cache[bus_index] = clamped_volume

# === DEBUG ===

func print_debug_info() -> void:
	print("=== AudioBusVolumeController ===")
	print("Bus Creator: %s" % ("Available" if bus_creator else "Not Available"))
	print("Volume Cache Size: %d" % volume_cache.size())
	
	if bus_creator:
		print("\nBus Volumes:")
		for bus_name in bus_creator.get_all_bus_names():
			var volume_db = get_bus_volume_db(bus_name)
			var volume_linear = get_bus_volume_linear(bus_name)
			print("  %s: %.1f dB (%.0f%%)" % [bus_name, volume_db, volume_linear * 100])