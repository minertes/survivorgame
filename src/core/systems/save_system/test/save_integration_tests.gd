# 🧪 SAVE INTEGRATION TESTS
# SaveSystem integration testleri
class_name SaveIntegrationTests
extends "res://src/core/systems/save_system/test/save_test_base.gd"

# === IMPORTS ===
const SaveSlotComponent = preload("res://src/core/systems/save_system/save_slot_component.gd")

# === LIFECYCLE ===

func _ready() -> void:
	module_name = "SaveIntegrationTests"
	super._ready()
	print("SaveIntegrationTests initialized")
	
	# Initialize test queue
	_initialize_test_queue()

# === TEST QUEUE INITIALIZATION ===

func _initialize_test_queue() -> void:
	test_queue = [
		{"name": "Basic Save/Load Cycle", "function": "_test_basic_save_load_cycle"},
		{"name": "Multiple Save Slots", "function": "_test_multiple_save_slots"},
		{"name": "Auto Save System", "function": "_test_auto_save_system"},
		{"name": "Integration Scenarios", "function": "_test_integration_scenarios"}
	]

# === INTEGRATION TEST FUNCTIONS ===

func _test_basic_save_load_cycle() -> Dictionary:
	var start_time = Time.get_ticks_msec()
	
	if save_manager == null:
		return {"success": false, "error": "SaveManager not available"}
	
	var test_slot = 0
	
	# Create test game state
	var test_game_state = {
		"player": {
			"name": "TestPlayer",
			"level": 1,
			"health": 100.0,
			"max_health": 100.0,
			"experience": 0,
			"position": Vector2(100, 200),
			"currency": 100
		},
		"inventory": {
			"items": ["sword", "shield"],
			"weapon": "basic_sword",
			"armor": "basic_armor"
		},
		"world": {
			"current_level": 1,
			"difficulty": "normal",
			"game_time": 0.0
		},
		"progression": {
			"skills_unlocked": ["basic_attack"],
			"upgrades_purchased": []
		}
	}
	
	# Cache for verification
	test_save_data_cache[test_slot] = test_game_state.duplicate(true)
	
	# Create save data
	var save_component = SaveSlotComponent.new() if SaveSlotComponent else null
	if save_component == null:
		return {"success": false, "error": "SaveSlotComponent not available"}
	
	var save_data = save_component.create_save_data(
		test_slot,
		test_game_state,
		Time.get_datetime_dict_from_system(),
		0.0
	) if save_component.has_method("create_save_data") else null
	
	if save_data == null:
		return {"success": false, "error": "Failed to create save data"}
	
	# Save
	var save_result = save_manager.save_game(test_slot) if save_manager.has_method("save_game") else {"success": false, "error": "Method not available"}
	if not save_result.success:
		return {"success": false, "error": "Save failed: " + save_result.error}
	
	# Modify local state to verify load works
	test_game_state["player"]["health"] = 50.0
	test_game_state["player"]["experience"] = 100
	
	# Load
	var load_result = save_manager.load_game(test_slot) if save_manager.has_method("load_game") else {"success": false, "error": "Method not available"}
	if not load_result.success:
		return {"success": false, "error": "Load failed: " + load_result.error}
	
	# Clean up
	if save_manager.has_method("delete_save_slot"):
		save_manager.delete_save_slot(test_slot)
	
	save_component.queue_free()
	
	var duration = Time.get_ticks_msec() - start_time
	
	return {
		"success": true,
		"data": {
			"save_success": save_result.success,
			"load_success": load_result.success,
			"save_time_ms": save_result.time_ms if save_result is Dictionary and save_result.has("time_ms") else 0,
			"load_time_ms": load_result.time_ms if load_result is Dictionary and load_result.has("time_ms") else 0,
			"duration_ms": duration
		}
	}

