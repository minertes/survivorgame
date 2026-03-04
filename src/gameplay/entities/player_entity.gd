# 👤 PLAYER ENTITY
# Oyuncu karakteri için entity
class_name PlayerEntity
extends Entity

# === PLAYER CONFIG ===
var player_id: String = "player_01"
var player_level: int = 1
var player_experience: float = 0.0
var player_score: int = 0

# === INPUT ===
var input_enabled: bool = true

# === COMPONENT REFERENCES ===
var health_component: HealthComponent = null
var movement_component: MovementComponent = null
# WeaponComponent ve diğerleri sonra eklenecek

# === SIGNALS ===
signal player_level_changed(old_level: int, new_level: int)
signal experience_gained(amount: float, new_total: float)
signal score_changed(old_score: int, new_score: int)
signal player_died()
signal player_respawned()

# === LIFECYCLE ===

func _initialize_entity() -> void:
	entity_name = "Player"
	entity_type = "player"
	
	# Temel component'ları oluştur
	_setup_components()
	
	# Input'u etkinleştir
	set_process_input(true)
	
	print("PlayerEntity initialized: %s" % entity_name)

func _setup_components() -> void:
	# Health Component
	health_component = HealthComponent.new()
	health_component.max_health = 100.0
	health_component.current_health = 100.0
	add_component(health_component)
	
	# Health component signal'larını dinle
	health_component.health_changed.connect(_on_health_changed)
	health_component.died.connect(_on_player_died)
	
	# Movement Component
	movement_component = MovementComponent.new()
	movement_component.speed = 300.0
	movement_component.max_speed = 500.0
	movement_component.acceleration = 1200.0
	movement_component.deceleration = 900.0
	add_component(movement_component)
	
	# Movement component signal'larını dinle
	movement_component.movement_started.connect(_on_movement_started)
	movement_component.movement_stopped.connect(_on_movement_stopped)
	movement_component.dash_started.connect(_on_dash_started)

func _process(delta: float) -> void:
	if not is_active or is_destroyed:
		return
	
	update(delta)

func _physics_process(delta: float) -> void:
	if not is_active or is_destroyed:
		return
	
	physics_update(delta)

func _input(event: InputEvent) -> void:
	if not is_active or not input_enabled or is_destroyed:
		return
	
	handle_input(event)

# === INPUT HANDLING ===

func handle_input(event: InputEvent) -> void:
	# Movement input
	var move_direction = Vector2.ZERO
	
	if Input.is_action_pressed("move_right"):
		move_direction.x += 1
	if Input.is_action_pressed("move_left"):
		move_direction.x -= 1
	if Input.is_action_pressed("move_down"):
		move_direction.y += 1
	if Input.is_action_pressed("move_up"):
		move_direction.y -= 1
	
	# Movement component'a gönder
	if movement_component:
		movement_component.move(move_direction)
	
	# Dash input
	if Input.is_action_just_pressed("dash") and movement_component:
		movement_component.dash(move_direction)
	
	# Attack input (sonra eklenecek)
	if Input.is_action_pressed("attack"):
		_try_attack()
	if Input.is_action_just_pressed("special_attack"):
		_try_special_attack()

# === UPDATE METHODS ===

func update(delta: float) -> void:
	# Player-specific update logic
	# Örneğin: ability cooldowns, buff timers, etc.
	pass

func physics_update(delta: float) -> void:
	if movement_component and movement_component.velocity.length() > 0:
		# Hareketi uygula
		position += movement_component.velocity * delta

# === PLAYER METHODS ===

func gain_experience(amount: float) -> void:
	if amount <= 0:
		return
	
	var old_exp = player_experience
	player_experience += amount
	
	experience_gained.emit(amount, player_experience)
	
	# Level up kontrolü
	_check_level_up()

func add_score(points: int) -> void:
	if points <= 0:
		return
	
	var old_score = player_score
	player_score += points
	
	score_changed.emit(old_score, player_score)

func level_up() -> void:
	var old_level = player_level
	player_level += 1
	
	# Level up bonus'ları
	_apply_level_up_bonuses()
	
	player_level_changed.emit(old_level, player_level)
	print("Player leveled up! Level %d → %d" % [old_level, player_level])

