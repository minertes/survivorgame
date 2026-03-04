# 🎵 AUDIO SYSTEM (ATOM)
# Temel ses yönetim sistemi
class_name AudioSystem extends Node

# === AUDIO BUS NAMES ===
enum AudioBus {
	MASTER = 0,
	MUSIC = 1,
	SFX = 2,
	UI = 3,
	VOICE = 4
}

# === VOLUME RANGES ===
const MIN_VOLUME: float = -80.0  # dB
const MAX_VOLUME: float = 6.0    # dB
const DEFAULT_VOLUME: float = 0.0

# === AUDIO POOL ===
const POOL_SIZE: int = 20  # Her ses tipi için pool boyutu

# === PROPERTIES ===
var _audio_pool: Dictionary = {}  # Ses tipine göre AudioStreamPlayer pool'ları
var _music_player: AudioStreamPlayer = null
var _current_music: AudioStream = null
var _music_queue: Array = []
var _is_music_fading: bool = false
var _spatial_audio_enabled: bool = true
var _audio_config: Dictionary = {}

# === SIGNALS ===
signal music_changed(music_name: String)
signal music_finished()
signal volume_changed(bus_name: String, volume: float)
signal audio_pool_created(pool_type: String, size: int)
signal audio_error(error_message: String)

# === LIFECYCLE ===

func _ready() -> void:
	print("AudioSystem initializing...")
	
	# Audio bus'ları oluştur
	_setup_audio_buses()
	
	# Audio pool'ları oluştur
	_setup_audio_pools()
	
	# Config yükle
	_load_audio_config()
	
	# EventBus listener'ları bağla
	_setup_event_listeners()
	
	print("AudioSystem initialized successfully")

func _setup_audio_buses() -> void:
	# Master bus
	AudioServer.set_bus_name(AudioBus.MASTER, "Master")
	
	# Music bus
	if AudioServer.get_bus_count() <= AudioBus.MUSIC:
		AudioServer.add_bus(AudioBus.MUSIC)
	AudioServer.set_bus_name(AudioBus.MUSIC, "Music")
	AudioServer.set_bus_send(AudioBus.MUSIC, "Master")
	
	# SFX bus
	if AudioServer.get_bus_count() <= AudioBus.SFX:
		AudioServer.add_bus(AudioBus.SFX)
	AudioServer.set_bus_name(AudioBus.SFX, "SFX")
	AudioServer.set_bus_send(AudioBus.SFX, "Master")
	
	# UI bus
	if AudioServer.get_bus_count() <= AudioBus.UI:
		AudioServer.add_bus(AudioBus.UI)
	AudioServer.set_bus_name(AudioBus.UI, "UI")
	AudioServer.set_bus_send(AudioBus.UI, "Master")
	
	# Voice bus
	if AudioServer.get_bus_count() <= AudioBus.VOICE:
		AudioServer.add_bus(AudioBus.VOICE)
	AudioServer.set_bus_name(AudioBus.VOICE, "Voice")
	AudioServer.set_bus_send(AudioBus.VOICE, "Master")
	
	print("Audio buses created: Master, Music, SFX, UI, Voice")

func _setup_audio_pools() -> void:
	# SFX pool'ları
	_create_audio_pool("sfx_2d", AudioStreamPlayer, POOL_SIZE)
	_create_audio_pool("sfx_3d", AudioStreamPlayer3D, POOL_SIZE)
	_create_audio_pool("ui_sfx", AudioStreamPlayer, POOL_SIZE / 2)
	
	# Music player oluştur
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	_music_player.finished.connect(_on_music_finished)
	add_child(_music_player)
	
	print("Audio pools created: sfx_2d, sfx_3d, ui_sfx")

