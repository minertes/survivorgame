# 🎵 AUDIO COMPONENT (MOLECULE)
# Entity-based audio component
class_name AudioComponent extends Component

# === AUDIO EVENT TYPES ===
enum AudioEvent {
	DAMAGE = 0,
	DEATH = 1,
	PICKUP = 2,
	ATTACK = 3,
	SPAWN = 4,
	LEVEL_UP = 5,
	HEAL = 6,
	INTERACT = 7
}

# === PROPERTIES ===
var audio_system: AudioSystem = null
var entity_position: Vector3 = Vector3.ZERO
var audio_events: Dictionary = {}  # AudioEvent -> sound_name mapping
var volume_multiplier: float = 1.0
var pitch_variation: float = 0.1
var spatial_audio_enabled: bool = true
var max_distance: float = 50.0
var min_distance: float = 1.0

# === SIGNALS ===
signal audio_played(event_type: AudioEvent, sound_name: String)
signal audio_failed(event_type: AudioEvent, error_message: String)
signal volume_changed(new_volume: float)
signal spatial_audio_toggled(enabled: bool)

# === LIFECYCLE ===

func _ready() -> void:
	print("AudioComponent initializing for entity: %s" % entity_id)
	
	# AudioSystem'i bul
	_find_audio_system()
	
	# Varsayılan audio event'lerini ayarla
	_setup_default_audio_events()
	
	# EventBus listener'ları bağla
	_setup_event_listeners()
	
	print("AudioComponent initialized successfully")

func _find_audio_system() -> void:
	# Scene'de AudioSystem'i ara
	var audio_systems = get_tree().get_nodes_in_group("audio_system")
	if audio_systems.size() > 0:
		audio_system = audio_systems[0]
		print("AudioSystem found: %s" % audio_system.name)
	else:
		print("Warning: AudioSystem not found in scene")

func _setup_default_audio_events() -> void:
	# Varsayılan audio event mapping'leri
	audio_events = {
		AudioEvent.DAMAGE: "hit",
		AudioEvent.DEATH: "explosion",
		AudioEvent.PICKUP: "pickup",
		AudioEvent.ATTACK: "shoot",
		AudioEvent.SPAWN: "spawn",
		AudioEvent.LEVEL_UP: "level_up",
		AudioEvent.HEAL: "heal",
		AudioEvent.INTERACT: "click"
	}

func _setup_event_listeners() -> void:
	# Entity event'lerini dinle
	if EventBus.is_available():
		EventBus.connect_static("entity_damaged", _on_entity_damaged)
		EventBus.connect_static("entity_died", _on_entity_died)
		EventBus.connect_static("item_picked_up", _on_item_picked_up)
		EventBus.connect_static("entity_attacked", _on_entity_attacked)
		EventBus.connect_static("entity_spawned", _on_entity_spawned)
		EventBus.connect_static("entity_level_up", _on_entity_level_up)
		EventBus.connect_static("entity_healed", _on_entity_healed)
		EventBus.connect_static("entity_interacted", _on_entity_interacted)

# === PUBLIC API - AUDIO PLAYBACK ===

func play_event(event_type: AudioEvent, custom_sound: String = "", 
			   volume_modifier: float = 1.0, pitch_modifier: float = 1.0) -> bool:
	# Audio event oynat
	if not audio_system:
		audio_failed.emit(event_type, "AudioSystem not available")
		return false
	
	# Sound name belirle
	var sound_name = custom_sound
	if sound_name.is_empty():
		sound_name = audio_events.get(event_type, "")
		if sound_name.is_empty():
			audio_failed.emit(event_type, "No sound mapped for this event")
			return false
	
	# Volume ve pitch hesapla
	var final_volume = _calculate_volume(volume_modifier)
	var final_pitch = _calculate_pitch(pitch_modifier)
	
	# 3D audio için pozisyon belirle
	var use_3d = spatial_audio_enabled and _should_use_3d_audio()
	var position = entity_position if use_3d else Vector3.ZERO
	
	# Ses oynat
	var success = audio_system.play_sound(sound_name, final_volume, final_pitch, position, use_3d)
	
	if success:
		audio_played.emit(event_type, sound_name)
	else:
		audio_failed.emit(event_type, "Failed to play sound")
	
	return success

