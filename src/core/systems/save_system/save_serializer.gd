# 🗂️ SAVE SERIALIZER
# Atomic Design prensiplerine uygun JSON serialization/deserialization
class_name SaveSerializer
extends Node

# === SERIALIZATION CONFIG ===
enum CompressionMode {
	NONE = 0,
	GZIP = 1,
	ZLIB = 2,
	DEFLATE = 3
}

enum EncryptionMode {
	NONE = 0,
	XOR = 1,      # Basic obfuscation
	AES = 2       # Strong encryption (requires key)
}

# === COMPONENT STATE ===
var compression_mode: CompressionMode = CompressionMode.GZIP
var encryption_mode: EncryptionMode = EncryptionMode.XOR
var encryption_key: String = "survivor_game_save_key"
var pretty_print: bool = false
var validate_json: bool = true
var max_depth: int = 100

# === SIGNALS ===
signal serialization_started(data_size: int)
signal serialization_completed(data_size: int, compressed_size: int, time_ms: int)
signal deserialization_started(data_size: int)
signal deserialization_completed(data_size: int, time_ms: int)
signal compression_applied(original_size: int, compressed_size: int, ratio: float)
signal encryption_applied(data_size: int, mode: EncryptionMode)
signal validation_passed(data_size: int)
signal validation_failed(data_size: int, error: String)

# === PUBLIC API ===

# Serialize save data to bytes
func serialize_save_data(save_data: SaveSlotComponent.SaveData) -> Dictionary:
	var start_time = Time.get_ticks_msec()
	
	# Convert to dictionary
	var data_dict = save_data.to_dictionary()
	var json_string = JSON.stringify(data_dict, "\t" if pretty_print else "")
	
	# Validate JSON
	if validate_json:
		var validation_result = _validate_json_string(json_string)
		if not validation_result.success:
			validation_failed.emit(json_string.length(), validation_result.error)
			return {"success": false, "error": "JSON validation failed: " + validation_result.error}
	
	validation_passed.emit(json_string.length())
	serialization_started.emit(json_string.length())
	
	# Convert to bytes
	var bytes = json_string.to_utf8_buffer()
	var original_size = bytes.size()
	
	# Apply compression
	if compression_mode != CompressionMode.NONE:
		var compression_result = _compress_bytes(bytes)
		if not compression_result.success:
			return {"success": false, "error": "Compression failed: " + compression_result.error}
		
		bytes = compression_result.bytes
		compression_applied.emit(original_size, bytes.size(), 
			float(bytes.size()) / float(original_size) if original_size > 0 else 0.0)
	
	# Apply encryption
	if encryption_mode != EncryptionMode.NONE:
		var encryption_result = _encrypt_bytes(bytes)
		if not encryption_result.success:
			return {"success": false, "error": "Encryption failed: " + encryption_result.error}
		
		bytes = encryption_result.bytes
		encryption_applied.emit(bytes.size(), encryption_mode)
	
	var elapsed_time = Time.get_ticks_msec() - start_time
	serialization_completed.emit(original_size, bytes.size(), elapsed_time)
	
	return {
		"success": true,
		"bytes": bytes,
		"original_size": original_size,
		"compressed_size": bytes.size(),
		"compression_ratio": float(bytes.size()) / float(original_size) if original_size > 0 else 0.0,
		"time_ms": elapsed_time
	}

# Deserialize bytes to save data
func deserialize_save_data(bytes: PackedByteArray) -> Dictionary:
	var start_time = Time.get_ticks_msec()
	
	if bytes.is_empty():
		return {"success": false, "error": "Empty byte array"}
	
	deserialization_started.emit(bytes.size())
	
	var processed_bytes = bytes
	
	# Decrypt if encrypted
	if encryption_mode != EncryptionMode.NONE:
		var decryption_result = _decrypt_bytes(processed_bytes)
		if not decryption_result.success:
			return {"success": false, "error": "Decryption failed: " + decryption_result.error}
		
		processed_bytes = decryption_result.bytes
	
	# Decompress if compressed
	if compression_mode != CompressionMode.NONE:
		var decompression_result = _decompress_bytes(processed_bytes)
		if not decompression_result.success:
			return {"success": false, "error": "Decompression failed: " + decompression_result.error}
		
		processed_bytes = decompression_result.bytes
	
	# Convert to string
	var json_string = processed_bytes.get_string_from_utf8()
	
	# Validate JSON
	if validate_json:
		var validation_result = _validate_json_string(json_string)
		if not validation_result.success:
			validation_failed.emit(json_string.length(), validation_result.error)
			return {"success": false, "error": "JSON validation failed: " + validation_result.error}
	
	validation_passed.emit(json_string.length())
	
	# Parse JSON
	var parse_result = JSON.parse_string(json_string)
	if parse_result == null:
		return {"success": false, "error": "JSON parsing failed"}
	
	if not parse_result is Dictionary:
		return {"success": false, "error": "Parsed data is not a dictionary"}
	
	# Create SaveData object
	var save_data = SaveSlotComponent.SaveData.from_dictionary(parse_result)
	
	var elapsed_time = Time.get_ticks_msec() - start_time
	deserialization_completed.emit(bytes.size(), elapsed_time)
	
	return {
		"success": true,
		"data": save_data,
		"original_size": bytes.size(),
		"decompressed_size": processed_bytes.size(),
		"time_ms": elapsed_time
	}

