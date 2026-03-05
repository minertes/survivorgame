# 🎵 AUDIO BUS EFFECT MANAGER
# Audio bus efekt yönetimi
class_name AudioBusEffectManager
extends Node

# === DEPENDENCIES ===
var bus_creator: AudioBusCreator = null

# === SIGNALS ===
signal effect_added(bus_name: String, effect_type: String, effect_index: int)
signal effect_removed(bus_name: String, effect_index: int)
signal effects_cleared(bus_name: String)

# === PUBLIC API ===

func add_bus_effect(bus_name: String, effect: AudioEffect) -> void:
	# Bus'a audio efekti ekle
	var bus_index = _get_bus_index(bus_name)
	if bus_index == -1:
		return
	
	var effect_index = AudioServer.get_bus_effect_count(bus_index)
	AudioServer.add_bus_effect(bus_index, effect, effect_index)
	
	# Config güncelle
	_update_bus_effects_config(bus_name, effect, effect_index)
	
	effect_added.emit(bus_name, effect.get_class(), effect_index)

func remove_bus_effect(bus_name: String, effect_index: int) -> void:
	# Bus'tan audio efekti kaldır
	var bus_index = _get_bus_index(bus_name)
	if bus_index == -1:
		return
	
	AudioServer.remove_bus_effect(bus_index, effect_index)
	
	# Config güncelle
	_remove_bus_effect_config(bus_name, effect_index)
	
	effect_removed.emit(bus_name, effect_index)

func get_bus_effects(bus_name: String) -> Array:
	# Bus'ın audio efektlerini al
	var bus_index = _get_bus_index(bus_name)
	if bus_index == -1:
		return []
	
	var effects = []
	for i in range(AudioServer.get_bus_effect_count(bus_index)):
		var effect = AudioServer.get_bus_effect(bus_index, i)
		if effect:
			effects.append({
				"index": i,
				"type": effect.get_class(),
				"effect": effect
			})
	
	return effects

func get_bus_effect(bus_name: String, effect_index: int) -> AudioEffect:
	# Belirli bir efekti al
	var bus_index = _get_bus_index(bus_name)
	if bus_index == -1:
		return null
	
	if effect_index < 0 or effect_index >= AudioServer.get_bus_effect_count(bus_index):
		return null
	
	return AudioServer.get_bus_effect(bus_index, effect_index)

func clear_bus_effects(bus_name: String) -> void:
	# Bus'ın tüm efektlerini temizle
	var bus_index = _get_bus_index(bus_name)
	if bus_index == -1:
		return
	
	# Ters sırada sil (index kaymasını önlemek için)
	for i in range(AudioServer.get_bus_effect_count(bus_index) - 1, -1, -1):
		AudioServer.remove_bus_effect(bus_index, i)
	
	# Config temizle
	_clear_bus_effects_config(bus_name)
	
	effects_cleared.emit(bus_name)

func has_bus_effects(bus_name: String) -> bool:
	# Bus'ın efekti var mı?
	var bus_index = _get_bus_index(bus_name)
	if bus_index == -1:
		return false
	
	return AudioServer.get_bus_effect_count(bus_index) > 0

func get_bus_effect_count(bus_name: String) -> int:
	# Bus'ın efekt sayısını al
	var bus_index = _get_bus_index(bus_name)
	if bus_index == -1:
		return 0
	
	return AudioServer.get_bus_effect_count(bus_index)