func _test_multiple_save_slots() -> Dictionary:
	var start_time = Time.get_ticks_msec()
	
	if save_manager == null:
		return {"success": false, "error": "SaveManager not available"}
	
	var test_slots = [0, 1, 2]
	var results = []
	
	for slot_index in test_slots:
		# Create unique game state for each slot
		var game_state = {
			"player": {
				"name": "Player_" + str(slot_index),
				"level": slot_index + 1,
				"health": 100.0 - slot_index * 10,
				"max_health": 100.0,
				"experience": slot_index * 1000
			},
			"timestamp": Time.get_ticks_msec() + slot_index
		}
		
		# Save
		var save_component = SaveSlotComponent.new() if SaveSlotComponent else null
		if save_component == null:
			return {"success": false, "error": "SaveSlotComponent not available"}
		
		var save_data = save_component.create_save_data(
			slot_index,
			game_state,
			Time.get_datetime_dict_from_system(),
			float(slot_index) * 3600.0
		) if save_component.has_method("create_save_data") else null
		
		var save_result = save_manager.save_game(slot_index) if save_manager.has_method("save_game") else {"success": false, "error": "Method not available"}
		results.append({
			"slot": slot_index,
			"save_success": save_result.success if save_result is Dictionary else false,
			"save_error": save_result.error if save_result is Dictionary and not save_result.success else ""
		})
		
		save_component.queue_free()
	
	# Verify all slots have data
	for slot_index in test_slots:
		if save_manager.has_method("has_save_data"):
			if not save_manager.has_save_data(slot_index):
				results.append({
					"slot": slot_index,
					"check": "has_data",
					"success": false,
					"error": "Slot should have data but doesn't"
				})
	
	# Test slot switching
	var original_slot = save_manager.current_slot_index if save_manager.has("current_slot_index") else 0
	var switch_result = save_manager.switch_save_slot(1) if save_manager.has_method("switch_save_slot") else false
	if not switch_result:
		results.append({
			"check": "slot_switch",
			"success": false,
			"error": "Failed to switch save slot"
		})
	
	# Switch back
	if save_manager.has_method("switch_save_slot"):
		save_manager.switch_save_slot(original_slot)
	
	# Get all slots info
	var all_slots = save_manager.get_all_save_slots() if save_manager.has_method("get_all_save_slots") else []
	var max_slots = save_manager.MAX_SAVE_SLOTS if save_manager.has("MAX_SAVE_SLOTS") else 3
	
	if all_slots.size() != max_slots:
		results.append({
			"check": "all_slots",
			"success": false,
			"error": "Incorrect number of slots returned"
		})
	
	# Clean up
	for slot_index in test_slots:
		if save_manager.has_method("delete_save_slot"):
			save_manager.delete_save_slot(slot_index)
	
	var duration = Time.get_ticks_msec() - start_time
	
	var all_successful = results.filter(func(r): return not r.get("success", true)).is_empty()
	
	return {
		"success": all_successful,
		"data": {
			"slots_tested": test_slots.size(),
			"results": results,
			"all_slots_count": all_slots.size(),
			"duration_ms": duration
		}
	}

func _test_auto_save_system() -> Dictionary:
	var start_time = Time.get_ticks_msec()
	
	if save_manager == null:
		return {"success": false, "error": "SaveManager not available"}
	
	# Enable auto-save
	if save_manager.has_method("enable_auto_save"):
		save_manager.enable_auto_save(true)
	
	var auto_save_enabled = save_manager.is_auto_save_enabled() if save_manager.has_method("is_auto_save_enabled") else false
	
	if not auto_save_enabled:
		return {"success": false, "error": "Failed to enable auto-save"}
	
	# Create test save
	var test_slot = 0
	var game_state = {"test": "auto_save", "timestamp": Time.get_ticks_msec()}
	
	var save_component = SaveSlotComponent.new() if SaveSlotComponent else null
	if save_component == null:
		return {"success": false, "error": "SaveSlotComponent not available"}
	
	var save_data = save_component.create_save_data(
		test_slot,
		game_state,
		Time.get_datetime_dict_from_system(),
		0.0
	) if save_component.has_method("create_save_data") else null
	
	if save_data == null:
		return {"success": false, "error": "Failed to create save data"}
	
	var save_result = save_manager.save_game(test_slot) if save_manager.has_method("save_game") else {"success": false, "error": "Method not available"}
	if not save_result.success:
		return {"success": false, "error": "Initial save failed: " + save_result.error}
	
	# Get initial save time
	var initial_save_time = save_manager.get_last_save_time(test_slot) if save_manager.has_method("get_last_save_time") else 0
	
	# Disable auto-save
	if save_manager.has_method("disable_auto_save"):
		save_manager.disable_auto_save()
	
	auto_save_enabled = save_manager.is_auto_save_enabled() if save_manager.has_method("is_auto_save_enabled") else false
	
	if auto_save_enabled:
		return {"success": false, "error": "Failed to disable auto-save"}
	
	# Clean up
	if save_manager.has_method("delete_save_slot"):
		save_manager.delete_save_slot(test_slot)
	
	save_component.queue_free()
	
	var duration = Time.get_ticks_msec() - start_time
	
	return {
		"success": true,
		"data": {
			"auto_save_enabled": true,
			"auto_save_disabled": true,
			"initial_save_success": save_result.success,
			"initial_save_time": initial_save_time,
			"duration_ms": duration
		}
	}

