# 🧪 SAVE TEST ORCHESTRATOR
# Tüm SaveSystem test modüllerini yönetir ve koordine eder
class_name SaveTestOrchestrator
extends "res://src/test/modules/ui_test_base.gd"

# === IMPORTS ===
const SaveTestBase = preload("res://src/core/systems/save_system/test/save_test_base.gd")
const SaveUnitTests = preload("res://src/core/systems/save_system/test/save_unit_tests.gd")
const SaveIntegrationTests = preload("res://src/core/systems/save_system/test/save_integration_tests.gd")
const SavePerformanceTests = preload("res://src/core/systems/save_system/test/save_performance_tests.gd")
const SaveRecoveryTests = preload("res://src/core/systems/save_system/test/save_recovery_tests.gd")

# === TEST MODULES ===
var test_modules = [
	{
		"name": "UnitTests",
		"class": SaveUnitTests,
		"scene_path": "res://src/core/systems/save_system/test/save_unit_tests.tscn"
	},
	{
		"name": "IntegrationTests",
		"class": SaveIntegrationTests,
		"scene_path": "res://src/core/systems/save_system/test/save_integration_tests.tscn"
	},
	{
		"name": "PerformanceTests",
		"class": SavePerformanceTests,
		"scene_path": "res://src/core/systems/save_system/test/save_performance_tests.tscn"
	},
	{
		"name": "RecoveryTests",
		"class": SaveRecoveryTests,
		"scene_path": "res://src/core/systems/save_system/test/save_recovery_tests.tscn"
	}
]

# === STATE ===
var current_module_index: int = 0
var all_test_results: Dictionary = {}
var module_queue: Array = []
var current_module: SaveTestBase = null

# === LIFECYCLE ===

func _ready() -> void:
	module_name = "SaveSystem"
	super._ready()
	print("SaveTestOrchestrator initialized")
	_initialize_modules()

# === PUBLIC API ===

func run_all_tests() -> Dictionary:
	if is_testing:
		return {"success": false, "error": "Already testing"}
	
	is_testing = true
	_reset_test_state()
	_start_all_tests()
	
	# Return promise-like result
	return {
		"success": true,
		"message": "Tests started",
		"total_modules": test_modules.size()
	}

func run_specific_module(module_name: String) -> Dictionary:
	for module_info in test_modules:
		if module_info.name == module_name:
			_run_module(module_info)
			return {"success": true, "message": "Module started: " + module_name}
	
	return {"success": false, "error": "Module not found: " + module_name}

func run_test_category(category: String) -> Dictionary:
	var category_map = {
		"unit": "UnitTests",
		"integration": "IntegrationTests",
		"performance": "PerformanceTests",
		"recovery": "RecoveryTests"
	}
	
	if not category_map.has(category):
		return {"success": false, "error": "Invalid category: " + category}
	
	return run_specific_module(category_map[category])

func get_all_test_results() -> Dictionary:
	return all_test_results.duplicate()

func get_comprehensive_statistics() -> Dictionary:
	var total_tests = 0
	var total_passed = 0
	var total_duration = 0
	
	for module_name in all_test_results:
		var module_results = all_test_results[module_name]
		var module_passed = 0
		var module_total = module_results.size()
		
		for test_name in module_results:
			var test_result = module_results[test_name]
			if test_result.passed:
				module_passed += 1
			total_duration += test_result.duration
		
		total_tests += module_total
		total_passed += module_passed
	
	return {
		"total_modules": all_test_results.size(),
		"total_tests": total_tests,
		"total_passed": total_passed,
		"total_failed": total_tests - total_passed,
		"success_rate": float(total_passed) / total_tests * 100.0 if total_tests > 0 else 0.0,
		"total_duration_ms": total_duration,
		"avg_duration_per_test": float(total_duration) / total_tests if total_tests > 0 else 0.0
	}

# === TEST EXECUTION ===

func _initialize_modules() -> void:
	module_queue = test_modules.duplicate()

func _start_all_tests() -> void:
	_run_next_module()

func _run_next_module() -> void:
	if module_queue.is_empty():
		_on_all_modules_completed()
		return
	
	var module_info = module_queue.pop_front()
	_run_module(module_info)

