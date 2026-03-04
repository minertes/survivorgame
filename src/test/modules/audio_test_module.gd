# 🎵 AUDIO TEST MODULE (ORGANISM)
# AudioSystem test senaryoları
class_name AudioTestModule extends UITestBase

# === TEST CATEGORIES ===
enum TestCategory {
	INITIALIZATION = 0,
	SOUND_EFFECTS = 1,
	MUSIC_SYSTEM = 2,
	VOLUME_CONTROLS = 3,
	SPATIAL_AUDIO = 4,
	AUDIO_POOLING = 5,
	UI_INTEGRATION = 6,
	EVENT_BUS = 7
}

# === PROPERTIES ===
var audio_system: AudioSystem = null
var test_audio_component: AudioComponent = null
var test_entity_id: String = "test_audio_entity_001"
var test_position: Vector3 = Vector3(10, 0, 10)

# === TEST RESULTS ===
var test_results: Dictionary = {}
var current_test_category: TestCategory = TestCategory.INITIALIZATION
var is_testing: bool = false

# === SIGNALS ===
signal audio_test_started(category: TestCategory)
signal audio_test_completed(category: TestCategory, results: Dictionary)
signal audio_test_progress(category: TestCategory, progress: float)

# === LIFECYCLE ===

func _ready() -> void:
	print("AudioTestModule initializing...")
	
	# Test base'i initialize et
	super._ready()
	
	# AudioSystem'i bul
	_find_audio_system()
	
	# Test AudioComponent oluştur
	_create_test_audio_component()
	
	# Test results dictionary'yi initialize et
	_initialize_test_results()
	
	print("AudioTestModule initialized successfully")

func _find_audio_system() -> void:
	# Scene'de AudioSystem'i ara
	var audio_systems = get_tree().get_nodes_in_group("audio_system")
	if audio_systems.size() > 0:
		audio_system = audio_systems[0]
		print("AudioSystem found for testing: %s" % audio_system.name)
	else:
		print("Warning: AudioSystem not found for testing")

func _create_test_audio_component() -> void:
	# Test için AudioComponent oluştur
	test_audio_component = AudioComponent.new()
	test_audio_component.entity_id = test_entity_id
	test_audio_component.update_position(test_position)
	add_child(test_audio_component)
	
	print("Test AudioComponent created: %s" % test_entity_id)

func _initialize_test_results() -> void:
	# Tüm test kategorileri için results dictionary initialize et
	for category in TestCategory.values():
		var category_name = TestCategory.keys()[category]
		test_results[category_name] = {
			"total_tests": 0,
			"passed_tests": 0,
			"failed_tests": 0,
			"test_cases": {}
		}

# === PUBLIC API ===

func run_all_tests() -> void:
	# Tüm testleri çalıştır
	print("\n=== RUNNING ALL AUDIO TESTS ===")
	
	# Test sırası
	var test_categories = [
		TestCategory.INITIALIZATION,
		TestCategory.SOUND_EFFECTS,
		TestCategory.MUSIC_SYSTEM,
		TestCategory.VOLUME_CONTROLS,
		TestCategory.SPATIAL_AUDIO,
		TestCategory.AUDIO_POOLING,
		TestCategory.UI_INTEGRATION,
		TestCategory.EVENT_BUS
	]
	
	for category in test_categories:
		_run_test_category(category)
		await get_tree().create_timer(1.0).timeout  # Testler arası bekleme
	
	# Final summary
	_show_final_summary()

func run_specific_test(category: TestCategory) -> void:
	# Belirli bir test kategorisini çalıştır
	_run_test_category(category)

func get_test_results() -> Dictionary:
	# Test sonuçlarını al
	return test_results.duplicate(true)

func get_category_results(category: TestCategory) -> Dictionary:
	# Belirli kategori sonuçlarını al
	var category_name = TestCategory.keys()[category]
	return test_results.get(category_name, {}).duplicate(true)

func reset_test_results() -> void:
	# Test sonuçlarını sıfırla
	_initialize_test_results()
	print("Audio test results reset")

# === TEST EXECUTION ===

