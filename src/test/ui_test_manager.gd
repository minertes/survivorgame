# 🎮 UI TEST MANAGER
# UI test komutlarını yönetir (F19-F30 tuşları)
class_name UITestManager
extends Node

# === TEST TYPES ===
enum TestType {
	ATOMS = 1,
	MOLECULES = 2,
	ORGANISMS = 3,
	FULL_INTEGRATION = 4,
	SAVE_SYSTEM = 5,
	AUDIO_SYSTEM = 6,
	MAIN_MENU = 7,
	UPGRADE_SCREEN = 8,
	SETTINGS_SCREEN = 9,
	NAVIGATION_SYSTEM = 10,
	FULL_UI_INTEGRATION = 11,
	UI_PERFORMANCE = 12,
	ALL_MODULES = 13
}

# === NODES ===
@onready var atoms_test: UIAtomsTest = $UIAtomsTest
@onready var molecules_test: UIMoleculesTest = $UIMoleculesTest
@onready var organisms_test: UIOrganismsTest = $UIOrganismsTest
@onready var test_orchestrator: UITestOrchestrator = $UITestOrchestrator
@onready var test_results_panel: Panel = $TestResultsPanel
@onready var results_label: Label = $TestResultsPanel/ResultsLabel
@onready var close_button: Button = $TestResultsPanel/CloseButton

# AudioTestModule referansı ekle
var audio_test_module: AudioTestModule = null

# === STATE ===
var current_test_type: TestType = TestType.ATOMS
var is_testing: bool = false
var test_history: Array = []

# === LIFECYCLE ===

func _ready() -> void:
	print("UI Test Manager initialized")
	_setup_ui()
	_setup_input_map()
	
	# Close button event
	close_button.pressed.connect(_on_close_button_pressed)
	
	# AudioTestModule oluştur
	audio_test_module = AudioTestModule.new()
	add_child(audio_test_module)
	print("AudioTestModule created")
	
	# Başlangıçta panel'i gizle
	test_results_panel.visible = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_test_atoms"):
		_run_test(TestType.ATOMS)
	elif event.is_action_pressed("ui_test_molecules"):
		_run_test(TestType.MOLECULES)
	elif event.is_action_pressed("ui_test_organisms"):
		_run_test(TestType.ORGANISMS)
	elif event.is_action_pressed("ui_test_full_integration"):
		_run_test(TestType.FULL_INTEGRATION)
	elif event.is_action_pressed("ui_test_save_system"):
		_run_test(TestType.SAVE_SYSTEM)
	elif event.is_action_pressed("ui_test_audio_system"):
		_run_test(TestType.AUDIO_SYSTEM)
	elif event.is_action_pressed("ui_test_main_menu"):
		_run_test(TestType.MAIN_MENU)
	elif event.is_action_pressed("ui_test_upgrade_screen"):
		_run_test(TestType.UPGRADE_SCREEN)
	elif event.is_action_pressed("ui_test_settings_screen"):
		_run_test(TestType.SETTINGS_SCREEN)
	elif event.is_action_pressed("ui_test_navigation_system"):
		_run_test(TestType.NAVIGATION_SYSTEM)
	elif event.is_action_pressed("ui_test_full_ui_integration"):
		_run_test(TestType.FULL_UI_INTEGRATION)
	elif event.is_action_pressed("ui_test_ui_performance"):
		_run_test(TestType.UI_PERFORMANCE)
	elif event.is_action_pressed("ui_test_all_modules"):
		_run_test(TestType.ALL_MODULES)

# === PUBLIC API ===

func run_test(test_type: TestType) -> void:
	if is_testing:
		push_warning("Test already in progress")
		return
	
	_run_test(test_type)

func run_all_tests() -> void:
	if is_testing:
		push_warning("Test already in progress")
		return
	
	_run_all_tests_sequence()

func get_test_history() -> Array:
	return test_history.duplicate()

func clear_test_history() -> void:
	test_history.clear()

func show_results_panel() -> void:
	test_results_panel.visible = true
	_update_results_display()

func hide_results_panel() -> void:
	test_results_panel.visible = false

# === TEST EXECUTION ===

