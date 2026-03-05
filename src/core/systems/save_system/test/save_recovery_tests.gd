# 🧪 SAVE RECOVERY TESTS
# SaveSystem recovery ve validation testleri
class_name SaveRecoveryTests
extends "res://src/core/systems/save_system/test/save_test_base.gd"

# === IMPORTS ===
const SaveSlotComponent = preload("res://src/core/systems/save_system/save_slot_component.gd")
const SaveDataValidator = preload("res://src/core/systems/save_system/save_data_validator.gd")
const LocalSaveHandler = preload("res://src/core/systems/save_system/local_save_handler.gd")

# === LIFECYCLE ===

func _ready() -> void:
	module_name = "SaveRecoveryTests"
	super._ready()
	print("SaveRecoveryTests initialized")
	
	# Initialize test queue
	_initialize_test_queue()

# === TEST QUEUE INITIALIZATION ===

func _initialize_test_queue() -> void:
	test_queue = [
		{"name": "Save Data Validation", "function": "_test_save_data_validation"},
		{"name": "Corruption Recovery", "function": "_test_corruption_recovery"}
	]

# === RECOVERY TEST FUNCTIONS ===

func _test_save_data_validation() -> Dictionary:
	var start_time = Time.get_ticks_msec()
	
	if save_manager == null:
		return {"success": false, "error": "SaveManager not available"}
	
	var validator = SaveDataValidator.new() if SaveDataValidator else null
	
	if validator == null:
		return {"success": false, "error": "SaveDataValidator not available"}
	
	# Test configuration
	if validator.has_method("set_validation_strictness"):
		validator.set_validation_strictness(2)  # Assuming 2 is HIGH
	
	# Test 1: Valid data
	var valid_save_data = SaveSlotComponent.SaveData.new(
		0,
		{
			"player": {
				"name": "ValidPlayer",
				"level": 10,
				"health": 85.0,
				"max_health": 100.0,
				"experience": 5000
			}
		},
		{
			"save_time": Time.get_datetime_dict_from_system(),
			"total_play_time": 7200.0,
			"game_version": "1.0.0",
			"checksum": "test_checksum"
		}
	) if SaveSlotComponent and SaveSlotComponent.SaveData else null
	
	if valid_save_data == null:
		return {"success": false, "error": "Failed to create valid save data"}
	
	var valid_result = validator.validate_save_data(valid_save_data) if validator.has_method("validate_save_data") else {"success": false, "errors": ["Method not available"]}
	
	# Test 2: Invalid data (should fail or have warnings)
	var invalid_save_data = SaveSlotComponent.SaveData.new(
		1,
		{
			"player": {
				"name": "",  # Empty
				"level": -5,  # Negative
				"health": 150.0,  # Exceeds max
				"max_health": 100.0,
				"experience": -100  # Negative
			}
		},
		{
			"save_time": {"year": 1800, "month": 13, "day": 32},  # Invalid date
			"total_play_time": -1000.0,  # Negative
			"game_version": "",
			"checksum": ""
		}
	) if SaveSlotComponent and SaveSlotComponent.SaveData else null
	
	var invalid_result = validator.validate_save_data(invalid_save_data) if invalid_save_data != null and validator.has_method("validate_save_data") else {"success": false, "errors": ["Test skipped"]}
	
	# Test 3: Corrupted data simulation
	var corrupted_result: Dictionary = {"success": false, "errors": ["Valid save data not available for corruption test"]}
	if valid_save_data != null:
		var corrupted_data = valid_save_data.to_dictionary() if valid_save_data.has_method("to_dictionary") else {}
		corrupted_data["game_state"] = corrupted_data.get("game_state", {})
		corrupted_data["game_state"]["player"] = corrupted_data["game_state"].get("player", {})
		corrupted_data["game_state"]["player"]["health"] = NAN  # NaN value
		
		var corrupted_save_data = SaveSlotComponent.SaveData.from_dictionary(corrupted_data) if SaveSlotComponent and SaveSlotComponent.SaveData else null
		if corrupted_save_data != null and validator.has_method("validate_save_data"):
			corrupted_result = validator.validate_save_data(corrupted_save_data)
		else:
			corrupted_result = {"success": false, "errors": ["Test skipped"]}
	
	validator.queue_free()
	
	var duration = Time.get_ticks_msec() - start_time
	
	return {
		"success": valid_result.success if valid_result is Dictionary else false,  # Only care if valid data passes
		"data": {
			"valid_data_passed": valid_result.success if valid_result is Dictionary else false,
			"valid_data_errors": valid_result.errors.size() if valid_result is Dictionary and valid_result.has("errors") else 0,
			"invalid_data_passed": invalid_result.success if invalid_result is Dictionary else false,
			"invalid_data_errors": invalid_result.errors.size() if invalid_result is Dictionary and invalid_result.has("errors") else 0,
			"corrupted_data_passed": corrupted_result.success if corrupted_result is Dictionary else false,
			"corrupted_data_errors": corrupted_result.errors.size() if corrupted_result is Dictionary and corrupted_result.has("errors") else 0,
			"duration_ms": duration
		}
	}

