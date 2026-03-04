# 🧪 UI ATOMS TEST
# UI Atom component'larını test eder
class_name UIAtomsTest
extends Node

# === TEST CONFIG ===
const TEST_SCENE_PATH = "res://src/test/ui_test_scene.tscn"

# === NODES ===
@onready var test_container: Control = $TestContainer
@onready var results_label: Label = $ResultsLabel
@onready var status_panel: Panel = $StatusPanel

# === STATE ===
var current_test_index: int = 0
var test_results: Dictionary = {}
var is_testing: bool = false
var test_queue: Array = []

# === TEST CASES ===
var test_cases = [
	{
		"name": "ButtonAtom Basic",
		"function": "_test_button_atom_basic"
	},
	{
		"name": "ButtonAtom Styles",
		"function": "_test_button_atom_styles"
	},
	{
		"name": "LabelAtom Basic",
		"function": "_test_label_atom_basic"
	},
	{
		"name": "LabelAtom Styles",
		"function": "_test_label_atom_styles"
	},
	{
		"name": "ProgressBarAtom Basic",
		"function": "_test_progress_bar_atom_basic"
	},
	{
		"name": "ProgressBarAtom Animations",
		"function": "_test_progress_bar_atom_animations"
	},
	{
		"name": "PanelAtom Basic",
		"function": "_test_panel_atom_basic"
	},
	{
		"name": "PanelAtom Children",
		"function": "_test_panel_atom_children"
	},
	{
		"name": "IconAtom Basic",
		"function": "_test_icon_atom_basic"
	},
	{
		"name": "IconAtom Animations",
		"function": "_test_icon_atom_animations"
	}
]

# === LIFECYCLE ===

func _ready() -> void:
	print("UI Atoms Test initialized")
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
	
	print("=== UI Atoms Test Summary ===")
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
	await get_tree().create_timer(1.0).timeout
	_run_next_test()

func _on_all_tests_completed() -> void:
	is_testing = false
	_update_status("All tests completed!")
	print_test_summary()
	
	# EventBus'a bildir
	if EventBus.is_available():
		EventBus.emit_now_static("ui_test_completed", {
			"test_type": "atoms",
			"results": test_results,
			"timestamp": Time.get_unix_time_from_system()
		})

# === TEST CASES IMPLEMENTATION ===

func _test_button_atom_basic() -> bool:
	print("Running: ButtonAtom Basic Test")
	
	# ButtonAtom oluştur
	var button = ButtonAtom.new()
	button.name = "TestButton"
	button.button_text = "Click Me!"
	button.button_style = "primary"
	
	# Test container'a ekle
	test_container.add_child(button)
	
	# Position
	button.position = Vector2(50, 50)
	
	# Test interactions
	var test_passed = true
	
	# Test 1: Button text
	if button.button_text != "Click Me!":
		print("FAIL: Button text mismatch")
		test_passed = false
	
	# Test 2: Button style
	if button.button_style != "primary":
		print("FAIL: Button style mismatch")
		test_passed = false
	
	# Test 3: Button visibility
	if not button.visible:
		print("FAIL: Button not visible")
		test_passed = false
	
	# Test 4: Button enabled
	if button.is_disabled:
		print("FAIL: Button should be enabled")
		test_passed = false
	
	# Wait for UI to update
	await get_tree().process_frame
	
	if test_passed:
		print("PASS: ButtonAtom Basic Test")
	
	return test_passed

func _test_button_atom_styles() -> bool:
	print("Running: ButtonAtom Styles Test")
	
	var styles = ["primary", "secondary", "danger"]
	var test_passed = true
	var y_offset = 0
	
	for style in styles:
		var button = ButtonAtom.new()
		button.name = "Button_" + style
		button.button_text = style.capitalize()
		button.button_style = style
		
		test_container.add_child(button)
		button.position = Vector2(50, 50 + y_offset)
		y_offset += 60
		
		# Style kontrolü
		if button.button_style != style:
			print("FAIL: Style mismatch for %s" % style)
			test_passed = false
	
	# Wait for UI to update
	await get_tree().process_frame
	
	if test_passed:
		print("PASS: ButtonAtom Styles Test")
	
	return test_passed