func _create_audio_pool(pool_name: String, player_type: GDScript, size: int) -> void:
	var pool: Array = []
	
	for i in range(size):
		var player: AudioStreamPlayer
		if player_type == AudioStreamPlayer3D:
			player = AudioStreamPlayer3D.new()
		else:
			player = AudioStreamPlayer.new()
		
		player.bus = pool_name.split("_")[0].capitalize()  # "sfx_2d" -> "Sfx"
		player.finished.connect(_on_audio_finished.bind(player, pool_name))
		
		add_child(player)
		pool.append(player)
	
	_audio_pool[pool_name] = pool
	audio_pool_created.emit(pool_name, size)

func _load_audio_config() -> void:
	# Varsayılan audio config
	_audio_config = {
		"master_volume": DEFAULT_VOLUME,
		"music_volume": DEFAULT_VOLUME,
		"sfx_volume": DEFAULT_VOLUME,
		"ui_volume": DEFAULT_VOLUME,
		"voice_volume": DEFAULT_VOLUME,
		"spatial_audio_enabled": true,
		"music_enabled": true,
		"sfx_enabled": true,
		"ui_sounds_enabled": true
	}
	
	# ConfigManager'dan yükle
	if ConfigManager.is_available():
		var config = ConfigManager.get_config("audio")
		if config:
			_audio_config.merge(config, true)
	
	# Volume'leri uygula
	_set_volume_db(AudioBus.MASTER, _audio_config.master_volume)
	_set_volume_db(AudioBus.MUSIC, _audio_config.music_volume)
	_set_volume_db(AudioBus.SFX, _audio_config.sfx_volume)
	_set_volume_db(AudioBus.UI, _audio_config.ui_volume)
	_set_volume_db(AudioBus.VOICE, _audio_config.voice_volume)
	
	_spatial_audio_enabled = _audio_config.spatial_audio_enabled

func _setup_event_listeners() -> void:
	if EventBus.is_available():
		EventBus.connect_static("play_sound", _on_play_sound_event)
		EventBus.connect_static("play_music", _on_play_music_event)
		EventBus.connect_static("stop_music", _on_stop_music_event)
		EventBus.connect_static("set_volume", _on_set_volume_event)
		EventBus.connect_static("toggle_mute", _on_toggle_mute_event)

# === PUBLIC API - SOUND EFFECTS ===

func play_sound(sound_name: String, volume_db: float = 0.0, pitch_scale: float = 1.0, 
				position: Vector3 = Vector3.ZERO, is_3d: bool = false) -> bool:
	# Sound effect oynat
	if not _audio_config.sfx_enabled:
		return false
	
	var stream = _load_audio_stream(sound_name, "sfx")
	if not stream:
		audio_error.emit("Sound not found: %s" % sound_name)
		return false
	
	var player = _get_available_player("sfx_3d" if is_3d else "sfx_2d")
	if not player:
		audio_error.emit("No available audio players in pool")
		return false
	
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	
	if is_3d and player is AudioStreamPlayer3D:
		player.position = position
		player.max_distance = 50.0
		player.unit_size = 1.0
	
	player.play()
	return true

func play_ui_sound(sound_name: String, volume_db: float = 0.0, pitch_scale: float = 1.0) -> bool:
	# UI sesi oynat
	if not _audio_config.ui_sounds_enabled:
		return false
	
	var stream = _load_audio_stream(sound_name, "ui")
	if not stream:
		audio_error.emit("UI sound not found: %s" % sound_name)
		return false
	
	var player = _get_available_player("ui_sfx")
	if not player:
		audio_error.emit("No available UI audio players")
		return false
	
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()
	return true

func stop_all_sounds() -> void:
	# Tüm sesleri durdur
	for pool_name in _audio_pool:
		for player in _audio_pool[pool_name]:
			if player.playing:
				player.stop()

func stop_sounds_by_type(sound_type: String) -> void:
	# Belirli tipteki sesleri durdur
	var pool_name = sound_type + "_2d"
	if _audio_pool.has(pool_name):
		for player in _audio_pool[pool_name]:
			if player.playing:
				player.stop()

