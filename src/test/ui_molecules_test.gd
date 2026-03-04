# 🧪 UI MOLECULES TEST
# UI Molecule component'larını test eder
class_name UIMoleculesTest
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

# === TEST CASES ===
var test_cases = [
	{
		"name": "HealthBarMolecule Basic",
		"function": "_test_health_bar_molecule_basic"
	},
	{
		"name": "HealthBarMolecule Binding",
		"function": "_test_health_bar_molecule_binding"
	},
	{
		"name": "WeaponCardMolecule Basic",
		"function": "_test_weapon_card_molecule_basic"
	},
	{
		"name": "WeaponCardMolecule Selection",
		"function": "_test_weapon_card_molecule_selection"
	},
	{
		"name": "InventorySlotMolecule Basic",
		"function": "_test_inventory_slot_molecule_basic"
	},
	{
		"name": "InventorySlotMolecule Interactions",
		"function": "_test_inventory_slot_molecule_interactions"
	}
]

# === LIFECYCLE ===

func _ready() -> void:
	print("UI Molecules Test initialized")
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
	
	print("=== UI Molecules Test Summary ===")
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
	await get_tree().create_timer(1.5).timeout
	_run_next_test()

func _on_all_tests_completed() -> void:
	is_testing = false
	_update_status("All tests completed!")
	print_test_summary()
	
	# EventBus'a bildir
	if EventBus.is_available():
		EventBus.emit_now_static("ui_test_completed", {
			"test_type": "molecules",
			"results": test_results,
			"timestamp": Time.get_unix_time_from_system()
		})

# === TEST CASES IMPLEMENTATION ===

func _test_health_bar_molecule_basic() -> bool:
	print("Running: HealthBarMolecule Basic Test")
	
	var health_bar = HealthBarMolecule.new()
	health_bar.name = "TestHealthBar"
	health_bar.show_label = true
	health_bar.show_icon = true
	health_bar.label_format = "{current}/{max} ({percentage_int}%)"
	
	test_container.add_child(health_bar)
	health_bar.position = Vector2(50, 50)
	
	var test_passed = true
	
	# Set health values
	health_bar.set_health(75.0, 100.0)
	
	# Test 1: Health values
	if health_bar.get_health_percentage() != 75.0:
		print("FAIL: Health percentage mismatch")
		test_passed = false
	
	# Test 2: Label visibility
	if not health_bar.show_label:
		print("FAIL: Label should be visible")
		test_passed = false
	
	# Test 3: Icon visibility
	if not health_bar.show_icon:
		print("FAIL: Icon should be visible")
		test_passed = false
	
	await get_tree().process_frame
	
	# Test health change
	health_bar.set_health(50.0, 100.0)
	await get_tree().create_timer(0.3).timeout
	
	if health_bar.get_health_percentage() != 50.0:
		print("FAIL: Health change not applied")
		test_passed = false
	
	await get_tree().process_frame
	
	if test_passed:
		print("PASS: HealthBarMolecule Basic Test")
	
	return test_passed

func _test_health_bar_molecule_binding() -> bool:
	print("Running: HealthBarMolecule Binding Test")
	
	var health_bar = HealthBarMolecule.new()
	health_bar.name = "TestHealthBarBinding"
	
	test_container.add_child(health_bar)
	health_bar.position = Vector2(50, 50)
	
	var test_passed = true
	
	# Mock entity oluştur
	var mock_entity = Node.new()
	mock_entity.name = "MockPlayer"
	
	# Mock HealthComponent oluştur
	var mock_component = Node.new()
	mock_component.name = "MockHealthComponent"
	
	# Mock properties ve methods ekle
	mock_component.current_health = 80.0
	mock_component.max_health = 100.0
	
	# Mock entity'ye component ekle
	mock_entity.add_child(mock_component)
	
	# HealthBar'ı bind et
	health_bar.bind_to_entity(mock_entity)
	
	await get_tree().process_frame
	
	# Test 1: Bound entity kontrolü
	if health_bar.get_bound_entity() != mock_entity:
		print("FAIL: Entity not properly bound")
		test_passed = false
	
	# Test 2: Health values kontrolü
	if health_bar.get_health_percentage() != 80.0:
		print("FAIL: Health values not loaded from entity")
		test_passed = false
	
	# Cleanup
	mock_entity.queue_free()
	health_bar.unbind_from_entity()
	
	await get_tree().process_frame
	
	if test_passed:
		print("PASS: HealthBarMolecule Binding Test")
	
	return test_passed

func _test_weapon_card_molecule_basic() -> bool:
	print("Running: WeaponCardMolecule Basic Test")
	
	var weapon_card = WeaponCardMolecule.new()
	weapon_card.name = "TestWeaponCard"
	weapon_card.show_name = true
	weapon_card.show_stats = true
	weapon_card.show_icon = true
	
	test_container.add_child(weapon_card)
	weapon_card.position = Vector2(50, 50)
	
	var test_passed = true
	
	# Weapon yükle
	weapon_card.load_weapon("pistol")
	
	await get_tree().process_frame
	
	# Test 1: Weapon loaded kontrolü
	if not weapon_card.is_weapon_loaded():
		print("FAIL: Weapon not loaded")
		test_passed = false
	
	# Test 2: Weapon data kontrolü
	var weapon_data = weapon_card.get_weapon_data()
	if weapon_data.is_empty():
		print("FAIL: Weapon data empty")
		test_passed = false
	
	# Test 3: Visibility kontrolü
	if not weapon_card.show_name:
		print("FAIL: Name should be visible")
		test_passed = false
	
	if not weapon_card.show_stats:
		print("FAIL: Stats should be visible")
		test_passed = false
	
	await get_tree().process_frame
	
	if test_passed:
		print("PASS: WeaponCardMolecule Basic Test")
	
	return test_passed