func _run_test(test_type: TestType) -> void:
	if is_testing:
		return
	
	is_testing = true
	current_test_type = test_type
	
	var test_name = TestType.keys()[test_type - 1]
	print("Starting test: %s" % test_name)
	
	# Test results panel'i göster
	show_results_panel()
	results_label.text = "Running %s Test...\n\nPlease wait..." % test_name
	
	match test_type:
		TestType.ATOMS:
			_run_atoms_test()
		TestType.MOLECULES:
			_run_molecules_test()
		TestType.ORGANISMS:
			_run_organisms_test()
		TestType.FULL_INTEGRATION:
			_run_full_integration_test()
		TestType.SAVE_SYSTEM:
			_run_save_system_test()
		TestType.AUDIO_SYSTEM:
			_run_audio_system_test()
		TestType.MAIN_MENU:
			_run_main_menu_test()
		TestType.UPGRADE_SCREEN:
			_run_upgrade_screen_test()
		TestType.SETTINGS_SCREEN:
			_run_settings_screen_test()
		TestType.NAVIGATION_SYSTEM:
			_run_navigation_system_test()
		TestType.FULL_UI_INTEGRATION:
			_run_full_ui_integration_test()
		TestType.UI_PERFORMANCE:
			_run_ui_performance_test()
		TestType.ALL_MODULES:
			_run_all_modules_test()
		_:
			push_warning("Unknown test type: %d" % test_type)
			is_testing = false

func _run_atoms_test() -> void:
	atoms_test.run_all_tests()
	
	# Test tamamlanmasını bekle
	await get_tree().create_timer(15.0).timeout  # Atoms test yaklaşık 15 saniye sürer
	
	var results = atoms_test.get_test_results()
	_on_test_completed("Atoms", results)

func _run_molecules_test() -> void:
	molecules_test.run_all_tests()
	
	await get_tree().create_timer(10.0).timeout  # Molecules test yaklaşık 10 saniye sürer
	
	var results = molecules_test.get_test_results()
	_on_test_completed("Molecules", results)

func _run_organisms_test() -> void:
	organisms_test.run_all_tests()
	
	await get_tree().create_timer(8.0).timeout  # Organisms test yaklaşık 8 saniye sürer
	
	var results = organisms_test.get_test_results()
	_on_test_completed("Organisms", results)