# === PUBLIC API - MUSIC ===

func play_music(music_name: String, fade_in: float = 0.0, loop: bool = true) -> bool:
	# Müzik oynat
	if not _audio_config.music_enabled:
		return false
	
	var stream = _load_audio_stream(music_name, "music")
	if not stream:
		audio_error.emit("Music not found: %s" % music_name)
		return false
	
	_current_music = stream
	_music_player.stream = stream
	_music_player.stream.loop = loop
	
	if fade_in > 0:
		_music_player.volume_db = MIN_VOLUME
		_music_player.play()
		_fade_volume(_music_player, MIN_VOLUME, _audio_config.music_volume, fade_in)
	else:
		_music_player.volume_db = _audio_config.music_volume
		_music_player.play()
	
	music_changed.emit(music_name)
	return true

func stop_music(fade_out: float = 0.0) -> void:
	# Müziği durdur
	if fade_out > 0:
		_fade_volume(_music_player, _music_player.volume_db, MIN_VOLUME, fade_out)
		await get_tree().create_timer(fade_out).timeout
	
	_music_player.stop()
	_current_music = null
	music_changed.emit("")

func pause_music() -> void:
	# Müziği duraklat
	if _music_player.playing:
		_music_player.stream_paused = true

func resume_music() -> void:
	# Müziği devam ettir
	if _music_player.stream_paused:
		_music_player.stream_paused = false

func queue_music(music_name: String) -> void:
	# Müzik kuyruğuna ekle
	_music_queue.append(music_name)

func play_next_in_queue() -> bool:
	# Kuyruktaki bir sonraki müziği oynat
	if _music_queue.is_empty():
		return false
	
	var next_music = _music_queue.pop_front()
	return play_music(next_music)

func set_music_loop(loop: bool) -> void:
	# Müzik döngüsünü ayarla
	if _music_player.stream:
		_music_player.stream.loop = loop

# === PUBLIC API - VOLUME CONTROL ===

func set_master_volume(volume_db: float) -> void:
	# Master volume ayarla
	_set_volume_db(AudioBus.MASTER, volume_db)
	_audio_config.master_volume = volume_db
	volume_changed.emit("Master", volume_db)

func set_music_volume(volume_db: float) -> void:
	# Müzik volume ayarla
	_set_volume_db(AudioBus.MUSIC, volume_db)
	_audio_config.music_volume = volume_db
	volume_changed.emit("Music", volume_db)

func set_sfx_volume(volume_db: float) -> void:
	# SFX volume ayarla
	_set_volume_db(AudioBus.SFX, volume_db)
	_audio_config.sfx_volume = volume_db
	volume_changed.emit("SFX", volume_db)

func set_ui_volume(volume_db: float) -> void:
	# UI volume ayarla
	_set_volume_db(AudioBus.UI, volume_db)
	_audio_config.ui_volume = volume_db
	volume_changed.emit("UI", volume_db)

func set_voice_volume(volume_db: float) -> void:
	# Ses volume ayarla
	_set_volume_db(AudioBus.VOICE, volume_db)
	_audio_config.voice_volume = volume_db
	volume_changed.emit("Voice", volume_db)

func get_volume(bus_name: String) -> float:
	# Volume değerini al
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index >= 0:
		return AudioServer.get_bus_volume_db(bus_index)
	return 0.0

func mute_all() -> void:
	# Tüm sesleri sustur
	for i in range(AudioServer.get_bus_count()):
		AudioServer.set_bus_mute(i, true)

func unmute_all() -> void:
	# Tüm seslerin susturmasını kaldır
	for i in range(AudioServer.get_bus_count()):
		AudioServer.set_bus_mute(i, false)

func toggle_mute(bus_name: String) -> bool:
	# Susturmayı aç/kapa
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index >= 0:
		var is_muted = AudioServer.is_bus_mute(bus_index)
		AudioServer.set_bus_mute(bus_index, not is_muted)
		return not is_muted
	return false

