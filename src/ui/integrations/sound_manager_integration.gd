# 🔊 SOUND MANAGER INTEGRATION
# AudioSystem ile entegrasyon
class_name SoundManagerIntegration
extends Node

# === SIGNALS ===
signal sound_system_initialized()
signal sound_state_changed(enabled: bool)
signal button_sound_played(sound_name: String)
signal sound_effect_played(effect_name: String)
signal audio_system_connected()
signal audio_system_disconnected()

# === CONSTANTS ===
const BUTTON_CLICK_SOUND := "ui_button_click"
const BUTTON_HOVER_SOUND := "ui_button_hover"
const MENU_MUSIC := "menu_music"
const TRANSITION_SOUND := "ui_transition"

# === NODE REFERENCES ===
var audio_system: Node = null
var sound_manager: Node = null

# === STATE ===
var is_initialized: bool = false
var is_connected: bool = false
var sound_enabled: bool = true
var current_music: String = ""
var sound_effects_enabled: bool = true
var music_volume: float = 0.8
var sfx_volume: float = 1.0

# === LIFECYCLE ===

func _ready() -> void:
	# AudioSystem'i ara
	_find_audio_systems()
	
	# GameData'dan ses ayarlarını yükle
	_load_sound_settings()
	
	is_initialized = true
	sound_system_initialized.emit()

# === PUBLIC API ===

func initialize() -> void:
	if is_initialized:
		return
	
	_find_audio_systems()
	_load_sound_settings()
	
	if audio_system:
		_connect_to_audio_system()
	
	is_initialized = true
	sound_system_initialized.emit()
	# Menü açıldığında ses açıksa arka plan müziğini başlat
	if sound_enabled:
		play_menu_music()

func play_button_sound(sound_type: String = "click") -> void:
	if not sound_enabled or not sound_effects_enabled:
		return
	
	var sound_name = BUTTON_CLICK_SOUND if sound_type == "click" else BUTTON_HOVER_SOUND
	
	if audio_system:
		# AudioSystemWrapper kullan (play_ui_sound fonksiyonu)
		audio_system.play_ui_sound(sound_name, linear_to_db(sfx_volume))
	elif sound_manager:
		# Eski SoundManager kullan
		sound_manager.play_sound(sound_name)
	else:
		# Fallback: basit ses çal
		_play_fallback_sound(sound_name)
	
	button_sound_played.emit(sound_name)

func play_ui_sound(sound_name: String, volume_db: float = 0.0) -> bool:
	"""UI sesi oynat (play_ui_sound API uyumluluğu için)"""
	if not sound_enabled or not sound_effects_enabled:
		return false
	
	if audio_system:
		# AudioSystemWrapper kullan
		return audio_system.play_ui_sound(sound_name, volume_db)
	elif sound_manager:
		# Eski SoundManager kullan
		sound_manager.play_sound(sound_name)
		return true
	else:
		# Fallback
		_play_fallback_sound(sound_name)
		return false

func play_sound_effect(effect_name: String, volume: float = 1.0) -> void:
	if not sound_enabled or not sound_effects_enabled:
		return
	
	if audio_system:
		# AudioSystemWrapper kullan (play_sound fonksiyonu)
		audio_system.play_sound(effect_name, linear_to_db(volume * sfx_volume))
	elif sound_manager:
		sound_manager.play_sound(effect_name)
	else:
		_play_fallback_sound(effect_name)
	
	sound_effect_played.emit(effect_name)

func play_menu_music() -> void:
	if not sound_enabled:
		return
	
	current_music = MENU_MUSIC
	
	if audio_system:
		audio_system.play_music(MENU_MUSIC, 0.0, true)  # fade_in = 0.0, loop = true
	elif sound_manager:
		sound_manager.play_music(MENU_MUSIC, true)
	else:
		print("No audio system available for menu music")

func stop_music(fade_out: float = 0.5) -> void:
	if audio_system:
		audio_system.stop_music(fade_out)
	elif sound_manager:
		sound_manager.stop_music(fade_out)
	
	current_music = ""

func update_sound_state() -> void:
	# GameData'dan ses durumunu güncelle
	_load_sound_settings()
	
	# AudioSystem'e bildir
	if audio_system:
		if sound_enabled:
			audio_system.unmute_all()
		else:
			audio_system.mute_all()
	
	# Eski SoundManager'a bildir
	if sound_manager:
		if sound_enabled:
			sound_manager.unmute_all()
		else:
			sound_manager.mute_all()
	
	sound_state_changed.emit(sound_enabled)

