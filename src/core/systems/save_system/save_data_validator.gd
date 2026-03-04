# 🗂️ SAVE DATA VALIDATOR
# Atomic Design prensiplerine uygun save data validation ve corruption recovery
class_name SaveDataValidator
extends Node

# === VALIDATION STRICTNESS ===
enum ValidationStrictness {
	LOW = 0,      # Basic validation only
	MEDIUM = 1,   # Standard validation (default)
	HIGH = 2,     # Strict validation
	PARANOID = 3  # Maximum validation with recovery attempts
}

# === VALIDATION RULES ===
class ValidationRule:
	var field_path: String
	var expected_type: int
	var min_value: Variant = null
	var max_value: Variant = null
	var required: bool = true
	var custom_validator: Callable = null
	
	func _init(path: String, type: int, req: bool = true, min_val: Variant = null, max_val: Variant = null, validator: Callable = null):
		field_path = path
		expected_type = type
		required = req
		min_value = min_val
		max_value = max_val
		custom_validator = validator
	
	func validate(value: Variant, context: Dictionary = {}) -> Dictionary:
		var errors = []
		
		# Check if required field is present
		if required and value == null:
			errors.append("Required field missing")
			return {"valid": false, "errors": errors, "value": value}
		
		# If not required and null, it's valid
		if not required and value == null:
			return {"valid": true, "value": value}
		
		# Check type
		if expected_type != TYPE_NIL and typeof(value) != expected_type:
			errors.append("Type mismatch: expected %s, got %s" % [
				_type_to_string(expected_type), _type_to_string(typeof(value))
			])
		
		# Check min/max for numeric types
		if min_value != null and value is int:
			if value < min_value:
				errors.append("Value %d below minimum %d" % [value, min_value])
		elif min_value != null and value is float:
			if value < min_value:
				errors.append("Value %.2f below minimum %.2f" % [value, min_value])
		
		if max_value != null and value is int:
			if value > max_value:
				errors.append("Value %d above maximum %d" % [value, max_value])
		elif max_value != null and value is float:
			if value > max_value:
				errors.append("Value %.2f above maximum %.2f" % [value, max_value])
		
		# Custom validation
		if custom_validator != null and custom_validator.is_valid():
			var custom_result = custom_validator.call(value, context)
			if custom_result is Dictionary and not custom_result.get("valid", true):
				errors.append_array(custom_result.get("errors", []))
		
		return {
			"valid": errors.is_empty(),
			"errors": errors,
			"value": value
		}
	
	func _type_to_string(type: int) -> String:
		match type:
			TYPE_NIL: return "NIL"
			TYPE_BOOL: return "BOOL"
			TYPE_INT: return "INT"
			TYPE_FLOAT: return "FLOAT"
			TYPE_STRING: return "STRING"
			TYPE_VECTOR2: return "VECTOR2"
			TYPE_VECTOR2I: return "VECTOR2I"
			TYPE_RECT2: return "RECT2"
			TYPE_RECT2I: return "RECT2I"
			TYPE_VECTOR3: return "VECTOR3"
			TYPE_VECTOR3I: return "VECTOR3I"
			TYPE_TRANSFORM2D: return "TRANSFORM2D"
			TYPE_VECTOR4: return "VECTOR4"
			TYPE_VECTOR4I: return "VECTOR4I"
			TYPE_PLANE: return "PLANE"
			TYPE_QUATERNION: return "QUATERNION"
			TYPE_AABB: return "AABB"
			TYPE_BASIS: return "BASIS"
			TYPE_TRANSFORM3D: return "TRANSFORM3D"
			TYPE_PROJECTION: return "PROJECTION"
			TYPE_COLOR: return "COLOR"
			TYPE_STRING_NAME: return "STRING_NAME"
			TYPE_NODE_PATH: return "NODE_PATH"
			TYPE_RID: return "RID"
			TYPE_OBJECT: return "OBJECT"
			TYPE_CALLABLE: return "CALLABLE"
			TYPE_SIGNAL: return "SIGNAL"
			TYPE_DICTIONARY: return "DICTIONARY"
			TYPE_ARRAY: return "ARRAY"
			TYPE_PACKED_BYTE_ARRAY: return "PACKED_BYTE_ARRAY"
			TYPE_PACKED_INT32_ARRAY: return "PACKED_INT32_ARRAY"
			TYPE_PACKED_INT64_ARRAY: return "PACKED_INT64_ARRAY"
			TYPE_PACKED_FLOAT32_ARRAY: return "PACKED_FLOAT32_ARRAY"
			TYPE_PACKED_FLOAT64_ARRAY: return "PACKED_FLOAT64_ARRAY"
			TYPE_PACKED_STRING_ARRAY: return "PACKED_STRING_ARRAY"
			TYPE_PACKED_VECTOR2_ARRAY: return "PACKED_VECTOR2_ARRAY"
			TYPE_PACKED_VECTOR3_ARRAY: return "PACKED_VECTOR3_ARRAY"
			TYPE_PACKED_COLOR_ARRAY: return "PACKED_COLOR_ARRAY"
			_: return "UNKNOWN(%d)" % type