# Serialize any dictionary to JSON string
func serialize_to_json(data: Dictionary, indent: bool = false) -> Dictionary:
	var start_time = Time.get_ticks_msec()
	
	var json_string = JSON.stringify(data, "\t" if indent else "")
	
	if json_string.is_empty():
		return {"success": false, "error": "JSON stringification failed"}
	
	# Validate
	if validate_json:
		var validation_result = _validate_json_string(json_string)
		if not validation_result.success:
			return {"success": false, "error": "JSON validation failed: " + validation_result.error}
	
	var elapsed_time = Time.get_ticks_msec() - start_time
	
	return {
		"success": true,
		"json_string": json_string,
		"size": json_string.length(),
		"time_ms": elapsed_time
	}

# Deserialize JSON string to dictionary
func deserialize_from_json(json_string: String) -> Dictionary:
	var start_time = Time.get_ticks_msec()
	
	if json_string.is_empty():
		return {"success": false, "error": "Empty JSON string"}
	
	# Validate
	if validate_json:
		var validation_result = _validate_json_string(json_string)
		if not validation_result.success:
			return {"success": false, "error": "JSON validation failed: " + validation_result.error}
	
	# Parse
	var parse_result = JSON.parse_string(json_string)
	if parse_result == null:
		return {"success": false, "error": "JSON parsing failed"}
	
	var elapsed_time = Time.get_ticks_msec() - start_time
	
	return {
		"success": true,
		"data": parse_result,
		"size": json_string.length(),
		"time_ms": elapsed_time
	}

# Set compression mode
func set_compression_mode(mode: CompressionMode) -> void:
	compression_mode = mode
	print("SaveSerializer: Compression mode set to %s" % _get_compression_mode_name(mode))

# Set encryption mode
func set_encryption_mode(mode: EncryptionMode, key: String = "") -> void:
	encryption_mode = mode
	if not key.is_empty():
		encryption_key = key
	print("SaveSerializer: Encryption mode set to %s" % _get_encryption_mode_name(mode))

# Enable/disable pretty print
func set_pretty_print(enabled: bool) -> void:
	pretty_print = enabled
	print("SaveSerializer: Pretty print %s" % ("enabled" if enabled else "disabled"))

# Enable/disable JSON validation
func set_validation_enabled(enabled: bool) -> void:
	validate_json = enabled
	print("SaveSerializer: JSON validation %s" % ("enabled" if enabled else "disabled"))

# Set maximum nesting depth
func set_max_depth(depth: int) -> void:
	max_depth = max(1, depth)
	print("SaveSerializer: Max depth set to %d" % max_depth)

# Get serialization statistics
func get_statistics() -> Dictionary:
	return {
		"compression_mode": _get_compression_mode_name(compression_mode),
		"encryption_mode": _get_encryption_mode_name(encryption_mode),
		"pretty_print": pretty_print,
		"validate_json": validate_json,
		"max_depth": max_depth,
		"encryption_key_set": not encryption_key.is_empty()
	}

