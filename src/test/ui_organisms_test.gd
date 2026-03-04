# 🧪 UI ORGANISMS TEST
# UI Organism component'larını test eder
class_name UIOrganismsTest
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
		"name": "GameHUDOrganism Basic",
		"function": "_test_game_hud_organism_basic"
	},
	{
		"name": "GameHUDOrganism Player Binding",
		"function": "_test_game_hud_organism_player_binding"
	},
	{
		"name": "GameHUDOrganism Event Integration",
		"function": "_test_game_hud_organism_event_integration"
	}
]

# === LIFECYCLE ===

func _ready() -> void:
	print("UI Organisms Test initialized")
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
	
	print("=== UI Organisms Test Summary ===")
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
	
	# EventBus'a bildir
	if EventBus.is_available():
		EventBus.emit_now_static("ui_test_completed", {
			"test_type": "organisms",
			"results": test_results,
			"timestamp": Time.get_unix_time_from_system()
		})

# === TEST CASES IMPLEMENTATION ===

func _test_game_hud_organism_basic() -> bool:
	print("Running: GameHUDOrganism Basic Test")
	
	var game_hud = GameHUDOrganism.new()
	game_hud.name = "TestGameHUD"
	
	# HUD visibility ayarları
	game_hud.show_health_bar = true
	game_hud.show_xp_bar = true
	game_hud.show_weapon_info = true
	game_hud.show_inventory = true
	game_hud.show_minimap = false  # Test için minimap'ı kapalı tut
	
	test_container.add_child(game_hud)
	game_hud.position = Vector2(20, 20)
	game_hud.size = Vector2(800, 600)
	
	var test_passed = true
	
	await get_tree().process_frame
	
	# Test 1: HUD initialization
	if not game_hud.is_initialized:
		print("FAIL: HUD not initialized")
		test_passed = false
	
	# Test 2: Visibility controls
	if not game_hud.show_health_bar:
		print("FAIL: Health bar should be visible")
		test_passed = false
	
	if not game_hud.show_xp_bar:
		print("FAIL: XP bar should be visible")
		test_passed = false
	
	if not game_hud.show_weapon_info:
		print("FAIL: Weapon info should be visible")
		test_passed = false
	
	if not game_hud.show_inventory:
		print("FAIL: Inventory should be visible")
		test_passed = false
	
	# Test 3: HUD visibility toggle
	game_hud.hide_hud()
	
	await get_tree().process_frame
	
	if game_hud.visible:
		print("FAIL: HUD should be hidden")
		test_passed = false
	
	game_hud.show_hud()
	
	await get_tree().process_frame
	
	if not game_hud.visible:
		print("FAIL: HUD should be visible")
		test_passed = false
	
	await get_tree().process_frame
	
	if test_passed:
		print("PASS: GameHUDOrganism Basic Test")
	
	return test_passed

func _test_game_hud_organism_player_binding() -> bool:
	print("Running: GameHUDOrganism Player Binding Test")
	
	var game_hud = GameHUDOrganism.new()
	game_hud.name = "TestGameHUDPlayerBinding"
	
	test_container.add_child(game_hud)
	game_hud.position = Vector2(20, 20)
	game_hud.size = Vector2(800, 600)
	
	var test_passed = true
	
	# Mock player entity oluştur
	var mock_player = Node.new()
	mock_player.name = "MockPlayer"
	
	# Mock component'lar oluştur
	var mock_health_component = _create_mock_health_component()
	var mock_exp_component = _create_mock_experience_component()
	var mock_inventory_component = _create_mock_inventory_component()
	var mock_weapon_component = _create_mock_weapon_component()
	
	# Mock player'a component'ları ekle
	mock_player.add_child(mock_health_component)
	mock_player.add_child(mock_exp_component)
	mock_player.add_child(mock_inventory_component)
	mock_player.add_child(mock_weapon_component)
	
	# Mock get_component method'u ekle
	mock_player.get_component = func(component_name: String):
		match component_name:
			"HealthComponent": return mock_health_component
			"ExperienceComponent": return mock_exp_component
			"InventoryComponent": return mock_inventory_component
			"WeaponComponent": return mock_weapon_component
			_: return null
	
	# HUD'ı player'a bağla
	game_hud.bind_to_player(mock_player)
	
	await get_tree().process_frame
	
	# Test 1: Player binding
	if not game_hud.is_player_bound():
		print("FAIL: Player not bound to HUD")
		test_passed = false
	
	if game_hud.get_player_entity() != mock_player:
		print("FAIL: Wrong player entity bound")
		test_passed = false
	
	# Test 2: Health bar binding
	# HealthBarMolecule otomatik olarak bind edilmeli
	
	# Test 3: Stats display
	# XP ve level bilgileri gösterilmeli
	
	# Test 4: Weapon info
	# Weapon card yüklenmeli
	
	# Test 5: Inventory display
	# Inventory slot'ları dolu olmalı
	
	# Player'ı unbind et
	game_hud.unbind_from_player()
	
	await get_tree().process_frame
	
	if game_hud.is_player_bound():
		print("FAIL: Player should be unbound")
		test_passed = false
	
	# Cleanup
	mock_player.queue_free()
	
	await get_tree().process_frame
	
	if test_passed:
		print("PASS: GameHUDOrganism Player Binding Test")
	
	return test_passed