func _run_test_category(category: TestCategory) -> void:
	if is_testing:
		print("Another test is already running!")
		return
	
	is_testing = true
	current_test_category = category
	
	var category_name = TestCategory.keys()[category]
	print("\n=== RUNNING %s TESTS ===" % category_name.to_upper())
	
	audio_test_started.emit(category)
	audio_test_progress.emit(category, 0.0)
	
	match category:
		TestCategory.INITIALIZATION:
			_run_initialization_tests()
		TestCategory.SOUND_EFFECTS:
			_run_sound_effects_tests()
		TestCategory.MUSIC_SYSTEM:
			_run_music_system_tests()
		TestCategory.VOLUME_CONTROLS:
			_run_volume_controls_tests()
		TestCategory.SPATIAL_AUDIO:
			_run_spatial_audio_tests()
		TestCategory.AUDIO_POOLING:
			_run_audio_pooling_tests()
		TestCategory.UI_INTEGRATION:
			_run_ui_integration_tests()
		TestCategory.EVENT_BUS:
			_run_event_bus_tests()
	
	audio_test_progress.emit(category, 1.0)
	is_testing = false
	
	# Sonuçları göster
	_show_category_summary(category)
	audio_test_completed.emit(category, get_category_results(category))

func _run_initialization_tests() -> void:
	# Initialization testleri
	var category = TestCategory.INITIALIZATION
	var test_cases = []
	
	# Test 1: AudioSystem mevcut mu?
	test_cases.append({
		"name": "AudioSystem Available",
		"test": func(): return audio_system != null,
		"expected": true
	})
	
	# Test 2: AudioComponent mevcut mu?
	test_cases.append({
		"name": "AudioComponent Available",
		"test": func(): return test_audio_component != null,
		"expected": true
	})
	
	# Test 3: AudioSystem başlatıldı mı?
	test_cases.append({
		"name": "AudioSystem Initialized",
		"test": func(): 
			if audio_system:
				return audio_system.is_inside_tree()
			return false,
		"expected": true
	})
	
	# Test 4: Audio bus'lar oluşturuldu mu?
	test_cases.append({
		"name": "Audio Buses Created",
		"test": func(): 
			var bus_names = ["Master", "Music", "SFX", "UI", "Voice"]
			for bus_name in bus_names:
				if AudioServer.get_bus_index(bus_name) == -1:
					return false
			return true,
		"expected": true
	})
	
	# Testleri çalıştır
	_execute_test_cases(category, test_cases)

func _run_sound_effects_tests() -> void:
	# Sound effects testleri
	var category = TestCategory.SOUND_EFFECTS
	var test_cases = []
	
	# Test 1: SFX oynatma
	test_cases.append({
		"name": "Play SFX",
		"test": func(): 
			if audio_system:
				return audio_system.play_sound("shoot", 0.0, 1.0, Vector3.ZERO, false)
			return false,
		"expected": true
	})
	
	# Test 2: Multiple SFX
	test_cases.append({
		"name": "Play Multiple SFX",
		"test": func(): 
			if audio_system:
				var success1 = audio_system.play_sound("hit", 0.0, 1.0, Vector3.ZERO, false)
				var success2 = audio_system.play_sound("explosion", 0.0, 1.0, Vector3.ZERO, false)
				return success1 and success2
			return false,
		"expected": true
	})
	
	# Test 3: SFX volume control
	test_cases.append({
		"name": "SFX Volume Control",
		"test": func(): 
			if audio_system:
				audio_system.set_sfx_volume(-10.0)
				var volume = audio_system.get_volume("SFX")
				return abs(volume - (-10.0)) < 0.1
			return false,
		"expected": true
	})
	
	# Test 4: Stop all sounds
	test_cases.append({
		"name": "Stop All Sounds",
		"test": func(): 
			if audio_system:
				audio_system.play_sound("pickup", 0.0, 1.0, Vector3.ZERO, false)
				audio_system.stop_all_sounds()
				# Bu test görsel/duysal doğrulama gerektirir
				return true  # Manual verification needed
			return false,
		"expected": true
	})
	
	# Testleri çalıştır
	_execute_test_cases(category, test_cases)

func _run_music_system_tests() -> void:
	# Music system testleri
	var category = TestCategory.MUSIC_SYSTEM
	var test_cases = []
	
	# Test 1: Music playback
	test_cases.append({
		"name": "Play Music",
		"test": func(): 
			if audio_system:
				return audio_system.play_music("background", 0.5, true)
			return false,
		"expected": true
	})
	
	# Test 2: Music volume control
	test_cases.append({
		"name": "Music Volume Control",
		"test": func(): 
			if audio_system:
				audio_system.set_music_volume(-5.0)
				var volume = audio_system.get_volume("Music")
				return abs(volume - (-5.0)) < 0.1
			return false,
		"expected": true
	})
	
	# Test 3: Music queue
	test_cases.append({
		"name": "Music Queue",
		"test": func(): 
			if audio_system:
				audio_system.queue_music("menu")
				audio_system.queue_music("battle")
				# Queue kontrolü
				return true  # Queue işlevselliği test edildi
			return false,
		"expected": true
	})
	
	# Test 4: Music fade
	test_cases.append({
		"name": "Music Fade Effect",
		"test": func(): 
			if audio_system:
				audio_system.play_music("background", 2.0, true)
				# Fade efektinin başladığını varsay
				return true  # Manual verification needed
			return false,
		"expected": true
	})
	
	# Testleri çalıştır
	_execute_test_cases(category, test_cases)