func _test_weapon_card_molecule_selection() -> bool:
	print("Running: WeaponCardMolecule Selection Test")
	
	var weapon_card = WeaponCardMolecule.new()
	weapon_card.name = "TestWeaponCardSelection"
	
	test_container.add_child(weapon_card)
	weapon_card.position = Vector2(50, 50)
	
	# Weapon yükle
	weapon_card.load_weapon("shotgun")
	
	var test_passed = true
	
	# Selection state test
	weapon_card.set_selected(true)
	
	await get_tree().process_frame
	
	# Test 1: Selected state
	if not weapon_card.is_selected:
		print("FAIL: Card should be selected")
		test_passed = false
	
	# Test 2: Unlock state
	weapon_card.set_unlocked(false)
	
	await get_tree().process_frame
	
	if weapon_card.is_unlocked:
		print("FAIL: Card should be locked")
		test_passed = false
	
	# Test 3: Click simulation
	# Note: GUI input test etmek için daha kompleks setup gerekebilir
	
	await get_tree().process_frame
	
	if test_passed:
		print("PASS: WeaponCardMolecule Selection Test")
	
	return test_passed

func _test_inventory_slot_molecule_basic() -> bool:
	print("Running: InventorySlotMolecule Basic Test")
	
	var inventory_slot = InventorySlotMolecule.new()
	inventory_slot.name = "TestInventorySlot"
	inventory_slot.slot_index = 0
	inventory_slot.show_count = true
	inventory_slot.show_rarity_border = true
	inventory_slot.hotkey = "1"
	
	test_container.add_child(inventory_slot)
	inventory_slot.position = Vector2(50, 50)
	
	var test_passed = true
	
	# Item set et
	inventory_slot.set_item("health_pack", 3, "uncommon")
	
	await get_tree().process_frame
	
	# Test 1: Item ID
	if inventory_slot.get_item_id() != "health_pack":
		print("FAIL: Item ID mismatch")
		test_passed = false
	
	# Test 2: Item count
	if inventory_slot.get_item_count() != 3:
		print("FAIL: Item count mismatch")
		test_passed = false
	
	# Test 3: Item rarity
	if inventory_slot.get_item_rarity() != "uncommon":
		print("FAIL: Item rarity mismatch")
		test_passed = false
	
	# Test 4: Hotkey
	if inventory_slot.hotkey != "1":
		print("FAIL: Hotkey mismatch")
		test_passed = false
	
	# Test 5: Empty slot
	inventory_slot.clear_slot()
	
	await get_tree().process_frame
	
	if not inventory_slot.is_slot_empty():
		print("FAIL: Slot should be empty")
		test_passed = false
	
	await get_tree().process_frame
	
	if test_passed:
		print("PASS: InventorySlotMolecule Basic Test")
	
	return test_passed

func _test_inventory_slot_molecule_interactions() -> bool:
	print("Running: InventorySlotMolecule Interactions Test")
	
	var inventory_slot = InventorySlotMolecule.new()
	inventory_slot.name = "TestInventorySlotInteractions"
	inventory_slot.slot_index = 1
	
	test_container.add_child(inventory_slot)
	inventory_slot.position = Vector2(50, 50)
	
	# Item set et
	inventory_slot.set_item("speed_boost", 1, "rare")
	
	var test_passed = true
	var click_detected = false
	var double_click_detected = false
	
	# Signal'leri dinle
	inventory_slot.slot_clicked.connect(func(idx, item_id): 
		click_detected = true
		print("Slot clicked: %d, %s" % [idx, item_id])
	)
	
	inventory_slot.slot_double_clicked.connect(func(idx, item_id): 
		double_click_detected = true
		print("Slot double clicked: %d, %s" % [idx, item_id])
	)
	
	# Selection test
	inventory_slot.set_selected(true)
	
	await get_tree().process_frame
	
	# Test 1: Selection state
	if not inventory_slot.is_slot_selected():
		print("FAIL: Slot should be selected")
		test_passed = false
	
	# Test 2: Click simulation
	# Note: GUI input simulation için özel method gerekebilir
	
	# Test 3: Count update
	inventory_slot.set_item("speed_boost", 5, "rare")
	
	await get_tree().process_frame
	
	if inventory_slot.get_item_count() != 5:
		print("FAIL: Item count not updated")
		test_passed = false
	
	await get_tree().process_frame
	
	if test_passed:
		print("PASS: InventorySlotMolecule Interactions Test")
	
	return test_passed

# === UI HELPERS ===

func _setup_test_ui() -> void:
	# Results label
	results_label.text = "UI Molecules Test\n\nWaiting to start..."
	results_label.add_theme_font_size_override("font_size", 16)
	
	# Status panel
	status_panel.add_theme_stylebox_override("panel", _create_panel_style())

func _update_status(message: String) -> void:
	results_label.text = "UI Molecules Test\n\n" + message
	print("Test Status: %s" % message)

func _update_results_display() -> void:
	var summary = "UI Molecules Test Results\n\n"
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
	return "[UIMoleculesTest: %d/%d tests completed]" % [
		test_results.size(),
		test_cases.size()
	]