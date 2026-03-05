# 🧪 TEST BASE ATOM
# Atomic Design: Temel test atomu
# Tüm test bileşenleri için temel sınıf
class_name TestBaseAtom
extends Node

# === TEST TYPES ===
enum TestType {
	UNIT = 0,
	INTEGRATION = 1,
	PERFORMANCE = 2,
	STRESS = 3,
	RECOVERY = 4,
	COMPATIBILITY = 5
}

# === TEST STATUS ===
enum TestStatus {
	PENDING = 0,
	RUNNING = 1,
	PASSED = 2,
	FAILED = 3,
	SKIPPED = 4,
	TIMEOUT = 5
}

# === TEST RESULT STRUCTURE ===
class TestResult:
	var test_name: String
	var test_type: TestType
	var status: TestStatus
	var duration_ms: int
	var error_message: String = ""
	var data: Dictionary = {}
	
	func _init(name: String, type: TestType):
		test_name = name
		test_type = type
		status = TestStatus.PENDING
		duration_ms = 0
	
	func to_dictionary() -> Dictionary:
		return {
			"test_name": test_name,
			"test_type": test_type,
			"status": status,
			"duration_ms": duration_ms,
			"error_message": error_message,
			"data": data
		}
	
	func _to_string() -> String:
		var status_str = TestStatus.keys()[status]
		var type_str = TestType.keys()[test_type]
		return "[TestResult: %s (%s) - %s - %dms]" % [
			test_name,
			type_str,
			status_str,
			duration_ms
		]

# === CONFIG ===
@export var test_name: String = "UnnamedTest":
	set(value):
		test_name = value
		if is_inside_tree():
			_update_test_info()

@export var test_type: TestType = TestType.UNIT:
	set(value):
		test_type = value
		if is_inside_tree():
			_update_test_info()

@export var timeout_ms: int = 5000:
	set(value):
		timeout_ms = value
		if is_inside_tree():
			_update_timeout_settings()

@export var retry_count: int = 0:
	set(value):
		retry_count = value
		if is_inside_tree():
			_update_retry_settings()

# === STATE ===
var current_status: TestStatus = TestStatus.PENDING
var start_time: int = 0
var end_time: int = 0
var current_retry: int = 0
var is_testing: bool = false
var test_result: TestResult = null

# === EVENTS ===
signal test_started(test_name: String, test_type: TestType)
signal test_completed(test_result: TestResult)
signal test_progress(progress: float, message: String)
signal test_error(error_message: String, error_code: int)
signal test_timeout(test_name: String, elapsed_ms: int)

# === LIFECYCLE ===

func _ready() -> void:
	# Test result oluştur
	test_result = TestResult.new(test_name, test_type)
	
	# Başlangıç durumu
	_update_test_info()

# === PUBLIC API ===

func run_test() -> TestResult:
	"""Testi çalıştır ve sonucu döndür"""
	if is_testing:
		test_result.error_message = "Test already running"
		test_result.status = TestStatus.FAILED
		return test_result
	
	is_testing = true
	current_retry = 0
	
	# Test başladı
	test_started.emit(test_name, test_type)
	test_result.status = TestStatus.RUNNING
	start_time = Time.get_ticks_msec()
	
	# Timeout timer başlat
	_start_timeout_timer()
	
	# Testi çalıştır
	var success = false
	var error_msg = ""
	
	for attempt in range(retry_count + 1):
		current_retry = attempt
		
		if attempt > 0:
			test_progress.emit(0.5, "Retry attempt %d/%d" % [attempt + 1, retry_count + 1])
			await get_tree().create_timer(0.5).timeout
		
		try:
			success = _execute_test()
			if success:
				break
		except:
			error_msg = "Test threw an exception on attempt %d" % (attempt + 1)
			test_error.emit(error_msg, 1000 + attempt)
	
	# Test tamamlandı
	end_time = Time.get_ticks_msec()
	test_result.duration_ms = end_time - start_time
	
	if success:
		test_result.status = TestStatus.PASSED
	else:
		test_result.status = TestStatus.FAILED
		test_result.error_message = error_msg if not error_msg.is_empty() else "Test failed after %d attempts" % (retry_count + 1)
	
	# Timeout timer durdur
	_stop_timeout_timer()
	
	is_testing = false
	test_completed.emit(test_result)
	
	return test_result