# === PUBLIC API - SPATIAL AUDIO ===

func enable_spatial_audio(enabled: bool) -> void:
	# Spatial audio'yu aç/kapa
	_spatial_audio_enabled = enabled
	_audio_config.spatial_audio_enabled = enabled

func set_listener_position(position: Vector3) -> void:
	# Dinleyici pozisyonunu ayarla
	var listener = get_viewport().get_camera_3d()
	if listener:
		listener.position = position

func update_audio_position(entity_id: String, position: Vector3) -> void:
	# Entity'nin audio pozisyonunu güncelle
	# Bu fonksiyon AudioComponent tarafından kullanılacak
	pass

# === PUBLIC API - CONFIGURATION ===

func save_audio_config() -> void:
	# Audio config'i kaydet
	if ConfigManager.is_available():
		ConfigManager.set_config("audio", _audio_config)

func reset_to_defaults() -> void:
	# Varsayılan ayarlara dön
	_audio_config = {
		"master_volume": DEFAULT_VOLUME,
		"music_volume": DEFAULT_VOLUME,
		"sfx_volume": DEFAULT_VOLUME,
		"ui_volume": DEFAULT_VOLUME,
		"voice_volume": DEFAULT_VOLUME,
		"spatial_audio_enabled": true,
		"music_enabled": true,
		"sfx_enabled": true,
		"ui_sounds_enabled": true
	}
	
	# Volume'leri uygula
	_set_volume_db(AudioBus.MASTER, DEFAULT_VOLUME)
	_set_volume_db(AudioBus.MUSIC, DEFAULT_VOLUME)
	_set_volume_db(AudioBus.SFX, DEFAULT_VOLUME)
	_set_volume_db(AudioBus.UI, DEFAULT_VOLUME)
	_set_volume_db(AudioBus.VOICE, DEFAULT_VOLUME)
	
	# Susturmayı kaldır
	unmute_all()

# === UTILITY METHODS ===

func _load_audio_stream(name: String, type: String) -> AudioStream:
	# Audio stream yükle
	# Not: Bu fonksiyon gerçek audio dosyaları yüklemek için extend edilmeli
	# Şimdilik placeholder olarak programatik ses üretimi kullanıyoruz
	
	match type:
		"sfx":
			return _generate_sfx_stream(name)
		"music":
			return _generate_music_stream(name)
		"ui":
			return _generate_ui_stream(name)
		_:
			return null

func _generate_sfx_stream(name: String) -> AudioStream:
	# Programatik SFX oluştur
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = 22050.0
	generator.buffer_length = 0.5
	
	match name:
		"shoot":
			generator.buffer_length = 0.1
		"hit":
			generator.buffer_length = 0.2
		"explosion":
			generator.buffer_length = 0.5
		"pickup":
			generator.buffer_length = 0.15
		"click":
			generator.buffer_length = 0.05
	
	return generator

func _generate_music_stream(name: String) -> AudioStream:
	# Programatik müzik oluştur
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = 44100.0
	generator.buffer_length = 10.0  # Loop için uzun buffer
	
	return generator

func _generate_ui_stream(name: String) -> AudioStream:
	# Programatik UI sesi oluştur
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = 22050.0
	generator.buffer_length = 0.1
	
	return generator

func _get_available_player(pool_name: String) -> AudioStreamPlayer:
	# Pool'dan boş player al
	if not _audio_pool.has(pool_name):
		return null
	
	for player in _audio_pool[pool_name]:
		if not player.playing:
			return player
	
	# Boş player yoksa, ilk player'ı yeniden kullan
	var player = _audio_pool[pool_name][0]
	player.stop()
	return player

func _set_volume_db(bus_index: int, volume_db: float) -> void:
	# Volume ayarla (dB cinsinden)
	var clamped_volume = clamp(volume_db, MIN_VOLUME, MAX_VOLUME)
	AudioServer.set_bus_volume_db(bus_index, clamped_volume)

