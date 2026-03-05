# 🎵 AUDIO TEST MODULE (ORGANISM) - GÜNCELLENDİ!
# Yeni modüler AudioSystem testleri için test modülü
# Atomic Design: Organism (AudioTestOrganism + UITestBase)
class_name AudioTestModule extends UITestBase

# === DEPENDENCIES ===
@onready var audio_test_organism: AudioTestOrganism = $AudioTestOrganism

# === STATE (test_results, is_testing parent UITestBase'den) ===

# === SIGNALS ===
signal audio_test_module_initialized
signal audio_test_module_completed(results: Dictionary)
signal audio_test_module_progress(progress: float, message: String)

# === LIFECYCLE ===

func _ready() -> void:
	print("AudioTestModule initializing (NEW MODULAR VERSION)...")
	
	# Test base'i initialize et
	super._ready()
	
	# AudioTestOrganism'i bul
	if not audio_test_organism:
		push_warning("AudioTestOrganism not found!")
		return
	
	# AudioTestOrganism event'lerini bağla
	_connect_audio_test_organism_events()
	
	# AudioSystem'i bul ve testlere set et
	_find_and_set_audio_system()
	
	print("AudioTestModule initialized successfully (Modular)")
	audio_test_module_initialized.emit()

# === PUBLIC API ===

func run_all_tests() -> void:
	"""Tüm audio testlerini çalıştır"""
	if is_testing:
		return
	
	print("\n=== RUNNING MODULAR AUDIO TESTS ===")
	
	is_testing = true
	test_results.clear()
	
	# AudioTestOrganism üzerinden testleri çalıştır
	audio_test_organism.run_all_tests()
	
	# Testler tamamlandığında _on_test_suite_completed'da is_testing=false yapılacak

func run_specific_test_category(category_name: String) -> Dictionary:
	"""Belirli bir test kategorisini çalıştır"""
	if is_testing:
		return {"success": false, "error": "Already testing"}
	
	# Category name'den enum'a çevir
	var category = _get_category_from_name(category_name)
	if category == null:
		return {"success": false, "error": "Invalid category name: %s" % category_name}
	
	print("\n=== RUNNING SPECIFIC AUDIO TEST: %s ===" % category_name)
	
	is_testing = true
	
	# Belirli testi çalıştır (coroutine - await gerekli)
	var test_result = await audio_test_organism.run_specific_test(category)
	
	is_testing = false
	
	return {
		"success": test_result.status == TestBaseAtom.TestStatus.PASSED if test_result else false,
		"data": test_result.to_dictionary() if test_result else {}
	}

func get_test_results() -> Dictionary:
	"""Test sonuçlarını al"""
	return test_results.duplicate(true)

func reset_test_results() -> void:
	"""Test sonuçlarını sıfırla"""
	audio_test_organism.reset_test_results()
	test_results.clear()
	print("AudioTestModule: Test results reset")

func set_audio_system(audio_system: Node) -> void:
	"""AudioSystem referansını ayarla"""
	if audio_test_organism:
		audio_test_organism.set_audio_system_for_all_tests(audio_system)
		print("AudioTestModule: AudioSystem set for all tests")

func enable_test_category(category_name: String, enabled: bool) -> void:
	"""Test kategorisini etkinleştir/devre dışı bırak"""
	var category = _get_category_from_name(category_name)
	if category != null and audio_test_organism:
		audio_test_organism.enable_test_category(category, enabled)
		print("AudioTestModule: Category %s %s" % [category_name, "enabled" if enabled else "disabled"])

# === PRIVATE METHODS ===

func _connect_audio_test_organism_events() -> void:
	"""AudioTestOrganism event'lerini bağla"""
	if not audio_test_organism:
		return
	
	audio_test_organism.audio_test_suite_started.connect(_on_test_suite_started)
	audio_test_organism.audio_test_started.connect(_on_test_started)
	audio_test_organism.audio_test_completed.connect(_on_test_completed)
	audio_test_organism.audio_test_progress.connect(_on_test_progress)
	audio_test_organism.audio_test_suite_completed.connect(_on_test_suite_completed)
	audio_test_organism.audio_test_summary_ready.connect(_on_test_summary_ready)

func _find_and_set_audio_system() -> void:
	"""AudioSystem'i bul ve testlere set et"""
	# Scene'de AudioSystem'i ara
	var audio_systems = get_tree().get_nodes_in_group("audio_system")
	if audio_systems.size() > 0:
		var audio_system = audio_systems[0]
		set_audio_system(audio_system)
		print("AudioTestModule: AudioSystem found and set: %s" % audio_system.name)
	else:
		print("AudioTestModule: Warning - AudioSystem not found in scene")