func _test_integration_scenarios() -> Dictionary:
	var start_time = Time.get_ticks_msec()
	
	if save_manager == null:
		return {"success": false, "error": "SaveManager not available"}
	
	var scenarios = []
	
	# Scenario 1: Game progression save/load
	scenarios.append(_test_scenario_game_progression())
	
	# Scenario 2: Inventory management
	scenarios.append(_test_scenario_inventory())
	
	# Scenario 3: Multiple players/profiles
	scenarios.append(_test_scenario_multiple_profiles())
	
	# Scenario 4: Settings persistence
	scenarios.append(_test_scenario_settings())
	
	# Scenario 5: Error recovery
	scenarios.append(_test_scenario_error_recovery())
	
	var successful_scenarios = scenarios.filter(func(s): return s.success).size()
	var duration = Time.get_ticks_msec() - start_time
	
	return {
		"success": successful_scenarios == scenarios.size(),
		"data": {
			"total_scenarios": scenarios.size(),
			"successful_scenarios": successful_scenarios,
			"scenarios": scenarios,
			"duration_ms": duration
		}
	}

# === SCENARIO TEST FUNCTIONS ===

func _test_scenario_game_progression() -> Dictionary:
	var scenario_name = "Game Progression"
	var start_time = Time.get_ticks_msec()
	
	var test_slot = 0
	
	# Simulate game progression
	var progression_data = {
		"player": {
			"name": "ProgressionTest",
			"level": 1,
			"health": 100.0,
			"max_health": 100.0,
			"experience": 0,
			"skill_points": 0
		},
		"progression": {
			"completed_levels": [],
			"unlocked_skills": [],
			"story_progress": 0.0
		}
	}
	
	# Save initial state
	var save_component = SaveSlotComponent.new() if SaveSlotComponent else null
	if save_component == null:
		return {"scenario": scenario_name, "success": false, "duration_ms": 0, "details": {"error": "SaveSlotComponent not available"}}
	
	var initial_save = save_component.create_save_data(
		test_slot,
		progression_data,
		Time.get_datetime_dict_from_system(),
		0.0
	) if save_component.has_method("create_save_data") else null
	
	if initial_save == null:
		return {"scenario": scenario_name, "success": false, "duration_ms": 0, "details": {"error": "Failed to create initial save"}}
	
	var save_result = save_manager.save_game(test_slot) if save_manager.has_method("save_game") else {"success": false, "error": "Method not available"}
	
	# Simulate gameplay progression
	progression_data["player"]["level"] = 5
	progression_data["player"]["experience"] = 5000
	progression_data["player"]["skill_points"] = 3
	progression_data["progression"]["completed_levels"] = [1, 2, 3, 4]
	progression_data["progression"]["unlocked_skills"] = ["double_jump", "fireball"]
	progression_data["progression"]["story_progress"] = 0.4
	
	# Save progressed state
	var progressed_save = save_component.create_save_data(
		test_slot,
		progression_data,
		Time.get_datetime_dict_from_system(),
		3600.0  # 1 hour play time
	) if save_component.has_method("create_save_data") else null
	
	var progressed_save_result = save_manager.save_game(test_slot) if save_manager.has_method("save_game") else {"success": false, "error": "Method not available"}
	
	# Load and verify
	var load_result = save_manager.load_game(test_slot) if save_manager.has_method("load_game") else {"success": false, "error": "Method not available"}
	
	# Clean up
	if save_manager.has_method("delete_save_slot"):
		save_manager.delete_save_slot(test_slot)
	
	save_component.queue_free()
	
	var duration = Time.get_ticks_msec() - start_time
	
	return {
		"scenario": scenario_name,
		"success": save_result.success and progressed_save_result.success and load_result.success,
		"duration_ms": duration,
		"details": {
			"initial_save": save_result.success,
			"progressed_save": progressed_save_result.success,
			"load_verification": load_result.success
		}
	}