func _test_label_atom_basic() -> bool:
	print("Running: LabelAtom Basic Test")
	
	var label = LabelAtom.new()
	label.name = "TestLabel"
	label.label_text = "Hello, World!"
	label.label_style = "title"
	
	test_container.add_child(label)
	label.position = Vector2(50, 50)
	
	var test_passed = true
	
	# Test 1: Label text
	if label.label_text != "Hello, World!":
		print("FAIL: Label text mismatch")
		test_passed = false
	
	# Test 2: Label style
	if label.label_style != "title":
		print("FAIL: Label style mismatch")
		test_passed = false
	
	# Test 3: Label visibility
	if not label.visible:
		print("FAIL: Label not visible")
		test_passed = false
	
	await get_tree().process_frame
	
	if test_passed:
		print("PASS: LabelAtom Basic Test")
	
	return test_passed

func _test_label_atom_styles() -> bool:
	print("Running: LabelAtom Styles Test")
	
	var styles = ["default", "title", "subtitle", "small"]
	var test_passed = true
	var y_offset = 0
	
	for style in styles:
		var label = LabelAtom.new()
		label.name = "Label_" + style
		label.label_text = "Style: " + style
		label.label_style = style
		
		test_container.add_child(label)
		label.position = Vector2(50, 50 + y_offset)
		y_offset += 40
		
		if label.label_style != style:
			print("FAIL: Style mismatch for %s" % style)
			test_passed = false
	
	await get_tree().process_frame
	
	if test_passed:
		print("PASS: LabelAtom Styles Test")
	
	return test_passed

func _test_progress_bar_atom_basic() -> bool:
	print("Running: ProgressBarAtom Basic Test")
	
	var progress_bar = ProgressBarAtom.new()
	progress_bar.name = "TestProgressBar"
	progress_bar.min_value = 0
	progress_bar.max_value = 100
	progress_bar.current_value = 75
	progress_bar.bar_style = "health"
	progress_bar.show_percentage = true
	
	test_container.add_child(progress_bar)
	progress_bar.position = Vector2(50, 50)
	
	var test_passed = true
	
	# Test 1: Value range
	if progress_bar.current_value != 75:
		print("FAIL: Current value mismatch")
		test_passed = false
	
	# Test 2: Percentage
	var expected_percentage = 75.0
	if abs(progress_bar.get_percentage() - expected_percentage) > 0.1:
		print("FAIL: Percentage calculation error")
		test_passed = false
	
	# Test 3: Style
	if progress_bar.bar_style != "health":
		print("FAIL: Style mismatch")
		test_passed = false
	
	await get_tree().process_frame
	
	if test_passed:
		print("PASS: ProgressBarAtom Basic Test")
	
	return test_passed

func _test_progress_bar_atom_animations() -> bool:
	print("Running: ProgressBarAtom Animations Test")
	
	var progress_bar = ProgressBarAtom.new()
	progress_bar.name = "TestProgressBarAnim"
	progress_bar.min_value = 0
	progress_bar.max_value = 100
	progress_bar.current_value = 0
	progress_bar.bar_style = "experience"
	
	test_container.add_child(progress_bar)
	progress_bar.position = Vector2(50, 50)
	
	var test_passed = true
	
	# Animate value change
	progress_bar.set_value(100, true)
	
	# Wait for animation
	await get_tree().create_timer(0.5).timeout
	
	# Check final value
	if progress_bar.current_value != 100:
		print("FAIL: Animation didn't reach target value")
		test_passed = false
	
	await get_tree().process_frame
	
	if test_passed:
		print("PASS: ProgressBarAtom Animations Test")
	
	return test_passed

