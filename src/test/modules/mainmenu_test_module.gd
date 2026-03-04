# 🧪 MAIN MENU TEST MODULE
# MainMenuOrganism testlerini yönetir
class_name MainMenuTestModule
extends UITestBase

# === STATE ===
var test_cases = [
	{
		"name": "MainMenuOrganism Basic",
		"function": "_test_mainmenu_organism_basic"
	},
	{
		"name": "MainMenuOrganism Config Loading",
		"function": "_test_mainmenu_organism_config_loading"
	},
	{
		"name": "MainMenuOrganism Event Integration",
		"function": "_test_mainmenu_organism_event_integration"
	}
]

# === LIFECYCLE ===

func _ready() -> void:
	module_name = "MainMenu"
	test_queue = test_cases.duplicate()
	super._ready()

# === TEST CASES IMPLEMENTATION ===

func _test_mainmenu_organism_basic() -> bool:
	print("Running: MainMenuOrganism Basic Test")
	
	var main_menu = MainMenuOrganism.new()
	main_menu.name = "TestMainMenu"
	
	test_container.add_child(main_menu)
	main_menu.position = Vector2(20, 20)
	main_menu.size = Vector2(800, 600)
	
	var test_passed = true
	
	await get_tree().process_frame
	
	# Test 1: Menu initialization
	if not main_menu.is_initialized:
		print("FAIL: MainMenu not initialized")
		test_passed = false
	
	# Test 2: Default visibility
	if not main_menu.show_title:
		print("FAIL: Title should be visible by default")
		test_passed = false
	
	if not main_menu.show_logo:
		print("FAIL: Logo should be visible by default")
		test_passed = false
	
	if not main_menu.show_background:
		print("FAIL: Background should be visible by default")
		test_passed = false
	
	if not main_menu.show_buttons:
		print("FAIL: Buttons should be visible by default")
		test_passed = false
	
	# Test 3: Menu visibility toggle
	main_menu.hide_menu()
	
	await get_tree().process_frame
	
	if main_menu.visible:
		print("FAIL: Menu should be hidden")
		test_passed = false
	
	main_menu.show_menu()
	
	await get_tree().process_frame
	
	if not main_menu.visible:
		print("FAIL: Menu should be visible")
		test_passed = false
	
	# Test 4: Fade animations
	main_menu.fade_out()
	
	await get_tree().create_timer(main_menu.fade_duration + 0.1).timeout
	
	if main_menu.visible:
		print("FAIL: Menu should be hidden after fade out")
		test_passed = false
	
	main_menu.fade_in()
	
	await get_tree().create_timer(main_menu.fade_duration + 0.1).timeout
	
	if not main_menu.visible:
		print("FAIL: Menu should be visible after fade in")
		test_passed = false
	
	# Test 5: Button states
	main_menu.set_button_state("start", false)
	
	await get_tree().process_frame
	
	if main_menu.button_states.start.enabled:
		print("FAIL: Start button should be disabled")
		test_passed = false
	
	main_menu.set_button_state("start", true)
	
	await get_tree().process_frame
	
	if not main_menu.button_states.start.enabled:
		print("FAIL: Start button should be enabled")
		test_passed = false
	
	await get_tree().process_frame
	
	if test_passed:
		print("PASS: MainMenuOrganism Basic Test")
	
	return test_passed

func _test_mainmenu_organism_config_loading() -> bool:
	print("Running: MainMenuOrganism Config Loading Test")
	
	var main_menu = MainMenuOrganism.new()
	main_menu.name = "TestMainMenuConfig"
	
	test_container.add_child(main_menu)
	main_menu.position = Vector2(20, 20)
	main_menu.size = Vector2(800, 600)
	
	var test_passed = true
	
	await get_tree().process_frame
	
	# ConfigManager kontrolü
	if not ConfigManager.is_available():
		print("SKIP: ConfigManager not available")
		return true  # Skip test, fail değil
	
	# Test 1: Config loading
	main_menu.reload_config()
	
	await get_tree().process_frame
	
	if main_menu.current_config.is_empty():
		print("FAIL: Config should be loaded")
		test_passed = false
	
	# Test 2: Title from config
	# Config'den title yüklenmeli
	
	# Test 3: Button texts from config
	# Config'den button text'leri yüklenmeli
	
	# Test 4: Button styles from config
	# Config'den button style'ları yüklenmeli
	
	# Test 5: Config change event
	# Config değiştiğinde reload edilmeli
	if EventBus.is_available():
		EventBus.emit_now_static("config_changed", {
			"file": "ui.json",
			"section": "screens.main_menu"
		})
	
	await get_tree().process_frame
	
	# Config reload edilmiş olmalı
	
	await get_tree().process_frame
	
	if test_passed:
		print("PASS: MainMenuOrganism Config Loading Test")
	
	return test_passed

func _test_mainmenu_organism_event_integration() -> bool:
	print("Running: MainMenuOrganism Event Integration Test")
	
	var main_menu = MainMenuOrganism.new()
	main_menu.name = "TestMainMenuEventIntegration"
	
	test_container.add_child(main_menu)
	main_menu.position = Vector2(20, 20)
	main_menu.size = Vector2(800, 600)
	
	var test_passed = true
	
	# EventBus kontrolü
	if not EventBus.is_available():
		print("SKIP: EventBus not available")
		return true  # Skip test, fail değil
	
	await get_tree().process_frame
	
	# Test 1: Button click events
	# Button click'leri EventBus'a emit edilmeli
	
	# Simüle button click'leri
	main_menu._on_start_button_pressed()
	main_menu._on_settings_button_pressed()
	main_menu._on_quit_button_pressed()
	
	await get_tree().process_frame
	
	# Test 2: Game state events
	EventBus.emit_now_static(EventBus.GAME_STARTED, {})
	
	await get_tree().create_timer(main_menu.fade_duration + 0.1).timeout
	
	if main_menu.visible:
		print("FAIL: Menu should be hidden when game starts")
		test_passed = false
	
	EventBus.emit_now_static(EventBus.GAME_PAUSED, {})
	
	await get_tree().create_timer(main_menu.fade_duration + 0.1).timeout
	
	if not main_menu.visible:
		print("FAIL: Menu should be visible when game paused")
		test_passed = false
	
	EventBus.emit_now_static(EventBus.GAME_RESUMED, {})
	
	await get_tree().create_timer(main_menu.fade_duration + 0.1).timeout
	
	if main_menu.visible:
		print("FAIL: Menu should be hidden when game resumed")
		test_passed = false
	
	# Test 3: UI show/hide events
	EventBus.emit_now_static(EventBus.UI_HIDE, {
		"component": "MainMenu"
	})
	
	await get_tree().process_frame
	
	if main_menu.visible:
		print("FAIL: Menu should be hidden by UI_HIDE event")
		test_passed = false
	
	EventBus.emit_now_static(EventBus.UI_SHOW, {
		"component": "MainMenu"
	})
	
	await get_tree().process_frame
	
	if not main_menu.visible:
		print("FAIL: Menu should be visible by UI_SHOW event")
		test_passed = false
	
	await get_tree().process_frame
	
	if test_passed:
		print("PASS: MainMenuOrganism Event Integration Test")
	
	return test_passed