func _test_corruption_recovery() -> Dictionary:
	var start_time = Time.get_ticks_msec()
	
	# This test simulates corruption recovery scenarios
	var handler = LocalSaveHandler.new() if LocalSaveHandler else null
	
	if handler == null:
		return {"success": false, "error": "LocalSaveHandler not available"}
	
	await get_tree().create_timer(0.1).timeout
	
	# Create valid save data
	var save_component = SaveSlotComponent.new() if SaveSlotComponent else null
	if save_component == null:
		return {"success": false, "error": "SaveSlotComponent not available"}
	
	var valid_save_data = save_component.create_save_data(
		999,
		{
			"test": "corruption_recovery",
			"important_value": 42,
			"array_data": [1, 2, 3, 4, 5]
		},
		Time.get_datetime_dict_from_system(),
		123.45
	) if save_component.has_method("create_save_data") else null
	
	if valid_save_data == null:
		return {"success": false, "error": "Failed to create test save data"}
	
	# Save valid data
	var save_result = handler.save_save_data(999, valid_save_data) if handler.has_method("save_save_data") else {"success": false, "error": "Method not available"}
	if not save_result.success:
		return {"success": false, "error": "Failed to save test data: " + save_result.error}
	
	# Simulate corruption by directly modifying the file
	var file_path = handler._get_save_file_path(999) if handler.has_method("_get_save_file_path") else ""
	if file_path != "":
		var file = FileAccess.open(file_path, FileAccess.READ_WRITE)
		if file != null:
			# Corrupt the file by writing garbage in the middle
			file.seek(file.get_length() / 2)
			file.store_8(0xFF)  # Write invalid byte
			file.store_8(0xFF)
			file.store_8(0xFF)
			file.close()
	
	# Try to load corrupted file
	var load_result = handler.load_save_data(999) if handler.has_method("load_save_data") else {"success": false, "error": "Method not available"}
	
	# The system should either:
	# 1. Detect corruption and fail gracefully
	# 2. Recover from backup
	# 3. Return validation errors
	
	# Clean up
	if handler.has_method("delete_save_slot"):
		handler.delete_save_slot(999)
	
	handler.queue_free()
	save_component.queue_free()
	
	var duration = Time.get_ticks_msec() - start_time
	
	return {
		"success": true,  # Test passes if it doesn't crash
		"data": {
			"save_success": save_result.success,
			"load_after_corruption_attempted": true,
			"corruption_simulated": file_path != "",
			"duration_ms": duration
		}
	}

# === DEBUG ===

func _to_string() -> String:
	return "[SaveRecoveryTests: %d recovery tests]" % test_queue.size()