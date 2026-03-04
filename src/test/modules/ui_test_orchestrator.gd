# 🧪 UI TEST ORCHESTRATOR
# Tüm UI test modüllerini yönetir ve koordine eder
class_name UITestOrchestrator
extends Node

# === NODES ===
@onready var test_container: Control = $TestContainer
@onready var results_label: Label = $ResultsLabel
@onready var status_panel: Panel = $StatusPanel
@onready var navigation_debug: Label = $NavigationDebug

# === STATE ===
var current_module_index: int = 0
var all_test_results: Dictionary = {}
var is_testing: bool = false
var module_queue: Array = []
var current_module: UITestBase = null

# === MODULES ===
var test_modules = [
	{
		"name": "MainMenu",
		"class": MainMenuTestModule,
		"scene_path": "res://src/test/modules/mainmenu_test_module.tscn"
	},
	{
		"name": "ScreenNavigation",
		"class": ScreenNavigationTestModule,
		"scene_path": "res://src/test/modules/screennavigation_test_module.tscn"
	},
	{
		"name": "UpgradeScreen",
		"class": UpgradeScreenTestModule,
		"scene_path": "res://src/test/modules/upgradescreen_test_module.tscn"
	},
	{
		"name": "SettingsScreen",
		"class": SettingsScreenTestModule,
		"scene_path": "res://src/test/modules/settingsscreen_test_module.tscn"
	},
	{
		"name": "Performance",
		"class": PerformanceTestModule,
		"scene_path": "res://src/test/modules/performance_test_module.tscn"
	},
	{
		"name": "Balance",
		"class": BalanceTestModule,
		"scene_path": "res://src/test/modules/balance/balance_test_module.tscn"
	},
	{
		"name": "SaveSystem",
		"class": SaveTestOrchestrator,
		"scene_path": "res://src/core/systems/save_system/test/save_test_orchestrator.tscn"
	}
]

# === LIFECYCLE ===

func _ready() -> void:
	print("UI Test Orchestrator initialized")
	_setup_test_ui()
	_initialize_modules()

# === PUBLIC API ===

func run_all_tests() -> void:
	if is_testing:
		push_warning("Tests already running")
		return
	
	_reset_test_state()
	_start_all_tests()

func run_specific_module(module_name: String) -> void:
	for module_info in test_modules:
		if module_info.name == module_name:
			_run_module(module_info)
			return
	
	push_warning("Module not found: %s" % module_name)

func get_all_test_results() -> Dictionary:
	return all_test_results.duplicate()

func print_comprehensive_summary() -> void:
	var total_tests = 0
	var total_passed = 0
	
	print("=== COMPREHENSIVE UI TEST SUMMARY ===")
	
	for module_name in all_test_results:
		var module_results = all_test_results[module_name]
		var module_passed = 0
		var module_total = module_results.size()
		
		for test_name in module_results:
			if module_results[test_name].passed:
				module_passed += 1
		
		total_tests += module_total
		total_passed += module_passed
		
		print("\n%s Module:" % module_name)
		print("  Tests: %d/%d passed (%.1f%%)" % [
			module_passed,
			module_total,
			float(module_passed) / module_total * 100 if module_total > 0 else 0
		])
	
	print("\n=== OVERALL SUMMARY ===")
	print("Total Modules: %d" % all_test_results.size())
	print("Total Tests: %d" % total_tests)
	print("Total Passed: %d" % total_passed)
	print("Total Failed: %d" % (total_tests - total_passed))
	print("Overall Success Rate: %.1f%%" % (float(total_passed) / total_tests * 100 if total_tests > 0 else 0))

# === TEST EXECUTION ===

func _initialize_modules() -> void:
	module_queue = test_modules.duplicate()

func _start_all_tests() -> void:
	is_testing = true
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
	if not current_module is UITestBase:
		push_error("Module is not UITestBase: %s" % module_info.name)
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
	print_comprehensive_summary()
	
	# Update results display
	_update_results_display()
	
	# EventBus'a bildir
	if EventBus.is_available():
		EventBus.emit_now_static("ui_test_all_completed", {
			"results": all_test_results,
			"timestamp": Time.get_unix_time_from_system()
		})

# === UI HELPERS ===

func _setup_test_ui() -> void:
	# Results label
	results_label.text = "UI Test Orchestrator\n\nWaiting to start..."
	results_label.add_theme_font_size_override("font_size", 16)
	
	# Status panel
	status_panel.add_theme_stylebox_override("panel", _create_panel_style())
	
	# Navigation debug
	navigation_debug.visible = false
	navigation_debug.add_theme_font_size_override("font_size", 12)

func _update_status(message: String) -> void:
	results_label.text = "UI Test Orchestrator\n\n" + message
	print("Orchestrator Status: %s" % message)

func _update_results_display() -> void:
	var summary = "UI Test Orchestrator Results\n\n"
	
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

func _clear_test_container() -> void:
	for child in test_container.get_children():
		child.queue_free()

func _reset_test_state() -> void:
	current_module_index = 0
	all_test_results.clear()
	_clear_test_container()
	module_queue = test_modules.duplicate()
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

# === DEBUG ===

func _to_string() -> String:
	return "[UITestOrchestrator: %d modules completed]" % all_test_results.size()