func reset_test() -> void:
	"""Testi sıfırla"""
	is_testing = false
	current_status = TestStatus.PENDING
	start_time = 0
	end_time = 0
	current_retry = 0
	
	test_result = TestResult.new(test_name, test_type)
	
	# Timeout timer durdur
	_stop_timeout_timer()

func get_test_result() -> TestResult:
	"""Current test result'ı al"""
	return test_result

func get_test_statistics() -> Dictionary:
	"""Test istatistiklerini al"""
	return {
		"test_name": test_name,
		"test_type": test_type,
		"status": current_status,
		"duration_ms": test_result.duration_ms if test_result else 0,
		"retry_count": retry_count,
		"current_retry": current_retry,
		"is_testing": is_testing,
		"timeout_ms": timeout_ms
	}

func set_test_data(key: String, value) -> void:
	"""Test data ekle"""
	if test_result:
		test_result.data[key] = value

func get_test_data(key: String, default = null):
	"""Test data al"""
	if test_result and key in test_result.data:
		return test_result.data[key]
	return default

# === PROTECTED METHODS (Override these in child classes) ===

func _execute_test() -> bool:
	"""Testi çalıştır - Child class'lar bu method'u override etmeli"""
	push_warning("TestBaseAtom._execute_test() not implemented in child class")
	return false

func _setup_test() -> void:
	"""Test setup - Child class'lar bu method'u override edebilir"""
	pass

func _cleanup_test() -> void:
	"""Test cleanup - Child class'lar bu method'u override edebilir"""
	pass

func _validate_test_result() -> bool:
	"""Test result validation - Child class'lar bu method'u override edebilir"""
	return test_result.status == TestStatus.PASSED

# === PRIVATE METHODS ===

func _update_test_info() -> void:
	# Test info güncelle
	if test_result:
		test_result.test_name = test_name
		test_result.test_type = test_type

func _update_timeout_settings() -> void:
	# Timeout settings güncelle
	pass

func _update_retry_settings() -> void:
	# Retry settings güncelle
	pass

func _start_timeout_timer() -> void:
	# Timeout timer başlat
	_stop_timeout_timer()  # Önceki timer'ı durdur
	
	if timeout_ms > 0:
		await get_tree().create_timer(timeout_ms / 1000.0).timeout
		
		if is_testing:
			# Timeout oldu
			test_result.status = TestStatus.TIMEOUT
			test_result.error_message = "Test timeout after %d ms" % timeout_ms
			test_timeout.emit(test_name, timeout_ms)
			
			# Testi durdur
			is_testing = false
			_cleanup_test()

func _stop_timeout_timer() -> void:
	# Timeout timer durdur
	# Godot'ta timer'ı durdurmanın doğrudan bir yolu yok,
	# bu yüzden flag-based approach kullanıyoruz
	pass

# === DEBUG ===

func _to_string() -> String:
	var status_str = TestStatus.keys()[current_status]
	var type_str = TestType.keys()[test_type]
	return "[TestBaseAtom: %s (%s) - %s]" % [
		test_name,
		type_str,
		status_str
	]

func print_debug_info() -> void:
	print("=== TestBaseAtom Debug ===")
	print("Test Name: %s" % test_name)
	print("Test Type: %s" % TestType.keys()[test_type])
	print("Status: %s" % TestStatus.keys()[current_status])
	print("Is Testing: %s" % str(is_testing))
	print("Timeout: %d ms" % timeout_ms)
	print("Retry Count: %d" % retry_count)
	print("Current Retry: %d" % current_retry)
	
	if test_result:
		print("Test Result: %s" % str(test_result))
		print("Duration: %d ms" % test_result.duration_ms)
		if test_result.error_message:
			print("Error: %s" % test_result.error_message)
		if not test_result.data.is_empty():
			print("Test Data: %s" % str(test_result.data))