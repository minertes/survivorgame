# 🎯 PROJECTILE ENTITY
# Weapon-based projectiles with collision and damage
class_name ProjectileEntity
extends Entity

# === COMPONENTS ===
var movement_component: MovementComponent
var collision_component: Area2D
var lifetime_component: Timer

# === PROJECTILE PROPERTIES ===
var damage: float = 10.0
var speed: float = 300.0
var pierce_count: int = 0
var current_pierces: int = 0
var knockback_force: float = 50.0
var owner_node: Node = null
var weapon_id: String = ""
var is_homing: bool = false
var homing_target: Node = null
var homing_strength: float = 5.0

# === SIGNALS ===
signal projectile_spawned
signal projectile_hit(target: Node, damage: float)
signal projectile_pierced(target: Node)
signal projectile_expired
signal projectile_destroyed

# === LIFECYCLE ===

func _ready() -> void:
	super._ready()
	entity_type = "projectile"
	_setup_components()
	_setup_collision()
	projectile_spawned.emit()

func _setup_components() -> void:
	# Movement component
	movement_component = MovementComponent.new()
	movement_component.speed = speed
	ComponentManager.instance.attach_component_to_entity(movement_component, self)
	
	# Lifetime component
	lifetime_component = Timer.new()
	lifetime_component.wait_time = 5.0  # Default 5 seconds
	lifetime_component.one_shot = true
	lifetime_component.timeout.connect(_on_lifetime_expired)
	add_child(lifetime_component)
	lifetime_component.start()

func _setup_collision() -> void:
	collision_component = Area2D.new()
	
	# Collision shape
	var collision_shape = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 4.0
	collision_shape.shape = shape
	
	collision_component.add_child(collision_shape)
	collision_component.body_entered.connect(_on_body_entered)
	collision_component.area_entered.connect(_on_area_entered)
	
	add_child(collision_component)

func _physics_process(delta: float) -> void:
	if not is_active:
		return
	
	# Update movement
	_update_movement(delta)
	
	# Homing logic
	if is_homing and homing_target and is_instance_valid(homing_target):
		_update_homing(delta)

# === PUBLIC API ===

func initialize_projectile(config: Dictionary, owner: Node, start_position: Vector2, direction: Vector2) -> void:
	global_position = start_position
	
	# Set properties from config
	if "damage" in config:
		damage = config.damage
	if "speed" in config:
		speed = config.speed
		movement_component.speed = speed
	if "pierce" in config:
		pierce_count = config.pierce
	if "knockback" in config:
		knockback_force = config.knockback
	if "lifetime" in config:
		lifetime_component.wait_time = config.lifetime
		lifetime_component.start()
	if "homing" in config:
		is_homing = config.homing
	if "homing_strength" in config:
		homing_strength = config.homing_strength
	
	owner_node = owner
	weapon_id = config.get("weapon_id", "")
	
	# Set initial velocity
	movement_component.velocity = direction.normalized() * speed
	
	# Set collision layers/masks
	_setup_collision_layers()

func set_homing_target(target: Node) -> void:
	homing_target = target
	is_homing = true

func set_pierce_count(count: int) -> void:
	pierce_count = count

func set_knockback(force: float) -> void:
	knockback_force = force

func get_remaining_lifetime() -> float:
	return lifetime_component.time_left

func extend_lifetime(seconds: float) -> void:
	lifetime_component.wait_time += seconds
	lifetime_component.start()

# === PRIVATE METHODS ===

func _update_movement(delta: float) -> void:
	if movement_component:
		movement_component.update(delta)

func _update_homing(delta: float) -> void:
	if not homing_target or not is_instance_valid(homing_target):
		return
	
	var target_direction = (homing_target.global_position - global_position).normalized()
	var current_direction = movement_component.velocity.normalized()
	
	# Smoothly rotate towards target
	var new_direction = current_direction.lerp(target_direction, homing_strength * delta).normalized()
	movement_component.velocity = new_direction * speed

func _setup_collision_layers() -> void:
	if not collision_component:
		return
	
	# Projectiles should not collide with owner
	if owner_node:
		collision_component.set_collision_mask_value(owner_node.get_collision_layer(), false)
	
	# Set appropriate collision layers
	collision_component.collision_layer = 0
	collision_component.collision_mask = 0
	
	# Collide with enemies if owner is player
	if owner_node and owner_node.has_method("is_player"):
		collision_component.set_collision_mask_value(2, true)  # Enemy layer
	# Collide with player if owner is enemy
	elif owner_node and owner_node.has_method("is_enemy"):
		collision_component.set_collision_mask_value(1, true)  # Player layer