func play_custom_sound(sound_name: String, volume_db: float = 0.0, 
					   pitch_scale: float = 1.0, is_3d: bool = false) -> bool:
	# Özel ses oynat
	if not audio_system:
		return false
	
	var position = entity_position if is_3d else Vector3.ZERO
	return audio_system.play_sound(sound_name, volume_db, pitch_scale, position, is_3d)

func stop_all_audio() -> void:
	# Tüm audio'yu durdur
	if audio_system:
		audio_system.stop_all_sounds()

# === PUBLIC API - CONFIGURATION ===

func set_audio_event(event_type: AudioEvent, sound_name: String) -> void:
	# Audio event mapping ayarla
	audio_events[event_type] = sound_name
	print("Audio event %s mapped to sound: %s" % [AudioEvent.keys()[event_type], sound_name])

func get_audio_event(event_type: AudioEvent) -> String:
	# Audio event mapping al
	return audio_events.get(event_type, "")

func set_volume_multiplier(multiplier: float) -> void:
	# Volume multiplier ayarla
	volume_multiplier = clamp(multiplier, 0.0, 2.0)
	volume_changed.emit(volume_multiplier)

func set_pitch_variation(variation: float) -> void:
	# Pitch variation ayarla
	pitch_variation = clamp(variation, 0.0, 0.5)

func enable_spatial_audio(enabled: bool) -> void:
	# Spatial audio'yu aç/kapa
	spatial_audio_enabled = enabled
	spatial_audio_toggled.emit(enabled)

func set_audio_distances(min_dist: float, max_dist: float) -> void:
	# Audio mesafelerini ayarla
	min_distance = max(min_dist, 0.1)
	max_distance = max(max_dist, min_distance + 1.0)

func update_position(new_position: Vector3) -> void:
	# Entity pozisyonunu güncelle
	entity_position = new_position
	
	# AudioSystem'e pozisyon güncellemesi bildir
	if audio_system and spatial_audio_enabled:
		audio_system.update_audio_position(entity_id, new_position)

# === UTILITY METHODS ===

func _calculate_volume(volume_modifier: float) -> float:
	# Volume hesapla (distance-based attenuation)
	var base_volume = 0.0  # 0 dB
	
	if spatial_audio_enabled:
		# Player pozisyonunu al
		var player = _get_player_entity()
		if player:
			var distance = entity_position.distance_to(player.position)
			
			# Distance-based volume attenuation
			if distance <= min_distance:
				base_volume = 0.0  # Full volume
			elif distance >= max_distance:
				base_volume = -80.0  # Muted
			else:
				# Linear attenuation
				var attenuation = (distance - min_distance) / (max_distance - min_distance)
				base_volume = lerp(0.0, -80.0, attenuation)
	
	# Volume multiplier uygula
	return base_volume + (volume_multiplier * volume_modifier)

func _calculate_pitch(pitch_modifier: float) -> float:
	# Pitch hesapla (random variation)
	var base_pitch = 1.0 * pitch_modifier
	
	if pitch_variation > 0:
		var random_variation = randf_range(-pitch_variation, pitch_variation)
		base_pitch += random_variation
	
	return clamp(base_pitch, 0.5, 2.0)

func _should_use_3d_audio() -> bool:
	# 3D audio kullanılmalı mı?
	if not spatial_audio_enabled:
		return false
	
	# Player varsa ve belirli mesafe içindeyse 3D audio kullan
	var player = _get_player_entity()
	if player:
		var distance = entity_position.distance_to(player.position)
		return distance <= max_distance
	
	return true

func _get_player_entity() -> Node:
	# Player entity'yi bul
	var players = get_tree().get_nodes_in_group("players")
	if players.size() > 0:
		return players[0]
	return null