# Test serialization/deserialization cycle
func test_cycle(test_data: Dictionary = {}) -> Dictionary:
	if test_data.is_empty():
		test_data = {
			"test": true,
			"timestamp": Time.get_ticks_msec(),
			"nested": {
				"level1": {
					"level2": {
						"level3": "deep_value"
					}
				}
			},
			"array": [1, 2, 3, 4, 5],
			"string": "Test serialization cycle"
		}
	
	print("Testing serialization/deserialization cycle...")
	
	# Create test save data
	var save_data = SaveSlotComponent.SaveData.new(
		0,
		test_data,
		{
			"save_time": Time.get_datetime_dict_from_system(),
			"total_play_time": 123.45,
			"game_version": "1.0.0"
		}
	)
	
	# Serialize
	var serialize_result = serialize_save_data(save_data)
	if not serialize_result.success:
		return {"success": false, "error": "Serialization failed: " + serialize_result.error}
	
	print("Serialization successful: %d bytes -> %d bytes (ratio: %.2f)" % [
		serialize_result.original_size,
		serialize_result.compressed_size,
		serialize_result.compression_ratio
	])
	
	# Deserialize
	var deserialize_result = deserialize_save_data(serialize_result.bytes)
	if not deserialize_result.success:
		return {"success": false, "error": "Deserialization failed: " + deserialize_result.error}
	
	print("Deserialization successful in %d ms" % deserialize_result.time_ms)
	
	# Verify data integrity
	var original_dict = save_data.to_dictionary()
	var restored_dict = deserialize_result.data.to_dictionary()
	
	var is_equal = _compare_dictionaries(original_dict, restored_dict)
	
	return {
		"success": true,
		"serialization_time": serialize_result.time_ms,
		"deserialization_time": deserialize_result.time_ms,
		"total_time": serialize_result.time_ms + deserialize_result.time_ms,
		"original_size": serialize_result.original_size,
		"compressed_size": serialize_result.compressed_size,
		"compression_ratio": serialize_result.compression_ratio,
		"data_integrity": is_equal,
		"test_passed": is_equal
	}

# === PRIVATE METHODS ===

func _validate_json_string(json_string: String) -> Dictionary:
	if json_string.is_empty():
		return {"success": false, "error": "Empty JSON string"}
	
	# Check for basic JSON structure
	if not (json_string.begins_with("{") and json_string.ends_with("}")) and \
	   not (json_string.begins_with("[") and json_string.ends_with("]")):
		return {"success": false, "error": "Invalid JSON structure"}
	
	# Check nesting depth
	var depth = 0
	var max_found_depth = 0
	
	for i in range(json_string.length()):
		var char = json_string[i]
		
		if char == "{" or char == "[":
			depth += 1
			max_found_depth = max(max_found_depth, depth)
			
			if depth > max_depth:
				return {"success": false, "error": "JSON nesting depth exceeded: %d > %d" % [depth, max_depth]}
		
		elif char == "}" or char == "]":
			depth -= 1
			
			if depth < 0:
				return {"success": false, "error": "Unmatched closing bracket at position %d" % i}
	
	if depth != 0:
		return {"success": false, "error": "Unmatched brackets in JSON"}
	
	return {"success": true, "max_depth": max_found_depth}

func _compress_bytes(bytes: PackedByteArray) -> Dictionary:
	match compression_mode:
		CompressionMode.GZIP:
			return _compress_gzip(bytes)
		CompressionMode.ZLIB:
			return _compress_zlib(bytes)
		CompressionMode.DEFLATE:
			return _compress_deflate(bytes)
		_:
			return {"success": true, "bytes": bytes}

func _decompress_bytes(bytes: PackedByteArray) -> Dictionary:
	match compression_mode:
		CompressionMode.GZIP:
			return _decompress_gzip(bytes)
		CompressionMode.ZLIB:
			return _decompress_zlib(bytes)
		CompressionMode.DEFLATE:
			return _decompress_deflate(bytes)
		_:
			return {"success": true, "bytes": bytes}

func _compress_gzip(bytes: PackedByteArray) -> Dictionary:
	var compressed = bytes.compress(FileAccess.COMPRESSION_GZIP)
	if compressed.is_empty():
		return {"success": false, "error": "GZIP compression failed"}
	return {"success": true, "bytes": compressed}

func _decompress_gzip(bytes: PackedByteArray) -> Dictionary:
	var decompressed = bytes.decompress_dynamic(64 * 1024 * 1024, FileAccess.COMPRESSION_GZIP)
	if decompressed.is_empty():
		return {"success": false, "error": "GZIP decompression failed"}
	return {"success": true, "bytes": decompressed}

func _compress_zlib(bytes: PackedByteArray) -> Dictionary:
	var compressed = bytes.compress(FileAccess.COMPRESSION_DEFLATE)
	if compressed.is_empty():
		return {"success": false, "error": "ZLIB compression failed"}
	return {"success": true, "bytes": compressed}