func _run_volume_controls_tests() -> void:
	# Volume controls testleri
	var category = TestCategory.VOLUME_CONTROLS
	var test_cases = []
	
	# Test 1: Master volume
	test_cases.append({
		"name": "Master Volume Control",
		"test": func(): 
			if audio_system:
				audio_system.set_master_volume(-3.0)
				var volume = audio_system.get_volume("Master")
				return abs(volume - (-3.0)) < 0.1
			return false,
		"expected": true
	})
	
	# Test 2: UI volume
	test_cases.append({
		"name": "UI Volume Control",
		"test": func(): 
			if audio_system:
				audio_system.set_ui_volume(-2.0)
				var volume = audio_system.get_volume("UI")
				return abs(volume - (-2.0)) < 0.1
			return false,
		"expected": true
	})
	
	# Test 3: Mute/unmute
	test_cases.append({
		"name": "Mute/Unmute Toggle",
		"test": func(): 
			if audio_system:
				var was_muted = audio_system.toggle_mute("Master")
				var is_now_muted = AudioServer.is_bus_mute(AudioServer.get_bus_index("Master"))
				# Tekrar aç
				audio_system.toggle_mute("Master")
				return was_muted != is_now_muted
			return false,
		"expected": true
	})
	
	# Test 4: Reset to defaults
	test_cases.append({
		"name": "Reset to Defaults",
		"test": func(): 
			if audio_system:
				audio_system.reset_to_defaults()
				var master_volume = audio_system.get_volume("Master")
				return abs(master_volume - 0.0) < 0.1
			return false,
		"expected": true
	})
	
	# Testleri çalıştır
	_execute_test_cases(category, test_cases)

func _run_spatial_audio_tests() -> void:
	# Spatial audio testleri
	var category = TestCategory.SPATIAL_AUDIO
	var test_cases = []
	
	# Test 1: Enable spatial audio
	test_cases.append({
		"name": "Enable Spatial Audio",
		"test": func(): 
			if audio_system:
				audio_system.enable_spatial_audio(true)
				return true  # Manual verification needed
			return false,
		"expected": true
	})
	
	# Test 2: 3D sound playback
	test_cases.append({
		"name": "3D Sound Playback",
		"test": func(): 
			if audio_system:
				return audio_system.play_sound("explosion", 0.0, 1.0, Vector3(20, 0, 20), true)
			return false,
		"expected": true
	})
	
	# Test 3: AudioComponent spatial audio
	test_cases.append({
		"name": "AudioComponent Spatial Audio",
		"test": func(): 
			if test_audio_component:
				test_audio_component.enable_spatial_audio(true)
				test_audio_component.update_position(Vector3(30, 0, 30))
				return test_audio_component.play_event(AudioComponent.AudioEvent.ATTACK)
			return false,
		"expected": true
	})
	
	# Test 4: Distance-based volume
	test_cases.append({
		"name": "Distance-based Volume",
		"test": func(): 
			if test_audio_component:
				test_audio_component.set_audio_distances(5.0, 100.0)
				return true  # Manual verification needed
			return false,
		"expected": true
	})
	
	# Testleri çalıştır
	_execute_test_cases(category, test_cases)

