# 🧪 UI TEST BASE CLASS
# Tüm UI test modülleri için temel sınıf
class_name UITestBase
extends Node

# === NODES ===
@onready var test_container: Control = $TestContainer
@onready var results_label: Label = $ResultsLabel
@onready var status_panel: Panel = $StatusPanel

# === STATE ===
var current_test_index: int = 0
var test_results: Dictionary = {}
var is_testing: bool = false
var test_queue: Array = []
var module_name: String = "Base"

# === LIFECYCLE ===

func _ready() -> void:
	print("%s Test Module initialized" % module_name)
	_setup_test_ui()

# === PUBLIC API ===

func run_all_tests() -> void:
	if is_testing:
		push_warning("Tests already running")
		return
	
	_reset_test_state()
	_start_tests()

func run_specific_test(test_name: String) -> void:
	for test_case in test_queue:
		if test_case.name == test_name:
			_run_test_case(test_case)
			return
	
	push_warning("Test not found: %s" % test_name)

func get_test_results() -> Dictionary:
	return test_results.duplicate()

func print_test_summary() -> void:
	var passed = 0
	var total = test_results.size()
	
	for test_name in test_results:
		if test_results[test_name].passed:
			passed += 1
	
	print("=== %s Test Summary ===" % module_name)
	print("Total Tests: %d" % total)
	print("Passed: %d" % passed)
	print("Failed: %d" % (total - passed))
	print("Success Rate: %.1f%%" % (float(passed) / total * 100 if total > 0 else 0))

# === TEST EXECUTION ===

func _start_tests() -> void:
	is_testing = true
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
		test_queue.size() + current_test_index
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
	await get_tree().create_timer(1.0).timeout
	_run_next_test()

func _on_all_tests_completed() -> void:
	is_testing = false
	_update_status("All tests completed!")
	print_test_summary()
	
	# EventBus'a bildir
	if EventBus.is_available():
		EventBus.emit_now_static("ui_test_completed", {
			"test_type": module_name,
			"results": test_results,
			"timestamp": Time.get_unix_time_from_system()
		})

# === UI HELPERS ===

func _setup_test_ui() -> void:
	# Results label
	results_label.text = "%s Test\n\nWaiting to start..." % module_name
	results_label.add_theme_font_size_override("font_size", 16)
	
	# Status panel
	status_panel.add_theme_stylebox_override("panel", _create_panel_style())

func _update_status(message: String) -> void:
	results_label.text = "%s Test\n\n" % module_name + message
	print("Test Status: %s" % message)

func _update_results_display() -> void:
	var summary = "%s Test Results\n\n" % module_name
	
	for test_name in test_results:
		var result = test_results[test_name]
		var status = "✓ PASS" if result.passed else "✗ FAIL"
		summary += "%s: %s (%.0fms)\n" % [test_name, status, result.duration]
	
	results_label.text = summary

func _clear_test_container() -> void:
	for child in test_container.get_children():
		child.queue_free()

func _reset_test_state() -> void:
	current_test_index = 0
	test_results.clear()
	_clear_test_container()
	_update_status("Ready to start tests...")

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

# === DEBUG ===

func _to_string() -> String:
	return "[%sTest: %d tests completed]" % [
		module_name,
		test_results.size()
	]