func _run_full_integration_test() -> void:
	# Tüm testleri sırayla çalıştır
	results_label.text = "Running Full Integration Test...\n\nPhase 1: Atoms..."
	
	atoms_test.run_all_tests()
	await get_tree().create_timer(15.0).timeout
	var atoms_results = atoms_test.get_test_results()
	
	results_label.text = "Running Full Integration Test...\n\nPhase 2: Molecules..."
	
	molecules_test.run_all_tests()
	await get_tree().create_timer(10.0).timeout
	var molecules_results = molecules_test.get_test_results()
	
	results_label.text = "Running Full Integration Test...\n\nPhase 3: Organisms..."
	
	organisms_test.run_all_tests()
	await get_tree().create_timer(8.0).timeout
	var organisms_results = organisms_test.get_test_results()
	
	# Tüm sonuçları birleştir
	var all_results = {
		"atoms": atoms_results,
		"molecules": molecules_results,
		"organisms": organisms_results,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	_on_test_completed("Full Integration", all_results)

func _run_save_system_test() -> void:
	# SaveSystem testi - Yeni modüler yapıyı kullan
	results_label.text = "Save System Test\n\nRunning SaveTestModule..."
	
	# Test orchestrator üzerinden spesifik modül çalıştır
	test_orchestrator.run_specific_module("SaveSystem")
	
	await get_tree().create_timer(20.0).timeout  # Save testleri daha uzun sürebilir
	
	var results = test_orchestrator.get_all_test_results()
	
	# Sadece SaveSystem test sonuçlarını filtrele
	var save_system_results = results.get("SaveSystem", {})
	
	_on_test_completed("Save System", save_system_results)

func _run_audio_system_test() -> void:
	# AudioSystem testi - Yeni AudioTestModule'ü kullan
	results_label.text = "Audio System Test\n\nRunning AudioTestModule..."
	
	# Tüm audio testlerini çalıştır
	audio_test_module.run_all_tests()
	
	await get_tree().create_timer(30.0).timeout  # Audio testleri yaklaşık 30 saniye sürer
	
	var results = audio_test_module.get_test_results()
	
	_on_test_completed("Audio System", results)

func _run_main_menu_test() -> void:
	# MainMenu testi - Yeni modüler yapıyı kullan
	results_label.text = "MainMenu Test\n\nRunning MainMenuTestModule..."
	
	# Test orchestrator üzerinden spesifik modül çalıştır
	test_orchestrator.run_specific_module("MainMenu")
	
	await get_tree().create_timer(10.0).timeout
	
	var results = test_orchestrator.get_all_test_results()
	
	# Sadece MainMenu test sonuçlarını filtrele
	var main_menu_results = results.get("MainMenu", {})
	
	_on_test_completed("Main Menu", main_menu_results)

func _run_upgrade_screen_test() -> void:
	# UpgradeScreen testi - Yeni modüler yapıyı kullan
	results_label.text = "Upgrade Screen Test\n\nRunning UpgradeScreenTestModule..."
	
	# Test orchestrator üzerinden spesifik modül çalıştır
	test_orchestrator.run_specific_module("UpgradeScreen")
	
	await get_tree().create_timer(10.0).timeout
	
	var results = test_orchestrator.get_all_test_results()
	
	# Sadece UpgradeScreen test sonuçlarını filtrele
	var upgrade_screen_results = results.get("UpgradeScreen", {})
	
	_on_test_completed("Upgrade Screen", upgrade_screen_results)

func _run_settings_screen_test() -> void:
	# SettingsScreen testi - Yeni modüler yapıyı kullan
	results_label.text = "Settings Screen Test\n\nRunning SettingsScreenTestModule..."
	
	# Test orchestrator üzerinden spesifik modül çalıştır
	test_orchestrator.run_specific_module("SettingsScreen")
	
	await get_tree().create_timer(10.0).timeout
	
	var results = test_orchestrator.get_all_test_results()
	
	# Sadece SettingsScreen test sonuçlarını filtrele
	var settings_screen_results = results.get("SettingsScreen", {})
	
	_on_test_completed("Settings Screen", settings_screen_results)

func _run_navigation_system_test() -> void:
	# Navigation System testi - Yeni modüler yapıyı kullan
	results_label.text = "Navigation System Test\n\nRunning ScreenNavigationTestModule..."
	
	# Test orchestrator üzerinden spesifik modül çalıştır
	test_orchestrator.run_specific_module("ScreenNavigation")
	
	await get_tree().create_timer(10.0).timeout
	
	var results = test_orchestrator.get_all_test_results()
	
	# Sadece ScreenNavigation test sonuçlarını filtrele
	var navigation_results = results.get("ScreenNavigation", {})
	
	_on_test_completed("Navigation System", navigation_results)

func _run_full_ui_integration_test() -> void:
	# Full UI Integration testi - Yeni modüler yapıyı kullan
	results_label.text = "Full UI Integration Test\n\nRunning all UI tests..."
	
	# Tüm UI testlerini çalıştır
	_run_atoms_test()
	await get_tree().create_timer(15.0).timeout
	
	_run_molecules_test()
	await get_tree().create_timer(10.0).timeout
	
	_run_organisms_test()
	await get_tree().create_timer(8.0).timeout
	
	# Yeni modüler testleri çalıştır
	test_orchestrator.run_all_tests()
	await get_tree().create_timer(30.0).timeout
	
	# Tüm sonuçları birleştir
	var all_results = {
		"atoms": atoms_test.get_test_results(),
		"molecules": molecules_test.get_test_results(),
		"organisms": organisms_test.get_test_results(),
		"modules": test_orchestrator.get_all_test_results(),
		"timestamp": Time.get_unix_time_from_system()
	}
	
	_on_test_completed("Full UI Integration", all_results)

func _run_ui_performance_test() -> void:
	# UI Performance testi - Yeni modüler yapıyı kullan
	results_label.text = "UI Performance Test\n\nRunning PerformanceTestModule..."
	
	# Test orchestrator üzerinden spesifik modül çalıştır
	test_orchestrator.run_specific_module("Performance")
	
	await get_tree().create_timer(15.0).timeout
	
	var results = test_orchestrator.get_all_test_results()
	
	# Sadece Performance test sonuçlarını filtrele
	var performance_results = results.get("Performance", {})
	
	_on_test_completed("UI Performance", performance_results)

func _run_all_modules_test() -> void:
	# Tüm modülleri çalıştır
	results_label.text = "All Modules Test\n\nRunning all test modules..."
	
	test_orchestrator.run_all_tests()
	
	await get_tree().create_timer(45.0).timeout
	
	var results = test_orchestrator.get_all_test_results()
	_on_test_completed("All Modules", results)

func _run_all_tests_sequence() -> void:
	results_label.text = "Running All Tests...\n\nThis will take about 90 seconds..."
	
	# Tüm test tiplerini sırayla çalıştır
	for test_type in range(1, 14):  # 1-13
		_run_test(test_type)
		await get_tree().create_timer(1.0).timeout  # Testler arası bekleme

func _on_test_completed(test_name: String, results: Dictionary) -> void:
	is_testing = false
	
	# Test geçmişine ekle
	var test_entry = {
		"name": test_name,
		"results": results,
		"timestamp": Time.get_unix_time_from_system(),
		"type": current_test_type
	}
	test_history.append(test_entry)
	
	# Sonuçları göster
	_show_test_results(test_name, results)
	
	# EventBus'a bildir
	if EventBus.is_available():
		EventBus.emit_now_static("ui_test_completed", {
			"test_name": test_name,
			"test_type": current_test_type,
			"results": results,
			"timestamp": Time.get_unix_time_from_system()
		})

# === UI MANAGEMENT ===

func _setup_ui() -> void:
	# Results panel style
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.05, 0.1, 0.95)
	panel_style.border_color = Color(0.2, 0.2, 0.3)
	panel_style.border_width_left = 3
	panel_style.border_width_top = 3
	panel_style.border_width_right = 3
	panel_style.border_width_bottom = 3
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12
	
	test_results_panel.add_theme_stylebox_override("panel", panel_style)
	
	# Results label style
	results_label.add_theme_font_size_override("font_size", 14)
	results_label.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	
	# Close button style
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color(0.3, 0.3, 0.5)
	button_style.border_color = Color(0.5, 0.5, 0.7)
	button_style.corner_radius_top_left = 6
	button_style.corner_radius_top_right = 6
	button_style.corner_radius_bottom_left = 6
	button_style.corner_radius_bottom_right = 6
	
	close_button.add_theme_stylebox_override("normal", button_style)
	close_button.text = "Close Results"

