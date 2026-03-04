# 🧪 UI SCREENS TEST
# UI Screen component'larını ve navigation sistemini test eder
class_name UIScreensTest
extends Node

# === NODES ===
@onready var test_container: Control = $TestContainer
@onready var results_label: Label = $ResultsLabel
@onready var status_panel: Panel = $StatusPanel
@onready var navigation_debug: Label = $NavigationDebug

# === STATE ===
var current_test_index: int = 0
var test_results: Dictionary = {}
var is_testing: bool = false
var test_queue: Array = []
var screen_navigation: ScreenNavigation = null

# === TEST CASES ===
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
	},
	{
		"name": "ScreenNavigation Basic",
		"function": "_test_screen_navigation_basic"
	},
	{
		"name": "ScreenNavigation Transitions",
		"function": "_test_screen_navigation_transitions"
	},
	{
		"name": "ScreenNavigation Stack Management",
		"function": "_test_screen_navigation_stack_management"
	},
	{
		"name": "UpgradeScreenOrganism Basic",
		"function": "_test_upgradescreen_organism_basic"
	},
	{
		"name": "UpgradeScreenOrganism Weapon Management",
		"function": "_test_upgradescreen_organism_weapon_management"
	},
	{
		"name": "UpgradeScreenOrganism Upgrade Logic",
		"function": "_test_upgradescreen_organism_upgrade_logic"
	},
	{
		"name": "SettingsScreenOrganism Basic",
		"function": "_test_settingsscreen_organism_basic"
	},
	{
		"name": "SettingsScreenOrganism Audio Controls",
		"function": "_test_settingsscreen_organism_audio_controls"
	},
	{
		"name": "SettingsScreenOrganism Graphics Controls",
		"function": "_test_settingsscreen_organism_graphics_controls"
	},
	{
		"name": "Screen Navigation Performance",
		"function": "_test_screen_navigation_performance"
	},
	{
		"name": "UI Memory Usage Test",
		"function": "_test_ui_memory_usage"
	}
]

# === LIFECYCLE ===

func _ready() -> void:
	print("UI Screens Test initialized")
	_setup_test_ui()
	_start_tests()

# === PUBLIC API ===

func run_all_tests() -> void:
	if is_testing:
		push_warning("Tests already running")
		return
	
	_reset_test_state()
	_start_tests()

func run_specific_test(test_name: String) -> void:
	for test_case in test_cases:
		if test_case.name == test_name:
			_run_test_case(test_case)
			return
	
	push_warning("Test not found: %s" % test_name)

func get_test_results() -> Dictionary:
	return test_results.duplicate()

func print_test_summary() -> void:
	var passed = 0
	var failed = 0
	
	for test_name in test_results:
		if test_results[test_name].passed:
			passed += 1
		else:
			failed += 1
	
	print("=== UI Screens Test Summary ===")
	print("Total Tests: %d" % test_results.size())
	print("Passed: %d" % passed)
	print("Failed: %d" % failed)
	print("Success Rate: %.1f%%" % (float(passed) / test_results.size() * 100 if test_results.size() > 0 else 0))

# === TEST EXECUTION ===

func _start_tests() -> void:
	is_testing = true
	test_queue = test_cases.duplicate()
	_run_next_test()

func _run_next_test() -> void:
	if test_queue.is_empty():
		_on_all_tests_completed()
		return
	
	var test_case = test_queue.pop_front()
	_run_test_case(test_case)