# === EVENT BUS HANDLERS ===

func _on_entity_damaged(params: Dictionary) -> void:
	# Entity hasar aldığında
	var damaged_entity_id = params.get("entity_id", "")
	if damaged_entity_id == entity_id:
		play_event(AudioEvent.DAMAGE)

func _on_entity_died(params: Dictionary) -> void:
	# Entity öldüğünde
	var died_entity_id = params.get("entity_id", "")
	if died_entity_id == entity_id:
		play_event(AudioEvent.DEATH)

func _on_item_picked_up(params: Dictionary) -> void:
	# Item alındığında
	var picking_entity_id = params.get("entity_id", "")
	if picking_entity_id == entity_id:
		play_event(AudioEvent.PICKUP)

func _on_entity_attacked(params: Dictionary) -> void:
	# Entity saldırdığında
	var attacking_entity_id = params.get("entity_id", "")
	if attacking_entity_id == entity_id:
		play_event(AudioEvent.ATTACK)

func _on_entity_spawned(params: Dictionary) -> void:
	# Entity spawn olduğunda
	var spawned_entity_id = params.get("entity_id", "")
	if spawned_entity_id == entity_id:
		play_event(AudioEvent.SPAWN)

func _on_entity_level_up(params: Dictionary) -> void:
	# Entity level atladığında
	var leveled_entity_id = params.get("entity_id", "")
	if leveled_entity_id == entity_id:
		play_event(AudioEvent.LEVEL_UP)

func _on_entity_healed(params: Dictionary) -> void:
	# Entity iyileştiğinde
	var healed_entity_id = params.get("entity_id", "")
	if healed_entity_id == entity_id:
		play_event(AudioEvent.HEAL)

func _on_entity_interacted(params: Dictionary) -> void:
	# Entity etkileşime girdiğinde
	var interacting_entity_id = params.get("entity_id", "")
	if interacting_entity_id == entity_id:
		play_event(AudioEvent.INTERACT)

# === COMPONENT INTERFACE ===

func get_component_type() -> String:
	return "AudioComponent"

func serialize() -> Dictionary:
	# Component'i serialize et
	return {
		"component_type": get_component_type(),
		"entity_id": entity_id,
		"audio_events": audio_events.duplicate(),
		"volume_multiplier": volume_multiplier,
		"pitch_variation": pitch_variation,
		"spatial_audio_enabled": spatial_audio_enabled,
		"max_distance": max_distance,
		"min_distance": min_distance
	}

func deserialize(data: Dictionary) -> void:
	# Component'i deserialize et
	if data.has("audio_events"):
		audio_events = data.audio_events.duplicate()
	
	if data.has("volume_multiplier"):
		volume_multiplier = data.volume_multiplier
	
	if data.has("pitch_variation"):
		pitch_variation = data.pitch_variation
	
	if data.has("spatial_audio_enabled"):
		spatial_audio_enabled = data.spatial_audio_enabled
	
	if data.has("max_distance"):
		max_distance = data.max_distance
	
	if data.has("min_distance"):
		min_distance = data.min_distance

# === DEBUG ===

func print_debug_info() -> void:
	print("=== AudioComponent Debug ===")
	print("Entity ID: %s" % entity_id)
	print("AudioSystem: %s" % ("Available" if audio_system else "Not found"))
	print("Spatial Audio: %s" % ("Enabled" if spatial_audio_enabled else "Disabled"))
	print("Volume Multiplier: %.2f" % volume_multiplier)
	print("Pitch Variation: %.2f" % pitch_variation)
	print("Audio Distances: %.1f - %.1f" % [min_distance, max_distance])
	
	print("Audio Event Mappings:")
	for event_type in audio_events:
		var event_name = AudioEvent.keys()[event_type]
		var sound_name = audio_events[event_type]
		print("  %s -> %s" % [event_name, sound_name])

func _to_string() -> String:
	return "[AudioComponent: entity=%s, events=%d]" % [entity_id, audio_events.size()]