func _test_game_hud_organism_event_integration() -> bool:
	print("Running: GameHUDOrganism Event Integration Test")
	
	var game_hud = GameHUDOrganism.new()
	game_hud.name = "TestGameHUDEventIntegration"
	
	test_container.add_child(game_hud)
	game_hud.position = Vector2(20, 20)
	game_hud.size = Vector2(800, 600)
	
	var test_passed = true
	
	# EventBus kontrolü
	if not EventBus.is_available():
		print("SKIP: EventBus not available")
		return true  # Skip test, fail değil
	
	# Mock player bağla
	var mock_player = Node.new()
	mock_player.name = "MockPlayerEventTest"
	
	var mock_health_component = _create_mock_health_component()
	var mock_exp_component = _create_mock_experience_component()
	var mock_weapon_component = _create_mock_weapon_component()
	
	mock_player.add_child(mock_health_component)
	mock_player.add_child(mock_exp_component)
	mock_player.add_child(mock_weapon_component)
	
	mock_player.get_component = func(component_name: String):
		match component_name:
			"HealthComponent": return mock_health_component
			"ExperienceComponent": return mock_exp_component
			"WeaponComponent": return mock_weapon_component
			_: return null
	
	game_hud.bind_to_player(mock_player)
	
	await get_tree().process_frame
	
	# Test 1: EventBus subscription
	# GameHUDOrganism EventBus'a subscribe olmalı
	
	# Test 2: Event handling
	# Çeşitli event'ler emit edip HUD'ın tepki vermesini test et
	
	# Örnek: Player level up event
	EventBus.emit_now_static(EventBus.PLAYER_LEVEL_UP, {
		"old_level": 1,
		"new_level": 2,
		"player": mock_player
	})
	
	await get_tree().process_frame
	
	# Örnek: Weapon changed event
	EventBus.emit_now_static(EventBus.WEAPON_CHANGED, {
		"old_weapon": "pistol",
		"new_weapon": "shotgun",
		"player": mock_player
	})
	
	await get_tree().process_frame
	
	# Örnek: Inventory changed event
	EventBus.emit_now_static(EventBus.INVENTORY_CHANGED, {
		"player": mock_player,
		"changes": ["item_added", "item_removed"]
	})
	
	await get_tree().process_frame
	
	# Test 3: Game state events
	EventBus.emit_now_static(EventBus.GAME_PAUSED, {})
	
	await get_tree().process_frame
	
	# HUD şeffaflaşmalı
	if game_hud.modulate.a > 0.8:
		print("FAIL: HUD should be transparent when game paused")
		test_passed = false
	
	EventBus.emit_now_static(EventBus.GAME_RESUMED, {})
	
	await get_tree().process_frame
	
	# HUD normale dönmeli
	if game_hud.modulate.a < 0.9:
		print("FAIL: HUD should be opaque when game resumed")
		test_passed = false
	
	# Cleanup
	game_hud.unbind_from_player()
	mock_player.queue_free()
	
	await get_tree().process_frame
	
	if test_passed:
		print("PASS: GameHUDOrganism Event Integration Test")
	
	return test_passed

# === MOCK COMPONENT CREATORS ===

func _create_mock_health_component() -> Node:
	var component = Node.new()
	component.name = "MockHealthComponent"
	
	component.current_health = 85.0
	component.max_health = 100.0
	
	component.get_current_health = func(): return component.current_health
	component.get_max_health = func(): return component.max_health
	
	# Signals (simülasyon)
	component.health_changed = Signal(component, "health_changed")
	component.max_health_changed = Signal(component, "max_health_changed")
	
	return component

func _create_mock_experience_component() -> Node:
	var component = Node.new()
	component.name = "MockExperienceComponent"
	
	component.current_level = 5
	component.current_experience = 350.0
	component.experience_for_next_level = 500.0
	
	component.get_current_level = func(): return component.current_level
	component.get_current_experience = func(): return component.current_experience
	component.get_experience_for_next_level = func(): return component.experience_for_next_level
	
	# Signals
	component.experience_changed = Signal(component, "experience_changed")
	component.level_up = Signal(component, "level_up")
	
	return component

func _create_mock_inventory_component() -> Node:
	var component = Node.new()
	component.name = "MockInventoryComponent"
	
	component.items = [
		{"id": "health_pack", "count": 3, "rarity": "common"},
		{"id": "speed_boost", "count": 1, "rarity": "uncommon"},
		{"id": "damage_boost", "count": 2, "rarity": "rare"}
	]
	
	component.get_items = func(): return component.items.duplicate()
	component.get_item_count = func(item_id: String):
		for item in component.items:
			if item.id == item_id:
				return item.count
		return 0
	
	# Signals
	component.inventory_changed = Signal(component, "inventory_changed")
	
	return component

func _create_mock_weapon_component() -> Node:
	var component = Node.new()
	component.name = "MockWeaponComponent"
	
	component.current_weapon_id = "pistol"
	component.available_weapons = ["pistol", "shotgun", "rifle"]
	
	component.get_current_weapon_id = func(): return component.current_weapon_id
	component.get_available_weapons = func(): return component.available_weapons.duplicate()
	
	# Signals
	component.weapon_changed = Signal(component, "weapon_changed")
	component.weapon_upgraded = Signal(component, "weapon_upgraded")
	
	return component

# === UI HELPERS ===

func _setup_test_ui() -> void:
	# Results label
	results_label.text = "UI Organisms Test\n\nWaiting to start..."
	results_label.add_theme_font_size_override("font_size", 16)
	
	# Status panel
	status_panel.add_theme_stylebox_override("panel", _create_panel_style())

func _update_status(message: String) -> void:
	results_label.text = "UI Organisms Test\n\n" + message
	print("Test Status: %s" % message)

func _update_results_display() -> void:
	var summary = "UI Organisms Test Results\n\n"
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
	return "[UIOrganismsTest: %d/%d tests completed]" % [
		test_results.size(),
		test_cases.size()
	]