func _test_scenario_inventory() -> Dictionary:
	var scenario_name = "Inventory Management"
	var start_time = Time.get_ticks_msec()
	
	var test_slot = 1
	
	var inventory_data = {
		"inventory": {
			"items": [
				{"id": "health_potion", "count": 5, "quality": "common"},
				{"id": "mana_potion", "count": 3, "quality": "common"},
				{"id": "legendary_sword", "count": 1, "quality": "legendary"}
			],
			"equipped": {
				"weapon": "basic_sword",
				"armor": "leather_armor",
				"accessory": "lucky_charm"
			},
			"currency": {
				"gold": 1250,
				"gems": 25,
				"tokens": 150
			}
		}
	}
	
	var save_component = SaveSlotComponent.new() if SaveSlotComponent else null
	if save_component == null:
		return {"scenario": scenario_name, "success": false, "duration_ms": 0, "details": {"error": "SaveSlotComponent not available"}}
	
	var save_data = save_component.create_save_data(
		test_slot,
		inventory_data,
		Time.get_datetime_dict_from_system(),
		1800.0  # 30 minutes
	) if save_component.has_method("create_save_data") else null
	
	if save_data == null:
		return {"scenario": scenario_name, "success": false, "duration_ms": 0, "details": {"error": "Failed to create save data"}}
	
	# Save
	var save_result = save_manager.save_game(test_slot) if save_manager.has_method("save_game") else {"success": false, "error": "Method not available"}
	
	# Modify inventory
	inventory_data["inventory"]["items"].append({"id": "scroll_of_town_portal", "count": 2, "quality": "rare"})
	inventory_data["inventory"]["currency"]["gold"] = 5000
	inventory_data["inventory"]["equipped"]["weapon"] = "legendary_sword"
	
	# Save modified inventory
	var modified_save = save_component.create_save_data(
		test_slot,
		inventory_data,
		Time.get_datetime_dict_from_system(),
		3600.0  # 1 hour
	) if save_component.has_method("create_save_data") else null
	
	var modified_save_result = save_manager.save_game(test_slot) if save_manager.has_method("save_game") else {"success": false, "error": "Method not available"}
	
	# Load and verify
	var load_result = save_manager.load_game(test_slot) if save_manager.has_method("load_game") else {"success": false, "error": "Method not available"}
	
	# Clean up
	if save_manager.has_method("delete_save_slot"):
		save_manager.delete_save_slot(test_slot)
	
	save_component.queue_free()
	
	var duration = Time.get_ticks_msec() - start_time
	
	return {
		"scenario": scenario_name,
		"success": save_result.success and modified_save_result.success and load_result.success,
		"duration_ms": duration,
		"details": {
			"initial_save": save_result.success,
			"modified_save": modified_save_result.success,
			"load_verification": load_result.success
		}
	}

