# 🏃 MOVEMENT COMPONENT
# Hareket yönetimi için atomic component
class_name MovementComponent
extends Component

# === CONFIGURATION ===
var speed: float = 200.0
var acceleration: float = 1000.0
var deceleration: float = 800.0
var max_speed: float = 500.0

# Movement state
var velocity: Vector2 = Vector2.ZERO
var input_direction: Vector2 = Vector2.ZERO
var is_moving: bool = false
var last_move_direction: Vector2 = Vector2.RIGHT

# Dash/Jump
var can_dash: bool = true
var dash_speed: float = 800.0
var dash_duration: float = 0.2
var dash_cooldown: float = 1.0
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0

# === SIGNALS ===
signal movement_started(direction: Vector2)
signal movement_stopped()
signal dash_started(direction: Vector2)
signal dash_ended()
signal velocity_changed(new_velocity: Vector2)

# === LIFECYCLE ===

func _initialize() -> void:
	set_physics_process(true)

func physics_update(delta: float) -> void:
	_update_dash(delta)
	_update_movement(delta)
	_update_cooldowns(delta)

# === PUBLIC API ===

func move(direction: Vector2) -> void:
	input_direction = direction.normalized() if direction.length() > 0.1 else Vector2.ZERO
	
	if input_direction.length() > 0:
		last_move_direction = input_direction
		
		if not is_moving:
			is_moving = true
			movement_started.emit(input_direction)
	else:
		if is_moving:
			is_moving = false
			movement_stopped.emit()

func dash(direction: Vector2 = Vector2.ZERO) -> bool:
	if not can_dash or is_dashing:
		return false
	
	var dash_dir = direction if direction.length() > 0.1 else last_move_direction
	if dash_dir.length() < 0.1:
		dash_dir = Vector2.RIGHT
	
	velocity = dash_dir.normalized() * dash_speed
	is_dashing = true
	dash_timer = 0.0
	can_dash = false
	
	dash_started.emit(dash_dir)
	return true

func stop() -> void:
	input_direction = Vector2.ZERO
	velocity = Vector2.ZERO
	is_moving = false
	movement_stopped.emit()
	velocity_changed.emit(velocity)

func get_speed_percentage() -> float:
	return velocity.length() / max_speed if max_speed > 0 else 0.0

func is_dash_available() -> bool:
	return can_dash and not is_dashing

func get_dash_cooldown_percentage() -> float:
	return 1.0 - (dash_cooldown_timer / dash_cooldown) if dash_cooldown > 0 else 1.0

# === PRIVATE METHODS ===

func _update_movement(delta: float) -> void:
	if is_dashing:
		return
	
	var target_velocity = input_direction * speed
	
	# Acceleration/Deceleration
	if input_direction.length() > 0.1:
		# Accelerate towards target velocity
		velocity = velocity.move_toward(target_velocity, acceleration * delta)
	else:
		# Decelerate to zero
		velocity = velocity.move_toward(Vector2.ZERO, deceleration * delta)
	
	# Clamp to max speed
	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed
	
	# Emit velocity change if significant
	if velocity.length() > 10.0 or (velocity.length() == 0.0 and input_direction.length() == 0.0):
		velocity_changed.emit(velocity)

func _update_dash(delta: float) -> void:
	if not is_dashing:
		return
	
	dash_timer += delta
	if dash_timer >= dash_duration:
		is_dashing = false
		dash_ended.emit()
		
		# Apply slowdown after dash
		velocity = velocity * 0.5

func _update_cooldowns(delta: float) -> void:
	if not can_dash:
		dash_cooldown_timer += delta
		if dash_cooldown_timer >= dash_cooldown:
			can_dash = true
			dash_cooldown_timer = 0.0

# === CONFIGURATION HELPERS ===

func set_speed(new_speed: float) -> void:
	speed = new_speed

func set_max_speed(new_max_speed: float) -> void:
	max_speed = new_max_speed

func set_acceleration(new_acceleration: float) -> void:
	acceleration = new_acceleration

func set_dash_config(new_dash_speed: float, new_dash_duration: float, new_dash_cooldown: float) -> void:
	dash_speed = new_dash_speed
	dash_duration = new_dash_duration
	dash_cooldown = new_dash_cooldown

# === SERIALIZATION ===

func serialize() -> Dictionary:
	var data = super.serialize()
	data["speed"] = speed
	data["max_speed"] = max_speed
	data["acceleration"] = acceleration
	data["deceleration"] = deceleration
	data["velocity_x"] = velocity.x
	data["velocity_y"] = velocity.y
	data["is_moving"] = is_moving
	data["last_move_direction_x"] = last_move_direction.x
	data["last_move_direction_y"] = last_move_direction.y
	data["can_dash"] = can_dash
	data["is_dashing"] = is_dashing
	data["dash_timer"] = dash_timer
	data["dash_cooldown_timer"] = dash_cooldown_timer
	return data

func deserialize(data: Dictionary) -> void:
	super.deserialize(data)
	
	if "speed" in data:
		speed = data["speed"]
	if "max_speed" in data:
		max_speed = data["max_speed"]
	if "acceleration" in data:
		acceleration = data["acceleration"]
	if "deceleration" in data:
		deceleration = data["deceleration"]
	if "velocity_x" in data and "velocity_y" in data:
		velocity = Vector2(data["velocity_x"], data["velocity_y"])
	if "is_moving" in data:
		is_moving = data["is_moving"]
	if "last_move_direction_x" in data and "last_move_direction_y" in data:
		last_move_direction = Vector2(data["last_move_direction_x"], data["last_move_direction_y"])
	if "can_dash" in data:
		can_dash = data["can_dash"]
	if "is_dashing" in data:
		is_dashing = data["is_dashing"]
	if "dash_timer" in data:
		dash_timer = data["dash_timer"]
	if "dash_cooldown_timer" in data:
		dash_cooldown_timer = data["dash_cooldown_timer"]

# === DEBUG ===

func _to_string() -> String:
	return "[MovementComponent: Speed=%.1f, Vel=(%.1f, %.1f)]" % [
		speed,
		velocity.x,
		velocity.y
	]