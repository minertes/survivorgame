# 🎵 AUDIO SYSTEM (MOLECULE)
# Modüler audio sistem - Atomic bileşenleri birleştirir
@tool
class_name AudioSystemMolecule
extends Node

# === DEPENDENCIES ===
var audio_resource_manager: AudioResourceManager = null
var audio_player_pool: AudioPlayerPool = null
var audio_bus_manager: AudioBusManager = null
var audio_settings: AudioSettings = null
var audio_event_manager: AudioEventManager = null

# === SYSTEM STATE ===
var is_initialized: bool = false
var initialization_progress: float = 0.0
var system_errors: Array = []

# === SIGNALS ===
signal system_initialized(success: bool)
signal initialization_progress_updated(progress: float, stage: String)
signal audio_error(error_message: String, error_code: int)
signal system_shutdown()

# === LIFECYCLE ===

func _ready() -> void:
	print("AudioSystemMolecule initializing...")
	
	# Atomic bileşenleri oluştur ve initialize et
	_initialize_components()

func _exit_tree() -> void:
	# Sistem kapanırken
	system_shutdown.emit()
	print("AudioSystemMolecule shutdown")

# === PUBLIC API ===

func play_sound(sound_name: String, volume_db: float = 0.0, pitch_scale: float = 1.0, 
				position: Vector3 = Vector3.ZERO, is_3d: bool = false) -> bool:
	# Ses efekti oynat
	if not is_initialized:
		audio_error.emit("Audio system not initialized", 1001)
		return false
	
	if not audio_settings.get_setting("sfx_enabled", true):
		return false
	
	# Ses kaynağını yükle
	var stream = audio_resource_manager.load_audio_resource(sound_name, "sfx")
	if not stream:
		audio_error.emit("Sound not found: %s" % sound_name, 1002)
		return false
	
	# Player al
	var pool_type = AudioPlayerPool.PoolType.SFX_3D if is_3d else AudioPlayerPool.PoolType.SFX_2D
	var player = audio_player_pool.get_player(pool_type, is_3d)
	if not player:
		audio_error.emit("No available audio players", 1003)
		return false
	
	# Player'ı ayarla
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	
	# 3D audio için pozisyon ayarla
	if is_3d and player is AudioStreamPlayer3D:
		player.position = position
		player.max_distance = 50.0
		player.unit_size = 1.0
	
	# Oynat
	player.play()
	return true

func play_ui_sound(sound_name: String, volume_db: float = 0.0, pitch_scale: float = 1.0) -> bool:
	# UI sesi oynat
	if not is_initialized:
		audio_error.emit("Audio system not initialized", 1001)
		return false
	
	if not audio_settings.get_setting("ui_sounds_enabled", true):
		return false
	
	# Ses kaynağını yükle
	var stream = audio_resource_manager.load_audio_resource(sound_name, "ui")
	if not stream:
		audio_error.emit("UI sound not found: %s" % sound_name, 1004)
		return false
	
	# Player al
	var player = audio_player_pool.get_player(AudioPlayerPool.PoolType.UI_SFX)
	if not player:
		audio_error.emit("No available UI audio players", 1005)
		return false
	
	# Player'ı ayarla
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	
	# Oynat
	player.play()
	return true

func play_music(music_name: String, fade_in: float = 0.0, loop: bool = true) -> bool:
	# Müzik oynat
	if not is_initialized:
		audio_error.emit("Audio system not initialized", 1001)
		return false
	
	if not audio_settings.get_setting("music_enabled", true):
		return false
	
	# Müzik kaynağını yükle
	var stream = audio_resource_manager.load_audio_resource(music_name, "music")
	if not stream:
		audio_error.emit("Music not found: %s" % music_name, 1006)
		return false
	
	# Music player için özel pool (sadece bir tane)
	var music_player = _get_music_player()
	if not music_player:
		audio_error.emit("Music player not available", 1007)
		return false
	
	# Müzik ayarla
	music_player.stream = stream
	music_player.stream.loop = loop
	
	# Fade efekti
	if fade_in > 0:
		music_player.volume_db = AudioBusManager.MIN_VOLUME_DB
		music_player.play()
		_fade_volume(music_player, AudioBusManager.MIN_VOLUME_DB, 
					audio_settings.get_volume("Music"), fade_in)
	else:
		music_player.volume_db = linear_to_db(audio_settings.get_volume("Music"))
		music_player.play()
	
	return true