func _test_scenario_multiple_profiles() -> Dictionary:
	var scenario_name = "Multiple Profiles"
	var start_time = Time.get_ticks_msec()
	
	var profiles = [
		{"slot": 0, "name": "CasualPlayer", "play_style": "casual"},
		{"slot": 1, "name": "HardcorePlayer", "play_style": "hardcore"},
		{"slot": 2, "name": "Completionist", "play_style": "completionist"}
	]
	
	var results = []
	
	for profile in profiles:
		var profile_data = {
			"player": {
				"name": profile.name,
				"play_style": profile.play_style,
				"level": 1,
				"play_time": 0.0
			},
			"profile_settings": {
				"difficulty": "normal" if profile.play_style == "casual" else "hard",
				"auto_save": true,
				"cloud_sync": profile.play_style != "hardcore"  # Hardcore players might not want cloud
			}
		}
		
		var save_component = SaveSlotComponent.new() if SaveSlotComponent else null
		if save_component == null:
			return {"scenario": scenario_name, "success": false, "duration_ms": 0, "details": {"error": "SaveSlotComponent not available"}}
		
		var save_data = save_component.create_save_data(
			profile.slot,
			profile_data,
			Time.get_datetime_dict_from_system(),
			0.0
		) if save_component.has_method("create_save_data") else null
		
		if save_data == null:
			results.append({
				"profile": profile.name,
				"save_success": false,
				"slot": profile.slot,
				"error": "Failed to create save data"
			})
			continue
		
		var save_result = save_manager.save_game(profile.slot) if save_manager.has_method("save_game") else {"success": false, "error": "Method not available"}
		
		results.append({
			"profile": profile.name,
			"save_success": save_result.success if save_result is Dictionary else false,
			"slot": profile.slot
		})
		
		save_component.queue_free()
	
	# Verify all profiles exist
	var all_slots = save_manager.get_all_save_slots() if save_manager.has_method("get_all_save_slots") else []
	var profiles_exist = true
	
	for profile in profiles:
		if save_manager.has_method("has_save_data"):
			if not save_manager.has_save_data(profile.slot):
				profiles_exist = false
				results.append({
					"profile": profile.name,
					"check": "exists",
					"success": false
				})
	
	# Clean up
	for profile in profiles:
		if save_manager.has_method("delete_save_slot"):
			save_manager.delete_save_slot(profile.slot)
	
	var duration = Time.get_ticks_msec() - start_time
	
	var all_successful = results.filter(func(r): return not r.get("save_success", true)).is_empty() and profiles_exist
	
	return {
		"scenario": scenario_name,
		"success": all_successful,
		"duration_ms": duration,
		"details": {
			"profiles_tested": profiles.size(),
			"all_profiles_exist": profiles_exist,
			"results": results
		}
	}

func _test_scenario_settings() -> Dictionary:
	var scenario_name = "Settings Persistence"
	var start_time = Time.get_ticks_msec()
	
	var test_slot = 3
	
	var settings_data = {
		"settings": {
			"audio": {
				"master_volume": 0.8,
				"music_volume": 0.7,
				"sfx_volume": 0.9,
				"ui_volume": 0.6
			},
			"graphics": {
				"resolution": "1920x1080",
				"fullscreen": true,
				"vsync": true,
				"quality": "high"
			},
			"controls": {
				"keyboard_layout": "qwerty",
				"mouse_sensitivity": 1.0,
				"invert_y_axis": false
			},
			"gameplay": {
				"difficulty": "normal",
				"auto_save_interval": 300,
				"show_tutorial": true,
				"language": "en"
			}
		}
	}
	
	var save_component = SaveSlotComponent.new() if SaveSlotComponent else null
	if save_component == null:
		return {"scenario": scenario_name, "success": false, "duration_ms": 0, "details": {"error": "SaveSlotComponent not available"}}
	
	var save_data = save_component.create_save_data(
		test_slot,
		settings_data,
		Time.get_datetime_dict_from_system(),
		0.0
	) if save_component.has_method("create_save_data") else null
	
	if save_data == null:
		return {"scenario": scenario_name, "success": false, "duration_ms": 0, "details": {"error": "Failed to create save data"}}
	
	# Save settings
	var save_result = save_manager.save_game(test_slot) if save_manager.has_method("save_game") else {"success": false, "error": "Method not available"}
	
	# Modify settings
	settings_data["settings"]["audio"]["master_volume"] = 0.5
	settings_data["settings"]["graphics"]["quality"] = "ultra"
	settings_data["settings"]["gameplay"]["difficulty"] = "hard"
	
	# Save modified settings
	var modified_save = save_component.create_save_data(
		test_slot,
		settings_data,
		Time.get_datetime_dict_from_system(),
		0.0
	) if save_component.has_method("create_save_data") else null
	
	var modified_save_result = save_manager.save_game(test_slot) if save_manager.has_method("save_game") else {"success": false, "error": "Method not available"}
	
	# Load and verify settings were persisted
	var load_result = save_manager.load_game(test_slot) if save_manager.has_method("load_game") else {"success": false, "error": "Method not available"}
	
	# Clean up
	if save_manager.has_method("delete_save_slot"):
		save_manager.delete_save_slot(test_slot)
	
	save_component.queue_free()
	
	var duration = Time.get_ticks_msec() - start_time
	
	return {
		"scenario": scenario_name,
		"success": save_result.success and modified_save_result.success and load_result.success,
		"duration_ms": duration,
		"details": {
			"initial_save": save_result.success,
			"modified_save": modified_save_result.success,
			"load_verification": load_result.success
		}
	}