# === COMPONENT STATE ===
var strictness: ValidationStrictness = ValidationStrictness.MEDIUM
var validation_rules: Array[ValidationRule] = []
var auto_fix_enabled: bool = true
var max_repair_attempts: int = 3
var validation_cache: Dictionary = {}

# === SIGNALS ===
signal validation_started(data_size: int, strictness: ValidationStrictness)
signal validation_completed(success: bool, errors: Array, warnings: Array, time_ms: int)
signal validation_rule_added(rule: ValidationRule)
signal validation_rule_removed(field_path: String)
signal auto_fix_applied(field_path: String, old_value: Variant, new_value: Variant)
signal corruption_detected(field_path: String, error: String)
signal repair_attempted(field_path: String, attempt: int, success: bool)
signal validation_cache_cleared(cache_size: int)

# === LIFECYCLE ===

func _ready() -> void:
	_setup_default_rules()
	print("SaveDataValidator initialized with %d rules" % validation_rules.size())

# === PUBLIC API ===

# Validate save data
func validate_save_data(save_data: SaveSlotComponent.SaveData) -> Dictionary:
	var start_time = Time.get_ticks_msec()
	
	if save_data == null:
		return {"success": false, "error": "Save data is null", "valid": false}
	
	# Check cache first
	var cache_key = _generate_cache_key(save_data)
	if validation_cache.has(cache_key):
		var cached_result = validation_cache[cache_key]
		print("Using cached validation result for %s" % cache_key)
		return cached_result
	
	validation_started.emit(_estimate_data_size(save_data), strictness)
	
	var errors = []
	var warnings = []
	var fixed_fields = []
	
	# Convert to dictionary for validation
	var data_dict = save_data.to_dictionary()
	
	# Validate structure
	var structure_result = _validate_structure(data_dict)
	if not structure_result.valid:
		errors.append_array(structure_result.errors)
	
	# Validate fields based on rules
	for rule in validation_rules:
		var value = _get_value_by_path(data_dict, rule.field_path)
		var validation_result = rule.validate(value, {"save_data": save_data})
		
		if not validation_result.valid:
			# Try to auto-fix if enabled
			if auto_fix_enabled and strictness < ValidationStrictness.PARANOID:
				var fix_result = _attempt_auto_fix(rule, value, data_dict)
				if fix_result.success:
					fixed_fields.append({
						"field": rule.field_path,
						"old_value": value,
						"new_value": fix_result.value,
						"rule": rule
					})
					auto_fix_applied.emit(rule.field_path, value, fix_result.value)
					continue
			
			errors.append_array(validation_result.errors.map(func(e): return "%s: %s" % [rule.field_path, e]))
		elif validation_result.errors.size() > 0:
			warnings.append_array(validation_result.errors.map(func(e): return "%s: %s" % [rule.field_path, e]))
	
	# Additional validation based on strictness
	match strictness:
		ValidationStrictness.HIGH, ValidationStrictness.PARANOID:
			var extra_result = _perform_strict_validation(save_data, data_dict)
			errors.append_array(extra_result.errors)
			warnings.append_array(extra_result.warnings)
	
	# Check for corruption
	var corruption_check = _check_for_corruption(data_dict)
	if corruption_check.detected:
		corruption_detected.emit(corruption_check.field, corruption_check.error)
		errors.append("Data corruption detected: %s" % corruption_check.error)
		
		# Attempt repair if enabled
		if auto_fix_enabled:
			var repair_result = _attempt_corruption_repair(data_dict, corruption_check)
			if repair_result.success:
				fixed_fields.append_array(repair_result.fixed_fields)
	
	var success = errors.is_empty()
	var elapsed_time = Time.get_ticks_msec() - start_time
	
	var result = {
		"success": success,
		"valid": success,
		"errors": errors,
		"warnings": warnings,
		"fixed_fields": fixed_fields,
		"strictness": strictness,
		"time_ms": elapsed_time,
		"data": save_data if success else null
	}
	
	# Cache successful validations
	if success and strictness < ValidationStrictness.PARANOID:
		validation_cache[cache_key] = result.duplicate(true)
	
	validation_completed.emit(success, errors, warnings, elapsed_time)
	
	return result

