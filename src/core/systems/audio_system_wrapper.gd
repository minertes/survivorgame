# 🎵 AUDIO SYSTEM WRAPPER
# Eski AudioSystem API'sini yeni modüler sisteme bağlar
@tool
class_name AudioSystemWrapper
extends Node

# === SYSTEM INSTANCE ===
var audio_system: AudioSystemMolecule = null
var is_wrapper_initialized: bool = false

# === COMPATIBILITY LAYER ===
# Eski AudioSystem enum'ları
enum AudioBus {
	MASTER = 0,
	MUSIC = 1,
	SFX = 2,
	UI = 3,
	VOICE = 4
}

const MIN_VOLUME: float = -80.0
const MAX_VOLUME: float = 6.0
const DEFAULT_VOLUME: float = 0.0
const POOL_SIZE: int = 20

# === SIGNALS (Eski AudioSystem sinyalleri) ===
signal music_changed(music_name: String)
signal music_finished()
signal volume_changed(bus_name: String, volume: float)
signal audio_pool_created(pool_type: String, size: int)
signal audio_error(error_message: String, error_code: int)

# === LIFECYCLE ===

func _ready() -> void:
	print("AudioSystemWrapper initializing...")
	
	# Yeni modüler sistemi oluştur
	_initialize_modular_system()

func _initialize_modular_system() -> void:
	# Modüler audio sistemini oluştur ve initialize et
	
	print("AudioSystemWrapper: Starting modular system initialization...")
	
	# AudioSystemMolecule sınıfını preload et
	var AudioSystemMoleculeClass = preload("res://src/core/systems/audio/audio_system_molecule.gd")
	if AudioSystemMoleculeClass:
		print("AudioSystemWrapper: AudioSystemMolecule class preloaded successfully")
		audio_system = AudioSystemMoleculeClass.new()
		audio_system.name = "AudioSystemMolecule"
		add_child(audio_system)
		
		# Sinyalleri bağla (compatibility için)
		audio_system.system_initialized.connect(_on_system_initialized)
		audio_system.audio_error.connect(_on_audio_error)
		
		# Molekül _ready senkron çalışıyor; yine de hemen kullanılabilir say (ses gecikmesin)
		is_wrapper_initialized = true
		
		print("AudioSystemWrapper: Modular system created and added to scene tree")
	else:
		print("AudioSystemWrapper: ERROR - Failed to preload AudioSystemMolecule class")
		audio_error.emit("Failed to load AudioSystemMolecule class", 9999)

func _on_system_initialized(success: bool) -> void:
	# Modüler sistem initialize edildi
	is_wrapper_initialized = success
	
	if success:
		print("AudioSystemWrapper: Modular system initialized successfully")
	else:
		print("AudioSystemWrapper: Modular system initialization failed")

func _on_audio_error(error_message: String, error_code: int) -> void:
	# Audio hatası
	audio_error.emit(error_message, error_code)

# === PUBLIC API (Eski AudioSystem API uyumluluğu) ===

func play_sound(sound_name: String, volume_db: float = 0.0, pitch_scale: float = 1.0, 
				position: Vector3 = Vector3.ZERO, is_3d: bool = false) -> bool:
	# Ses efekti oynat
	if not is_wrapper_initialized or not audio_system:
		return false
	
	# dB'yi linear'a çevir (yeni sistem linear kullanıyor)
	var volume_linear = db_to_linear(volume_db)
	
	# Volume ayarını uygula (SFX bus için)
	var sfx_volume = audio_system.get_volume("SFX")
	var final_volume = volume_linear * sfx_volume
	
	# Linear'ı tekrar dB'ye çevir
	var final_volume_db = linear_to_db(final_volume)
	
	return audio_system.play_sound(sound_name, final_volume_db, pitch_scale, position, is_3d)

func play_ui_sound(sound_name: String, volume_db: float = 0.0, pitch_scale: float = 1.0) -> bool:
	# UI sesi oynat
	if not is_wrapper_initialized or not audio_system:
		return false
	
	# dB'yi linear'a çevir
	var volume_linear = db_to_linear(volume_db)
	
	# Volume ayarını uygula (UI bus için)
	var ui_volume = audio_system.get_volume("UI")
	var final_volume = volume_linear * ui_volume
	
	# Linear'ı tekrar dB'ye çevir
	var final_volume_db = linear_to_db(final_volume)
	
	return audio_system.play_ui_sound(sound_name, final_volume_db, pitch_scale)

