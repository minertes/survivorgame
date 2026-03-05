# ❤️ HEALTH COMPONENT
# Can yönetimi için atomic component
class_name HealthComponent
extends Component

# === CONFIGURATION ===
var max_health: float = 100.0
var current_health: float = 100.0
var is_invincible: bool = false
var invincibility_duration: float = 0.0
var invincibility_timer: float = 0.0

# Regeneration
var health_regeneration: float = 0.0  # health per second
var regeneration_timer: float = 0.0
var regeneration_interval: float = 1.0

# === SIGNALS ===
signal health_changed(old_value: float, new_value: float)
signal health_healed(amount: float)
signal health_damaged(amount: float, source: Node)
signal died(killer: Node)
signal invincibility_started(duration: float)
signal invincibility_ended()

# === LIFECYCLE ===

func _initialize() -> void:
	current_health = max_health
	set_process(true)

func update(delta: float) -> void:
	_update_invincibility(delta)
	_update_regeneration(delta)

# === PUBLIC API ===

func take_damage(amount: float, source: Node = null) -> void:
	if is_invincible or current_health <= 0:
		return
	
	var old_health = current_health
	current_health = max(0.0, current_health - amount)
	
	health_changed.emit(old_health, current_health)
	health_damaged.emit(amount, source)
	
	if current_health <= 0:
		die(source)

func heal(amount: float) -> void:
	if current_health <= 0:
		return
	
	var old_health = current_health
	current_health = min(max_health, current_health + amount)
	
	health_changed.emit(old_health, current_health)
	health_healed.emit(amount)

func die(killer: Node = null) -> void:
	current_health = 0.0
	died.emit(killer)

func resurrect(health_percentage: float = 1.0) -> void:
	current_health = max_health * health_percentage
	health_changed.emit(0.0, current_health)

func set_invincible(duration: float) -> void:
	is_invincible = true
	invincibility_duration = duration
	invincibility_timer = 0.0
	invincibility_started.emit(duration)

func set_max_health(new_max: float, fill_health: bool = true) -> void:
	var percentage = current_health / max_health if max_health > 0 else 1.0
	max_health = new_max
	
	if fill_health:
		current_health = max_health
	else:
		current_health = max_health * percentage
	
	health_changed.emit(current_health, current_health)

func get_health_percentage() -> float:
	return current_health / max_health if max_health > 0 else 0.0

func is_alive() -> bool:
	return current_health > 0

func is_dead() -> bool:
	return current_health <= 0

# === PRIVATE METHODS ===

func _update_invincibility(delta: float) -> void:
	if not is_invincible:
		return
	
	invincibility_timer += delta
	if invincibility_timer >= invincibility_duration:
		is_invincible = false
		invincibility_duration = 0.0
		invincibility_timer = 0.0
		invincibility_ended.emit()

func _update_regeneration(delta: float) -> void:
	if health_regeneration <= 0 or current_health <= 0 or current_health >= max_health:
		return
	
	regeneration_timer += delta
	if regeneration_timer >= regeneration_interval:
		heal(health_regeneration * regeneration_interval)
		regeneration_timer = 0.0

# === SERIALIZATION ===

func serialize() -> Dictionary:
	var data = super.serialize()
	data["max_health"] = max_health
	data["current_health"] = current_health
	data["is_invincible"] = is_invincible
	data["invincibility_timer"] = invincibility_timer
	data["invincibility_duration"] = invincibility_duration
	data["health_regeneration"] = health_regeneration
	return data

func deserialize(data: Dictionary) -> void:
	super.deserialize(data)
	
	if "max_health" in data:
		max_health = data["max_health"]
	if "current_health" in data:
		current_health = data["current_health"]
	if "is_invincible" in data:
		is_invincible = data["is_invincible"]
	if "invincibility_timer" in data:
		invincibility_timer = data["invincibility_timer"]
	if "invincibility_duration" in data:
		invincibility_duration = data["invincibility_duration"]
	if "health_regeneration" in data:
		health_regeneration = data["health_regeneration"]

# === DEBUG ===

func _to_string() -> String:
	return "[HealthComponent: %.1f/%.1f (%.1f%%)]" % [
		current_health, 
		max_health, 
		get_health_percentage() * 100
	]