func setup_default_effects() -> void:
	# Varsayılan efektleri kur
	
	# Music bus için reverb efekti
	if _has_bus("Music"):
		var reverb = AudioEffectReverb.new()
		reverb.room_size = 0.8
		reverb.damping = 0.5
		reverb.wet = 0.3
		reverb.dry = 1.0
		add_bus_effect("Music", reverb)
	
	# SFX ve Weapons bus'ları için compressor
	for bus_name in ["SFX", "Weapons"]:
		if _has_bus(bus_name):
			var compressor = AudioEffectCompressor.new()
			compressor.threshold = -20.0
			compressor.ratio = 4.0
			compressor.attack_us = 20000
			compressor.release_ms = 250
			add_bus_effect(bus_name, compressor)
	
	# Master bus için limiter
	if _has_bus("Master"):
		var limiter = AudioEffectLimiter.new()
		limiter.ceiling_db = -1.0
		limiter.threshold_db = -10.0
		limiter.soft_clip_db = 2.0
		add_bus_effect("Master", limiter)

func add_reverb_effect(bus_name: String, room_size: float = 0.8, damping: float = 0.5, wet: float = 0.3) -> void:
	# Reverb efekti ekle
	var reverb = AudioEffectReverb.new()
	reverb.room_size = room_size
	reverb.damping = damping
	reverb.wet = wet
	reverb.dry = 1.0
	add_bus_effect(bus_name, reverb)

func add_compressor_effect(bus_name: String, threshold: float = -20.0, ratio: float = 4.0) -> void:
	# Compressor efekti ekle
	var compressor = AudioEffectCompressor.new()
	compressor.threshold = threshold
	compressor.ratio = ratio
	compressor.attack_us = 20000
	compressor.release_ms = 250
	add_bus_effect(bus_name, compressor)

func add_limiter_effect(bus_name: String, ceiling: float = -1.0, threshold: float = -10.0) -> void:
	# Limiter efekti ekle
	var limiter = AudioEffectLimiter.new()
	limiter.ceiling_db = ceiling
	limiter.threshold_db = threshold
	limiter.soft_clip_db = 2.0
	add_bus_effect(bus_name, limiter)

# === PRIVATE METHODS ===

func _get_bus_index(bus_name: String) -> int:
	# Bus index'ini al
	if bus_creator:
		return bus_creator.get_bus_index(bus_name)
	return -1

func _has_bus(bus_name: String) -> bool:
	# Bus var mı?
	if bus_creator:
		return bus_creator.has_bus(bus_name)
	return false

func _update_bus_effects_config(bus_name: String, effect: AudioEffect, effect_index: int) -> void:
	# Bus efekt config'ini güncelle
	if not bus_creator:
		return
	
	var config = bus_creator.get_bus_config(bus_name)
	if config.is_empty():
		return
	
	if not "effects" in config:
		config["effects"] = []
	
	config["effects"].append({
		"type": effect.get_class(),
		"index": effect_index
	})
	
	bus_creator.update_bus_config(bus_name, config)

func _remove_bus_effect_config(bus_name: String, effect_index: int) -> void:
	# Bus efekt config'inden kaldır
	if not bus_creator:
		return
	
	var config = bus_creator.get_bus_config(bus_name)
	if config.is_empty() or not "effects" in config:
		return
	
	var effects = config["effects"]
	for i in range(effects.size()):
		if effects[i].index == effect_index:
			effects.remove_at(i)
			break
	
	bus_creator.update_bus_config(bus_name, config)

func _clear_bus_effects_config(bus_name: String) -> void:
	# Bus efekt config'ini temizle
	if not bus_creator:
		return
	
	var config = bus_creator.get_bus_config(bus_name)
	if config.is_empty():
		return
	
	config["effects"] = []
	bus_creator.update_bus_config(bus_name, config)

# === DEBUG ===

func print_debug_info() -> void:
	print("=== AudioBusEffectManager ===")
	print("Bus Creator: %s" % ("Available" if bus_creator else "Not Available"))
	
	if bus_creator:
		print("\nBus Effects:")
		for bus_name in bus_creator.get_all_bus_names():
			var effects = get_bus_effects(bus_name)
			print("  %s: %d effects" % [bus_name, effects.size()])
			
			for effect_info in effects:
				print("    - %s (Index: %d)" % [effect_info.type, effect_info.index])