func play_music(music_name: String, fade_in: float = 0.0, loop: bool = true) -> bool:
	# Müzik oynat
	if not is_wrapper_initialized or not audio_system:
		return false
	
	# Music volume ayarını uygula
	var music_volume = audio_system.get_volume("Music")
	
	# Eski API fade_in parametresini destekle
	return audio_system.play_music(music_name, fade_in, loop)

func stop_music(fade_out: float = 0.0) -> void:
	# Müziği durdur
	if audio_system:
		audio_system.stop_music(fade_out)

func stop_all_sounds() -> void:
	# Tüm sesleri durdur
	if audio_system:
		audio_system.stop_all_sounds()

func set_master_volume(volume_db: float) -> void:
	# Master volume ayarla
	if audio_system:
		var volume_linear = db_to_linear(volume_db)
		audio_system.set_volume("Master", volume_linear)
		volume_changed.emit("Master", volume_db)

func set_music_volume(volume_db: float) -> void:
	# Müzik volume ayarla
	if audio_system:
		var volume_linear = db_to_linear(volume_db)
		audio_system.set_volume("Music", volume_linear)
		volume_changed.emit("Music", volume_db)

func set_sfx_volume(volume_db: float) -> void:
	# SFX volume ayarla
	if audio_system:
		var volume_linear = db_to_linear(volume_db)
		audio_system.set_volume("SFX", volume_linear)
		volume_changed.emit("SFX", volume_db)

func set_ui_volume(volume_db: float) -> void:
	# UI volume ayarla
	if audio_system:
		var volume_linear = db_to_linear(volume_db)
		audio_system.set_volume("UI", volume_linear)
		volume_changed.emit("UI", volume_db)

func set_voice_volume(volume_db: float) -> void:
	# Ses volume ayarla
	if audio_system:
		var volume_linear = db_to_linear(volume_db)
		audio_system.set_volume("Voice", volume_linear)
		volume_changed.emit("Voice", volume_db)

func get_volume(bus_name: String) -> float:
	# Volume değerini al (dB cinsinden)
	if audio_system:
		var volume_linear = audio_system.get_volume(bus_name)
		return linear_to_db(volume_linear)
	return 0.0

func mute_all() -> void:
	# Tüm sesleri sustur
	if audio_system:
		audio_system.toggle_mute("Master")
		# Diğer bus'ları da mute'la
		for bus in ["Music", "SFX", "UI", "Voice"]:
			if not audio_system.is_muted(bus):
				audio_system.toggle_mute(bus)

func unmute_all() -> void:
	# Tüm seslerin susturmasını kaldır
	if audio_system:
		for bus in ["Master", "Music", "SFX", "UI", "Voice"]:
			if audio_system.is_muted(bus):
				audio_system.toggle_mute(bus)

func toggle_mute(bus_name: String) -> bool:
	# Susturmayı aç/kapa
	if audio_system:
		return audio_system.toggle_mute(bus_name)
	return false

func enable_spatial_audio(enabled: bool) -> void:
	# Spatial audio'yu aç/kapa
	# Yeni sistemde bu ayar AudioSettings'te
	if audio_system:
		# Event olarak gönder
		audio_system.process_audio_event("spatial_audio_changed", {
			"enabled": enabled
		})

func save_audio_config() -> void:
	# Audio config'i kaydet
	if audio_system:
		audio_system.save_settings()

func reset_to_defaults() -> void:
	# Varsayılan ayarlara dön
	if audio_system:
		audio_system.reset_settings()

func print_debug_info() -> void:
	# Debug bilgilerini yazdır
	if audio_system:
		audio_system.print_system_info()
	else:
		print("AudioSystemWrapper: Modular system not available")

# === YENİ SİSTEM ÖZELLİKLERİ ===

func get_modular_system() -> AudioSystemMolecule:
	# Modüler sisteme direkt erişim (yeni kod için)
	return audio_system

func is_modular_system_available() -> bool:
	# Modüler sistem mevcut mu?
	return audio_system != null and is_wrapper_initialized

func process_audio_event(event_name: String, event_data: Dictionary = {}) -> bool:
	# Audio event işle (yeni özellik)
	if audio_system:
		return audio_system.process_audio_event(event_name, event_data)
	return false

func preload_resources(resource_list: Array) -> void:
	# Kaynakları önceden yükle (yeni özellik)
	if audio_system:
		audio_system.preload_audio_resources(resource_list)

# === DEBUG ===

func _to_string() -> String:
	var status = "Wrapper Ready" if is_wrapper_initialized else "Wrapper Not Ready"
	var system_status = "Modular System Available" if audio_system else "No Modular System"
	return "[AudioSystemWrapper: %s, %s]" % [status, system_status]