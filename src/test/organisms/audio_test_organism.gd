# 🎵 AUDIO TEST ORGANISM
# Atomic Design: Organism (AudioTestMolecule x 8 + TestOrchestrator)
# Tüm audio testlerini koordine eden organizma
class_name AudioTestOrganism
extends Node

# === CONFIG ===
@export var run_all_tests_on_ready: bool = false:
	set(value):
		run_all_tests_on_ready = value
		if is_inside_tree():
			_update_auto_run_settings()

@export var test_categories_to_run: Array[AudioTestMolecule.AudioTestCategory] = [
	AudioTestMolecule.AudioTestCategory.INITIALIZATION,
	AudioTestMolecule.AudioTestCategory.SOUND_EFFECTS,
	AudioTestMolecule.AudioTestCategory.MUSIC_SYSTEM,
	AudioTestMolecule.AudioTestCategory.VOLUME_CONTROLS,
	AudioTestMolecule.AudioTestCategory.SPATIAL_AUDIO,
	AudioTestMolecule.AudioTestCategory.AUDIO_POOLING,
	AudioTestMolecule.AudioTestCategory.UI_INTEGRATION,
	AudioTestMolecule.AudioTestCategory.EVENT_BUS
]:
	set(value):
		test_categories_to_run = value
		if is_inside_tree():
			_update_test_categories()

@export var delay_between_tests: float = 1.0:
	set(value):
		delay_between_tests = value
		if is_inside_tree():
			_update_test_timing()

# === NODES ===
@onready var initialization_test: AudioTestMolecule = $InitializationTest
@onready var sound_effects_test: AudioTestMolecule = $SoundEffectsTest
@onready var music_system_test: AudioTestMolecule = $MusicSystemTest
@onready var volume_controls_test: AudioTestMolecule = $VolumeControlsTest
@onready var spatial_audio_test: AudioTestMolecule = $SpatialAudioTest
@onready var audio_pooling_test: AudioTestMolecule = $AudioPoolingTest
@onready var ui_integration_test: AudioTestMolecule = $UIIntegrationTest
@onready var event_bus_test: AudioTestMolecule = $EventBusTest

# === STATE ===
var is_testing: bool = false
var current_test_index: int = 0
var test_results: Dictionary = {}
var total_tests: int = 0
var passed_tests: int = 0
var failed_tests: int = 0
var total_duration_ms: int = 0

# === TEST MOLECULE REFERENCES ===
var test_molecules: Dictionary = {}  # category → molecule

# === EVENTS ===
signal audio_test_suite_started(total_tests: int)
signal audio_test_started(category: AudioTestMolecule.AudioTestCategory, test_name: String)
signal audio_test_completed(category: AudioTestMolecule.AudioTestCategory, result: TestBaseAtom.TestResult)
signal audio_test_progress(category: AudioTestMolecule.AudioTestCategory, progress: float, message: String)
signal audio_test_suite_completed(total_tests: int, passed_tests: int, failed_tests: int, total_duration_ms: int)
signal audio_test_summary_ready(summary: Dictionary)

# === LIFECYCLE ===

func _ready() -> void:
	# Test moleküllerini initialize et
	_initialize_test_molecules()
	
	# Test categories güncelle
	_update_test_categories()
	
	# Auto-run settings güncelle
	_update_auto_run_settings()
	
	# Test timing güncelle
	_update_test_timing()
	
	# Auto-run başlat
	if run_all_tests_on_ready:
		await get_tree().create_timer(1.0).timeout
		run_all_tests()

# === PUBLIC API ===

func run_all_tests() -> void:
	"""Tüm testleri çalıştır"""
	if is_testing:
		print("AudioTestOrganism: Already testing!")
		return
	
	print("\n" + "=".repeat(50))
	print("AUDIO TEST SUITE STARTING")
	print("=".repeat(50))
	
	is_testing = true
	current_test_index = 0
	test_results.clear()
	total_tests = test_categories_to_run.size()
	passed_tests = 0
	failed_tests = 0
	total_duration_ms = 0
	
	audio_test_suite_started.emit(total_tests)
	
	# Testleri sırayla çalıştır
	for i in range(total_tests):
		var category = test_categories_to_run[i]
		current_test_index = i
		
		# Test progress
		var progress = float(i) / float(total_tests)
		audio_test_progress.emit(category, progress, "Starting test %d/%d" % [i + 1, total_tests])
		
		# Testi çalıştır (coroutine - await gerekli)
		var test_result = await _run_single_test(category)
		
		# Sonuçları kaydet
		test_results[category] = test_result
		
		if test_result.status == TestBaseAtom.TestStatus.PASSED:
			passed_tests += 1
		else:
			failed_tests += 1
		
		total_duration_ms += test_result.duration_ms
		
		# Testler arası bekleme
		if i < total_tests - 1 and delay_between_tests > 0:
			await get_tree().create_timer(delay_between_tests).timeout
	
	# Final summary
	_show_final_summary()
	is_testing = false