# Validate any dictionary data
func validate_dictionary(data: Dictionary, custom_rules: Array = []) -> Dictionary:
	var start_time = Time.get_ticks_msec()
	
	var errors = []
	var warnings = []
	var rules_to_use = validation_rules if custom_rules.is_empty() else custom_rules
	
	for rule in rules_to_use:
		var value = _get_value_by_path(data, rule.field_path)
		var validation_result = rule.validate(value, {"data": data})
		
		if not validation_result.valid:
			errors.append_array(validation_result.errors.map(func(e): return "%s: %s" % [rule.field_path, e]))
		elif validation_result.errors.size() > 0:
			warnings.append_array(validation_result.errors.map(func(e): return "%s: %s" % [rule.field_path, e]))
	
	var success = errors.is_empty()
	var elapsed_time = Time.get_ticks_msec() - start_time
	
	return {
		"success": success,
		"valid": success,
		"errors": errors,
		"warnings": warnings,
		"time_ms": elapsed_time
	}

# Set validation strictness
func set_validation_strictness(new_strictness: ValidationStrictness) -> void:
	strictness = new_strictness
	print("SaveDataValidator: Strictness set to %s" % _strictness_to_string(new_strictness))

# Enable/disable auto-fix
func set_auto_fix_enabled(enabled: bool) -> void:
	auto_fix_enabled = enabled
	print("SaveDataValidator: Auto-fix %s" % ("enabled" if enabled else "disabled"))

# Add custom validation rule
func add_validation_rule(rule: ValidationRule) -> bool:
	if rule == null:
		return false
	
	# Check for duplicate
	for existing_rule in validation_rules:
		if existing_rule.field_path == rule.field_path:
			push_warning("Validation rule for path '%s' already exists" % rule.field_path)
			return false
	
	validation_rules.append(rule)
	validation_rule_added.emit(rule)
	
	print("Added validation rule for: %s" % rule.field_path)
	return true

# Remove validation rule
func remove_validation_rule(field_path: String) -> bool:
	for i in range(validation_rules.size()):
		if validation_rules[i].field_path == field_path:
			validation_rules.remove_at(i)
			validation_rule_removed.emit(field_path)
			
			print("Removed validation rule for: %s" % field_path)
			return true
	
	return false