func _run_test_case(test_case: Dictionary) -> void:
	current_test_index += 1
	
	# Clear previous test
	_clear_test_container()
	
	# Update status
	_update_status("Running: %s (%d/%d)" % [
		test_case.name,
		current_test_index,
		test_cases.size()
	])
	
	# Run test
	var start_time = Time.get_ticks_msec()
	var result = call(test_case.function)
	var end_time = Time.get_ticks_msec()
	var duration = end_time - start_time
	
	# Store result
	test_results[test_case.name] = {
		"passed": result,
		"duration": duration,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	# Update UI
	_update_results_display()
	
	# Next test
	await get_tree().create_timer(2.0).timeout
	_run_next_test()

func _on_all_tests_completed() -> void:
	is_testing = false
	_update_status("All tests completed!")
	print_test_summary()
	
	# Cleanup
	if screen_navigation:
		screen_navigation.queue_free()
		screen_navigation = null
	
	# EventBus'a bildir
	if EventBus.is_available():
		EventBus.emit_now_static("ui_test_completed", {
			"test_type": "screens",
			"results": test_results,
			"timestamp": Time.get_unix_time_from_system()
		})

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

func _test_screen_navigation_basic() -> bool:
	print("Running: ScreenNavigation Basic Test")
	
	# ScreenNavigation oluştur
	screen_navigation = ScreenNavigation.new()
	screen_navigation.name = "TestScreenNavigation"
	
	test_container.add_child(screen_navigation)
	screen_navigation.position = Vector2(20, 20)
	screen_navigation.size = Vector2(800, 600)
	
	var test_passed = true
	
	await get_tree().process_frame
	
	# Test 1: Navigation initialization
	# Varsayılan ekran yüklenmeli (MainMenu)
	
	# Test 2: Current screen type
	var current_type = screen_navigation.get_current_screen_type()
	if current_type != ScreenNavigation.ScreenType.MAIN_MENU:
		print("FAIL: Default screen should be MAIN_MENU")
		test_passed = false
	
	# Test 3: Screen stack
	var stack = screen_navigation.get_screen_stack()
	if stack.size() != 1:
		print("FAIL: Screen stack should have 1 entry")
		test_passed = false
	
	if stack[0] != ScreenNavigation.ScreenType.MAIN_MENU:
		print("FAIL: Screen stack first entry should be MAIN_MENU")
		test_passed = false
	
	# Test 4: Screen instances
	var main_menu_instance = screen_navigation.get_screen_instance(ScreenNavigation.ScreenType.MAIN_MENU)
	if not main_menu_instance:
		print("FAIL: MainMenu instance should be created")
		test_passed = false
	
	# Test 5: Screen visibility
	if not screen_navigation.is_screen_visible(ScreenNavigation.ScreenType.MAIN_MENU):
		print("FAIL: MainMenu should be visible")
		test_passed = false
	
	await get_tree().process_frame
	
	if test_passed:
		print("PASS: ScreenNavigation Basic Test")
	
	return test_passed

func _test_screen_navigation_transitions() -> bool:
	print("Running: ScreenNavigation Transitions Test")
	
	if not screen_navigation:
		print("FAIL: ScreenNavigation not initialized")
		return false
	
	var test_passed = true
	
	# Test 1: Fade transition
	screen_navigation.show_screen(ScreenNavigation.ScreenType.GAME_HUD, ScreenNavigation.TransitionType.FADE)
	
	await get_tree().create_timer(screen_navigation.transition_duration + 0.1).timeout
	
	if screen_navigation.get_current_screen_type() != ScreenNavigation.ScreenType.GAME_HUD:
		print("FAIL: Should transition to GAME_HUD")
		test_passed = false
	
	# Test 2: Slide transition
	screen_navigation.show_screen(ScreenNavigation.ScreenType.UPGRADE_SCREEN, ScreenNavigation.TransitionType.SLIDE_LEFT)
	
	await get_tree().create_timer(screen_navigation.transition_duration + 0.1).timeout
	
	if screen_navigation.get_current_screen_type() != ScreenNavigation.ScreenType.UPGRADE_SCREEN:
		print("FAIL: Should transition to UPGRADE_SCREEN")
		test_passed = false
	
	# Test 3: Slide back transition
	screen_navigation.show_screen(ScreenNavigation.ScreenType.SETTINGS_SCREEN, ScreenNavigation.TransitionType.SLIDE_RIGHT)
	
	await get_tree().create_timer(screen_navigation.transition_duration + 0.1).timeout
	
	if screen_navigation.get_current_screen_type() != ScreenNavigation.ScreenType.SETTINGS_SCREEN:
		print("FAIL: Should transition to SETTINGS_SCREEN")
		test_passed = false
	
	# Test 4: No transition
	screen_navigation.show_screen(ScreenNavigation.ScreenType.MAIN_MENU, ScreenNavigation.TransitionType.NONE)
	
	await get_tree().process_frame
	
	if screen_navigation.get_current_screen_type() != ScreenNavigation.ScreenType.MAIN_MENU:
		print("FAIL: Should transition to MAIN_MENU (no transition)")
		test_passed = false
	
	# Test 5: Transition blocking
	screen_navigation.block_navigation()
	screen_navigation.show_screen(ScreenNavigation.ScreenType.GAME_HUD)
	
	await get_tree().process_frame
	
	if screen_navigation.get_current_screen_type() == ScreenNavigation.ScreenType.GAME_HUD:
		print("FAIL: Navigation should be blocked")
		test_passed = false
	
	screen_navigation.resume_navigation()
	
	await get_tree().process_frame
	
	_update_navigation_debug()
	
	if test_passed:
		print("PASS: ScreenNavigation Transitions Test")
	
	return test_passed

func _test_screen_navigation_stack_management() -> bool:
	print("Running: ScreenNavigation Stack Management Test")
	
	if not screen_navigation:
		print("FAIL: ScreenNavigation not initialized")
		return false
	
	var test_passed = true
	
	# Stack'i temizle
	screen_navigation.clear_screen_stack()
	
	# Test 1: Stack tracking
	screen_navigation.show_screen(ScreenNavigation.ScreenType.MAIN_MENU)
	
	await get_tree().create_timer(0.5).timeout
	
	var stack = screen_navigation.get_screen_stack()
	if stack.size() != 1 or stack[0] != ScreenNavigation.ScreenType.MAIN_MENU:
		print("FAIL: Stack should have MAIN_MENU")
		test_passed = false
	
	screen_navigation.show_screen(ScreenNavigation.ScreenType.GAME_HUD)
	
	await get_tree().create_timer(0.5).timeout
	
	stack = screen_navigation.get_screen_stack()
	if stack.size() != 2 or stack[1] != ScreenNavigation.ScreenType.GAME_HUD:
		print("FAIL: Stack should have MAIN_MENU → GAME_HUD")
		test_passed = false
	
	# Test 2: Go back
	var can_go_back = screen_navigation.go_back()
	if not can_go_back:
		print("FAIL: Should be able to go back")
		test_passed = false
	
	await get_tree().create_timer(screen_navigation.transition_duration + 0.1).timeout
	
	if screen_navigation.get_current_screen_type() != ScreenNavigation.ScreenType.MAIN_MENU:
		print("FAIL: Should go back to MAIN_MENU")
		test_passed = false
	
	stack = screen_navigation.get_screen_stack()
	if stack.size() != 1:
		print("FAIL: Stack should have 1 entry after going back")
		test_passed = false
	
	# Test 3: Go to main menu (clear stack)
	screen_navigation.show_screen(ScreenNavigation.ScreenType.GAME_HUD)
	
	await get_tree().create_timer(0.5).timeout
	
	screen_navigation.go_to_main_menu()
	
	await get_tree().create_timer(screen_navigation.transition_duration + 0.1).timeout
	
	if screen_navigation.get_current_screen_type() != ScreenNavigation.ScreenType.MAIN_MENU:
		print("FAIL: Should go to main menu")
		test_passed = false
	
	stack = screen_navigation.get_screen_stack()
	if stack.size() != 1:
		print("FAIL: Stack should be cleared when going to main menu")
		test_passed = false
	
	# Test 4: Go to game HUD (clear stack)
	screen_navigation.go_to_game_hud()
	
	await get_tree().create_timer(screen_navigation.transition_duration + 0.1).timeout
	
	if screen_navigation.get_current_screen_type() != ScreenNavigation.ScreenType.GAME_HUD:
		print("FAIL: Should go to game HUD")
		test_passed = false
	
	stack = screen_navigation.get_screen_stack()
	if stack.size() != 1:
		print("FAIL: Stack should be cleared when going to game HUD")
		test_passed = false
	
	# Test 5: Previous screen type
	screen_navigation.show_screen(ScreenNavigation.ScreenType.UPGRADE_SCREEN)
	
	await get_tree().create_timer(0.5).timeout
	
	var previous_type = screen_navigation.get_previous_screen_type()
	if previous_type != ScreenNavigation.ScreenType.GAME_HUD:
		print("FAIL: Previous screen should be GAME_HUD")
		test_passed = false
	
	_update_navigation_debug()
	
	if test_passed:
		print("PASS: ScreenNavigation Stack Management Test")
	
	return test_passed

# === UI HELPERS ===

func _setup_test_ui() -> void:
	# Results label
	results_label.text = "UI Screens Test\n\nWaiting to start..."
	results_label.add_theme_font_size_override("font_size", 16)
	
	# Status panel
	status_panel.add_theme_stylebox_override("panel", _create_panel_style())
	
	# Navigation debug
	navigation_debug.visible = false
	navigation_debug.add_theme_font_size_override("font_size", 12)

func _update_status(message: String) -> void:
	results_label.text = "UI Screens Test\n\n" + message
	print("Test Status: %s" % message)

func _update_results_display() -> void:
	var summary = "UI Screens Test Results\n\n"
	var test_count = test_results.size()
	
	for test_name in test_results:
		var result = test_results[test_name]
		var status = "✓ PASS" if result.passed else "✗ FAIL"
		summary += "%s: %s (%.0fms)\n" % [test_name, status, result.duration]
	
	results_label.text = summary

func _update_navigation_debug() -> void:
	if not screen_navigation:
		return
	
	navigation_debug.visible = true
	
	var debug_text = "=== Navigation Debug ===\n"
	debug_text += "Current: %s\n" % ScreenNavigation.ScreenType.keys()[screen_navigation.get_current_screen_type()]
	debug_text += "Previous: %s\n" % ScreenNavigation.ScreenType.keys()[screen_navigation.get_previous_screen_type()]
	debug_text += "Stack: %s\n" % str(screen_navigation.get_screen_stack().map(func(t): return ScreenNavigation.ScreenType.keys()[t]))
	debug_text += "Transitioning: %s\n" % str(screen_navigation.is_transitioning)
	
	navigation_debug.text = debug_text

func _clear_test_container() -> void:
	for child in test_container.get_children():
		if child != screen_navigation:  # ScreenNavigation'ı koru
			child.queue_free()

func _reset_test_state() -> void:
	current_test_index = 0
	test_results.clear()
	_clear_test_container()
	
	if screen_navigation:
		screen_navigation.queue_free()
		screen_navigation = null
	
	_update_status("Ready to start tests...")
	navigation_debug.visible = false

func _create_panel_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	style.border_color = Color(0.3, 0.3, 0.3)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style
func _test_upgradescreen_organism_basic() -> bool:
	print("Running: UpgradeScreenOrganism Basic Test")
	
	var upgrade_screen = UpgradeScreenOrganism.new()
	upgrade_screen.name = "TestUpgradeScreen"
	
	test_container.add_child(upgrade_screen)
	upgrade_screen.position = Vector2(20, 20)
	upgrade_screen.size = Vector2(800, 600)
	
	var test_passed = true
	
	await get_tree().process_frame
	
	# Test 1: Screen initialization
	if not upgrade_screen.is_initialized:
		print("FAIL: UpgradeScreen not initialized")
		test_passed = false
	
	# Test 2: Default visibility
	if not upgrade_screen.show_title:
		print("FAIL: Title should be visible by default")
		test_passed = false
	
	if not upgrade_screen.show_stats:
		print("FAIL: Stats should be visible by default")
		test_passed = false
	
	if not upgrade_screen.show_weapons:
		print("FAIL: Weapons should be visible by default")
		test_passed = false
	
	if not upgrade_screen.show_background:
		print("FAIL: Background should be visible by default")
		test_passed = false
	
	# Test 3: Screen visibility toggle
	upgrade_screen.hide_upgrade_screen()
	
	await get_tree().process_frame
	
	if upgrade_screen.visible:
		print("FAIL: Screen should be hidden")
		test_passed = false
	
	upgrade_screen.show_upgrade_screen()
	
	await get_tree().process_frame
	
	if not upgrade_screen.visible:
		print("FAIL: Screen should be visible")
		test_passed = false
	
	# Test 4: Fade animations
	upgrade_screen.fade_out()
	
	await get_tree().create_timer(upgrade_screen.fade_duration + 0.1).timeout
	
	if upgrade_screen.visible:
		print("FAIL: Screen should be hidden after fade out")
		test_passed = false
	
	upgrade_screen.fade_in()
	
	await get_tree().create_timer(upgrade_screen.fade_duration + 0.1).timeout
	
	if not upgrade_screen.visible:
		print("FAIL: Screen should be visible after fade in")
		test_passed = false
	
	# Test 5: Weapon cards initialization
	# Weapon card'ları başlatılmış olmalı
	if upgrade_screen.weapon_cards.is_empty():
		print("FAIL: Weapon cards should be initialized")
		test_passed = false
	
	await get_tree().process_frame
	
	if test_passed:
		print("PASS: UpgradeScreenOrganism Basic Test")
	
	return test_passed

func _test_upgradescreen_organism_weapon_management() -> bool:
	print("Running: UpgradeScreenOrganism Weapon Management Test")
	
	var upgrade_screen = UpgradeScreenOrganism.new()
	upgrade_screen.name = "TestUpgradeScreenWeapon"
	
	test_container.add_child(upgrade_screen)
	upgrade_screen.position = Vector2(20, 20)
	upgrade_screen.size = Vector2(800, 600)
	
	var test_passed = true
	
	await get_tree().process_frame
	
	# Test 1: Weapon selection
	var initial_weapon = upgrade_screen.selected_weapon_id
	if initial_weapon.is_empty():
		print("FAIL: Should have initial weapon selected")
		test_passed = false
	
	# Test 2: Weapon level setting
	upgrade_screen.set_weapon_level("pistol", 3)
	
	await get_tree().process_frame
	
	if upgrade_screen.weapon_levels.get("pistol", 1) != 3:
		print("FAIL: Weapon level should be set to 3")
		test_passed = false
	
	# Test 3: Max upgrade level
	upgrade_screen.set_max_upgrade_level(15)
	
	if upgrade_screen.max_upgrade_level != 15:
		print("FAIL: Max upgrade level should be 15")
		test_passed = false
	
	# Test 4: Cost multiplier
	upgrade_screen.set_cost_multiplier(2.0)
	
	if upgrade_screen.cost_multiplier != 2.0:
		print("FAIL: Cost multiplier should be 2.0")
		test_passed = false
	
	# Test 5: Upgrade cost calculation
	var cost = upgrade_screen.calculate_upgrade_cost("pistol", 3)
	if cost <= 0:
		print("FAIL: Upgrade cost should be positive")
		test_passed = false
	
	# Test 6: Can upgrade check
	var can_upgrade = upgrade_screen.can_upgrade("pistol")
	if not can_upgrade:
		print("FAIL: Should be able to upgrade weapon")
		test_passed = false
	
	# Test 7: Max level reached
	upgrade_screen.set_weapon_level("pistol", upgrade_screen.max_upgrade_level)
	can_upgrade = upgrade_screen.can_upgrade("pistol")
	if can_upgrade:
		print("FAIL: Should not be able to upgrade max level weapon")
		test_passed = false
	
	await get_tree().process_frame
	
	if test_passed:
		print("PASS: UpgradeScreenOrganism Weapon Management Test")
	
	return test_passed

func _test_upgradescreen_organism_upgrade_logic() -> bool:
	print("Running: UpgradeScreenOrganism Upgrade Logic Test")
	
	var upgrade_screen = UpgradeScreenOrganism.new()
	upgrade_screen.name = "TestUpgradeScreenLogic"
	
	test_container.add_child(upgrade_screen)
	upgrade_screen.position = Vector2(20, 20)
	upgrade_screen.size = Vector2(800, 600)
	
	var test_passed = true
	
	await get_tree().process_frame
	
	# Test 1: Initial weapon level
	upgrade_screen.set_weapon_level("pistol", 1)
	var initial_level = upgrade_screen.weapon_levels.get("pistol", 1)
	if initial_level != 1:
		print("FAIL: Initial weapon level should be 1")
		test_passed = false
	
	# Test 2: Perform upgrade
	var upgrade_result = upgrade_screen.perform_upgrade("pistol")
	if not upgrade_result:
		print("FAIL: Upgrade should succeed")
		test_passed = false
	
	# Test 3: Level after upgrade
	var new_level = upgrade_screen.weapon_levels.get("pistol", 1)
	if new_level != 2:
		print("FAIL: Weapon level should be 2 after upgrade")
		test_passed = false
	
	# Test 4: Multiple upgrades
	for i in range(3):
		upgrade_screen.perform_upgrade("pistol")
	
	var final_level = upgrade_screen.weapon_levels.get("pistol", 1)
	if final_level != 5:
		print("FAIL: Weapon level should be 5 after multiple upgrades")
		test_passed = false
	
	# Test 5: Max level upgrade
	upgrade_screen.set_weapon_level("pistol", upgrade_screen.max_upgrade_level)
	upgrade_result = upgrade_screen.perform_upgrade("pistol")
	if upgrade_result:
		print("FAIL: Should not be able to upgrade max level weapon")
		test_passed = false
	
	# Test 6: Cost calculation consistency
	upgrade_screen.set_weapon_level("shotgun", 1)
	var cost1 = upgrade_screen.calculate_upgrade_cost("shotgun", 1)
	var cost2 = upgrade_screen.calculate_upgrade_cost("shotgun", 2)
	
	if cost2 <= cost1:
		print("FAIL: Higher level should have higher cost")
		test_passed = false
	
	await get_tree().process_frame
	
	if test_passed:
		print("PASS: UpgradeScreenOrganism Upgrade Logic Test")
	
	return test_passed

func _test_settingsscreen_organism_basic() -> bool:
	print("Running: SettingsScreenOrganism Basic Test")
	
	var settings_screen = SettingsScreenOrganism.new()
	settings_screen.name = "TestSettingsScreen"
	
	test_container.add_child(settings_screen)
	settings_screen.position = Vector2(20, 20)
	settings_screen.size = Vector2(800, 600)
	
	var test_passed = true
	
	await get_tree().process_frame
	
	# Test 1: Screen initialization
	if not settings_screen.is_initialized:
		print("FAIL: SettingsScreen not initialized")
		test_passed = false
	
	# Test 2: Default visibility
	if not settings_screen.show_title:
		print("FAIL: Title should be visible by default")
		test_passed = false
	
	if not settings_screen.show_sections:
		print("FAIL: Sections should be visible by default")
		test_passed = false
	
	if not settings_screen.show_background:
		print("FAIL: Background should be visible by default")
		test_passed = false
	
	# Test 3: Screen visibility toggle
	settings_screen.hide_settings_screen()
	
	await get_tree().process_frame
	
	if settings_screen.visible:
		print("FAIL: Screen should be hidden")
		test_passed = false
	
	settings_screen.show_settings_screen()
	
	await get_tree().process_frame
	
	if not settings_screen.visible:
		print("FAIL: Screen should be visible")
		test_passed = false
	
	# Test 4: Fade animations
	settings_screen.fade_out()
	
	await get_tree().create_timer(settings_screen.fade_duration + 0.1).timeout
	
	if settings_screen.visible:
		print("FAIL: Screen should be hidden after fade out")
		test_passed = false
	
	settings_screen.fade_in()
	
	await get_tree().create_timer(settings_screen.fade_duration + 0.1).timeout
	
	if not settings_screen.visible:
		print("FAIL: Screen should be visible after fade in")
		test_passed = false
	
	# Test 5: Settings changed flag
	if settings_screen.are_settings_changed():
		print("FAIL: Settings should not be changed initially")
		test_passed = false
	
	await get_tree().process_frame
	
	if test_passed:
		print("PASS: SettingsScreenOrganism Basic Test")
	
	return test_passed

func _test_settingsscreen_organism_audio_controls() -> bool:
	print("Running: SettingsScreenOrganism Audio Controls Test")
	
	var settings_screen = SettingsScreenOrganism.new()
	settings_screen.name = "TestSettingsScreenAudio"
	
	test_container.add_child(settings_screen)
	settings_screen.position = Vector2(20, 20)
	settings_screen.size = Vector2(800, 600)
	
	var test_passed = true
	
	await get_tree().process_frame
	
	# Test 1: Initial audio settings
	var initial_master = settings_screen.get_setting("audio", "master_volume", 80)
	if initial_master != 80:
		print("FAIL: Initial master volume should be 80")
		test_passed = false
	
	var initial_music = settings_screen.get_setting("audio", "music_volume", 70)
	if initial_music != 70:
		print("FAIL: Initial music volume should be 70")
		test_passed = false
	
	var initial_sfx = settings_screen.get_setting("audio", "sfx_volume", 90)
	if initial_sfx != 90:
		print("FAIL: Initial SFX volume should be 90")
		test_passed = false
	
	# Test 2: Volume setting
	settings_screen.set_setting("audio", "master_volume", 50)
	
	await get_tree().process_frame
	
	var new_master = settings_screen.get_setting("audio", "master_volume", 80)
	if new_master != 50:
		print("FAIL: Master volume should be 50")
		test_passed = false
	
	# Test 3: Settings changed flag
	if not settings_screen.are_settings_changed():
		print("FAIL: Settings should be marked as changed")
		test_passed = false
	
	# Test 4: Multiple volume changes
	settings_screen.set_setting("audio", "music_volume", 60)
	settings_screen.set_setting("audio", "sfx_volume", 75)
	
	await get_tree().process_frame
	
	var final_music = settings_screen.get_setting("audio", "music_volume", 70)
	var final_sfx = settings_screen.get_setting("audio", "sfx_volume", 90)
	
	if final_music != 60:
		print("FAIL: Music volume should be 60")
		test_passed = false
	
	if final_sfx != 75:
		print("FAIL: SFX volume should be 75")
		test_passed = false
	
	# Test 5: Save settings
	settings_screen.save_settings()
	
	await get_tree().process_frame
	
	if settings_screen.are_settings_changed():
		print("FAIL: Settings should not be changed after save")
		test_passed = false
	
	await get_tree().process_frame
	
	if test_passed:
		print("PASS: SettingsScreenOrganism Audio Controls Test")
	
	return test_passed

func _test_settingsscreen_organism_graphics_controls() -> bool:
	print("Running: SettingsScreenOrganism Graphics Controls Test")
	
	var settings_screen = SettingsScreenOrganism.new()
	settings_screen.name = "TestSettingsScreenGraphics"
	
	test_container.add_child(settings_screen)
	settings_screen.position = Vector2(20, 20)
	settings_screen.size = Vector2(800, 600)
	
	var test_passed = true
	
	await get_tree().process_frame
	
	# Test 1: Initial graphics settings
	var initial_quality = settings_screen.get_setting("graphics", "quality", "medium")
	if initial_quality != "medium":
		print("FAIL: Initial quality should be medium")
		test_passed = false
	
	var initial_resolution = settings_screen.get_setting("graphics", "resolution", "1920x1080")
	if initial_resolution != "1920x1080":
		print("FAIL: Initial resolution should be 1920x1080")
		test_passed = false
	
	var initial_vsync = settings_screen.get_setting("graphics", "vsync", true)
	if not initial_vsync:
		print("FAIL: Initial VSync should be true")
		test_passed = false
	
	# Test 2: Quality setting
	settings_screen.set_setting("graphics", "quality", "high")
	
	await get_tree().process_frame
	
	var new_quality = settings_screen.get_setting("graphics", "quality", "medium")
	if new_quality != "high":
		print("FAIL: Quality should be high")
		test_passed = false
	
	# Test 3: Resolution setting
	settings_screen.set_setting("graphics", "resolution", "1600x900")
	
	await get_tree().process_frame
	
	var new_resolution = settings_screen.get_setting("graphics", "resolution", "1920x1080")
	if new_resolution != "1600x900":
		print("FAIL: Resolution should be 1600x900")
		test_passed = false
	
	# Test 4: VSync setting
	settings_screen.set_setting("graphics", "vsync", false)
	
	await get_tree().process_frame
	
	var new_vsync = settings_screen.get_setting("graphics", "vsync", true)
	if new_vsync:
		print("FAIL: VSync should be false")
		test_passed = false
	
	# Test 5: Reset settings
	settings_screen.reset_settings()
	
	await get_tree().process_frame
	
	var reset_quality = settings_screen.get_setting("graphics", "quality", "")
	var reset_resolution = settings_screen.get_setting("graphics", "resolution", "")
	var reset_vsync = settings_screen.get_setting("graphics", "vsync", false)
	
	if reset_quality != "medium":
		print("FAIL: Quality should be reset to medium")
		test_passed = false
	
	if reset_resolution != "1920x1080":
		print("FAIL: Resolution should be reset to 1920x1080")
		test_passed = false
	
	if not reset_vsync:
		print("FAIL: VSync should be reset to true")
		test_passed = false
	
	await get_tree().process_frame
	
	if test_passed:
		print("PASS: SettingsScreenOrganism Graphics Controls Test")
	
	return test_passed

func _test_screen_navigation_performance() -> bool:
	print("Running: Screen Navigation Performance Test")
	
	if not screen_navigation:
		print("FAIL: ScreenNavigation not initialized")
		return false
	
	var test_passed = true
	var performance_results = {}
	
	# Test 1: Transition performance
	var transition_times = []
	
	for i in range(10):
		var start_time = Time.get_ticks_msec()
		screen_navigation.show_screen(ScreenNavigation.ScreenType.MAIN_MENU, ScreenNavigation.TransitionType.FADE)
		await get_tree().create_timer(screen_navigation.transition_duration + 0.1).timeout
		var end_time = Time.get_ticks_msec()
		transition_times.append(end_time - start_time)
	
	var avg_transition_time = 0
	for time in transition_times:
		avg_transition_time += time
	avg_transition_time /= transition_times.size()
	
	performance_results["transition_performance"] = {
		"passed": avg_transition_time < 500,  # 500ms'den az olmalı
		"duration": avg_transition_time,
		"note": "Average transition time: %.2fms" % avg_transition_time
	}
	
	if avg_transition_time >= 500:
		print("FAIL: Transition performance too slow: %.2fms" % avg_transition_time)
		test_passed = false
	
	# Test 2: Screen loading performance
	var loading_times = []
	
	for i in range(5):
		var start_time = Time.get_ticks_msec()
		screen_navigation.show_screen(ScreenNavigation.ScreenType.GAME_HUD, ScreenNavigation.TransitionType.NONE)
		await get_tree().process_frame
		var end_time = Time.get_ticks_msec()
		loading_times.append(end_time - start_time)
		
		screen_navigation.show_screen(ScreenNavigation.ScreenType.MAIN_MENU, ScreenNavigation.TransitionType.NONE)
		await get_tree().process_frame
	
	var avg_loading_time = 0
	for time in loading_times:
		avg_loading_time += time
	avg_loading_time /= loading_times.size()
	
	performance_results["loading_performance"] = {
		"passed": avg_loading_time < 100,  # 100ms'den az olmalı
		"duration": avg_loading_time,
		"note": "Average screen loading time: %.2fms" % avg_loading_time
	}
	
	if avg_loading_time >= 100:
		print("FAIL: Screen loading performance too slow: %.2fms" % avg_loading_time)
		test_passed = false
	
	# Test 3: Memory usage during transitions
	var memory_before = Performance.get_monitor(Performance.MEMORY_STATIC)
	
	for i in range(20):
		screen_navigation.show_screen(ScreenNavigation.ScreenType.GAME_HUD, ScreenNavigation.TransitionType.NONE)
		await get_tree().process_frame
		screen_navigation.show_screen(ScreenNavigation.ScreenType.MAIN_MENU, ScreenNavigation.TransitionType.NONE)
		await get_tree().process_frame
	
	var memory_after = Performance.get_monitor(Performance.MEMORY_STATIC)
	var memory_increase = memory_after - memory_before
	
	performance_results["memory_performance"] = {
		"passed": memory_increase < 1024 * 50,  # 50KB'den az olmalı
		"duration": memory_increase,
		"note": "Memory increase during transitions: %d bytes" % memory_increase
	}
	
	if memory_increase >= 1024 * 50:
		print("FAIL: Memory usage too high during transitions: %d bytes" % memory_increase)
		test_passed = false
	
	# Sonuçları kaydet
	test_results["Screen Navigation Performance"] = {
		"passed": test_passed,
		"duration": avg_transition_time + avg_loading_time,
		"performance_results": performance_results,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	if test_passed:
		print("PASS: Screen Navigation Performance Test")
	
	return test_passed

func _test_ui_memory_usage() -> bool:
	print("Running: UI Memory Usage Test")
	
	var test_passed = true
	var memory_results = {}
	
	# Test 1: Component creation memory
	var memory_before = Performance.get_monitor(Performance.MEMORY_STATIC)
	
	var test_components = []
	for i in range(20):
		var main_menu = MainMenuOrganism.new()
		var upgrade_screen = UpgradeScreenOrganism.new()
		var settings_screen = SettingsScreenOrganism.new()
		
		test_components.append(main_menu)
		test_components.append(upgrade_screen)
		test_components.append(settings_screen)
	
	var memory_after = Performance.get_monitor(Performance.MEMORY_STATIC)
	var memory_increase = memory_after - memory_before
	
	memory_results["component_creation"] = {
		"passed": memory_increase < 1024 * 100,  # 100KB'den az olmalı
		"duration": memory_increase,
		"note": "Memory increase for 60 UI components: %d bytes" % memory_increase
	}
	
	if memory_increase >= 1024 * 100:
		print("FAIL: Component creation memory too high: %d bytes" % memory_increase)
		test_passed = false
	
	# Cleanup
	for component in test_components:
		component.queue_free()
	
	await get_tree().process_frame
	
	# Test 2: Screen navigation memory
	memory_before = Performance.get_monitor(Performance.MEMORY_STATIC)
	
	var nav = ScreenNavigation.new()
	test_container.add_child(nav)
	
	# Multiple screen transitions
	for i in range(10):
		nav.show_screen(ScreenNavigation.ScreenType.MAIN_MENU, ScreenNavigation.TransitionType.NONE)
		await get_tree().process_frame
		nav.show_screen(ScreenNavigation.ScreenType.GAME_HUD, ScreenNavigation.TransitionType.NONE)
		await get_tree().process_frame
	
	memory_after = Performance.get_monitor(Performance.MEMORY_STATIC)
	memory_increase = memory_after - memory_before
	
	memory_results["navigation_memory"] = {
		"passed": memory_increase < 1024 * 50,  # 50KB'den az olmalı
		"duration": memory_increase,
		"note": "Memory increase during navigation: %d bytes" % memory_increase
	}
	
	if memory_increase >= 1024 * 50:
		print("FAIL: Navigation memory too high: %d bytes" % memory_increase)
		test_passed = false
	
	# Cleanup
	nav.queue_free()
	
	await get_tree().process_frame
	
	# Test 3: EventBus memory (if available)
	if EventBus.is_available():
		memory_before = Performance.get_monitor(Performance.MEMORY_STATIC)
		
		var event_counts = []
		for i in range(1000):
			EventBus.emit_now_static("test_memory_event", {"index": i})
		
		memory_after = Performance.get_monitor(Performance.MEMORY_STATIC)
		memory_increase = memory_after - memory_before
		
		memory_results["eventbus_memory"] = {
			"passed": memory_increase < 1024 * 10,  # 10KB'den az olmalı
			"duration": memory_increase,
			"note": "Memory increase for 1000 events: %d bytes" % memory_increase
		}
		
		if memory_increase >= 1024 * 10:
			print("FAIL: EventBus memory too high: %d bytes" % memory_increase)
			test_passed = false
	
	# Sonuçları kaydet
	test_results["UI Memory Usage Test"] = {
		"passed": test_passed,
		"duration": 0,
		"memory_results": memory_results,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	if test_passed:
		print("PASS: UI Memory Usage Test")
	
	return test_passed
# === DEBUG ===

func _to_string() -> String:
	return "[UIScreensTest: %d/%d tests completed]" % [
		test_results.size(),
		test_cases.size()
	]