func set_music_volume(volume: float) -> void:
	music_volume = clamp(volume, 0.0, 1.0)
	
	if audio_system:
		# dB cinsinden volume ayarla
		audio_system.set_music_volume(linear_to_db(music_volume))

func set_sfx_volume(volume: float) -> void:
	sfx_volume = clamp(volume, 0.0, 1.0)
	
	if audio_system:
		# dB cinsinden volume ayarla
		audio_system.set_sfx_volume(linear_to_db(sfx_volume))

func toggle_sound() -> void:
	sound_enabled = not sound_enabled
	update_sound_state()

func toggle_music() -> void:
	if current_music:
		stop_music()
	else:
		play_menu_music()

func get_audio_status() -> Dictionary:
	return {
		"initialized": is_initialized,
		"connected": is_connected,
		"sound_enabled": sound_enabled,
		"sound_effects_enabled": sound_effects_enabled,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"current_music": current_music,
		"audio_system_available": audio_system != null,
		"sound_manager_available": sound_manager != null
	}

# === PRIVATE METHODS ===

func _find_audio_systems() -> void:
	# AudioSystemWrapper'ı ara (autoload)
	if has_node("/root/AudioSystem"):
		audio_system = get_node("/root/AudioSystem")
		print("AudioSystemWrapper found (autoload)")
	
	# Eski SoundManager'ı ara
	if has_node("/root/SoundManager"):
		sound_manager = get_node("/root/SoundManager")
		print("SoundManager found")
	
	if not audio_system and not sound_manager:
		print("No audio system found")
		# AudioSystemWrapper autoload olmalı, bu yüzden oluşturmaya gerek yok

func _connect_to_audio_system() -> void:
	if not audio_system:
		return
	
	# AudioSystemWrapper sinyallerine bağlan
	if audio_system.has_signal("music_changed"):
		audio_system.music_changed.connect(_on_music_changed)
	
	if audio_system.has_signal("music_finished"):
		audio_system.music_finished.connect(_on_music_finished)
	
	if audio_system.has_signal("audio_error"):
		audio_system.audio_error.connect(_on_audio_error)
	
	is_connected = true
	audio_system_connected.emit()

func _load_sound_settings() -> void:
	# GameData'dan ses ayarlarını yükle
	if has_node("/root/GameData"):
		var game_data = get_node("/root/GameData")
		sound_enabled = game_data.sound_enabled
	else:
		# Varsayılan değerler
		sound_enabled = true
		sound_effects_enabled = true
		music_volume = 0.8
		sfx_volume = 1.0

func _play_fallback_sound(sound_name: String) -> void:
	# Basit fallback ses efekti
	print("Playing fallback sound: %s" % sound_name)
	# Burada basit bir ses çalma kodu eklenebilir

# === EVENT HANDLERS ===

func _on_music_changed(music_name: String) -> void:
	print("Music changed: %s" % music_name)
	if music_name:
		current_music = music_name
	else:
		current_music = ""

func _on_music_finished() -> void:
	print("Music finished")
	current_music = ""

func _on_audio_error(error_message: String) -> void:
	print("Audio error: %s" % error_message)

# === CLEANUP ===

func _exit_tree() -> void:
	# Müziği durdur
	stop_music()
	
	# Bağlantıları kes
	if is_connected and audio_system:
		# Sinyal bağlantılarını kes
		if audio_system.is_connected("music_changed", _on_music_changed):
			audio_system.music_changed.disconnect(_on_music_changed)
		if audio_system.is_connected("music_finished", _on_music_finished):
			audio_system.music_finished.disconnect(_on_music_finished)
		if audio_system.is_connected("audio_error", _on_audio_error):
			audio_system.audio_error.disconnect(_on_audio_error)
	
	is_connected = false
	audio_system_disconnected.emit()

# === DEBUG ===

func print_debug_info() -> void:
	print("=== SoundManagerIntegration ===")
	print("Initialized: %s" % str(is_initialized))
	print("Connected: %s" % str(is_connected))
	print("Sound Enabled: %s" % str(sound_enabled))
	print("Sound Effects Enabled: %s" % str(sound_effects_enabled))
	print("Music Volume: %.2f" % music_volume)
	print("SFX Volume: %.2f" % sfx_volume)
	print("Current Music: %s" % current_music)
	print("Audio System Available: %s" % str(audio_system != null))
	print("Sound Manager Available: %s" % str(sound_manager != null))