func _show_test_results(test_name: String, results: Dictionary) -> void:
	var summary = "=== %s Test Results ===\n\n" % test_name
	
	if test_name in ["Save System", "Audio System", "UI Performance"]:
		# Mock results veya performance results için özel format
		for test_case in results:
			var result = results[test_case]
			var status = "✓ PASS" if result.passed else "✗ FAIL"
			var note = result.get("note", "")
			
			summary += "%s: %s" % [test_case.replace("_", " ").capitalize(), status]
			if note:
				summary += " (%s)" % note
			summary += "\n"
	elif test_name in ["All Modules", "Full UI Integration"]:
		# Modüler test sonuçları için özel format
		for module_name in results:
			if module_name in ["atoms", "molecules", "organisms"]:
				continue  # Bunlar zaten diğer testlerde gösteriliyor
			
			var module_results = results[module_name]
			var passed = 0
			var total = module_results.size()
			
			for test_case in module_results:
				if module_results[test_case].passed:
					passed += 1
			
			summary += "%s: %d/%d passed (%.1f%%)\n" % [
				module_name,
				passed,
				total,
				float(passed) / total * 100 if total > 0 else 0
			]
	else:
		# Normal test results
		var passed = 0
		var total = results.size()
		
		for test_case in results:
			var result = results[test_case]
			var status = "✓ PASS" if result.passed else "✗ FAIL"
			
			summary += "%s: %s (%.0fms)\n" % [test_case, status, result.duration]
			
			if result.passed:
				passed += 1
		
		summary += "\nSummary: %d/%d passed (%.1f%%)" % [
			passed,
			total,
			float(passed) / total * 100 if total > 0 else 0
		]
	
	summary += "\n\nTest Tuşları:"
	summary += "\n- SaveSystem: F23 veya Ctrl+Shift+S"
	summary += "\n- AudioSystem: F24 veya Ctrl+Shift+A"
	summary += "\n- MainMenu: F25 veya Ctrl+Shift+M"
	summary += "\n- Tüm Testler: F31 veya Ctrl+Shift+T"
	summary += "\n- Diğer: F19-F30"
	
	results_label.text = summary

