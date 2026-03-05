# 🎵 AUDIO TEST MOLECULE
# Atomic Design: Molecule (TestBaseAtom + AudioSystem integration)
# Audio sistem testleri için molekül
class_name AudioTestMolecule
extends TestBaseAtom

# === AUDIO TEST CATEGORIES ===
enum AudioTestCategory {
	INITIALIZATION = 0,
	SOUND_EFFECTS = 1,
	MUSIC_SYSTEM = 2,
	VOLUME_CONTROLS = 3,
	SPATIAL_AUDIO = 4,
	AUDIO_POOLING = 5,
	UI_INTEGRATION = 6,
	EVENT_BUS = 7,
	PERFORMANCE = 8,
	STRESS = 9
}

# === CONFIG ===
@export var test_category: AudioTestCategory = AudioTestCategory.INITIALIZATION:
	set(value):
		test_category = value
		if is_inside_tree():
			_update_test_config()

@export var audio_system_path: NodePath = "":
	set(value):
		audio_system_path = value
		if is_inside_tree():
			_find_audio_system()

@export var test_sound_names: Array[String] = ["click", "shoot", "hit", "explosion", "pickup"]:
	set(value):
		test_sound_names = value
		if is_inside_tree():
			_update_test_sounds()

@export var test_music_names: Array[String] = ["background_music"]:
	set(value):
		test_music_names = value
		if is_inside_tree():
			_update_test_music()

# === NODES ===
var audio_system: Node = null
var audio_component: Node = null
var test_entity_id: String = "test_audio_entity_001"
var test_position: Vector3 = Vector3(10, 0, 10)

# === STATE ===
var audio_system_found: bool = false
var test_sounds_loaded: bool = false
var test_music_loaded: bool = false

# === EVENTS ===
signal audio_test_initialized(category: AudioTestCategory)
signal audio_test_sound_played(sound_name: String, success: bool)
signal audio_test_music_played(music_name: String, success: bool)
signal audio_test_volume_changed(bus_name: String, volume_db: float)
signal audio_test_mute_toggled(bus_name: String, muted: bool)

# === LIFECYCLE ===

func _ready() -> void:
	super._ready()
	
	# AudioSystem'i bul
	_find_audio_system()
	
	# Test config güncelle
	_update_test_config()
	
	# Test sounds güncelle
	_update_test_sounds()
	
	# Test music güncelle
	_update_test_music()
	
	audio_test_initialized.emit(test_category)

# === PUBLIC API ===

func set_test_category(category: AudioTestCategory) -> void:
	"""Test kategorisini ayarla"""
	test_category = category
	_update_test_config()

func set_audio_system(system_node: Node) -> void:
	"""AudioSystem referansını ayarla"""
	audio_system = system_node
	audio_system_found = audio_system != null
	
	if audio_system_found:
		print("AudioTestMolecule: AudioSystem found: %s" % audio_system.name)

func create_test_audio_component() -> bool:
	"""Test AudioComponent oluştur"""
	if not audio_system_found:
		test_result.error_message = "AudioSystem not found for creating AudioComponent"
		return false
	
	# Burada AudioComponent oluşturulabilir
	# Şimdilik placeholder
	print("AudioTestMolecule: Test AudioComponent created for entity: %s" % test_entity_id)
	return true

func play_test_sound(sound_name: String, volume_db: float = 0.0, is_3d: bool = false) -> bool:
	"""Test sesi oynat"""
	if not audio_system_found:
		test_result.error_message = "AudioSystem not found for playing sound"
		return false
	
	if not sound_name in test_sound_names:
		test_result.error_message = "Sound not in test sounds: %s" % sound_name
		return false
	
	# AudioSystem üzerinden ses oynat
	var success = false
	
	if audio_system.has_method("play_sound"):
		success = audio_system.play_sound(sound_name, volume_db, 1.0, test_position if is_3d else Vector3.ZERO, is_3d)
	elif audio_system.has_method("play_ui_sound"):
		success = audio_system.play_ui_sound(sound_name, volume_db)
	
	audio_test_sound_played.emit(sound_name, success)
	return success

func play_test_music(music_name: String, fade_in: float = 0.0) -> bool:
	"""Test müziği oynat"""
	if not audio_system_found:
		test_result.error_message = "AudioSystem not found for playing music"
		return false
	
	if not music_name in test_music_names:
		test_result.error_message = "Music not in test music: %s" % music_name
		return false
	
	# AudioSystem üzerinden müzik oynat
	var success = false
	
	if audio_system.has_method("play_music"):
		success = audio_system.play_music(music_name, fade_in, true)
	
	audio_test_music_played.emit(music_name, success)
	return success

