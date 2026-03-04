# 🧪 SAVE TEST BASE
# Tüm SaveSystem testleri için temel sınıf
class_name SaveTestBase
extends "res://src/test/modules/ui_test_base.gd"

# === IMPORTS ===
const SaveManager = preload("res://src/core/systems/save_system/save_manager.gd")

# === TEST TYPES ===
enum TestType {
	UNIT = 0,
	INTEGRATION = 1,
	PERFORMANCE = 2,
	STRESS = 3,
	CORRUPTION = 4,
	RECOVERY = 5
}

# === TEST RESULT ===
class TestResult:
	var test_name: String
	var test_type: TestType
	var success: bool
	var error: String = ""
	var duration_ms: int = 0
	var data: Dictionary = {}
	
	func _init(name: String, type: TestType, success_val: bool, duration: int = 0, error_val: String = ""):
		test_name = name
		test_type = type
		success = success_val
		duration_ms = duration
		error = error_val
	
	func _to_string() -> String:
		var status = "✅ PASS" if success else "❌ FAIL"
		return "[%s] %s (%d ms)" % [status, test_name, duration_ms]

# === STATE ===
var detailed_test_results: Array[TestResult] = []
var save_manager = null
var test_save_data_cache: Dictionary = {}

# === LIFECYCLE ===

func _ready() -> void:
	module_name = "SaveSystem"
	super._ready()
	print("SaveTestBase initialized")
	
	# Get SaveManager instance
	# Try to find existing SaveManager in scene tree
	save_manager = get_node("/root/SaveManager") if has_node("/root/SaveManager") else null
	if not save_manager:
		# Try to create new instance
		save_manager = SaveManager.new() if SaveManager else null

# === TEST EXECUTION OVERRIDE ===

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
	
	# Convert result to simple boolean for UITestBase
	var passed = false
	var error_msg = ""
	
	if result is Dictionary:
		passed = result.get("success", false)
		error_msg = result.get("error", "")
	else:
		passed = bool(result)
	
	# Store detailed result
	var detailed_result = TestResult.new(
		test_case.name,
		TestType.UNIT,
		passed,
		duration,
		error_msg
	)
	
	if result is Dictionary and result.has("data"):
		detailed_result.data = result.data
	
	detailed_test_results.append(detailed_result)
	
	# Store simple result for UITestBase
	test_results[test_case.name] = {
		"passed": passed,
		"duration": duration,
		"timestamp": Time.get_unix_time_from_system(),
		"error": error_msg
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
	print_detailed_results()
	
	# EventBus'a bildir
	if EventBus.is_available():
		EventBus.emit_now_static("ui_test_completed", {
			"test_type": module_name,
			"results": test_results,
			"detailed_results": detailed_test_results,
			"timestamp": Time.get_unix_time_from_system()
		})

# === PUBLIC API EXTENSIONS ===

func get_detailed_test_results() -> Array:
	return detailed_test_results.duplicate()

func get_test_statistics() -> Dictionary:
	var total_tests = detailed_test_results.size()
	var passed_tests = detailed_test_results.filter(func(r): return r.success).size()
	var failed_tests = total_tests - passed_tests
	
	var total_duration = 0
	var unit_tests = 0
	var integration_tests = 0
	var performance_tests = 0
	
	for result in detailed_test_results:
		total_duration += result.duration_ms
		
		match result.test_type:
			TestType.UNIT: unit_tests += 1
			TestType.INTEGRATION: integration_tests += 1
			TestType.PERFORMANCE: performance_tests += 1
	
	return {
		"total_tests": total_tests,
		"passed_tests": passed_tests,
		"failed_tests": failed_tests,
		"success_rate": float(passed_tests) / total_tests * 100.0 if total_tests > 0 else 0.0,
		"total_duration_ms": total_duration,
		"avg_duration_ms": float(total_duration) / total_tests if total_tests > 0 else 0.0,
		"unit_tests": unit_tests,
		"integration_tests": integration_tests,
		"performance_tests": performance_tests
	}

func clear_detailed_test_results() -> void:
	detailed_test_results.clear()
	print("Detailed test results cleared")

func print_detailed_results() -> void:
	var stats = get_test_statistics()
	print("=== SaveTestModule Detailed Results ===")
	print("Total Tests: %d" % stats.total_tests)
	print("Passed: %d" % stats.passed_tests)
	print("Failed: %d" % stats.failed_tests)
	print("Success Rate: %.1f%%" % stats.success_rate)
	print("Total Duration: %d ms" % stats.total_duration_ms)
	print("Average Duration: %.1f ms" % stats.avg_duration_ms)
	print("Unit Tests: %d" % stats.unit_tests)
	print("Integration Tests: %d" % stats.integration_tests)
	print("Performance Tests: %d" % stats.performance_tests)
	
	if not detailed_test_results.is_empty():
		print("\nDetailed Results:")
		for result in detailed_test_results:
			print("  %s" % result)

# === UTILITY FUNCTIONS ===

func _calculate_average(values: Array) -> float:
	if values.is_empty():
		return 0.0
	
	var sum = 0.0
	for value in values:
		sum += float(value)
	
	return sum / values.size()

func _calculate_max(values: Array) -> float:
	if values.is_empty():
		return 0.0
	
	var max_value = values[0]
	for value in values:
		if value > max_value:
			max_value = value
	
	return float(max_value)

# === DEBUG ===

func _to_string() -> String:
	return "[SaveTestBase: %d detailed tests]" % detailed_test_results.size()