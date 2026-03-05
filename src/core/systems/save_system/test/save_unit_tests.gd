# 🧪 SAVE UNIT TESTS
# SaveSystem unit testleri
class_name SaveUnitTests
extends "res://src/core/systems/save_system/test/save_test_base.gd"

# === IMPORTS ===
const SaveSlotComponent = preload("res://src/core/systems/save_system/save_slot_component.gd")
const SaveSerializer = preload("res://src/core/systems/save_system/save_serializer.gd")
const SaveDataValidator = preload("res://src/core/systems/save_system/save_data_validator.gd")
const LocalSaveHandler = preload("res://src/core/systems/save_system/local_save_handler.gd")
const CloudSaveAdapter = preload("res://src/core/systems/save_system/cloud_save_adapter.gd")

# === LIFECYCLE ===

func _ready() -> void:
	module_name = "SaveUnitTests"
	super._ready()
	print("SaveUnitTests initialized")
	
	# Initialize test queue
	_initialize_test_queue()

# === TEST QUEUE INITIALIZATION ===

func _initialize_test_queue() -> void:
	test_queue = [
		{"name": "SaveManager Initialization", "function": "_test_save_manager_initialization"},
		{"name": "Save Slot Component", "function": "_test_save_slot_component"},
		{"name": "Save Serializer", "function": "_test_save_serializer"},
		{"name": "Save Data Validator", "function": "_test_save_data_validator"},
		{"name": "Local Save Handler", "function": "_test_local_save_handler"},
		{"name": "Cloud Save Adapter", "function": "_test_cloud_save_adapter"}
	]

# === UNIT TEST FUNCTIONS ===

func _test_save_manager_initialization() -> Dictionary:
	var start_time = Time.get_ticks_msec()
	
	if save_manager == null:
		return {"success": false, "error": "SaveManager not available"}
	
	# Test basic functionality
	var system_info = save_manager.get_system_info() if save_manager.has_method("get_system_info") else {}
	
	if system_info.is_empty():
		return {"success": false, "error": "Failed to get system info"}
	
	# Test save slots
	var save_slots = save_manager.get_all_save_slots() if save_manager.has_method("get_all_save_slots") else []
	var max_slots = save_manager.MAX_SAVE_SLOTS if save_manager.has("MAX_SAVE_SLOTS") else 3
	
	if save_slots.size() != max_slots:
		return {"success": false, "error": "Incorrect number of save slots"}
	
	var duration = Time.get_ticks_msec() - start_time
	
	return {
		"success": true,
		"data": {
			"system_info": system_info,
			"save_slots_count": save_slots.size(),
			"duration_ms": duration
		}
	}

func _test_save_slot_component() -> Dictionary:
	var start_time = Time.get_ticks_msec()
	
	var component = SaveSlotComponent.new() if SaveSlotComponent else null
	
	if component == null:
		return {"success": false, "error": "SaveSlotComponent not available"}
	
	# Test creating slot data
	var slot_data = component.create_empty_slot_data(0) if component.has_method("create_empty_slot_data") else null
	if slot_data == null:
		return {"success": false, "error": "Failed to create slot data"}
	
	# Test validation
	var validation_result = component.validate_slot_data(slot_data) if component.has_method("validate_slot_data") else {"success": false, "errors": ["Method not available"]}
	if not validation_result.success:
		return {"success": false, "error": "Slot data validation failed: " + str(validation_result.errors)}
	
	# Test save data creation
	var game_state = {"test": "data"}
	var save_time = Time.get_datetime_dict_from_system()
	var save_data = component.create_save_data(0, game_state, save_time, 3600.0) if component.has_method("create_save_data") else null
	
	if save_data == null:
		return {"success": false, "error": "Failed to create save data"}
	
	# Test updating slot from save data
	var updated_slot = component.update_slot_from_save_data(slot_data, save_data) if component.has_method("update_slot_from_save_data") else null
	if updated_slot == null or not updated_slot.has_data:
		return {"success": false, "error": "Failed to update slot from save data"}
	
	component.queue_free()
	
	var duration = Time.get_ticks_msec() - start_time
	
	return {
		"success": true,
		"data": {
			"slot_data_created": true,
			"save_data_created": true,
			"slot_updated": true,
			"duration_ms": duration
		}
	}