func run_specific_test(category: AudioTestMolecule.AudioTestCategory) -> TestBaseAtom.TestResult:
	"""Belirli bir test kategorisini çalıştır (caller await etmeli)"""
	if is_testing:
		print("AudioTestOrganism: Cannot run specific test while testing suite")
		return null
	
	print("\n=== RUNNING SPECIFIC TEST: %s ===" % AudioTestMolecule.AudioTestCategory.keys()[category])
	
	is_testing = true
	var test_result = await _run_single_test(category)
	is_testing = false
	
	return test_result

func get_test_results() -> Dictionary:
	"""Tüm test sonuçlarını al"""
	return test_results.duplicate(true)

func get_category_result(category: AudioTestMolecule.AudioTestCategory) -> TestBaseAtom.TestResult:
	"""Belirli kategori sonucunu al"""
	if category in test_results:
		return test_results[category]
	return null

func get_test_summary() -> Dictionary:
	"""Test özetini al"""
	return {
		"total_tests": total_tests,
		"passed_tests": passed_tests,
		"failed_tests": failed_tests,
		"success_rate": float(passed_tests) / float(total_tests) * 100 if total_tests > 0 else 0,
		"total_duration_ms": total_duration_ms,
		"avg_duration_ms": float(total_duration_ms) / float(total_tests) if total_tests > 0 else 0,
		"test_results": test_results.duplicate(true)
	}

func reset_test_results() -> void:
	"""Test sonuçlarını sıfırla"""
	is_testing = false
	current_test_index = 0
	test_results.clear()
	total_tests = 0
	passed_tests = 0
	failed_tests = 0
	total_duration_ms = 0
	
	# Tüm test moleküllerini reset et
	for category in test_molecules:
		var molecule = test_molecules[category]
		if molecule:
			molecule.reset_test()
	
	print("AudioTestOrganism: All test results reset")

func set_audio_system_for_all_tests(audio_system: Node) -> void:
	"""Tüm testler için AudioSystem referansını ayarla"""
	for category in test_molecules:
		var molecule = test_molecules[category]
		if molecule:
			molecule.set_audio_system(audio_system)

func enable_test_category(category: AudioTestMolecule.AudioTestCategory, enabled: bool) -> void:
	"""Test kategorisini etkinleştir/devre dışı bırak"""
	if enabled and not category in test_categories_to_run:
		test_categories_to_run.append(category)
	elif not enabled and category in test_categories_to_run:
		test_categories_to_run.erase(category)
	
	_update_test_categories()

# === PRIVATE METHODS ===

func _initialize_test_molecules() -> void:
	"""Test moleküllerini initialize et"""
	# Test moleküllerini dictionary'e ekle
	test_molecules = {
		AudioTestMolecule.AudioTestCategory.INITIALIZATION: initialization_test,
		AudioTestMolecule.AudioTestCategory.SOUND_EFFECTS: sound_effects_test,
		AudioTestMolecule.AudioTestCategory.MUSIC_SYSTEM: music_system_test,
		AudioTestMolecule.AudioTestCategory.VOLUME_CONTROLS: volume_controls_test,
		AudioTestMolecule.AudioTestCategory.SPATIAL_AUDIO: spatial_audio_test,
		AudioTestMolecule.AudioTestCategory.AUDIO_POOLING: audio_pooling_test,
		AudioTestMolecule.AudioTestCategory.UI_INTEGRATION: ui_integration_test,
		AudioTestMolecule.AudioTestCategory.EVENT_BUS: event_bus_test
	}
	
	# Her bir molekülü initialize et
	for category in test_molecules:
		var molecule = test_molecules[category]
		if molecule:
			molecule.test_category = category
			
			# Event bağlantıları
			molecule.test_started.connect(_on_test_started.bind(category))
			molecule.test_completed.connect(_on_test_completed.bind(category))
			molecule.test_progress.connect(_on_test_progress.bind(category))
			
			print("AudioTestOrganism: Initialized test molecule for category: %s" % 
				  AudioTestMolecule.AudioTestCategory.keys()[category])

func _update_test_categories() -> void:
	"""Test kategorilerini güncelle"""
	# Test moleküllerinin visibility'sini güncelle
	for category in test_molecules:
		var molecule = test_molecules[category]
		if molecule:
			var should_be_enabled = category in test_categories_to_run
			molecule.visible = should_be_enabled
			molecule.process_mode = Node.PROCESS_MODE_INHERIT if should_be_enabled else Node.PROCESS_MODE_DISABLED

func _update_auto_run_settings() -> void:
	"""Auto-run settings güncelle"""
	pass

func _update_test_timing() -> void:
	"""Test timing güncelle"""
	pass