func respawn() -> void:
	if health_component:
		health_component.resurrect(1.0)
	
	# Reset position (sonra spawn point sistemi eklenecek)
	position = Vector2(400, 300)
	
	# Enable input
	input_enabled = true
	
	player_respawned.emit()
	print("Player respawned at position: %s" % str(position))

func take_damage(amount: float, source: Node = null) -> void:
	if health_component:
		health_component.take_damage(amount, source)

func heal(amount: float) -> void:
	if health_component:
		health_component.heal(amount)

func get_health_percentage() -> float:
	if health_component:
		return health_component.get_health_percentage()
	return 0.0

func is_alive() -> bool:
	if health_component:
		return health_component.is_alive()
	return false

# === PRIVATE METHODS ===

func _check_level_up() -> void:
	# Basit level up formülü: her level için 100 * level experience gerekiyor
	var exp_needed = player_level * 100
	
	while player_experience >= exp_needed:
		player_experience -= exp_needed
		level_up()
		exp_needed = player_level * 100  # Yeni level için gerekli exp

func _apply_level_up_bonuses() -> void:
	# Health bonus
	if health_component:
		var health_increase = 20.0
		health_component.set_max_health(
			health_component.max_health + health_increase,
			true  # Health'i full yap
		)
	
	# Speed bonus
	if movement_component:
		var speed_increase = 10.0
		movement_component.set_speed(
			movement_component.speed + speed_increase
		)

func _try_attack() -> void:
	# Weapon component eklendikten sonra implemente edilecek
	print("Player attacking (weapon system not implemented yet)")

func _try_special_attack() -> void:
	# Ability component eklendikten sonra implemente edilecek
	print("Player special attack (ability system not implemented yet)")

# === SIGNAL HANDLERS ===

func _on_health_changed(old_value: float, new_value: float) -> void:
	print("Player health: %.1f → %.1f" % [old_value, new_value])

func _on_player_died(killer: Node = null) -> void:
	print("Player died! Killer: %s" % (killer.get_name() if killer else "Unknown"))
	
	# Input'u devre dışı bırak
	input_enabled = false
	
	player_died.emit()
	
	# 3 saniye sonra respawn
	var respawn_timer = get_tree().create_timer(3.0)
	respawn_timer.timeout.connect(respawn)

func _on_movement_started(direction: Vector2) -> void:
	print("Player started moving: %s" % str(direction))

func _on_movement_stopped() -> void:
	print("Player stopped moving")

func _on_dash_started(direction: Vector2) -> void:
	print("Player dashed: %s" % str(direction))

# === SERIALIZATION ===

func serialize() -> Dictionary:
	var data = super.serialize()
	
	data["player_id"] = player_id
	data["player_level"] = player_level
	data["player_experience"] = player_experience
	data["player_score"] = player_score
	data["input_enabled"] = input_enabled
	
	return data

func deserialize(data: Dictionary) -> void:
	super.deserialize(data)
	
	if "player_id" in data:
		player_id = data["player_id"]
	if "player_level" in data:
		player_level = data["player_level"]
	if "player_experience" in data:
		player_experience = data["player_experience"]
	if "player_score" in data:
		player_score = data["player_score"]
	if "input_enabled" in data:
		input_enabled = data["input_enabled"]

# === DEBUG ===

func _to_string() -> String:
	var health_str = "N/A"
	if health_component:
		health_str = "%.1f/%.1f" % [health_component.current_health, health_component.max_health]
	
	return "[PlayerEntity: %s | Level %d | HP: %s | Score: %d]" % [
		entity_name,
		player_level,
		health_str,
		player_score
	]

func print_player_stats() -> void:
	print("=== Player Stats ===")
	print("Name: %s" % entity_name)
	print("Level: %d" % player_level)
	print("Experience: %.1f/%d" % [player_experience, player_level * 100])
	print("Score: %d" % player_score)
	
	if health_component:
		print("Health: %.1f/%.1f (%.1f%%)" % [
			health_component.current_health,
			health_component.max_health,
			health_component.get_health_percentage() * 100
		])
	
	if movement_component:
		print("Speed: %.1f" % movement_component.speed)
	
	print("Components: %d" % get_component_count())
	print("Component Types: %s" % str(get_component_types()))