func _update_results_display() -> void:
	if test_history.is_empty():
		results_label.text = "No test results yet.\n\nPress F19-F30 to run tests."
		return
	
	# En son test sonuçlarını göster
	var latest_test = test_history.back()
	_show_test_results(latest_test.name, latest_test.results)

func _on_close_button_pressed() -> void:
	hide_results_panel()

# === INPUT MAP SETUP ===

func _setup_input_map() -> void:
	# F19-F30 tuşlarını input map'e ekle
	var test_keys = [
		{"action": "ui_test_atoms", "keycode": KEY_F19},
		{"action": "ui_test_molecules", "keycode": KEY_F20},
		{"action": "ui_test_organisms", "keycode": KEY_F21},
		{"action": "ui_test_full_integration", "keycode": KEY_F22},
		{"action": "ui_test_save_system", "keycode": KEY_F23},  # Orijinal F23
		{"action": "ui_test_audio_system", "keycode": KEY_F24},
		{"action": "ui_test_main_menu", "keycode": KEY_F25},
		{"action": "ui_test_upgrade_screen", "keycode": KEY_F26},
		{"action": "ui_test_settings_screen", "keycode": KEY_F27},
		{"action": "ui_test_navigation_system", "keycode": KEY_F28},
		{"action": "ui_test_full_ui_integration", "keycode": KEY_F29},
		{"action": "ui_test_ui_performance", "keycode": KEY_F30},
		{"action": "ui_test_all_modules", "keycode": KEY_F31}
	]
	
	for test_key in test_keys:
		var action_name = test_key.action
		var keycode = test_key.keycode
		
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
		
		var input_event = InputEventKey.new()
		input_event.keycode = keycode
		input_event.pressed = true
		
		InputMap.action_add_event(action_name, input_event)
	
	# Alternatif tuş kombinasyonları ekle
	_add_alternative_keybindings()
	
	print("UI Test input map configured (F19-F31 + alternatifler)")

func _add_alternative_keybindings() -> void:
	# SaveSystem testi için alternatif: Ctrl+Shift+S
	var alt_save_event = InputEventKey.new()
	alt_save_event.keycode = KEY_S
	alt_save_event.ctrl_pressed = true
	alt_save_event.shift_pressed = true
	alt_save_event.pressed = true
	
	if InputMap.has_action("ui_test_save_system"):
		InputMap.action_add_event("ui_test_save_system", alt_save_event)
	
	# AudioSystem testi için alternatif: Ctrl+Shift+A
	var alt_audio_event = InputEventKey.new()
	alt_audio_event.keycode = KEY_A
	alt_audio_event.ctrl_pressed = true
	alt_audio_event.shift_pressed = true
	alt_audio_event.pressed = true
	
	if InputMap.has_action("ui_test_audio_system"):
		InputMap.action_add_event("ui_test_audio_system", alt_audio_event)
	
	# MainMenu testi için alternatif: Ctrl+Shift+M
	var alt_menu_event = InputEventKey.new()
	alt_menu_event.keycode = KEY_M
	alt_menu_event.ctrl_pressed = true
	alt_menu_event.shift_pressed = true
	alt_menu_event.pressed = true
	
	if InputMap.has_action("ui_test_main_menu"):
		InputMap.action_add_event("ui_test_main_menu", alt_menu_event)
	
	# Tüm testler için alternatif: Ctrl+Shift+T
	var alt_all_event = InputEventKey.new()
	alt_all_event.keycode = KEY_T
	alt_all_event.ctrl_pressed = true
	alt_all_event.shift_pressed = true
	alt_all_event.pressed = true
	
	if InputMap.has_action("ui_test_all_modules"):
		InputMap.action_add_event("ui_test_all_modules", alt_all_event)

# === DEBUG ===

func _to_string() -> String:
	return "[UITestManager: %d tests in history]" % test_history.size()

func print_debug_info() -> void:
	print("=== UI Test Manager Debug ===")
	print("Current Test Type: %s" % TestType.keys()[current_test_type - 1])
	print("Is Testing: %s" % str(is_testing))
	print("Test History Count: %d" % test_history.size())
	print("Input Actions Configured: %s" % str(InputMap.get_actions()))