func _decompress_zlib(bytes: PackedByteArray) -> Dictionary:
	var decompressed = bytes.decompress_dynamic(64 * 1024 * 1024, FileAccess.COMPRESSION_DEFLATE)
	if decompressed.is_empty():
		return {"success": false, "error": "ZLIB decompression failed"}
	return {"success": true, "bytes": decompressed}

func _compress_deflate(bytes: PackedByteArray) -> Dictionary:
	var compressed = bytes.compress(FileAccess.COMPRESSION_DEFLATE)
	if compressed.is_empty():
		return {"success": false, "error": "Deflate compression failed"}
	return {"success": true, "bytes": compressed}

func _decompress_deflate(bytes: PackedByteArray) -> Dictionary:
	var decompressed = bytes.decompress_dynamic(64 * 1024 * 1024, FileAccess.COMPRESSION_DEFLATE)
	if decompressed.is_empty():
		return {"success": false, "error": "Deflate decompression failed"}
	return {"success": true, "bytes": decompressed}

func _encrypt_bytes(bytes: PackedByteArray) -> Dictionary:
	match encryption_mode:
		EncryptionMode.XOR:
			return _encrypt_xor(bytes)
		EncryptionMode.AES:
			return _encrypt_aes(bytes)
		_:
			return {"success": true, "bytes": bytes}

func _decrypt_bytes(bytes: PackedByteArray) -> Dictionary:
	match encryption_mode:
		EncryptionMode.XOR:
			return _decrypt_xor(bytes)
		EncryptionMode.AES:
			return _decrypt_aes(bytes)
		_:
			return {"success": true, "bytes": bytes}

func _encrypt_xor(bytes: PackedByteArray) -> Dictionary:
	var key_bytes = encryption_key.to_utf8_buffer()
	var result = PackedByteArray()
	result.resize(bytes.size())
	
	for i in range(bytes.size()):
		var key_index = i % key_bytes.size()
		result[i] = bytes[i] ^ key_bytes[key_index]
	
	return {"success": true, "bytes": result}

func _decrypt_xor(bytes: PackedByteArray) -> Dictionary:
	# XOR encryption is symmetric
	return _encrypt_xor(bytes)

func _encrypt_aes(bytes: PackedByteArray) -> Dictionary:
	# Note: Godot doesn't have built-in AES encryption in GDScript
	# This is a placeholder for future implementation
	push_warning("AES encryption not implemented, using XOR instead")
	return _encrypt_xor(bytes)

func _decrypt_aes(bytes: PackedByteArray) -> Dictionary:
	push_warning("AES decryption not implemented, using XOR instead")
	return _decrypt_xor(bytes)

func _compare_dictionaries(dict1: Dictionary, dict2: Dictionary, path: String = "") -> bool:
	# Compare keys
	var keys1 = dict1.keys()
	var keys2 = dict2.keys()
	
	keys1.sort()
	keys2.sort()
	
	if keys1 != keys2:
		print("Key mismatch at %s: %s != %s" % [path, str(keys1), str(keys2)])
		return false
	
	# Compare values
	for key in keys1:
		var value1 = dict1[key]
		var value2 = dict2[key]
		var current_path = path + ("." if not path.is_empty() else "") + str(key)
		
		if typeof(value1) != typeof(value2):
			print("Type mismatch at %s: %s != %s" % [current_path, typeof(value1), typeof(value2)])
			return false
		
		match typeof(value1):
			TYPE_DICTIONARY:
				if not _compare_dictionaries(value1, value2, current_path):
					return false
			TYPE_ARRAY:
				if not _compare_arrays(value1, value2, current_path):
					return false
			_:
				if value1 != value2:
					print("Value mismatch at %s: %s != %s" % [current_path, str(value1), str(value2)])
					return false
	
	return true

func _compare_arrays(arr1: Array, arr2: Array, path: String = "") -> bool:
	if arr1.size() != arr2.size():
		print("Array size mismatch at %s: %d != %d" % [path, arr1.size(), arr2.size()])
		return false
	
	for i in range(arr1.size()):
		var value1 = arr1[i]
		var value2 = arr2[i]
		var current_path = "%s[%d]" % [path, i]
		
		if typeof(value1) != typeof(value2):
			print("Type mismatch at %s: %s != %s" % [current_path, typeof(value1), typeof(value2)])
			return false
		
		match typeof(value1):
			TYPE_DICTIONARY:
				if not _compare_dictionaries(value1, value2, current_path):
					return false
			TYPE_ARRAY:
				if not _compare_arrays(value1, value2, current_path):
					return false
			_:
				if value1 != value2:
					print("Value mismatch at %s: %s != %s" % [current_path, str(value1), str(value2)])
					return false
	
	return true