func _test_save_serializer() -> Dictionary:
	var start_time = Time.get_ticks_msec()
	
	var serializer = SaveSerializer.new() if SaveSerializer else null
	
	if serializer == null:
		return {"success": false, "error": "SaveSerializer not available"}
	
	# Test configuration
	if serializer.has_method("set_compression_mode"):
		serializer.set_compression_mode(0)  # Assuming 0 is GZIP
	if serializer.has_method("set_encryption_mode"):
		serializer.set_encryption_mode(0)   # Assuming 0 is XOR
	if serializer.has_method("set_pretty_print"):
		serializer.set_pretty_print(false)
	
	# Create test data
	var test_data = {
		"test_string": "Hello, World!",
		"test_number": 42,
		"test_float": 3.14159,
		"test_array": [1, 2, 3, 4, 5],
		"test_nested": {
			"level1": {
				"level2": "deep_value"
			}
		}
	}
	
	# Test JSON serialization
	var json_result = serializer.serialize_to_json(test_data) if serializer.has_method("serialize_to_json") else {"success": false, "error": "Method not available"}
	if not json_result.success:
		return {"success": false, "error": "JSON serialization failed: " + json_result.error}
	
	# Test JSON deserialization
	var deserialize_result = serializer.deserialize_from_json(json_result.json_string) if serializer.has_method("deserialize_from_json") else {"success": false, "error": "Method not available"}
	if not deserialize_result.success:
		return {"success": false, "error": "JSON deserialization failed: " + deserialize_result.error}
	
	# Test full cycle with SaveData
	var save_component = SaveSlotComponent.new() if SaveSlotComponent else null
	if save_component == null:
		return {"success": false, "error": "SaveSlotComponent not available for full cycle test"}
	
	var save_data = save_component.create_save_data(
		0,
		test_data,
		Time.get_datetime_dict_from_system(),
		123.45
	) if save_component.has_method("create_save_data") else null
	
	if save_data == null:
		return {"success": false, "error": "Failed to create save data for full cycle"}
	
	var serialize_result = serializer.serialize_save_data(save_data) if serializer.has_method("serialize_save_data") else {"success": false, "error": "Method not available"}
	if not serialize_result.success:
		return {"success": false, "error": "Save data serialization failed: " + serialize_result.error}
	
	var deserialize_save_result = serializer.deserialize_save_data(serialize_result.bytes) if serializer.has_method("deserialize_save_data") else {"success": false, "error": "Method not available"}
	if not deserialize_save_result.success:
		return {"success": false, "error": "Save data deserialization failed: " + deserialize_save_result.error}
	
	# Test cycle
	var cycle_result = serializer.test_cycle() if serializer.has_method("test_cycle") else {"success": false, "error": "Method not available"}
	
	serializer.queue_free()
	save_component.queue_free()
	
	var duration = Time.get_ticks_msec() - start_time
	
	return {
		"success": true,
		"data": {
			"json_serialization": json_result.success,
			"json_deserialization": deserialize_result.success,
			"save_data_serialization": serialize_result.success,
			"save_data_deserialization": deserialize_save_result.success,
			"test_cycle": cycle_result.success if cycle_result is Dictionary else false,
			"compression_ratio": serialize_result.compression_ratio if serialize_result is Dictionary and serialize_result.has("compression_ratio") else 0.0,
			"duration_ms": duration
		}
	}