func _run_single_test(category: AudioTestMolecule.AudioTestCategory) -> TestBaseAtom.TestResult:
	"""Tek bir testi çalıştır"""
	var molecule = test_molecules.get(category)
	if not molecule:
		print("AudioTestOrganism: Test molecule not found for category: %s" % 
			  AudioTestMolecule.AudioTestCategory.keys()[category])
		return null
	
	# Testi çalıştır (run_test coroutine olduğu için await gerekli)
	var result = await molecule.run_test()
	
	return result

func _show_final_summary() -> void:
	"""Final özeti göster"""
	print("\n" + "=".repeat(50))
	print("AUDIO TEST SUITE COMPLETED")
	print("=".repeat(50))
	
	var summary = get_test_summary()
	
	print("\nSUMMARY:")
	print("Total Tests: %d" % summary.total_tests)
	print("Passed: %d" % summary.passed_tests)
	print("Failed: %d" % summary.failed_tests)
	print("Success Rate: %.1f%%" % summary.success_rate)
	print("Total Duration: %d ms" % summary.total_duration_ms)
	print("Average Duration: %.1f ms" % summary.avg_duration_ms)
	
	print("\nDETAILED RESULTS:")
	for category in test_results:
		var result = test_results[category]
		var category_name = AudioTestMolecule.AudioTestCategory.keys()[category]
		var status_str = TestBaseAtom.TestStatus.keys()[result.status]
		
		print("  %s:" % category_name.replace("_", " ").capitalize())
		print("    Status: %s" % status_str)
		print("    Duration: %d ms" % result.duration_ms)
		if result.error_message:
			print("    Error: %s" % result.error_message)
	
	print("\n" + "=".repeat(50))
	if summary.passed_tests == summary.total_tests:
		print("🎉 ALL AUDIO TESTS PASSED!")
	else:
		print("⚠️  SOME AUDIO TESTS FAILED!")
	print("=".repeat(50))
	
	# Event emit
	audio_test_suite_completed.emit(
		summary.total_tests,
		summary.passed_tests,
		summary.failed_tests,
		summary.total_duration_ms
	)
	
	audio_test_summary_ready.emit(summary)

# === EVENT HANDLERS ===

func _on_test_started(test_name: String, test_type: TestBaseAtom.TestType, category: AudioTestMolecule.AudioTestCategory) -> void:
	# Test başladı
	var category_name = AudioTestMolecule.AudioTestCategory.keys()[category]
	print("AudioTestOrganism: Test started - %s (%s)" % [category_name, test_name])
	
	audio_test_started.emit(category, test_name)

func _on_test_completed(result: TestBaseAtom.TestResult, category: AudioTestMolecule.AudioTestCategory) -> void:
	# Test tamamlandı
	var category_name = AudioTestMolecule.AudioTestCategory.keys()[category]
	var status_str = TestBaseAtom.TestStatus.keys()[result.status]
	
	print("AudioTestOrganism: Test completed - %s: %s (%d ms)" % [
		category_name,
		status_str,
		result.duration_ms
	])
	
	audio_test_completed.emit(category, result)

func _on_test_progress(progress: float, message: String, category: AudioTestMolecule.AudioTestCategory) -> void:
	# Test progress
	# Overall progress hesapla
	var overall_progress = (float(current_test_index) + progress) / float(total_tests) if total_tests > 0 else 0
	
	audio_test_progress.emit(category, overall_progress, message)

# === DEBUG ===

func _to_string() -> String:
	return "[AudioTestOrganism: Testing: %s, Tests: %d/%d, Passed: %d, Failed: %d]" % [
		str(is_testing),
		current_test_index + 1 if is_testing else 0,
		total_tests,
		passed_tests,
		failed_tests
	]

func print_debug_info() -> void:
	print("=== AudioTestOrganism Debug ===")
	print("Is Testing: %s" % str(is_testing))
	print("Current Test Index: %d" % current_test_index)
	print("Total Tests: %d" % total_tests)
	print("Passed Tests: %d" % passed_tests)
	print("Failed Tests: %d" % failed_tests)
	print("Total Duration: %d ms" % total_duration_ms)
	print("Run All Tests on Ready: %s" % str(run_all_tests_on_ready))
	print("Delay Between Tests: %.1f s" % delay_between_tests)
	print("Test Categories to Run: %d" % test_categories_to_run.size())
	
	for category in test_categories_to_run:
		var category_name = AudioTestMolecule.AudioTestCategory.keys()[category]
		print("  - %s" % category_name)
	
	print("\nTest Molecules:")
	for category in test_molecules:
		var molecule = test_molecules[category]
		var category_name = AudioTestMolecule.AudioTestCategory.keys()[category]
		if molecule:
			print("  %s: %s" % [category_name, molecule.test_name])
		else:
			print("  %s: NOT FOUND" % category_name)
	
	print("\nTest Results (%d):" % test_results.size())
	for category in test_results:
		var result = test_results[category]
		var category_name = AudioTestMolecule.AudioTestCategory.keys()[category]
		print("  %s: %s" % [category_name, str(result)])