func _get_compression_mode_name(mode: CompressionMode) -> String:
	match mode:
		CompressionMode.NONE: return "NONE"
		CompressionMode.GZIP: return "GZIP"
		CompressionMode.ZLIB: return "ZLIB"
		CompressionMode.DEFLATE: return "DEFLATE"
		_: return "UNKNOWN"

func _get_encryption_mode_name(mode: EncryptionMode) -> String:
	match mode:
		EncryptionMode.NONE: return "NONE"
		EncryptionMode.XOR: return "XOR"
		EncryptionMode.AES: return "AES"
		_: return "UNKNOWN"

# === DEBUG & UTILITY ===

func print_statistics() -> void:
	var stats = get_statistics()
	print("=== SaveSerializer Statistics ===")
	print("Compression Mode: %s" % stats.compression_mode)
	print("Encryption Mode: %s" % stats.encryption_mode)
	print("Pretty Print: %s" % str(stats.pretty_print))
	print("Validate JSON: %s" % str(stats.validate_json))
	print("Max Depth: %d" % stats.max_depth)
	print("Encryption Key Set: %s" % str(stats.encryption_key_set))

func benchmark_serialization(test_iterations: int = 100, data_size: int = 1024) -> Dictionary:
	print("Running serialization benchmark (%d iterations, %d bytes each)..." % [test_iterations, data_size])
	
	# Generate test data
	var test_data = {}
	for i in range(data_size):
		test_data["key_%d" % i] = "value_" + "x".repeat(i % 100)
	
	var total_serialize_time = 0
	var total_deserialize_time = 0
	var total_original_size = 0
	var total_compressed_size = 0
	var successes = 0
	
	for i in range(test_iterations):
		# Update timestamp to make each iteration unique
		test_data["timestamp"] = Time.get_ticks_msec() + i
		
		var save_data = SaveSlotComponent.SaveData.new(
			0,
			test_data,
			{
				"save_time": Time.get_datetime_dict_from_system(),
				"total_play_time": float(i),
				"game_version": "1.0.0"
			}
		)
		
		# Serialize
		var serialize_result = serialize_save_data(save_data)
		if not serialize_result.success:
			print("Iteration %d: Serialization failed: %s" % [i, serialize_result.error])
			continue
		
		# Deserialize
		var deserialize_result = deserialize_save_data(serialize_result.bytes)
		if not deserialize_result.success:
			print("Iteration %d: Deserialization failed: %s" % [i, deserialize_result.error])
			continue
		
		total_serialize_time += serialize_result.time_ms
		total_deserialize_time += deserialize_result.time_ms
		total_original_size += serialize_result.original_size
		total_compressed_size += serialize_result.compressed_size
		successes += 1
	
	if successes == 0:
		return {"success": false, "error": "All benchmark iterations failed"}
	
	var avg_serialize_time = float(total_serialize_time) / successes
	var avg_deserialize_time = float(total_deserialize_time) / successes
	var avg_original_size = float(total_original_size) / successes
	var avg_compressed_size = float(total_compressed_size) / successes
	var avg_compression_ratio = avg_compressed_size / avg_original_size if avg_original_size > 0 else 0.0
	
	print("Benchmark completed: %d/%d successful iterations" % [successes, test_iterations])
	print("Average Serialize Time: %.2f ms" % avg_serialize_time)
	print("Average Deserialize Time: %.2f ms" % avg_deserialize_time)
	print("Average Original Size: %.0f bytes" % avg_original_size)
	print("Average Compressed Size: %.0f bytes" % avg_compressed_size)
	print("Average Compression Ratio: %.3f" % avg_compression_ratio)
	
	return {
		"success": true,
		"iterations": successes,
		"avg_serialize_time_ms": avg_serialize_time,
		"avg_deserialize_time_ms": avg_deserialize_time,
		"avg_original_size_bytes": avg_original_size,
		"avg_compressed_size_bytes": avg_compressed_size,
		"avg_compression_ratio": avg_compression_ratio,
		"total_time_ms": total_serialize_time + total_deserialize_time
	}