func _get_category_from_name(category_name: String) -> int:
	"""Category name'den enum değerini al"""
	var category_dict = {
		"initialization": AudioTestMolecule.AudioTestCategory.INITIALIZATION,
		"sound_effects": AudioTestMolecule.AudioTestCategory.SOUND_EFFECTS,
		"music_system": AudioTestMolecule.AudioTestCategory.MUSIC_SYSTEM,
		"volume_controls": AudioTestMolecule.AudioTestCategory.VOLUME_CONTROLS,
		"spatial_audio": AudioTestMolecule.AudioTestCategory.SPATIAL_AUDIO,
		"audio_pooling": AudioTestMolecule.AudioTestCategory.AUDIO_POOLING,
		"ui_integration": AudioTestMolecule.AudioTestCategory.UI_INTEGRATION,
		"event_bus": AudioTestMolecule.AudioTestCategory.EVENT_BUS
	}
	
	return category_dict.get(category_name.to_lower())

# === EVENT HANDLERS ===

func _on_test_suite_started(total_tests: int) -> void:
	# Test suite başladı
	print("AudioTestModule: Test suite started with %d tests" % total_tests)
	audio_test_module_progress.emit(0.0, "Test suite starting...")

func _on_test_started(category: AudioTestMolecule.AudioTestCategory, test_name: String) -> void:
	# Test başladı
	var category_name = AudioTestMolecule.AudioTestCategory.keys()[category]
	print("AudioTestModule: Test started - %s: %s" % [category_name, test_name])

func _on_test_completed(category: AudioTestMolecule.AudioTestCategory, result: TestBaseAtom.TestResult) -> void:
	# Test tamamlandı
	var category_name = AudioTestMolecule.AudioTestCategory.keys()[category]
	var status_str = TestBaseAtom.TestStatus.keys()[result.status]
	
	print("AudioTestModule: Test completed - %s: %s (%d ms)" % [
		category_name,
		status_str,
		result.duration_ms
	])

func _on_test_progress(category: AudioTestMolecule.AudioTestCategory, progress: float, message: String) -> void:
	# Test progress
	audio_test_module_progress.emit(progress, message)

func _on_test_suite_completed(total_tests: int, passed_tests: int, failed_tests: int, total_duration_ms: int) -> void:
	# Test suite tamamlandı
	is_testing = false
	print("AudioTestModule: Test suite completed")
	print("  Total: %d, Passed: %d, Failed: %d, Duration: %d ms" % [
		total_tests,
		passed_tests,
		failed_tests,
		total_duration_ms
	])

func _on_test_summary_ready(summary: Dictionary) -> void:
	# Test summary hazır
	test_results = summary
	print("AudioTestModule: Test summary ready")

# === TEST ORCHESTRATOR INTEGRATION ===

func run_module_tests() -> Dictionary:
	"""Test orchestrator için module testlerini çalıştır"""
	print("Running AudioTestModule (Modular)...")
	run_all_tests()
	return {"success": true, "message": "Tests started"}

func get_module_info() -> Dictionary:
	"""Module info for test orchestrator"""
	return {
		"module_name": "AudioSystem",
		"version": "2.0.0",  # Yeni modüler versiyon
		"test_count": 8,
		"test_types": ["unit", "integration", "performance", "ui"],
		"description": "Modüler AudioSystem testleri - Yeni atomic design yapısı",
		"dependencies": ["AudioTestOrganism", "AudioTestMolecule", "TestBaseAtom"],
		"features": [
			"Initialization tests",
			"Sound effects playback",
			"Music system functionality", 
			"Volume controls testing",
			"Spatial audio testing",
			"Audio pooling performance",
			"UI integration testing",
			"EventBus integration testing"
		]
	}

# === DEBUG ===

func _to_string() -> String:
	var summary = audio_test_organism.get_test_summary() if audio_test_organism else {}
	return "[AudioTestModule (Modular): Tests: %d, Passed: %d, Failed: %d]" % [
		summary.get("total_tests", 0),
		summary.get("passed_tests", 0),
		summary.get("failed_tests", 0)
	]

func print_debug_info() -> void:
	print("=== AudioTestModule Debug (Modular) ===")
	print("Is Testing: %s" % str(is_testing))
	print("AudioTestOrganism: %s" % ("Available" if audio_test_organism else "Not found"))
	
	if audio_test_organism:
		print("\nAudioTestOrganism Info:")
		audio_test_organism.print_debug_info()
	
	print("\nTest Results:")
	for key in test_results:
		if key != "test_results":  # test_results iç içe dictionary
			print("  %s: %s" % [key, str(test_results[key])])