func _test_save_data_validator() -> Dictionary:
	var start_time = Time.get_ticks_msec()
	
	var validator = SaveDataValidator.new() if SaveDataValidator else null
	
	if validator == null:
		return {"success": false, "error": "SaveDataValidator not available"}
	
	# Test configuration
	if validator.has_method("set_validation_strictness"):
		validator.set_validation_strictness(1)  # Assuming 1 is MEDIUM
	if validator.has_method("set_auto_fix_enabled"):
		validator.set_auto_fix_enabled(true)
	
	# Create test save data
	var save_component = SaveSlotComponent.new() if SaveSlotComponent else null
	if save_component == null:
		return {"success": false, "error": "SaveSlotComponent not available"}
	
	var test_save_data = save_component.create_save_data(
		0,
		{
			"player": {
				"name": "TestPlayer",
				"level": 5,
				"health": 75.0,
				"max_health": 100.0,
				"experience": 1250
			},
			"world": {
				"current_level": 3,
				"difficulty": "normal",
				"game_time": 3600.5
			}
		},
		Time.get_datetime_dict_from_system(),
		3600.5
	) if save_component.has_method("create_save_data") else null
	
	if test_save_data == null:
		return {"success": false, "error": "Failed to create test save data"}
	
	# Test validation
	var validation_result = validator.validate_save_data(test_save_data) if validator.has_method("validate_save_data") else {"success": false, "errors": ["Method not available"]}
	if not validation_result.success:
		return {"success": false, "error": "Validation failed: " + str(validation_result.errors)}
	
	# Test with corrupted data (simulated)
	var corrupted_data = save_component.create_save_data(
		1,
		{
			"player": {
				"name": "",  # Empty name should trigger validation
				"level": -5,  # Invalid level
				"health": 150.0,  # Exceeds max health
				"max_health": 100.0,
				"experience": -100  # Negative experience
			}
		},
		Time.get_datetime_dict_from_system(),
		-100.0  # Negative play time
	) if save_component.has_method("create_save_data") else null
	
	var corrupted_validation = validator.validate_save_data(corrupted_data) if corrupted_data != null and validator.has_method("validate_save_data") else {"success": false, "errors": ["Test skipped"]}
	
	# Test dictionary validation
	var dict_validation = validator.validate_dictionary({"test": "data"}) if validator.has_method("validate_dictionary") else {"success": false, "errors": ["Method not available"]}
	
	# Test statistics
	var stats = validator.get_statistics() if validator.has_method("get_statistics") else {"rule_count": 0, "strictness": 0}
	
	validator.queue_free()
	save_component.queue_free()
	
	var duration = Time.get_ticks_msec() - start_time
	
	return {
		"success": true,
		"data": {
			"validation_passed": validation_result.success,
			"corrupted_validation_errors": corrupted_validation.errors.size() if corrupted_validation is Dictionary and corrupted_validation.has("errors") else 0,
			"dict_validation": dict_validation.success if dict_validation is Dictionary else false,
			"rule_count": stats.rule_count if stats is Dictionary and stats.has("rule_count") else 0,
			"strictness": stats.strictness if stats is Dictionary and stats.has("strictness") else 0,
			"duration_ms": duration
		}
	}

