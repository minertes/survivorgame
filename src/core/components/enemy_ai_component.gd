# 🤖 ENEMY AI COMPONENT
# Düşman AI sistemi için atomic component
class_name EnemyAIComponent
extends Component

# === AI STATES ===
enum AIState {
	IDLE,
	CHASING,
	ATTACKING,
	FLEEING,
	PATROLLING
}

# === AI CONFIG ===
var ai_state: AIState = AIState.IDLE
var target: Node2D = null
var detection_range: float = 300.0
var attack_range: float = 50.0
var chase_speed_multiplier: float = 1.2
var flee_health_threshold: float = 0.3  # %30 can altında kaçar
var patrol_points: Array[Vector2] = []
var current_patrol_index: int = 0
var patrol_speed: float = 0.5  # Normal hızın yüzdesi

# === SIGNALS ===
signal ai_state_changed(old_state: AIState, new_state: AIState)
signal target_spotted(target: Node2D)
signal target_lost()
signal attack_triggered(target: Node2D)
signal flee_triggered()

# === LIFECYCLE ===

func _initialize() -> void:
	print("EnemyAIComponent initialized")
	set_process(true)

func update(delta: float) -> void:
	if not is_enabled:
		return
	
	# AI state machine
	match ai_state:
		AIState.IDLE:
			_update_idle_state(delta)
		
		AIState.CHASING:
			_update_chasing_state(delta)
		
		AIState.ATTACKING:
			_update_attacking_state(delta)
		
		AIState.FLEEING:
			_update_fleeing_state(delta)
		
		AIState.PATROLLING:
			_update_patrolling_state(delta)
	
	# Target detection
	_update_target_detection()
	
	# Flee check
	_check_flee_condition()

# === PUBLIC API ===

func set_target(new_target: Node2D) -> void:
	if target != new_target:
		var old_target = target
		target = new_target
		
		if target:
			set_state(AIState.CHASING)
			target_spotted.emit(target)
		else:
			set_state(AIState.IDLE)
			if old_target:
				target_lost.emit()

func clear_target() -> void:
	set_target(null)

func set_state(new_state: AIState) -> void:
	if ai_state == new_state:
		return
	
	var old_state = ai_state
	ai_state = new_state
	ai_state_changed.emit(old_state, new_state)

func get_state() -> AIState:
	return ai_state

func get_state_name() -> String:
	return AIState.keys()[ai_state]

func set_detection_range(range: float) -> void:
	detection_range = max(0.0, range)

func set_attack_range(range: float) -> void:
	attack_range = max(0.0, range)

func set_chase_speed_multiplier(multiplier: float) -> void:
	chase_speed_multiplier = max(0.1, multiplier)

func set_flee_health_threshold(threshold: float) -> void:
	flee_health_threshold = clamp(threshold, 0.0, 1.0)

func set_patrol_points(points: Array[Vector2]) -> void:
	patrol_points = points.duplicate()
	current_patrol_index = 0

func add_patrol_point(point: Vector2) -> void:
	patrol_points.append(point)

func start_patrolling() -> void:
	if not patrol_points.is_empty():
		set_state(AIState.PATROLLING)

func stop_patrolling() -> void:
	if ai_state == AIState.PATROLLING:
		set_state(AIState.IDLE)

func get_movement_direction() -> Vector2:
	match ai_state:
		AIState.CHASING:
			if target:
				return (target.global_position - entity.global_position).normalized()
		
		AIState.FLEEING:
			if target:
				return (entity.global_position - target.global_position).normalized()
		
		AIState.PATROLLING:
			if not patrol_points.is_empty():
				var target_point = patrol_points[current_patrol_index]
				var direction = (target_point - entity.global_position).normalized()
				
				# Hedef noktaya ulaştı mı?
				if entity.global_position.distance_to(target_point) < 10.0:
					current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
				
				return direction
		
		AIState.IDLE:
			# Rastgele küçük hareketler
			if randf() < 0.01:
				return Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	
	return Vector2.ZERO

func get_movement_speed_multiplier() -> float:
	match ai_state:
		AIState.CHASING:
			return chase_speed_multiplier
		
		AIState.FLEEING:
			return 1.5  # Kaçarken daha hızlı
		
		AIState.PATROLLING:
			return patrol_speed
		
		_:
			return 1.0

func should_attack() -> bool:
	if ai_state != AIState.ATTACKING:
		return false
	
	if not target:
		return false
	
	# Hedef hala attack range'de mi?
	var distance = entity.global_position.distance_to(target.global_position)
	return distance <= attack_range

func can_see_target() -> bool:
	if not target:
		return false
	
	var distance = entity.global_position.distance_to(target.global_position)
	return distance <= detection_range

# === PRIVATE METHODS ===

func _update_idle_state(delta: float) -> void:
	# IDLE state'inde özel bir şey yapma
	pass

