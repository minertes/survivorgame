# 🧪 SCREEN NAVIGATION TEST MODULE
# ScreenNavigation testlerini yönetir
class_name ScreenNavigationTestModule
extends UITestBase

# === STATE ===
var screen_navigation: ScreenNavigation = null
var test_cases = [
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
	}
]

# === LIFECYCLE ===

func _ready() -> void:
	module_name = "ScreenNavigation"
	test_queue = test_cases.duplicate()
	super._ready()

# === TEST CASES IMPLEMENTATION ===

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
	
	if test_passed:
		print("PASS: ScreenNavigation Stack Management Test")
	
	return test_passed

# === CLEANUP ===

func _on_all_tests_completed() -> void:
	# Cleanup
	if screen_navigation:
		screen_navigation.queue_free()
		screen_navigation = null
	
	super._on_all_tests_completed()