func stop_music(fade_out: float = 0.0) -> void:
	# Müziği durdur
	var music_player = _get_music_player()
	if not music_player or not music_player.playing:
		return
	
	if fade_out > 0:
		_fade_volume(music_player, music_player.volume_db, 
					AudioBusManager.MIN_VOLUME_DB, fade_out)
		await get_tree().create_timer(fade_out).timeout
	
	music_player.stop()

func stop_all_sounds() -> void:
	# Tüm sesleri durdur
	if audio_player_pool:
		audio_player_pool.stop_all_players()

func set_volume(bus_name: String, volume_linear: float) -> void:
	# Volume ayarla
	if audio_settings:
		audio_settings.set_volume(bus_name, volume_linear)

func get_volume(bus_name: String) -> float:
	# Volume al
	if audio_settings:
		return audio_settings.get_volume(bus_name)
	return 1.0

func toggle_mute(bus_name: String) -> bool:
	# Mute aç/kapa
	if audio_settings:
		return audio_settings.toggle_mute(bus_name)
	return false

func is_muted(bus_name: String) -> bool:
	# Mute durumunu kontrol et
	if audio_settings:
		return audio_settings.is_muted(bus_name)
	return false

func process_audio_event(event_name: String, event_data: Dictionary = {}) -> bool:
	# Audio event işle
	if audio_event_manager:
		return audio_event_manager.process_event(event_name, event_data)
	return false

func preload_audio_resources(resource_list: Array) -> void:
	# Ses kaynaklarını önceden yükle
	if audio_resource_manager:
		audio_resource_manager.preload_audio_resources(resource_list)

func get_system_info() -> Dictionary:
	# Sistem bilgilerini al
	return {
		"initialized": is_initialized,
		"initialization_progress": initialization_progress,
		"errors": system_errors.duplicate(),
		"components": {
			"resource_manager": audio_resource_manager != null,
			"player_pool": audio_player_pool != null,
			"bus_manager": audio_bus_manager != null,
			"settings": audio_settings != null,
			"event_manager": audio_event_manager != null
		}
	}

func save_settings() -> bool:
	# Ayarları kaydet
	if audio_settings:
		return audio_settings.save_settings()
	return false

func reset_settings() -> void:
	# Ayarları varsayılana döndür
	if audio_settings:
		audio_settings.reset_to_defaults()

# === PRIVATE METHODS ===