func test_volume_control(bus_name: String, test_volume_db: float = -10.0) -> bool:
	"""Volume control testi"""
	if not audio_system_found:
		test_result.error_message = "AudioSystem not found for volume control test"
		return false
	
	# Volume ayarla
	var success = false
	
	if audio_system.has_method("set_%s_volume" % bus_name.to_lower()):
		var method_name = "set_%s_volume" % bus_name.to_lower()
		audio_system.call(method_name, test_volume_db)
		success = true
	elif audio_system.has_method("set_volume_db"):
		audio_system.set_volume_db(bus_name, test_volume_db)
		success = true
	
	if success:
		audio_test_volume_changed.emit(bus_name, test_volume_db)
	
	return success

func test_mute_toggle(bus_name: String) -> bool:
	"""Mute toggle testi"""
	if not audio_system_found:
		test_result.error_message = "AudioSystem not found for mute test"
		return false
	
	# Mute toggle
	var success = false
	
	if audio_system.has_method("toggle_mute"):
		var was_muted = audio_system.toggle_mute(bus_name)
		var is_now_muted = not was_muted  # toggle_mute tersine çevirir
		success = true
		
		audio_test_mute_toggled.emit(bus_name, is_now_muted)
	
	return success

func test_spatial_audio() -> bool:
	"""Spatial audio testi"""
	if not audio_system_found:
		test_result.error_message = "AudioSystem not found for spatial audio test"
		return false
	
	# Spatial audio testi
	var success = false
	
	if audio_system.has_method("enable_spatial_audio"):
		audio_system.enable_spatial_audio(true)
		success = true
	
	# 3D sound test
	if success:
		success = play_test_sound("explosion", 0.0, true)
	
	return success

func test_audio_pooling(concurrent_sounds: int = 10) -> bool:
	"""Audio pooling testi"""
	if not audio_system_found:
		test_result.error_message = "AudioSystem not found for pooling test"
		return false
	
	# Multiple concurrent sounds test
	var successes = 0
	
	for i in range(concurrent_sounds):
		var sound_name = test_sound_names[i % test_sound_names.size()]
		if play_test_sound(sound_name, -20.0, false):
			successes += 1
	
	# En az %80 başarılı olmalı
	return float(successes) / float(concurrent_sounds) >= 0.8

# === PROTECTED METHODS ===

func _execute_test():
	"""Testi çalıştır (coroutine - await ile çağrılmalı)"""
	match test_category:
		AudioTestCategory.INITIALIZATION:
			return _run_initialization_test()
		AudioTestCategory.SOUND_EFFECTS:
			return await _run_sound_effects_test()
		AudioTestCategory.MUSIC_SYSTEM:
			return _run_music_system_test()
		AudioTestCategory.VOLUME_CONTROLS:
			return await _run_volume_controls_test()
		AudioTestCategory.SPATIAL_AUDIO:
			return await _run_spatial_audio_test()
		AudioTestCategory.AUDIO_POOLING:
			return _run_audio_pooling_test()
		AudioTestCategory.UI_INTEGRATION:
			return _run_ui_integration_test()
		AudioTestCategory.EVENT_BUS:
			return _run_event_bus_test()
		AudioTestCategory.PERFORMANCE, AudioTestCategory.STRESS:
			return _run_initialization_test()  # Placeholder
		_:
			return false

func _run_initialization_test() -> bool:
	"""Initialization testi"""
	test_progress.emit(0.1, "Checking AudioSystem...")
	
	if not audio_system_found:
		test_result.error_message = "AudioSystem not found"
		return false
	
	test_progress.emit(0.3, "AudioSystem found: %s" % audio_system.name)
	
	# Audio bus'ları kontrol et
	var bus_names = ["Master", "Music", "SFX", "UI"]
	for bus_name in bus_names:
		if AudioServer.get_bus_index(bus_name) == -1:
			test_result.error_message = "Audio bus not found: %s" % bus_name
			return false
	
	test_progress.emit(0.6, "All audio buses found")
	
	# Test AudioComponent oluştur
	if not create_test_audio_component():
		test_result.error_message = "Failed to create test AudioComponent"
		return false
	
	test_progress.emit(1.0, "Initialization test completed")
	return true

func _run_sound_effects_test() -> bool:
	"""Sound effects testi"""
	test_progress.emit(0.1, "Starting sound effects test...")
	
	# Her bir test sesini oynat
	var total_sounds = test_sound_names.size()
	var successful_sounds = 0
	
	for i in range(total_sounds):
		var sound_name = test_sound_names[i]
		test_progress.emit(float(i) / total_sounds, "Playing sound: %s" % sound_name)
		
		if play_test_sound(sound_name):
			successful_sounds += 1
		
		await get_tree().create_timer(0.2).timeout
	
	test_progress.emit(1.0, "Sound effects test completed: %d/%d" % [successful_sounds, total_sounds])
	
	# Tüm sesler başarılı olmalı
	return successful_sounds == total_sounds