func _update_chasing_state(delta: float) -> void:
	if not target or not is_instance_valid(target):
		clear_target()
		return
	
	# Hedefe doğru hareket et
	var distance_to_target = entity.global_position.distance_to(target.global_position)
	
	# Attack range kontrolü
	if distance_to_target <= attack_range:
		set_state(AIState.ATTACKING)

func _update_attacking_state(delta: float) -> void:
	if not target or not is_instance_valid(target):
		clear_target()
		return
	
	# Hedef hala attack range'de mi?
	var distance_to_target = entity.global_position.distance_to(target.global_position)
	
	if distance_to_target > attack_range:
		# Hedef kaçtı, tekrar chase et
		set_state(AIState.CHASING)
		return
	
	# Attack yap
	attack_triggered.emit(target)

func _update_fleeing_state(delta: float) -> void:
	if not target or not is_instance_valid(target):
		clear_target()
		return
	
	# Hedeften uzaklaş
	# Movement direction zaten hesaplanacak

func _update_patrolling_state(delta: float) -> void:
	# Patrol movement direction zaten hesaplanacak
	pass

func _update_target_detection() -> void:
	if target and is_instance_valid(target):
		# Mevcut target hala detection range'de mi?
		var distance_to_target = entity.global_position.distance_to(target.global_position)
		if distance_to_target > detection_range * 1.5:  # Biraz tolerans
			clear_target()
		return
	
	# Yeni target ara
	var players = _find_players()
	if players.size() > 0:
		var closest_player = _get_closest_player(players)
		var closest_distance = entity.global_position.distance_to(closest_player.global_position)
		
		if closest_distance <= detection_range:
			set_target(closest_player)

func _check_flee_condition() -> void:
	if ai_state == AIState.FLEEING:
		return
	
	# Health component kontrolü
	var health_component = entity.get_component("HealthComponent") if entity else null
	if health_component:
		var health_percentage = health_component.get_health_percentage()
		
		if health_percentage < flee_health_threshold and target:
			set_state(AIState.FLEEING)
			flee_triggered.emit()

func _find_players() -> Array:
	return get_tree().get_nodes_in_group("players")

func _get_closest_player(players: Array) -> Node2D:
	if players.is_empty():
		return null
	
	var closest_player = players[0]
	var closest_distance = entity.global_position.distance_to(closest_player.global_position)
	
	for player in players:
		var distance = entity.global_position.distance_to(player.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_player = player
	
	return closest_player

# === SERIALIZATION ===

func serialize() -> Dictionary:
	var data = super.serialize()
	
	data["ai_state"] = ai_state
	data["detection_range"] = detection_range
	data["attack_range"] = attack_range
	data["chase_speed_multiplier"] = chase_speed_multiplier
	data["flee_health_threshold"] = flee_health_threshold
	data["patrol_points"] = patrol_points
	data["current_patrol_index"] = current_patrol_index
	data["patrol_speed"] = patrol_speed
	
	if target and is_instance_valid(target):
		data["target_id"] = target.get_instance_id()
	else:
		data["target_id"] = 0
	
	return data

func deserialize(data: Dictionary) -> void:
	super.deserialize(data)
	
	if "ai_state" in data:
		ai_state = data["ai_state"]
	if "detection_range" in data:
		detection_range = data["detection_range"]
	if "attack_range" in data:
		attack_range = data["attack_range"]
	if "chase_speed_multiplier" in data:
		chase_speed_multiplier = data["chase_speed_multiplier"]
	if "flee_health_threshold" in data:
		flee_health_threshold = data["flee_health_threshold"]
	if "patrol_points" in data:
		patrol_points = data["patrol_points"]
	if "current_patrol_index" in data:
		current_patrol_index = data["current_patrol_index"]
	if "patrol_speed" in data:
		patrol_speed = data["patrol_speed"]
	
	# Target sonra restore edilecek

# === DEBUG ===

func _to_string() -> String:
	var target_name = target.name if target and is_instance_valid(target) else "None"
	
	return "[EnemyAIComponent: %s | Target: %s | Detection: %.1f | Attack: %.1f]" % [
		get_state_name(),
		target_name,
		detection_range,
		attack_range
	]

func print_ai_info() -> void:
	print("=== Enemy AI Info ===")
	print("State: %s" % get_state_name())
	print("Target: %s" % (target.name if target and is_instance_valid(target) else "None"))
	print("Detection Range: %.1f" % detection_range)
	print("Attack Range: %.1f" % attack_range)
	print("Chase Speed Multiplier: %.1f" % chase_speed_multiplier)
	print("Flee Health Threshold: %.1f%%" % (flee_health_threshold * 100))
	
	if not patrol_points.is_empty():
		print("Patrol Points: %d" % patrol_points.size())
		print("Current Patrol Index: %d" % current_patrol_index)