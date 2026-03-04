# 🧪 PERFORMANCE TEST MODULE
# UI performans testlerini yönetir
class_name PerformanceTestModule
extends UITestBase

# === STATE ===
var screen_navigation: ScreenNavigation = null
var test_cases = [
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
	module_name = "Performance"
	test_queue = test_cases.duplicate()
	super._ready()

# === TEST CASES IMPLEMENTATION ===

func _test_screen_navigation_performance() -> bool:
	print("Running: Screen Navigation Performance Test")
	
	# ScreenNavigation oluştur
	screen_navigation = ScreenNavigation.new()
	screen_navigation.name = "TestScreenNavigationPerformance"
	
	test_container.add_child(screen_navigation)
	screen_navigation.position = Vector2(20, 20)
	screen_navigation.size = Vector2(800, 600)
	
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

# === CLEANUP ===

func _on_all_tests_completed() -> void:
	# Cleanup
	if screen_navigation:
		screen_navigation.queue_free()
		screen_navigation = null
	
	super._on_all_tests_completed()