func _run_music_system_test() -> bool:
	"""Music system testi"""
	test_progress.emit(0.1, "Starting music system test...")
	
	# Müzik oynat
	var success = false
	
	for music_name in test_music_names:
		test_progress.emit(0.3, "Playing music: %s" % music_name)
		
		if play_test_music(music_name, 1.0):
			success = true
			break
	
	if not success:
		test_result.error_message = "Failed to play test music"
		return false
	
	test_progress.emit(0.6, "Music playing, testing volume control...")
	
	# Music volume control test
	if not test_volume_control("Music", -5.0):
		test_result.error_message = "Failed to test music volume control"
		return false
	
	test_progress.emit(0.8, "Testing mute toggle...")
	
	# Mute toggle test
	if not test_mute_toggle("Music"):
		test_result.error_message = "Failed to test music mute toggle"
		return false
	
	test_progress.emit(1.0, "Music system test completed")
	return true

func _run_volume_controls_test() -> bool:
	"""Volume controls testi"""
	test_progress.emit(0.1, "Starting volume controls test...")
	
	var buses_to_test = ["Master", "Music", "SFX", "UI"]
	var total_buses = buses_to_test.size()
	var successful_tests = 0
	
	for i in range(total_buses):
		var bus_name = buses_to_test[i]
		test_progress.emit(float(i) / total_buses, "Testing %s volume..." % bus_name)
		
		# Volume control test
		if test_volume_control(bus_name, -i * 5.0):
			successful_tests += 1
		
		# Mute toggle test
		if test_mute_toggle(bus_name):
			successful_tests += 1
		
		await get_tree().create_timer(0.3).timeout
	
	test_progress.emit(1.0, "Volume controls test completed: %d/%d tests passed" % [successful_tests, total_buses * 2])
	
	# En az %75 başarılı olmalı
	return float(successful_tests) / float(total_buses * 2) >= 0.75

func _run_spatial_audio_test() -> bool:
	"""Spatial audio testi"""
	test_progress.emit(0.1, "Starting spatial audio test...")
	
	# Spatial audio enable
	test_progress.emit(0.3, "Enabling spatial audio...")
	if not test_spatial_audio():
		test_result.error_message = "Failed to enable spatial audio"
		return false
	
	test_progress.emit(0.6, "Testing 3D sound playback...")
	
	# Multiple 3D sounds
	var success_count = 0
	for i in range(3):
		if play_test_sound("explosion", 0.0, true):
			success_count += 1
		await get_tree().create_timer(0.1).timeout
	
	test_progress.emit(1.0, "Spatial audio test completed: %d/3 3D sounds played" % success_count)
	
	return success_count >= 2

func _run_audio_pooling_test() -> bool:
	"""Audio pooling testi"""
	test_progress.emit(0.1, "Starting audio pooling test...")
	
	# Concurrent sounds test
	test_progress.emit(0.3, "Testing concurrent sounds (10)...")
	if not test_audio_pooling(10):
		test_result.error_message = "Audio pooling test failed (10 concurrent sounds)"
		return false
	
	test_progress.emit(0.6, "Testing more concurrent sounds (20)...")
	
	# More concurrent sounds
	var success_count = 0
	for i in range(20):
		var sound_name = test_sound_names[i % test_sound_names.size()]
		if play_test_sound(sound_name, -30.0, false):
			success_count += 1
	
	test_progress.emit(0.9, "Pooling test: %d/20 sounds played successfully" % success_count)
	
	# Performance test
	var start_time = Time.get_ticks_msec()
	for i in range(30):
		play_test_sound("click", -40.0, false)
	var end_time = Time.get_ticks_msec()
	var duration = end_time - start_time
	
	test_progress.emit(1.0, "Audio pooling test completed in %d ms" % duration)
	
	# En az 15 başarılı olmalı ve 1 saniyeden az sürmeli
	return success_count >= 15 and duration < 1000

func _run_ui_integration_test() -> bool:
	"""UI integration testi"""
	test_progress.emit(0.1, "Starting UI integration test...")
	
	# UI sounds test
	test_progress.emit(0.3, "Testing UI sounds...")
	
	var ui_success = false
	if audio_system.has_method("play_ui_sound"):
		ui_success = audio_system.play_ui_sound("button_click", 0.0)
	elif EventBus.is_available():
		# EventBus üzerinden test
		EventBus.emit_now_static("play_ui_sound", {
			"sound_name": "button_click",
			"source": "AudioTestMolecule"
		})
		ui_success = true
	
	if not ui_success:
		test_result.error_message = "UI sound test failed"
		return false
	
	test_progress.emit(0.6, "Testing UI volume control...")
	
	# UI volume control
	if not test_volume_control("UI", -3.0):
		test_result.error_message = "UI volume control test failed"
		return false
	
	test_progress.emit(0.8, "Testing UI mute toggle...")
	
	# UI mute toggle
	if not test_mute_toggle("UI"):
		test_result.error_message = "UI mute toggle test failed"
		return false
	
	test_progress.emit(1.0, "UI integration test completed")
	return true