func _run_module(module_info: Dictionary) -> void:
	current_module_index += 1
	
	# Clear previous module
	_clear_test_container()
	
	# Update status
	_update_status("Running Module: %s (%d/%d)" % [
		module_info.name,
		current_module_index,
		module_queue.size() + current_module_index
	])
	
	# Load module scene
	var module_scene = load(module_info.scene_path)
	if not module_scene:
		push_error("Failed to load module scene: %s" % module_info.scene_path)
		_run_next_module()
		return
	
	# Create module instance
	current_module = module_scene.instantiate()
	if not current_module is SaveTestBase:
		push_error("Module is not SaveTestBase: %s" % module_info.name)
		current_module.queue_free()
		_run_next_module()
		return
	
	# Add to container
	test_container.add_child(current_module)
	
	# Connect signals
	current_module.tree_exiting.connect(_on_module_completed.bind(module_info.name))
	
	# Run module tests
	current_module.run_all_tests()

func _on_module_completed(module_name: String) -> void:
	# Collect results
	if current_module:
		var module_results = current_module.get_test_results()
		all_test_results[module_name] = module_results
	
	# Cleanup
	current_module = null
	
	# Next module
	await get_tree().create_timer(1.0).timeout
	_run_next_module()

func _on_all_modules_completed() -> void:
	is_testing = false
	_update_status("All modules completed!")
	
	# Print comprehensive summary
	_print_comprehensive_summary()
	
	# Update results display
	_update_results_display()
	
	# EventBus'a bildir
	if EventBus.is_available():
		EventBus.emit_now_static("save_test_all_completed", {
			"results": all_test_results,
			"statistics": get_comprehensive_statistics(),
			"timestamp": Time.get_unix_time_from_system()
		})

# === UI HELPERS ===

func _update_results_display() -> void:
	var summary = "SaveSystem Test Results\n\n"
	var stats = get_comprehensive_statistics()
	
	summary += "Modules: %d\n" % stats.total_modules
	summary += "Total Tests: %d\n" % stats.total_tests
	summary += "Passed: %d\n" % stats.total_passed
	summary += "Failed: %d\n" % stats.total_failed
	summary += "Success Rate: %.1f%%\n" % stats.success_rate
	summary += "Total Duration: %d ms\n\n" % stats.total_duration_ms
	
	for module_name in all_test_results:
		var module_results = all_test_results[module_name]
		var module_passed = 0
		var module_total = module_results.size()
		
		for test_name in module_results:
			if module_results[test_name].passed:
				module_passed += 1
		
		summary += "%s: %d/%d passed (%.1f%%)\n" % [
			module_name,
			module_passed,
			module_total,
			float(module_passed) / module_total * 100 if module_total > 0 else 0
		]
	
	results_label.text = summary

func _reset_test_state() -> void:
	current_module_index = 0
	all_test_results.clear()
	_clear_test_container()
	module_queue = test_modules.duplicate()
	_update_status("Ready to start tests...")

func _print_comprehensive_summary() -> void:
	var stats = get_comprehensive_statistics()
	
	print("=== COMPREHENSIVE SAVESYSTEM TEST SUMMARY ===")
	print("Total Modules: %d" % stats.total_modules)
	print("Total Tests: %d" % stats.total_tests)
	print("Total Passed: %d" % stats.total_passed)
	print("Total Failed: %d" % stats.total_failed)
	print("Overall Success Rate: %.1f%%" % stats.success_rate)
	print("Total Duration: %d ms" % stats.total_duration_ms)
	print("Average Duration per Test: %.1f ms" % stats.avg_duration_per_test)
	
	for module_name in all_test_results:
		var module_results = all_test_results[module_name]
		var module_passed = 0
		var module_total = module_results.size()
		
		for test_name in module_results:
			if module_results[test_name].passed:
				module_passed += 1
		
		print("\n%s Module:" % module_name)
		print("  Tests: %d/%d passed (%.1f%%)" % [
			module_passed,
			module_total,
			float(module_passed) / module_total * 100 if module_total > 0 else 0
		])

# === DEBUG ===

func _to_string() -> String:
	return "[SaveTestOrchestrator: %d modules completed]" % all_test_results.size()