# Clear validation cache
func clear_validation_cache() -> void:
	var cache_size = validation_cache.size()
	validation_cache.clear()
	validation_cache_cleared.emit(cache_size)
	
	print("Cleared validation cache (%d entries)" % cache_size)

# Get validation statistics
func get_statistics() -> Dictionary:
	return {
		"strictness": _strictness_to_string(strictness),
		"rule_count": validation_rules.size(),
		"auto_fix_enabled": auto_fix_enabled,
		"max_repair_attempts": max_repair_attempts,
		"cache_size": validation_cache.size(),
		"rules": validation_rules.map(func(r): return r.field_path)
	}

# Test validation with sample data
func test_validation() -> Dictionary:
	print("Running validation test...")
	
	# Create test save data
	var test_save_data = SaveSlotComponent.SaveData.new(
		0,
		{
			"player": {
				"name": "TestPlayer",
				"level": 5,
				"health": 75.5,
				"max_health": 100.0,
				"position": Vector2(100, 200),
				"experience": 1250
			},
			"world": {
				"current_level": 3,
				"difficulty": "normal",
				"game_time": 3600.5
			},
			"inventory": {
				"items": ["sword", "shield", "potion"],
				"currency": 500
			}
		},
		{
			"save_time": OS.get_datetime(),
			"total_play_time": 3600.5,
			"game_version": "1.0.0",
			"checksum": "test_checksum"
		}
	)
	
	# Test with different strictness levels
	var results = []
	
	for test_strictness in [ValidationStrictness.LOW, ValidationStrictness.MEDIUM, ValidationStrictness.HIGH]:
		var original_strictness = strictness
		strictness = test_strictness
		
		var result = validate_save_data(test_save_data)
		results.append({
			"strictness": _strictness_to_string(test_strictness),
			"success": result.success,
			"errors": result.errors.size(),
			"warnings": result.warnings.size(),
			"time_ms": result.time_ms
		})
		
		strictness = original_strictness
	
	print("Validation test completed")
	return {"success": true, "results": results}

# === PRIVATE METHODS ===

func _setup_default_rules() -> void:
	# Basic save data structure rules
	validation_rules.append(ValidationRule.new("slot_index", TYPE_INT, true, 0, 4))
	validation_rules.append(ValidationRule.new("version", TYPE_STRING, true))
	validation_rules.append(ValidationRule.new("game_state", TYPE_DICTIONARY, true))
	validation_rules.append(ValidationRule.new("metadata", TYPE_DICTIONARY, true))
	
	# Metadata rules
	validation_rules.append(ValidationRule.new("metadata.save_time", TYPE_DICTIONARY, true))
	validation_rules.append(ValidationRule.new("metadata.total_play_time", TYPE_FLOAT, true, 0.0))
	validation_rules.append(ValidationRule.new("metadata.game_version", TYPE_STRING, true))
	validation_rules.append(ValidationRule.new("metadata.checksum", TYPE_STRING, false))
	
	# Player data rules (if present)
	validation_rules.append(ValidationRule.new("game_state.player", TYPE_DICTIONARY, false))
	validation_rules.append(ValidationRule.new("game_state.player.name", TYPE_STRING, false))
	validation_rules.append(ValidationRule.new("game_state.player.level", TYPE_INT, false, 1, 100))
	validation_rules.append(ValidationRule.new("game_state.player.health", TYPE_FLOAT, false, 0.0, 1000.0))
	validation_rules.append(ValidationRule.new("game_state.player.max_health", TYPE_FLOAT, false, 0.0, 1000.0))
	validation_rules.append(ValidationRule.new("game_state.player.experience", TYPE_INT, false, 0))
	
	# World data rules
	validation_rules.append(ValidationRule.new("game_state.world", TYPE_DICTIONARY, false))
	validation_rules.append(ValidationRule.new("game_state.world.current_level", TYPE_INT, false, 1))
	validation_rules.append(ValidationRule.new("game_state.world.difficulty", TYPE_STRING, false))
	validation_rules.append(ValidationRule.new("game_state.world.game_time", TYPE_FLOAT, false, 0.0))