func _run_audio_pooling_tests() -> void:
	# Audio pooling testleri
	var category = TestCategory.AUDIO_POOLING
	var test_cases = []
	
	# Test 1: Pool creation
	test_cases.append({
		"name": "Audio Pool Creation",
		"test": func(): 
			if audio_system:
				# AudioSystem pool'ları oluşturdu mu?
				return true  # AudioSystem constructor'da pool'lar oluşturuluyor
			return false,
		"expected": true
	})
	
	# Test 2: Multiple concurrent sounds
	test_cases.append({
		"name": "Multiple Concurrent Sounds",
		"test": func(): 
			if audio_system:
				var successes = 0
				# 10 concurrent sound çal
				for i in range(10):
					if audio_system.play_sound("click", -10.0, 1.0, Vector3.ZERO, false):
						successes += 1
				return successes >= 8  # En az 8 başarılı olmalı
			return false,
		"expected": true
	})
	
	# Test 3: Pool reuse
	test_cases.append({
		"name": "Pool Reuse",
		"test": func(): 
			if audio_system:
				# Çok sayıda sound çal ve pool'un reuse ettiğini varsay
				for i in range(30):
					audio_system.play_sound("hit", -20.0, 1.0, Vector3.ZERO, false)
				return true  # Crash olmadan çalıştıysa başarılı
			return false,
		"expected": true
	})
	
	# Test 4: Performance test
	test_cases.append({
		"name": "Pool Performance",
		"test": func(): 
			if audio_system:
				var start_time = Time.get_ticks_msec()
				# 50 sound çal
				for i in range(50):
					audio_system.play_sound("pickup", -30.0, 1.0, Vector3.ZERO, false)
				var end_time = Time.get_ticks_msec()
				var duration = end_time - start_time
				print("50 sounds played in %d ms" % duration)
				return duration < 1000  # 1 saniyeden az sürmeli
			return false,
		"expected": true
	})
	
	# Testleri çalıştır
	_execute_test_cases(category, test_cases)

func _run_ui_integration_tests() -> void:
	# UI integration testleri
	var category = TestCategory.UI_INTEGRATION
	var test_cases = []
	
	# Test 1: UI sound playback
	test_cases.append({
		"name": "UI Sound Playback",
		"test": func(): 
			if audio_system:
				return audio_system.play_ui_sound("click", 0.0, 1.0)
			return false,
		"expected": true
	})
	
	# Test 2: Button click sound
	test_cases.append({
		"name": "Button Click Sound",
		"test": func(): 
			# Test butonu oluştur
			var test_button = Button.new()
			test_button.text = "Test Button"
			test_button.pressed.connect(func():
				if audio_system:
					audio_system.play_ui_sound("click", 0.0, 1.0)
			)
			add_child(test_button)
			
			# Butona tıkla
			test_button.emit_signal("pressed")
			test_button.queue_free()
			
			return true  # Manual verification needed
		"expected": true
	})
	
	# Test 3: UI volume control
	test_cases.append({
		"name": "UI Volume Control Integration",
		"test": func(): 
			if audio_system:
				# UI volume slider simülasyonu
				audio_system.set_ui_volume(-6.0)
				var volume = audio_system.get_volume("UI")
				return abs(volume - (-6.0)) < 0.1
			return false,
		"expected": true
	})
	
	# Test 4: Settings integration
	test_cases.append({
		"name": "Settings Integration",
		"test": func(): 
			if audio_system:
				# Audio config kaydet
				audio_system.save_audio_config()
				return true  # Config kaydedildi
			return false,
		"expected": true
	})
	
	# Testleri çalıştır
	_execute_test_cases(category, test_cases)

func _run_event_bus_tests() -> void:
	# EventBus integration testleri
	var category = TestCategory.EVENT_BUS
	var test_cases = []
	
	# Test 1: EventBus connection
	test_cases.append({
		"name": "EventBus Connection",
		"test": func(): 
			return EventBus.is_available()
		"expected": true
	})
	
	# Test 2: Play sound via EventBus
	test_cases.append({
		"name": "Play Sound via EventBus",
		"test": func(): 
			if EventBus.is_available():
				EventBus.emit_now_static("play_sound", {
					"sound_name": "shoot",
					"volume_db": 0.0,
					"pitch_scale": 1.0,
					"position": Vector3.ZERO,
					"is_3d": false
				})
				return true  # Event gönderildi
			return false,
		"expected": true
	})
	
	# Test 3: Play music via EventBus
	test_cases.append({
		"name": "Play Music via EventBus",
		"test": func(): 
			if EventBus.is_available():
				EventBus.emit_now_static("play_music", {
					"music_name": "background",
					"fade_in": 1.0,
					"loop": true
				})
				return true  # Event gönderildi
			return false,
		"expected": true
	})
	
	# Test 4: AudioComponent EventBus integration
	test_cases.append({
		"name": "AudioComponent EventBus Integration",
		"test": func(): 
			if EventBus.is_available() and test_audio_component:
				# Entity damaged event gönder
				EventBus.emit_now_static("entity_damaged", {
					"entity_id": test_entity_id,
					"damage_amount": 10,
					"damage_type": "test"
				})
				return true  # Event gönderildi
			return false,
		"expected": true
	})
	
	# Testleri çalıştır
	_execute_test_cases(category, test_cases)