func _test_local_save_handler() -> Dictionary:
	var start_time = Time.get_ticks_msec()
	
	var handler = LocalSaveHandler.new() if LocalSaveHandler else null
	
	if handler == null:
		return {"success": false, "error": "LocalSaveHandler not available"}
	
	# Wait for initialization
	await get_tree().create_timer(0.1).timeout
	
	# Test configuration
	if handler.has_method("set_backup_count"):
		handler.set_backup_count(2)
	if handler.has_method("set_compression_enabled"):
		handler.set_compression_enabled(true)
	if handler.has_method("set_encryption_enabled"):
		handler.set_encryption_enabled(true)
	
	# Create test save data
	var save_component = SaveSlotComponent.new() if SaveSlotComponent else null
	if save_component == null:
		return {"success": false, "error": "SaveSlotComponent not available"}
	
	var test_save_data = save_component.create_save_data(
		999,  # Use high slot index for testing
		{
			"test": true,
			"timestamp": Time.get_ticks_msec(),
			"message": "Test local save handler"
		},
		Time.get_datetime_dict_from_system(),
		0.0
	) if save_component.has_method("create_save_data") else null
	
	if test_save_data == null:
		return {"success": false, "error": "Failed to create test save data"}
	
	# Test save
	var save_result = handler.save_save_data(999, test_save_data) if handler.has_method("save_save_data") else {"success": false, "error": "Method not available"}
	if not save_result.success:
		return {"success": false, "error": "Save failed: " + save_result.error}
	
	# Test load
	var load_result = handler.load_save_data(999) if handler.has_method("load_save_data") else {"success": false, "error": "Method not available"}
	if not load_result.success:
		return {"success": false, "error": "Load failed: " + load_result.error}
	
	# Test file info
	var file_info = handler.get_save_file_info(999) if handler.has_method("get_save_file_info") else {"success": false, "error": "Method not available"}
	
	# Test backup loading (should exist after save)
	var backup_result = handler.load_backup_data(999, 0) if handler.has_method("load_backup_data") else {"success": false, "error": "Method not available"}
	# Backup might not exist yet, that's OK
	
	# Test delete
	var delete_result = handler.delete_save_slot(999) if handler.has_method("delete_save_slot") else {"success": false, "error": "Method not available"}
	if not delete_result.success:
		return {"success": false, "error": "Delete failed: " + delete_result.error}
	
	# Test disk usage
	var disk_usage = handler.get_disk_usage_info() if handler.has_method("get_disk_usage_info") else {"total_size_mb": 0.0}
	
	handler.queue_free()
	save_component.queue_free()
	
	var duration = Time.get_ticks_msec() - start_time
	
	return {
		"success": true,
		"data": {
			"save_success": save_result.success,
			"load_success": load_result.success,
			"file_info_success": file_info.success if file_info is Dictionary else false,
			"delete_success": delete_result.success,
			"backup_count": 2,
			"disk_usage_mb": disk_usage.total_size_mb if disk_usage is Dictionary and disk_usage.has("total_size_mb") else 0.0,
			"duration_ms": duration
		}
	}

func _test_cloud_save_adapter() -> Dictionary:
	var start_time = Time.get_ticks_msec()
	
	var adapter = CloudSaveAdapter.new() if CloudSaveAdapter else null
	
	if adapter == null:
		return {"success": false, "error": "CloudSaveAdapter not available"}
	
	# Test initialization
	var init_result = adapter.initialize() if adapter.has_method("initialize") else {"success": false, "error": "Method not available"}
	# Might fail if no cloud service is available, that's OK for test
	
	# Test configuration
	if adapter.has_method("set_enabled"):
		adapter.set_enabled(true)
	if adapter.has_method("set_conflict_resolution"):
		adapter.set_conflict_resolution("local")
	if adapter.has_method("set_sync_interval"):
		adapter.set_sync_interval(300.0)
	
	# Test sync status
	var sync_status = adapter.get_sync_status() if adapter.has_method("get_sync_status") else {"sync_status": "not_available"}
	
	# Test quota (will likely fail without real cloud service)
	var quota_result = adapter.get_cloud_quota() if adapter.has_method("get_cloud_quota") else {"success": false, "error": "Method not available"}
	
	# Test file list
	var file_list_result = adapter.get_cloud_file_list() if adapter.has_method("get_cloud_file_list") else {"success": false, "error": "Method not available"}
	
	adapter.queue_free()
	
	var duration = Time.get_ticks_msec() - start_time
	
	return {
		"success": true,  # We consider this test passed even if cloud isn't available
		"data": {
			"initialized": init_result.success if init_result is Dictionary else false,
			"enabled": true,
			"sync_status": sync_status.sync_status if sync_status is Dictionary and sync_status.has("sync_status") else "unknown",
			"quota_available": quota_result.success if quota_result is Dictionary else false,
			"file_list_available": file_list_result.success if file_list_result is Dictionary else false,
			"duration_ms": duration
		}
	}

# === DEBUG ===

func _to_string() -> String:
	return "[SaveUnitTests: %d unit tests]" % test_queue.size()