func _test_panel_atom_basic() -> bool:
	print("Running: PanelAtom Basic Test")
	
	var panel = PanelAtom.new()
	panel.name = "TestPanel"
	panel.panel_style = "default"
	panel.padding_all = 20
	
	test_container.add_child(panel)
	panel.position = Vector2(50, 50)
	panel.size = Vector2(200, 150)
	
	var test_passed = true
	
	# Test 1: Panel style
	if panel.panel_style != "default":
		print("FAIL: Panel style mismatch")
		test_passed = false
	
	# Test 2: Panel padding
	if panel.padding_all != 20:
		print("FAIL: Panel padding mismatch")
		test_passed = false
	
	await get_tree().process_frame
	
	if test_passed:
		print("PASS: PanelAtom Basic Test")
	
	return test_passed

func _test_panel_atom_children() -> bool:
	print("Running: PanelAtom Children Test")
	
	var panel = PanelAtom.new()
	panel.name = "TestPanelChildren"
	panel.panel_style = "highlight"
	
	test_container.add_child(panel)
	panel.position = Vector2(50, 50)
	panel.size = Vector2(300, 200)
	
	# Add child atoms
	var label = LabelAtom.new()
	label.label_text = "Panel Child Label"
	panel.add_child_atom(label)
	
	var button = ButtonAtom.new()
	button.button_text = "Panel Button"
	panel.add_child_atom(button)
	
	var test_passed = true
	
	# Test child count
	var child_count = panel.get_children_atoms().size()
	if child_count != 2:
		print("FAIL: Expected 2 children, got %d" % child_count)
		test_passed = false
	
	await get_tree().process_frame
	
	if test_passed:
		print("PASS: PanelAtom Children Test")
	
	return test_passed

func _test_icon_atom_basic() -> bool:
	print("Running: IconAtom Basic Test")
	
	var icon = IconAtom.new()
	icon.name = "TestIcon"
	icon.icon_size = Vector2(64, 64)
	icon.icon_color = Color.RED
	
	# Note: Gerçek texture yüklemek için asset gerekli
	# icon.icon_texture = preload("res://assets/test_icon.png")
	
	test_container.add_child(icon)
	icon.position = Vector2(50, 50)
	
	var test_passed = true
	
	# Test 1: Icon size
	if icon.icon_size != Vector2(64, 64):
		print("FAIL: Icon size mismatch")
		test_passed = false
	
	# Test 2: Icon color
	if icon.icon_color != Color.RED:
		print("FAIL: Icon color mismatch")
		test_passed = false
	
	await get_tree().process_frame
	
	if test_passed:
		print("PASS: IconAtom Basic Test")
	
	return test_passed

func _test_icon_atom_animations() -> bool:
	print("Running: IconAtom Animations Test")
	
	var icon = IconAtom.new()
	icon.name = "TestIconAnim"
	icon.icon_size = Vector2(48, 48)
	icon.icon_color = Color.BLUE
	
	test_container.add_child(icon)
	icon.position = Vector2(50, 50)
	
	var test_passed = true
	
	# Color animation test
	icon.set_color(Color.GREEN, true)
	
	# Wait for animation
	await get_tree().create_timer(0.4).timeout
	
	# Check color
	if icon.icon_color != Color.GREEN:
		print("FAIL: Color animation didn't reach target")
		test_passed = false
	
	# Pulse animation test
	icon.pulse_color(Color.YELLOW, 0.3)
	
	await get_tree().create_timer(0.4).timeout
	
	await get_tree().process_frame
	
	if test_passed:
		print("PASS: IconAtom Animations Test")
	
	return test_passed

# === UI HELPERS ===

func _setup_test_ui() -> void:
	# Results label
	results_label.text = "UI Atoms Test\n\nWaiting to start..."
	results_label.add_theme_font_size_override("font_size", 16)
	
	# Status panel
	status_panel.add_theme_stylebox_override("panel", _create_panel_style())

func _update_status(message: String) -> void:
	results_label.text = "UI Atoms Test\n\n" + message
	print("Test Status: %s" % message)

func _update_results_display() -> void:
	var summary = "UI Atoms Test Results\n\n"
	var test_count = test_results.size()
	
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
	return "[UIAtomsTest: %d/%d tests completed]" % [
		test_results.size(),
		test_cases.size()
	]