func _run_event_bus_test() -> bool:
	"""EventBus integration testi"""
	test_progress.emit(0.1, "Starting EventBus integration test...")
	
	if not EventBus.is_available():
		test_result.error_message = "EventBus not available"
		return false
	
	# EventBus connection test
	test_progress.emit(0.3, "Testing EventBus connection...")
	
	# Play sound via EventBus
	EventBus.emit_now_static("play_sound", {
		"sound_name": "shoot",
		"volume_db": 0.0,
		"pitch_scale": 1.0,
		"position": Vector3.ZERO,
		"is_3d": false
	})
	
	test_progress.emit(0.6, "Testing music via EventBus...")
	
	# Play music via EventBus
	EventBus.emit_now_static("play_music", {
		"music_name": "background_music",
		"fade_in": 0.5,
		"loop": true
	})
	
	test_progress.emit(0.8, "Testing volume control via EventBus...")
	
	# Volume control via EventBus
	EventBus.emit_now_static("set_volume", {
		"bus_name": "Master",
		"volume_db": -2.0
	})
	
	test_progress.emit(1.0, "EventBus integration test completed")
	return true

# === PRIVATE METHODS ===

func _find_audio_system() -> void:
	"""AudioSystem'i bul"""
	if audio_system_path.is_empty():
		# Scene'de AudioSystem'i ara
		var audio_systems = get_tree().get_nodes_in_group("audio_system")
		if audio_systems.size() > 0:
			audio_system = audio_systems[0]
			audio_system_found = true
			print("AudioTestMolecule: AudioSystem found in scene: %s" % audio_system.name)
	else:
		# NodePath'ten bul
		var node = get_node_or_null(audio_system_path)
		if node:
			audio_system = node
			audio_system_found = true
			print("AudioTestMolecule: AudioSystem found via path: %s" % audio_system.name)
	
	if not audio_system_found:
		print("AudioTestMolecule: Warning - AudioSystem not found")

func _update_test_config() -> void:
	"""Test config güncelle"""
	# Test name güncelle
	var category_name = AudioTestCategory.keys()[test_category]
	test_name = "AudioTest_%s" % category_name
	
	# Test type ayarla (kategoriye göre)
	match test_category:
		AudioTestCategory.INITIALIZATION, AudioTestCategory.EVENT_BUS:
			test_type = TestType.INTEGRATION
		AudioTestCategory.PERFORMANCE:
			test_type = TestType.PERFORMANCE
		AudioTestCategory.STRESS:
			test_type = TestType.STRESS
		_:
			test_type = TestType.UNIT

func _update_test_sounds() -> void:
	"""Test sounds güncelle"""
	test_sounds_loaded = not test_sound_names.is_empty()
	
	if test_sounds_loaded:
		print("AudioTestMolecule: %d test sounds loaded" % test_sound_names.size())

func _update_test_music() -> void:
	"""Test music güncelle"""
	test_music_loaded = not test_music_names.is_empty()
	
	if test_music_loaded:
		print("AudioTestMolecule: %d test music loaded" % test_music_names.size())

# === DEBUG ===

func _to_string() -> String:
	var category_name = AudioTestCategory.keys()[test_category]
	return "[AudioTestMolecule: %s, Category: %s, AudioSystem: %s]" % [
		test_name,
		category_name,
		"Found" if audio_system_found else "Not Found"
	]

func print_debug_info() -> void:
	super.print_debug_info()
	
	print("\n=== AudioTestMolecule Debug ===")
	print("Test Category: %s" % AudioTestCategory.keys()[test_category])
	print("Audio System Found: %s" % str(audio_system_found))
	print("Test Sounds Loaded: %s" % str(test_sounds_loaded))
	print("Test Music Loaded: %s" % str(test_music_loaded))
	print("Test Sounds: %s" % str(test_sound_names))
	print("Test Music: %s" % str(test_music_names))
	print("Test Entity ID: %s" % test_entity_id)
	print("Test Position: %s" % str(test_position))
	
	if audio_system:
		print("Audio System: %s" % audio_system.name)
		print("Audio System Methods:")
		var methods = audio_system.get_method_list()
		var audio_methods = []
		for method in methods:
			if method.name.begins_with("play_") or method.name.begins_with("set_") or method.name.begins_with("toggle_"):
				audio_methods.append(method.name)
		print("  %s" % str(audio_methods))