func _validate_structure(data: Dictionary) -> Dictionary:
	var errors = []
	
	# Check required top-level fields
	var required_fields = ["slot_index", "version", "game_state", "metadata"]
	for field in required_fields:
		if not data.has(field):
			errors.append("Missing required field: %s" % field)
	
	# Check metadata structure
	if data.has("metadata"):
		var metadata = data["metadata"]
		var required_metadata = ["save_time", "total_play_time", "game_version"]
		for field in required_metadata:
			if not metadata.has(field):
				errors.append("Missing required metadata field: %s" % field)
	
	# Check game_state is a dictionary
	if data.has("game_state") and not data["game_state"] is Dictionary:
		errors.append("game_state must be a dictionary")
	
	return {"valid": errors.is_empty(), "errors": errors}

func _perform_strict_validation(save_data: SaveSlotComponent.SaveData, data_dict: Dictionary) -> Dictionary:
	var errors = []
	var warnings = []
	
	# Verify checksum if present
	if data_dict.has("metadata") and data_dict["metadata"].has("checksum"):
		var metadata = data_dict["metadata"]
		var checksum = metadata["checksum"]
		
		if checksum is String and not checksum.is_empty():
			# Recalculate checksum and compare
			var game_state = data_dict.get("game_state", {})
			var checksum_data = {
				"game_state": game_state,
				"metadata": {
					"save_time": metadata.get("save_time", {}),
					"total_play_time": metadata.get("total_play_time", 0.0),
					"game_version": metadata.get("game_version", "")
				}
			}
			
			var data_string = JSON.stringify(checksum_data)
			var calculated_checksum = data_string.sha256_text().left(16)
			
			if checksum != calculated_checksum:
				errors.append("Checksum mismatch: data may be corrupted")
	
	# Validate save time is reasonable
	if data_dict.has("metadata") and data_dict["metadata"].has("save_time"):
		var save_time = data_dict["metadata"]["save_time"]
		if save_time is Dictionary:
			var year = save_time.get("year", 0)
			var month = save_time.get("month", 0)
			var day = save_time.get("day", 0)
			
			if year < 2020 or year > 2100:
				warnings.append("Suspicious save year: %d" % year)
			if month < 1 or month > 12:
				errors.append("Invalid save month: %d" % month)
			if day < 1 or day > 31:
				warnings.append("Suspicious save day: %d" % day)
	
	# Validate player health consistency
	if data_dict.has("game_state") and data_dict["game_state"].has("player"):
		var player = data_dict["game_state"]["player"]
		var health = player.get("health", 0.0)
		var max_health = player.get("max_health", 0.0)
		
		if max_health > 0 and health > max_health * 1.5:  # Allow 50% overheal
			warnings.append("Player health (%.1f) significantly exceeds max health (%.1f)" % [health, max_health])
	
	return {"errors": errors, "warnings": warnings}

func _check_for_corruption(data: Dictionary) -> Dictionary:
	# Check for NaN or Infinity values
	var nan_check = _check_for_nan_values(data)
	if nan_check.detected:
		return nan_check
	
	# Check for extremely large values
	var size_check = _check_for_size_anomalies(data)
	if size_check.detected:
		return size_check
	
	# Check for type inconsistencies
	var type_check = _check_for_type_inconsistencies(data)
	if type_check.detected:
		return type_check
	
	return {"detected": false}

func _check_for_nan_values(data: Variant, path: String = "") -> Dictionary:
	if data is float:
		if is_nan(data) or is_inf(data):
			return {
				"detected": true,
				"field": path,
				"error": "Invalid float value: %s" % str(data),
				"value": data
			}
	elif data is Dictionary:
		for key in data:
			var result = _check_for_nan_values(data[key], path + ("." if not path.is_empty() else "") + str(key))
			if result.detected:
				return result
	elif data is Array:
		for i in range(data.size()):
			var result = _check_for_nan_values(data[i], "%s[%d]" % [path, i])
			if result.detected:
				return result
	
	return {"detected": false}

