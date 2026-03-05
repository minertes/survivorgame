# 🎵 AUDIO RESOURCE MANAGER (ATOM)
# Ses dosyalarını yükler ve yönetir
class_name AudioResourceManager
extends Node

# === AUDIO RESOURCE PATHS ===
const AUDIO_DIRECTORY: String = "res://assets/audio/"
const SFX_DIRECTORY: String = AUDIO_DIRECTORY + "sfx/"
const MUSIC_DIRECTORY: String = AUDIO_DIRECTORY + "music/"
const UI_DIRECTORY: String = AUDIO_DIRECTORY + "ui/"

# === AUDIO FILE EXTENSIONS ===
const SUPPORTED_EXTENSIONS: Array = [".wav", ".ogg", ".mp3"]

# === RESOURCE CACHE ===
var _audio_cache: Dictionary = {}  # path → AudioStream
var _loading_queue: Array = []     # Yüklenmeyi bekleyen dosyalar
var _is_loading: bool = false
var _total_resources: int = 0
var _loaded_resources: int = 0

# === SIGNALS ===
signal resource_loaded(resource_path: String, success: bool)
signal loading_progress(loaded: int, total: int, progress: float)
signal loading_completed(success: bool)
signal resource_cache_updated(cache_size: int)

# === LIFECYCLE ===

func _ready() -> void:
	print("AudioResourceManager initialized")
	
	# Audio dizinlerini kontrol et
	_ensure_audio_directories()

# === PUBLIC API ===

func load_audio_resource(resource_name: String, audio_type: String = "sfx") -> AudioStream:
	# UI eşlemesi: ui_button_click -> button_click (dosya adı farklı)
	if audio_type == "ui" and resource_name == "ui_button_click":
		resource_name = "button_click"
	# Müzik eşlemesi: menu_music -> background_music (dosya adı farklı)
	if audio_type == "music" and resource_name == "menu_music":
		resource_name = "background_music"
	# Ses kaynağını yükle (cache'ten veya diskten)
	var resource_path = _get_resource_path(resource_name, audio_type)
	
	# Cache'te var mı kontrol et
	if _audio_cache.has(resource_path):
		return _audio_cache[resource_path]
	
	# Diskten yükle
	var stream = _load_from_disk(resource_path)
	if stream:
		_audio_cache[resource_path] = stream
		resource_cache_updated.emit(_audio_cache.size())
	
	return stream

func preload_audio_resources(resource_list: Array) -> void:
	# Birden fazla ses kaynağını önceden yükle
	for resource_data in resource_list:
		var resource_name = resource_data.get("name", "")
		var audio_type = resource_data.get("type", "sfx")
		var priority = resource_data.get("priority", 0)
		
		if resource_name:
			_loading_queue.append({
				"name": resource_name,
				"type": audio_type,
				"priority": priority
			})
	
	_total_resources = _loading_queue.size()
	_loaded_resources = 0
	
	# Önceliğe göre sırala
	_loading_queue.sort_custom(func(a, b): return a.priority > b.priority)
	
	# Yüklemeyi başlat
	_start_loading()

func get_resource_path(resource_name: String, audio_type: String = "sfx") -> String:
	# Ses kaynağının tam yolunu döndür
	return _get_resource_path(resource_name, audio_type)

func is_resource_loaded(resource_name: String, audio_type: String = "sfx") -> bool:
	# Ses kaynağı yüklendi mi?
	var resource_path = _get_resource_path(resource_name, audio_type)
	return _audio_cache.has(resource_path)

func get_loaded_resources_count() -> int:
	# Yüklenen kaynak sayısı
	return _audio_cache.size()

func clear_cache(keep_essential: bool = true) -> void:
	# Cache'i temizle
	if keep_essential:
		# Temel sesleri sakla
		var essential_resources = []
		for path in _audio_cache:
			if "essential" in path or "ui" in path:
				essential_resources.append(path)
		
		var new_cache = {}
		for path in essential_resources:
			new_cache[path] = _audio_cache[path]
		
		_audio_cache = new_cache
	else:
		_audio_cache.clear()
	
	resource_cache_updated.emit(_audio_cache.size())

