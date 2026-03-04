# 🧪 SAVE PERFORMANCE TESTS
# SaveSystem performance ve stress testleri
class_name SavePerformanceTests
extends "res://src/core/systems/save_system/test/save_test_base.gd"

# === IMPORTS ===
const SaveManager = preload("res://src/core/systems/save_system/save_manager.gd")
const SaveSlotComponent = preload("res://src/core/systems/save_system/save_slot_component.gd")

# === LIFECYCLE ===

func _ready() -> void:
	module_name = "SavePerformanceTests"
	super._ready()
	print("SavePerformanceTests initialized")
	
	# Initialize test queue
	_initialize_test_queue()

# === TEST QUEUE INITIALIZATION ===

func _initialize_test_queue() -> void:
	test_queue = [
		{"name": "Performance Benchmark", "function": "_test_performance_benchmark"},
		{"name": "Stress Test", "function": "_test_stress_test"}
	]

# === PERFORMANCE TEST FUNCTIONS ===

func _test_performance_benchmark() -> Dictionary:
	var start_time = Time.get_ticks_msec()
	
	if save_manager == null:
		return {"success": false, "error": "SaveManager not available"}
	
	var iterations = 10
	var save_times = []
	var load_times = []
	var file_sizes = []
	
	for i in range(iterations):
		var test_slot = i
		
		# Create data of varying sizes
		var data_size = 100 + i * 100  # 100 to 1000 bytes
		var game_state = {
			"iteration": i,
			"timestamp": Time.get_ticks_msec(),
			"data": "x".repeat(data_size),
			"array": range(i + 1),
			"nested": {
				"level1": {
					"level2": {
						"value": i * 10
					}
				}
			}
		}
		
		var save_component = SaveSlotComponent.new() if SaveSlotComponent else null
		if save_component == null:
			return {"success": false, "error": "SaveSlotComponent not available"}
		
		var save_data = save_component.create_save_data(
			test_slot,
			game_state,
			OS.get_datetime(),
			float(i) * 60.0
		) if save_component.has_method("create_save_data") else null
		
		if save_data == null:
			return {"success": false, "error": "Failed to create save data"}
		
		# Save
		var save_start = Time.get_ticks_msec()
		var save_result = save_manager.save_game(test_slot) if save_manager.has_method("save_game") else {"success": false, "error": "Method not available"}
		var save_time = Time.get_ticks_msec() - save_start
		
		if save_result.success:
			save_times.append(save_time)
			file_sizes.append(save_result.get("file_size", 0))
		
		# Load
		var load_start = Time.get_ticks_msec()
		var load_result = save_manager.load_game(test_slot) if save_manager.has_method("load_game") else {"success": false, "error": "Method not available"}
		var load_time = Time.get_ticks_msec() - load_start
		
		if load_result.success:
			load_times.append(load_time)
		
		# Clean up
		if save_manager.has_method("delete_save_slot"):
			save_manager.delete_save_slot(test_slot)
		
		save_component.queue_free()
	
	# Calculate statistics
	var avg_save_time = _calculate_average(save_times)
	var avg_load_time = _calculate_average(load_times)
	var avg_file_size = _calculate_average(file_sizes)
	
	var max_save_time = _calculate_max(save_times)
	var max_load_time = _calculate_max(load_times)
	
	var duration = Time.get_ticks_msec() - start_time
	
	# Performance requirements (adjust based on your needs)
	var save_time_requirement = 100  # ms
	var load_time_requirement = 100  # ms
	
	var save_performance_ok = avg_save_time < save_time_requirement
	var load_performance_ok = avg_load_time < load_time_requirement
	
	return {
		"success": save_performance_ok and load_performance_ok,
		"data": {
			"iterations": iterations,
			"avg_save_time_ms": avg_save_time,
			"avg_load_time_ms": avg_load_time,
			"avg_file_size_bytes": avg_file_size,
			"max_save_time_ms": max_save_time,
			"max_load_time_ms": max_load_time,
			"save_performance_ok": save_performance_ok,
			"load_performance_ok": load_performance_ok,
			"save_time_requirement_ms": save_time_requirement,
			"load_time_requirement_ms": load_time_requirement,
			"duration_ms": duration
		}
	}

func _test_stress_test() -> Dictionary:
	var start_time = Time.get_ticks_msec()
	
	if save_manager == null:
		return {"success": false, "error": "SaveManager not available"}
	
	var stress_iterations = 50
	var concurrent_saves = 5
	var successful_operations = 0
	var failed_operations = 0
	var operations = []
	
	# Stress test: rapid save/load operations
	for i in range(stress_iterations):
		var slot = i % save_manager.MAX_SAVE_SLOTS if save_manager.has("MAX_SAVE_SLOTS") else i % 3
		
		# Create data
		var game_state = {
			"stress_test": true,
			"iteration": i,
			"timestamp": Time.get_ticks_msec(),
			"large_data": "x".repeat(1000 + (i % 10) * 100)
		}
		
		var save_component = SaveSlotComponent.new() if SaveSlotComponent else null
		if save_component == null:
			return {"success": false, "error": "SaveSlotComponent not available"}
		
		var save_data = save_component.create_save_data(
			slot,
			game_state,
			OS.get_datetime(),
			float(i) * 10.0
		) if save_component.has_method("create_save_data") else null
		
		if save_data == null:
			failed_operations += 1
			continue
		
		# Save
		var save_result = save_manager.save_game(slot) if save_manager.has_method("save_game") else {"success": false, "error": "Method not available"}
		operations.append({
			"type": "save",
			"iteration": i,
			"slot": slot,
			"success": save_result.success if save_result is Dictionary else false,
			"time_ms": save_result.get("time_ms", 0) if save_result is Dictionary else 0
		})
		
		if save_result is Dictionary and save_result.success:
			successful_operations += 1
		else:
			failed_operations += 1
		
		# Load (every other iteration)
		if i % 2 == 0:
			var load_result = save_manager.load_game(slot) if save_manager.has_method("load_game") else {"success": false, "error": "Method not available"}
			operations.append({
				"type": "load",
				"iteration": i,
				"slot": slot,
				"success": load_result.success if load_result is Dictionary else false,
				"time_ms": load_result.get("time_ms", 0) if load_result is Dictionary else 0
			})
			
			if load_result is Dictionary and load_result.success:
				successful_operations += 1
			else:
				failed_operations += 1
		
		save_component.queue_free()
	
	# Clean up all slots
	var max_slots = save_manager.MAX_SAVE_SLOTS if save_manager.has("MAX_SAVE_SLOTS") else 3
	for slot in range(max_slots):
		if save_manager.has_method("delete_save_slot"):
			save_manager.delete_save_slot(slot)
	
	var duration = Time.get_ticks_msec() - start_time
	var success_rate = float(successful_operations) / (successful_operations + failed_operations) * 100.0 if (successful_operations + failed_operations) > 0 else 0.0
	
	# Stress test passes if success rate is high enough
	var stress_test_passed = success_rate > 90.0
	
	return {
		"success": stress_test_passed,
		"data": {
			"iterations": stress_iterations,
			"total_operations": successful_operations + failed_operations,
			"successful_operations": successful_operations,
			"failed_operations": failed_operations,
			"success_rate": success_rate,
			"duration_ms": duration,
			"operations_per_second": float(successful_operations + failed_operations) / (duration / 1000.0) if duration > 0 else 0.0,
			"stress_test_passed": stress_test_passed
		}
	}

# === DEBUG ===

func _to_string() -> String:
	return "[SavePerformanceTests: %d performance tests]" % test_queue.size()