func _check_for_size_anomalies(data: Dictionary) -> Dictionary:
	# Check for extremely large arrays or strings
	var check_result = _check_data_size(data, "root")
	if check_result.size_exceeded:
		return {
			"detected": true,
			"field": check_result.field,
			"error": "Data size anomaly: %s has %d elements" % [check_result.field, check_result.size],
			"value": check_result.value
		}
	
	return {"detected": false}

func _check_data_size(data: Variant, path: String) -> Dictionary:
	var MAX_ARRAY_SIZE = 10000
	var MAX_STRING_LENGTH = 100000
	var MAX_DICT_KEYS = 1000
	
	if data is Array:
		if data.size() > MAX_ARRAY_SIZE:
			return {"size_exceeded": true, "field": path, "size": data.size(), "value": data}
		
		for i in range(min(data.size(), 100)):  # Check first 100 elements
			var result = _check_data_size(data[i], "%s[%d]" % [path, i])
			if result.size_exceeded:
				return result
				
	elif data is String:
		if data.length() > MAX_STRING_LENGTH:
			return {"size_exceeded": true, "field": path, "size": data.length(), "value": data}
			
	elif data is Dictionary:
		if data.size() > MAX_DICT_KEYS:
			return {"size_exceeded": true, "field": path, "size": data.size(), "value": data}
		
		var keys_checked = 0
		for key in data:
			if keys_checked >= 100:  # Check first 100 keys
				break
			
			var result = _check_data_size(data[key], path + "." + str(key))
			if result.size_exceeded:
				return result
			
			keys_checked += 1
	
	return {"size_exceeded": false}

func _check_for_type_inconsistencies(data: Dictionary) -> Dictionary:
	# Check for fields that should have consistent types but don't
	# This is a simple implementation - can be expanded based on game-specific rules
	
	if data.has("game_state") and data["game_state"] is Dictionary:
		var game_state = data["game_state"]
		
		# Check player fields
		if game_state.has("player") and game_state["player"] is Dictionary:
			var player = game_state["player"]
			
			# Health should be numeric
			if player.has("health") and not (player["health"] is int or player["health"] is float):
				return {
					"detected": true,
					"field": "game_state.player.health",
					"error": "Type inconsistency: health should be numeric, got %s" % typeof(player["health"]),
					"value": player["health"]
				}
	
	return {"detected": false}

func _attempt_auto_fix(rule: ValidationRule, value: Variant, data: Dictionary) -> Dictionary:
	var field_path = rule.field_path
	
	# Generate default value based on type
	var default_value = _get_default_value_for_type(rule.expected_type)
	
	# Apply min/max constraints
	if default_value is int or default_value is float:
		if rule.min_value != null and default_value < rule.min_value:
			default_value = rule.min_value
		if rule.max_value != null and default_value > rule.max_value:
			default_value = rule.max_value
	
	# Set the fixed value
	_set_value_by_path(data, field_path, default_value)
	
	return {"success": true, "value": default_value}

func _attempt_corruption_repair(data: Dictionary, corruption_info: Dictionary) -> Dictionary:
	var fixed_fields = []
	var attempts = 0
	
	while attempts < max_repair_attempts:
		attempts += 1
		repair_attempted.emit(corruption_info.field, attempts, false)
		
		# Try different repair strategies
		var repair_strategy = attempts % 3
		var repair_result = {"success": false}
		
		match repair_strategy:
			0:  # Remove corrupted field
				repair_result = _repair_by_removal(data, corruption_info)
			1:  # Replace with default value
				repair_result = _repair_by_replacement(data, corruption_info)
			2:  # Try to extract valid parts
				repair_result = _repair_by_extraction(data, corruption_info)
		
		if repair_result.success:
			fixed_fields.append({
				"field": corruption_info.field,
				"strategy": repair_strategy,
				"attempt": attempts
			})
			repair_attempted.emit(corruption_info.field, attempts, true)
			break
	
	return {"success": not fixed_fields.is_empty(), "fixed_fields": fixed_fields}