func _fade_volume(player: AudioStreamPlayer, from_db: float, to_db: float, duration: float) -> void:
	# Volume fade efekti
	if _is_music_fading:
		return
	
	_is_music_fading = true
	var tween = create_tween()
	tween.tween_method(_set_player_volume.bind(player), from_db, to_db, duration)
	tween.finished.connect(func(): _is_music_fading = false)

func _set_player_volume(volume_db: float, player: AudioStreamPlayer) -> void:
	player.volume_db = volume_db

# === SIGNAL HANDLERS ===

func _on_audio_finished(player: AudioStreamPlayer, pool_name: String) -> void:
	# Audio bittiğinde pool'a geri dön
	player.stop()
	player.stream = null

func _on_music_finished() -> void:
	# Müzik bittiğinde
	music_finished.emit()
	
	# Kuyrukta müzik varsa, bir sonrakini oynat
	if not _music_queue.is_empty():
		play_next_in_queue()

# === EVENT BUS HANDLERS ===

func _on_play_sound_event(params: Dictionary) -> void:
	# EventBus'tan gelen play_sound event'i
	var sound_name = params.get("sound_name", "")
	var volume_db = params.get("volume_db", 0.0)
	var pitch_scale = params.get("pitch_scale", 1.0)
	var position = params.get("position", Vector3.ZERO)
	var is_3d = params.get("is_3d", false)
	
	play_sound(sound_name, volume_db, pitch_scale, position, is_3d)

func _on_play_music_event(params: Dictionary) -> void:
	# EventBus'tan gelen play_music event'i
	var music_name = params.get("music_name", "")
	var fade_in = params.get("fade_in", 0.0)
	var loop = params.get("loop", true)
	
	play_music(music_name, fade_in, loop)

func _on_stop_music_event(params: Dictionary) -> void:
	# EventBus'tan gelen stop_music event'i
	var fade_out = params.get("fade_out", 0.0)
	stop_music(fade_out)

func _on_set_volume_event(params: Dictionary) -> void:
	# EventBus'tan gelen set_volume event'i
	var bus_name = params.get("bus_name", "Master")
	var volume_db = params.get("volume_db", 0.0)
	
	match bus_name:
		"Master":
			set_master_volume(volume_db)
		"Music":
			set_music_volume(volume_db)
		"SFX":
			set_sfx_volume(volume_db)
		"UI":
			set_ui_volume(volume_db)
		"Voice":
			set_voice_volume(volume_db)

func _on_toggle_mute_event(params: Dictionary) -> void:
	# EventBus'tan gelen toggle_mute event'i
	var bus_name = params.get("bus_name", "Master")
	toggle_mute(bus_name)

# === DEBUG ===

func print_debug_info() -> void:
	print("=== AudioSystem Debug ===")
	print("Music Player: %s" % ("Playing" if _music_player.playing else "Stopped"))
	print("Current Music: %s" % (_current_music.get_path() if _current_music else "None"))
	print("Music Queue Size: %d" % _music_queue.size())
	print("Spatial Audio: %s" % ("Enabled" if _spatial_audio_enabled else "Disabled"))
	
	for pool_name in _audio_pool:
		var active_count = 0
		for player in _audio_pool[pool_name]:
			if player.playing:
				active_count += 1
		print("%s Pool: %d/%d active" % [pool_name, active_count, _audio_pool[pool_name].size()])
	
	print("Volume Levels:")
	print("  Master: %.1f dB" % get_volume("Master"))
	print("  Music: %.1f dB" % get_volume("Music"))
	print("  SFX: %.1f dB" % get_volume("SFX"))
	print("  UI: %.1f dB" % get_volume("UI"))

func _to_string() -> String:
	return "[AudioSystem: Music=%s, Pools=%d]" % [
		"Playing" if _music_player.playing else "Stopped",
		_audio_pool.size()
	]