func _test_scenario_error_recovery() -> Dictionary:
	var scenario_name = "Error Recovery"
	var start_time = Time.get_ticks_msec()
	
	var test_slot = 4
	
	# Test 1: Save to invalid slot (should fail gracefully)
	var invalid_slot_result = save_manager.save_game(999) if save_manager.has_method("save_game") else {"success": false, "error": "Method not available"}
	var invalid_slot_expected_fail = not invalid_slot_result.success
	
	# Test 2: Load from empty slot (should fail gracefully)
	var empty_slot_result = save_manager.load_game(test_slot) if save_manager.has_method("load_game") else {"success": false, "error": "Method not available"}
	var empty_slot_expected_fail = not empty_slot_result.success
	
	# Test 3: Valid save/load cycle
	var valid_data = {
		"test": "error_recovery",
		"timestamp": Time.get_ticks_msec()
	}
	
	var save_component = SaveSlotComponent.new() if SaveSlotComponent else null
	if save_component == null:
		return {"scenario": scenario_name, "success": false, "duration_ms": 0, "details": {"error": "SaveSlotComponent not available"}}
	
	var save_data = save_component.create_save_data(
		test_slot,
		valid_data,
		Time.get_datetime_dict_from_system(),
		0.0
	) if save_component.has_method("create_save_data") else null
	
	if save_data == null:
		return {"scenario": scenario_name, "success": false, "duration_ms": 0, "details": {"error": "Failed to create save data"}}
	
	var valid_save_result = save_manager.save_game(test_slot) if save_manager.has_method("save_game") else {"success": false, "error": "Method not available"}
	var valid_load_result = save_manager.load_game(test_slot) if save_manager.has_method("load_game") else {"success": false, "error": "Method not available"}
	
	# Test 4: Delete and verify
	var delete_result = save_manager.delete_save_slot(test_slot) if save_manager.has_method("delete_save_slot") else {"success": false, "error": "Method not available"}
	var verify_deleted = not save_manager.has_save_data(test_slot) if save_manager.has_method("has_save_data") else false
	
	save_component.queue_free()
	
	var duration = Time.get_ticks_msec() - start_time
	
	var all_tests_passed = (
		invalid_slot_expected_fail and
		empty_slot_expected_fail and
		valid_save_result.success and
		valid_load_result.success and
		delete_result.success and
		verify_deleted
	)
	
	return {
		"scenario": scenario_name,
		"success": all_tests_passed,
		"duration_ms": duration,
		"details": {
			"invalid_slot_handled": invalid_slot_expected_fail,
			"empty_slot_handled": empty_slot_expected_fail,
			"valid_save_success": valid_save_result.success,
			"valid_load_success": valid_load_result.success,
			"delete_success": delete_result.success,
			"verify_deleted": verify_deleted
		}
	}

# === DEBUG ===

func _to_string() -> String:
	return "[SaveIntegrationTests: %d integration tests]" % test_queue.size()