func _repair_by_removal(data: Dictionary, corruption_info: Dictionary) -> Dictionary:
	var path_parts = corruption_info.field.split(".")
	var current = data
	
	for i in range(path_parts.size() - 1):
		var part = path_parts[i]
		if not current.has(part) or not current[part] is Dictionary:
			return {"success": false}
		current = current[part]
	
	var last_part = path_parts[-1]
	if current.has(last_part):
		current.erase(last_part)
		return {"success": true}
	
	return {"success": false}

func _repair_by_replacement(data: Dictionary, corruption_info: Dictionary) -> Dictionary:
	# Determine expected type from path
	var expected_type = TYPE_NIL
	if corruption_info.field.contains("health") or corruption_info.field.contains("time"):
		expected_type = TYPE_FLOAT
	elif corruption_info.field.contains("level") or corruption_info.field.contains("index"):
		expected_type = TYPE_INT
	elif corruption_info.field.contains("name") or corruption_info.field.contains("version"):
		expected_type = TYPE_STRING
	
	var default_value = _get_default_value_for_type(expected_type)
	_set_value_by_path(data, corruption_info.field, default_value)
	
	return {"success": true}

func _repair_by_extraction(data: Dictionary, corruption_info: Dictionary) -> Dictionary:
	# Try to extract any valid data from corrupted field
	var value = _get_value_by_path(data, corruption_info.field)
	
	if value is String and value.length() > 1000:
		# Truncate very long strings
		_set_value_by_path(data, corruption_info.field, value.left(1000))
		return {"success": true}
	elif value is Array and value.size() > 10000:
		# Truncate very large arrays
		_set_value_by_path(data, corruption_info.field, value.slice(0, 10000))
		return {"success": true}
	
	return {"success": false}

func _get_value_by_path(data: Dictionary, path: String) -> Variant:
	if path.is_empty():
		return null
	
	var parts = path.split(".")
	var current = data
	
	for i in range(parts.size()):
		var part = parts[i]
		
		# Handle array indices
		if part.begins_with("[") and part.ends_with("]"):
			var index_str = part.substr(1, part.length() - 2)
			if not index_str.is_valid_int():
				return null
			
			var index = index_str.to_int()
			if not current is Array or index < 0 or index >= current.size():
				return null
			
			current = current[index]
		else:
			if not current.has(part):
				return null
			
			current = current[part]
	
	return current

func _set_value_by_path(data: Dictionary, path: String, value: Variant) -> bool:
	if path.is_empty():
		return false
	
	var parts = path.split(".")
	var current = data
	
	for i in range(parts.size() - 1):
		var part = parts[i]
		
		# Handle array indices in middle of path
		if part.begins_with("[") and part.ends_with("]"):
			# Not supporting array indices in middle of path for simplicity
			return false
		
		if not current.has(part):
			current[part] = {}
		
		if not current[part] is Dictionary:
			# Can't set value if intermediate part is not a dictionary
			return false
		
		current = current[part]
	
	var last_part = parts[-1]
	
	# Handle array index at the end
	if last_part.begins_with("[") and last_part.ends_with("]"):
		var index_str = last_part.substr(1, last_part.length() - 2)
		if not index_str.is_valid_int():
			return false
		
		var index = index_str.to_int()
		if not current is Array:
			return false
		
		if index >= 0 and index < current.size():
			current[index] = value
			return true
		else:
			return false
	else:
		current[last_part] = value
		return true