func get_cache_info() -> Dictionary:
	# Cache bilgilerini al
	var total_size = 0
	for stream in _audio_cache.values():
		if stream is AudioStreamWAV:
			total_size += stream.data.size()
		elif stream is AudioStreamOggVorbis:
			total_size += stream.data.size()
	
	return {
		"total_resources": _audio_cache.size(),
		"cache_size_bytes": total_size,
		"cache_size_mb": total_size / (1024.0 * 1024.0)
	}

# === PRIVATE METHODS ===

func _ensure_audio_directories() -> void:
	# Audio dizinlerini oluştur (eğer yoksa)
	var dir = DirAccess.open("res://")
	
	if not dir.dir_exists(AUDIO_DIRECTORY):
		dir.make_dir(AUDIO_DIRECTORY)
	
	if not dir.dir_exists(SFX_DIRECTORY):
		dir.make_dir(SFX_DIRECTORY)
	
	if not dir.dir_exists(MUSIC_DIRECTORY):
		dir.make_dir(MUSIC_DIRECTORY)
	
	if not dir.dir_exists(UI_DIRECTORY):
		dir.make_dir(UI_DIRECTORY)
	
	print("Audio directories ensured")

func _get_resource_path(resource_name: String, audio_type: String) -> String:
	# Ses kaynağının tam yolunu oluştur
	var directory = ""
	
	match audio_type:
		"sfx":
			directory = SFX_DIRECTORY
		"music":
			directory = MUSIC_DIRECTORY
		"ui":
			directory = UI_DIRECTORY
		_:
			directory = AUDIO_DIRECTORY
	
	# Uzantıyı kontrol et
	var full_path = directory + resource_name
	
	# Uzantı yoksa, desteklenen uzantılardan birini dene
	if not _has_extension(resource_name):
		for ext in SUPPORTED_EXTENSIONS:
			var test_path = full_path + ext
			if ResourceLoader.exists(test_path):
				return test_path
	
	return full_path

func _has_extension(filename: String) -> bool:
	# Dosya adında uzantı var mı?
	for ext in SUPPORTED_EXTENSIONS:
		if filename.ends_with(ext):
			return true
	return false

func _load_from_disk(resource_path: String) -> AudioStream:
	# Diskten ses kaynağını yükle
	if not ResourceLoader.exists(resource_path):
		print("Audio resource not found: %s" % resource_path)
		return null
	
	var stream = ResourceLoader.load(resource_path, "AudioStream")
	if stream:
		print("Loaded audio resource: %s" % resource_path)
		return stream
	else:
		print("Failed to load audio resource: %s" % resource_path)
	
	return null

func _start_loading() -> void:
	# Yükleme işlemini başlat
	if _is_loading or _loading_queue.is_empty():
		return
	
	_is_loading = true
	
	# Async olarak yükle
	call_deferred("_load_next_resource")

func _load_next_resource() -> void:
	# Sıradaki kaynağı yükle
	if _loading_queue.is_empty():
		_is_loading = false
		loading_completed.emit(true)
		return
	
	var resource_data = _loading_queue.pop_front()
	var resource_name = resource_data.name
	var audio_type = resource_data.type
	
	var stream = load_audio_resource(resource_name, audio_type)
	var success = stream != null
	
	resource_loaded.emit(resource_name, success)
	
	if success:
		_loaded_resources += 1
	
	# Progress güncelle
	var progress = float(_loaded_resources) / float(_total_resources) if _total_resources > 0 else 0.0
	loading_progress.emit(_loaded_resources, _total_resources, progress)
	
	# Bir sonraki frame'de devam et
	await get_tree().process_frame
	_load_next_resource()

# === DEBUG ===

func print_cache_info() -> void:
	var info = get_cache_info()
	print("=== AudioResourceManager Cache Info ===")
	print("Total Resources: %d" % info.total_resources)
	print("Cache Size: %.2f MB" % info.cache_size_mb)
	
	print("\nLoaded Resources:")
	for path in _audio_cache:
		print("  %s" % path.get_file())

func _to_string() -> String:
	return "[AudioResourceManager: %d resources cached]" % _audio_cache.size()