func _on_body_entered(body: Node) -> void:
	_handle_collision(body)

func _on_area_entered(area: Area2D) -> void:
	_handle_collision(area.get_parent())

func _handle_collision(target: Node) -> void:
	if not target or not is_instance_valid(target):
		return
	
	# Don't collide with owner
	if target == owner_node:
		return
	
	# Don't collide with other projectiles
	if target is ProjectileEntity:
		return
	
	# Apply damage if target has health component
	var health_component = ComponentManager.instance.get_first_component_of_type(target, "HealthComponent")
	if health_component:
		# Calculate final damage
		var final_damage = damage
		
		# Apply critical hit chance
		var weapon_config = ConfigManager.instance.get_weapon_config(weapon_id)
		if weapon_config and "critical_chance" in weapon_config:
			var crit_chance = weapon_config.critical_chance
			if randf() < crit_chance:
				final_damage *= weapon_config.get("critical_multiplier", 2.0)
				EventBus.emit_now_static(EventBus.CRITICAL_HIT, {
					"damage": final_damage,
					"target": target,
					"projectile": self
				})
		
		# Apply damage
		health_component.take_damage(final_damage)
		
		# Apply knockback
		if knockback_force > 0:
			_apply_knockback(target)
		
		# Emit hit event
		projectile_hit.emit(target, final_damage)
		EventBus.emit_now_static(EventBus.PROJECTILE_HIT, {
			"damage": final_damage,
			"target": target,
			"projectile": self,
			"weapon_id": weapon_id,
			"owner": owner_node
		})
		
		# Check pierce
		if pierce_count > 0 and current_pierces < pierce_count:
			current_pierces += 1
			projectile_pierced.emit(target)
		else:
			_destroy_projectile()
	else:
		# Hit something without health (wall, obstacle)
		_destroy_projectile()

func _apply_knockback(target: Node) -> void:
	var movement = ComponentManager.instance.get_first_component_of_type(target, "MovementComponent")
	if movement:
		var knockback_direction = movement_component.velocity.normalized()
		movement.apply_knockback(knockback_direction * knockback_force)

func _on_lifetime_expired() -> void:
	projectile_expired.emit()
	EventBus.emit_now_static("projectile_expired", {
		"projectile": self,
		"weapon_id": weapon_id
	})
	_destroy_projectile()

func _destroy_projectile() -> void:
	projectile_destroyed.emit()
	
	# Clean up components
	if movement_component:
		ComponentManager.instance.detach_component_from_entity(movement_component)
		movement_component.queue_free()
	
	queue_free()

# === SERIALIZATION ===

func serialize() -> Dictionary:
	var data = super.serialize()
	
	data["projectile_data"] = {
		"damage": damage,
		"speed": speed,
		"pierce_count": pierce_count,
		"current_pierces": current_pierces,
		"knockback_force": knockback_force,
		"weapon_id": weapon_id,
		"is_homing": is_homing,
		"homing_strength": homing_strength,
		"remaining_lifetime": get_remaining_lifetime()
	}
	
	return data

func deserialize(data: Dictionary) -> void:
	super.deserialize(data)
	
	if "projectile_data" in data:
		var projectile_data = data["projectile_data"]
		damage = projectile_data.get("damage", damage)
		speed = projectile_data.get("speed", speed)
		pierce_count = projectile_data.get("pierce_count", pierce_count)
		current_pierces = projectile_data.get("current_pierces", current_pierces)
		knockback_force = projectile_data.get("knockback_force", knockback_force)
		weapon_id = projectile_data.get("weapon_id", weapon_id)
		is_homing = projectile_data.get("is_homing", is_homing)
		homing_strength = projectile_data.get("homing_strength", homing_strength)
		
		# Restore movement component
		if movement_component:
			movement_component.speed = speed
		
		# Restore lifetime
		if "remaining_lifetime" in projectile_data:
			lifetime_component.wait_time = projectile_data.remaining_lifetime
			lifetime_component.start()

# === DEBUG ===

func _to_string() -> String:
	return "[ProjectileEntity: %s, Damage: %.1f, Speed: %.0f]" % [entity_name, damage, speed]