func _initialize_components() -> void:
	# Tüm atomic bileşenleri oluştur ve initialize et
	
	initialization_progress_updated.emit(0.1, "Creating components...")
	
	# 1. AudioResourceManager oluştur (preload ile)
	var AudioResourceManagerClass = preload("res://src/core/systems/audio/audio_resource_manager.gd")
	audio_resource_manager = AudioResourceManagerClass.new()
	audio_resource_manager.name = "AudioResourceManager"
	add_child(audio_resource_manager)
	
	initialization_progress_updated.emit(0.2, "Resource manager created")
	
	# 2. AudioPlayerPool oluştur (preload ile)
	var AudioPlayerPoolClass = preload("res://src/core/systems/audio/audio_player_pool.gd")
	audio_player_pool = AudioPlayerPoolClass.new()
	audio_player_pool.name = "AudioPlayerPool"
	add_child(audio_player_pool)
	
	initialization_progress_updated.emit(0.4, "Player pool created")
	
	# 3. AudioBusManager oluştur (preload ile)
	var AudioBusManagerClass = preload("res://src/core/systems/audio/audio_bus_manager.gd")
	audio_bus_manager = AudioBusManagerClass.new()
	audio_bus_manager.name = "AudioBusManager"
	add_child(audio_bus_manager)
	
	initialization_progress_updated.emit(0.6, "Bus manager created")
	
	# 4. AudioSettings oluştur (preload ile)
	var AudioSettingsClass = preload("res://src/core/systems/audio/audio_settings.gd")
	audio_settings = AudioSettingsClass.new()
	audio_settings.name = "AudioSettings"
	add_child(audio_settings)
	
	# Dependency'leri bağla
	audio_settings.set_audio_bus_manager(audio_bus_manager)
	
	initialization_progress_updated.emit(0.8, "Settings created")
	
	# 5. AudioEventManager oluştur (preload ile)
	var AudioEventManagerClass = preload("res://src/core/systems/audio/audio_event_manager.gd")
	audio_event_manager = AudioEventManagerClass.new()
	audio_event_manager.name = "AudioEventManager"
	add_child(audio_event_manager)
	
	# Dependency'leri bağla
	audio_event_manager.set_dependencies(self, audio_settings)
	
	initialization_progress_updated.emit(0.9, "Event manager created")
	
	# 6. Temel ses kaynaklarını önceden yükle
	_preload_essential_resources()
	
	initialization_progress_updated.emit(1.0, "Initialization complete")
	
	is_initialized = true
	system_initialized.emit(true)
	
	print("AudioSystemMolecule initialized successfully")

func _preload_essential_resources() -> void:
	# Temel ses kaynaklarını önceden yükle
	var essential_resources = [
		{"name": "click", "type": "ui", "priority": 100},
		{"name": "shoot", "type": "sfx", "priority": 90},
		{"name": "hurt", "type": "sfx", "priority": 80},
		{"name": "level_up", "type": "sfx", "priority": 70},
		{"name": "enemy_die", "type": "sfx", "priority": 60},
		{"name": "xp_collect", "type": "sfx", "priority": 50}
	]
	
	if audio_resource_manager:
		audio_resource_manager.preload_audio_resources(essential_resources)

func _get_music_player() -> AudioStreamPlayer:
	# Music player al (özel pool)
	# Not: Şu anlık basit implementasyon, sonra geliştirilebilir
	var music_players = get_tree().get_nodes_in_group("music_player")
	if music_players.size() > 0:
		return music_players[0]
	
	# Music player yoksa oluştur
	var music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = "Music"
	music_player.add_to_group("music_player")
	add_child(music_player)
	
	return music_player

func _fade_volume(player: AudioStreamPlayer, from_db: float, to_db: float, duration: float) -> void:
	# Volume fade efekti
	var tween = create_tween()
	tween.tween_method(_set_player_volume.bind(player), from_db, to_db, duration)

func _set_player_volume(volume_db: float, player: AudioStreamPlayer) -> void:
	# Player volume ayarla
	player.volume_db = volume_db

# === DEBUG ===

func print_system_info() -> void:
	var info = get_system_info()
	print("=== AudioSystemMolecule Info ===")
	print("Initialized: %s" % str(info.initialized))
	print("Progress: %.0f%%" % (info.initialization_progress * 100))
	
	print("\nComponents:")
	for component_name in info.components:
		print("  %s: %s" % [component_name.replace("_", " ").capitalize(), 
						   "✓" if info.components[component_name] else "✗"])
	
	if info.errors.size() > 0:
		print("\nErrors:")
		for error in info.errors:
			print("  %s" % error)
	
	# Component detayları
	if audio_resource_manager:
		print("\nResource Manager:")
		audio_resource_manager.print_cache_info()
	
	if audio_player_pool:
		print("\nPlayer Pool:")
		audio_player_pool.print_pool_stats()
	
	if audio_bus_manager:
		print("\nBus Manager:")
		audio_bus_manager.print_bus_info()
	
	if audio_settings:
		print("\nSettings:")
		audio_settings.print_settings()

func _to_string() -> String:
	return "[AudioSystemMolecule: %s]" % ("Initialized" if is_initialized else "Not Initialized")