func _get_default_value_for_type(type: int) -> Variant:
	match type:
		TYPE_BOOL: return false
		TYPE_INT: return 0
		TYPE_FLOAT: return 0.0
		TYPE_STRING: return ""
		TYPE_VECTOR2: return Vector2.ZERO
		TYPE_VECTOR3: return Vector3.ZERO
		TYPE_DICTIONARY: return {}
		TYPE_ARRAY: return []
		_: return null

func _generate_cache_key(save_data: SaveSlotComponent.SaveData) -> String:
	# Create a simple cache key based on save data properties
	var data_dict = save_data.to_dictionary()
	var key_parts = [
		str(save_data.slot_index),
		save_data.version,
		str(data_dict.get("metadata", {}).get("total_play_time", 0)),
		str(strictness)
	]
	return "_".join(key_parts).sha256_text().left(16)

func _estimate_data_size(save_data: SaveSlotComponent.SaveData) -> int:
	# Rough estimate of data size
	var data_dict = save_data.to_dictionary()
	var json_string = JSON.stringify(data_dict)
	return json_string.length()

func _strictness_to_string(strictness: ValidationStrictness) -> String:
	match strictness:
		ValidationStrictness.LOW: return "LOW"
		ValidationStrictness.MEDIUM: return "MEDIUM"
		ValidationStrictness.HIGH: return "HIGH"
		ValidationStrictness.PARANOID: return "PARANOID"
		_: return "UNKNOWN"

# === DEBUG & UTILITY ===

func print_statistics() -> void:
	var stats = get_statistics()
	print("=== SaveDataValidator Statistics ===")
	print("Strictness: %s" % stats.strictness)
	print("Rule Count: %d" % stats.rule_count)
	print("Auto-fix Enabled: %s" % str(stats.auto_fix_enabled))
	print("Max Repair Attempts: %d" % stats.max_repair_attempts)
	print("Cache Size: %d" % stats.cache_size)
	print("Rules: %s" % str(stats.rules))

func benchmark_validation(test_iterations: int = 100) -> Dictionary:
	print("Running validation benchmark (%d iterations)..." % test_iterations)
	
	# Create test save data
	var test_save_data = SaveSlotComponent.SaveData.new(
		0,
		{
			"player": {
				"name": "BenchmarkPlayer",
				"level": 10,
				"health": 85.0,
				"max_health": 100.0,
				"experience": 5000
			},
			"world": {
				"current_level": 5,
				"difficulty": "hard",
				"game_time": 7200.0
			}
		},
		{
			"save_time": OS.get_datetime(),
			"total_play_time": 7200.0,
			"game_version": "1.0.0",
			"checksum": "benchmark_checksum"
		}
	)
	
	var total_time = 0
	var successes = 0
	var total_errors = 0
	var total_warnings = 0
	
	for i in range(test_iterations):
		# Modify data slightly each iteration
		test_save_data.game_state["player"]["experience"] = 5000 + i * 100
		test_save_data.metadata["total_play_time"] = 7200.0 + i * 60.0
		
		var result = validate_save_data(test_save_data)
		
		total_time += result.time_ms
		if result.success:
			successes += 1
		total_errors += result.errors.size()
		total_warnings += result.warnings.size()
	
	var avg_time = float(total_time) / test_iterations
	var success_rate = float(successes) / test_iterations * 100.0
	var avg_errors = float(total_errors) / test_iterations
	var avg_warnings = float(total_warnings) / test_iterations
	
	print("Benchmark completed:")
	print("  Average Time: %.2f ms" % avg_time)
	print("  Success Rate: %.1f%%" % success_rate)
	print("  Average Errors: %.2f" % avg_errors)
	print("  Average Warnings: %.2f" % avg_warnings)
	
	return {
		"success": true,
		"iterations": test_iterations,
		"avg_time_ms": avg_time,
		"success_rate": success_rate,
		"avg_errors": avg_errors,
		"avg_warnings": avg_warnings,
		"total_time_ms": total_time
	}