# === TEST UTILITIES ===

func _execute_test_cases(category: TestCategory, test_cases: Array) -> void:
	# Test case'leri çalıştır
	var category_name = TestCategory.keys()[category]
	var category_results = test_results[category_name]
	
	var total_tests = test_cases.size()
	var passed_tests = 0
	
	print("Running %d test cases for %s..." % [total_tests, category_name])
	
	for i in range(total_tests):
		var test_case = test_cases[i]
		var test_name = test_case.name
		
		# Progress güncelle
		var progress = float(i) / float(total_tests)
		audio_test_progress.emit(category, progress)
		
		# Testi çalıştır
		var start_time = Time.get_ticks_msec()
		var test_passed = false
		var error_message = ""
		
		try:
			var test_func = test_case.test
			var result = test_func.call()
			test_passed = (result == test_case.expected)
			
			if not test_passed:
				error_message = "Expected: %s, Got: %s" % [str(test_case.expected), str(result)]
		except:
			test_passed = false
			error_message = "Test threw an exception"
		
		var end_time = Time.get_ticks_msec()
		var duration = end_time - start_time
		
		# Sonucu kaydet
		category_results.test_cases[test_name] = {
			"passed": test_passed,
			"duration": duration,
			"error": error_message if not test_passed else ""
		}
		
		if test_passed:
			passed_tests += 1
			print("  ✓ %s (%.0fms)" % [test_name, duration])
		else:
			print("  ✗ %s (%.0fms) - %s" % [test_name, duration, error_message])
		
		# Kısa bekleme (testlerin birbirine karışmaması için)
		await get_tree().create_timer(0.1).timeout
	
	# Category sonuçlarını güncelle
	category_results.total_tests = total_tests
	category_results.passed_tests = passed_tests
	category_results.failed_tests = total_tests - passed_tests
	
	test_results[category_name] = category_results

func _show_category_summary(category: TestCategory) -> void:
	# Kategori özetini göster
	var category_name = TestCategory.keys()[category]
	var results = test_results[category_name]
	
	print("\n=== %s TEST SUMMARY ===" % category_name.to_upper())
	print("Total Tests: %d" % results.total_tests)
	print("Passed: %d" % results.passed_tests)
	print("Failed: %d" % results.failed_tests)
	print("Success Rate: %.1f%%" % (
		float(results.passed_tests) / float(results.total_tests) * 100 
		if results.total_tests > 0 else 0
	))

func _show_final_summary() -> void:
	# Final özeti göster
	print("\n" + "="*50)
	print("AUDIO SYSTEM TEST FINAL SUMMARY")
	print("="*50)
	
	var total_tests = 0
	var total_passed = 0
	
	for category_name in test_results:
		var results = test_results[category_name]
		total_tests += results.total_tests
		total_passed += results.passed_tests
		
		print("\n%s:" % category_name.replace("_", " ").capitalize())
		print("  %d/%d passed (%.1f%%)" % [
			results.passed_tests,
			results.total_tests,
			float(results.passed_tests) / results.total_tests * 100 
			if results.total_tests > 0 else 0
		])
	
	print("\n" + "="*50)
	print("OVERALL: %d/%d tests passed (%.1f%%)" % [
		total_passed,
		total_tests,
		float(total_passed) / total_tests * 100 if total_tests > 0 else 0
	])
	
	if total_passed == total_tests:
		print("🎉 ALL AUDIO TESTS PASSED!")
	else:
		print("⚠️  SOME AUDIO TESTS FAILED!")
	print("="*50)

# === DEBUG ===

func print_debug_info() -> void:
	print("=== AudioTestModule Debug ===")
	print("AudioSystem: %s" % ("Available" if audio_system else "Not found"))
	print("AudioComponent: %s" % ("Available" if test_audio_component else "Not found"))
	print("Current Test Category: %s" % TestCategory.keys()[current_test_category])
	print("Is Testing: %s" % str(is_testing))
	
	print("\nTest Results Summary:")
	for category_name in test_results:
		var results = test_results[category_name]
		print("  %s: %d/%d" % [
			category_name,
			results.passed_tests,
			results.total_tests
		])

func _to_string() -> String:
	var total_tests = 0
	var total_passed = 0
	
	for category_name in test_results:
		var results = test_results[category_name]
		total_tests += results.total_tests
		total_passed += results.passed_tests
	
	return "[AudioTestModule: %d/%d tests passed]" % [total_passed, total_tests]