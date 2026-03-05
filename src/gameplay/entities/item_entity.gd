# 🎁 ITEM ENTITY
# Toplanabilir item'lar için entity sınıfı
class_name ItemEntity
extends Entity

# === ITEM PROPERTIES ===
var item_id: String = ""
var item_count: int = 1
var item_data: Dictionary = {}
var rarity: String = "common"
var is_collectible: bool = true
var auto_pickup_range: float = 50.0
var pickup_delay: float = 0.5  # Spawn'dan sonra pickup için bekleme süresi
var spawn_time: float = 0.0

# === VISUAL EFFECTS ===
var glow_effect: Node2D = null
var particle_effect: GPUParticles2D = null
var bob_speed: float = 2.0
var bob_height: float = 5.0
var rotation_speed: float = 45.0
var base_y: float = 0.0

# === COLLISION ===
var pickup_area: Area2D = null
var collision_shape: CollisionShape2D = null

# === SIGNALS ===
signal item_ready_for_pickup
signal item_picked_up(picker: Node, item_id: String, count: int)
signal item_despawned

# === RARITY COLORS ===
const RARITY_COLORS = {
	"common": Color(0.8, 0.8, 0.8, 1.0),      # Light Gray
	"uncommon": Color(0.2, 0.8, 0.2, 1.0),    # Green
	"rare": Color(0.2, 0.4, 1.0, 1.0),        # Blue
	"epic": Color(0.8, 0.2, 0.8, 1.0),        # Purple
	"legendary": Color(1.0, 0.5, 0.0, 1.0)    # Orange
}

# === LIFECYCLE ===

func _initialize_entity() -> void:
	entity_type = "item"
	_setup_visuals()
	_setup_collision()
	_setup_physics()
	
	spawn_time = Time.get_ticks_msec() / 1000.0
	base_y = position.y
	
	print("ItemEntity spawned: %s x%d" % [item_id, item_count])

func _setup_visuals() -> void:
	# Sprite oluştur
	var sprite = Sprite2D.new()
	sprite.texture = _get_item_texture()
	sprite.centered = true
	add_child(sprite)
	
	# Rarity'ye göre glow effect
	_create_glow_effect()
	
	# Particle effect
	_create_particle_effect()

func _setup_collision() -> void:
	# Pickup area oluştur
	pickup_area = Area2D.new()
	pickup_area.name = "PickupArea"
	
	# Collision shape
	collision_shape = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = 16.0
	collision_shape.shape = circle_shape
	
	pickup_area.add_child(collision_shape)
	add_child(pickup_area)
	
	# Connect signals
	pickup_area.body_entered.connect(_on_body_entered)
	pickup_area.area_entered.connect(_on_area_entered)

func _setup_physics() -> void:
	# Hafif fizik etkileşimi
	set_collision_layer_value(1, false)  # World layer
	set_collision_layer_value(3, true)   # Item layer
	set_collision_mask_value(2, true)    # Player layer

# === PUBLIC API ===

func initialize(item_config_id: String, count: int = 1, spawn_position: Vector2 = Vector2.ZERO) -> void:
	item_id = item_config_id
	item_count = count
	
	# Config'den item data'yı al
	var config_manager = ConfigManager.get_instance()
	if config_manager:
		item_data = config_manager.get_item_config(item_id)
		entity_name = item_data.get("name", "Unknown Item")
		rarity = item_data.get("rarity", "common")
	
	# Position ayarla
	if spawn_position != Vector2.ZERO:
		position = spawn_position
	
	# Visual'ları güncelle
	_update_visuals()

func set_item_data(data: Dictionary) -> void:
	item_data = data
	item_id = data.get("id", "")
	entity_name = data.get("name", "Unknown Item")
	rarity = data.get("rarity", "common")
	
	_update_visuals()

func get_item_info() -> Dictionary:
	return {
		"id": item_id,
		"name": entity_name,
		"count": item_count,
		"rarity": rarity,
		"type": item_data.get("type", ""),
		"data": item_data
	}

func can_be_picked_up() -> bool:
	if not is_collectible:
		return false
	
	# Pickup delay kontrolü
	var current_time = Time.get_ticks_msec() / 1000.0
	return (current_time - spawn_time) >= pickup_delay

func pickup(picker: Node) -> bool:
	if not can_be_picked_up():
		return false
	
	# Event emit et
	EventBus.emit_now_static(EventBus.ITEM_PICKED_UP, {
		"picker": picker,
		"item_id": item_id,
		"item_count": item_count,
		"item_data": item_data,
		"item_entity": self
	})
	
	# Signal emit et
	item_picked_up.emit(picker, item_id, item_count)
	
	# Pickup sound'u çal
	_play_pickup_sound()
	
	# Visual effect
	_create_pickup_effect()
	
	# Destroy entity
	call_deferred("destroy")
	
	return true

func despawn() -> void:
	# Fade out effect
	_create_despawn_effect()
	
	# Signal emit et
	item_despawned.emit()
	
	# Destroy after effect
	await get_tree().create_timer(0.5).timeout
	destroy()

# === UPDATE LOOP ===

func update(delta: float) -> void:
	# Floating animation
	_animate_floating(delta)
	
	# Rotation animation
	_animate_rotation(delta)
	
	# Auto-pickup check
	_check_auto_pickup()

func _animate_floating(delta: float) -> void:
	var time = Time.get_ticks_msec() / 1000.0
	var offset = sin(time * bob_speed) * bob_height
	position.y = base_y + offset

func _animate_rotation(delta: float) -> void:
	rotation_degrees += rotation_speed * delta
	if rotation_degrees >= 360:
		rotation_degrees -= 360

func _check_auto_pickup() -> void:
	if not can_be_picked_up():
		return
	
	# Player'ı ara
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	
	var player = players[0]
	var distance = position.distance_to(player.position)
	
	if distance <= auto_pickup_range:
		pickup(player)

# === COLLISION HANDLING ===

func _on_body_entered(body: Node) -> void:
	if not can_be_picked_up():
		return
	
	if body.is_in_group("player"):
		pickup(body)

func _on_area_entered(area: Area2D) -> void:
	if not can_be_picked_up():
		return
	
	# Player'ın pickup area'sı
	if area.get_parent() and area.get_parent().is_in_group("player"):
		pickup(area.get_parent())

# === VISUAL EFFECTS ===

func _create_glow_effect() -> void:
	if glow_effect:
		glow_effect.queue_free()
	
	glow_effect = Sprite2D.new()
	# Basit bir daire texture'ı oluştur
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color(1, 1, 1, 1))
	
	# Daire çiz
	var center = Vector2(32, 32)
	for x in range(64):
		for y in range(64):
			var distance = center.distance_to(Vector2(x, y))
			if distance <= 32:
				var alpha = 1.0 - (distance / 32.0)
				image.set_pixel(x, y, Color(1, 1, 1, alpha))
	
	var texture = ImageTexture.create_from_image(image)
	glow_effect.texture = texture
	glow_effect.centered = true
	glow_effect.modulate = RARITY_COLORS.get(rarity, Color.WHITE)
	glow_effect.modulate.a = 0.3
	glow_effect.scale = Vector2(1.5, 1.5)
	
	add_child(glow_effect)
	glow_effect.z_index = -1

func _create_particle_effect() -> void:
	if particle_effect:
		particle_effect.queue_free()
	
	particle_effect = GPUParticles2D.new()
	particle_effect.amount = 8
	particle_effect.lifetime = 2.0
	particle_effect.explosiveness = 0.0
	particle_effect.emission_shape = GPUParticles2D.EMISSION_SHAPE_SPHERE
	particle_effect.emission_sphere_radius = 20.0
	particle_effect.gravity = Vector2(0, 20)
	particle_effect.initial_velocity = 10.0
	particle_effect.initial_velocity_random = 0.5
	
	var material = ParticlesMaterial.new()
	material.gravity = Vector3(0, 20, 0)
	material.spread = 45.0
	material.flatness = 1.0
	particle_effect.process_material = material
	
	particle_effect.modulate = RARITY_COLORS.get(rarity, Color.WHITE)
	
	add_child(particle_effect)

func _create_pickup_effect() -> void:
	# Pickup particle effect
	var pickup_particles = GPUParticles2D.new()
	pickup_particles.amount = 16
	pickup_particles.lifetime = 0.5
	pickup_particles.explosiveness = 1.0
	pickup_particles.one_shot = true
	
	var material = ParticlesMaterial.new()
	material.gravity = Vector3(0, -100, 0)
	material.spread = 360.0
	pickup_particles.process_material = material
	
	pickup_particles.modulate = RARITY_COLORS.get(rarity, Color.WHITE)
	
	add_child(pickup_particles)
	pickup_particles.emitting = true

func _create_despawn_effect() -> void:
	# Fade out animation
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)

func _update_visuals() -> void:
	# Sprite'ı güncelle
	var sprite = get_node_or_null("Sprite2D")
	if sprite:
		sprite.texture = _get_item_texture()
	
	# Glow rengini güncelle
	if glow_effect:
		glow_effect.modulate = RARITY_COLORS.get(rarity, Color.WHITE)
	
	# Particle rengini güncelle
	if particle_effect:
		particle_effect.modulate = RARITY_COLORS.get(rarity, Color.WHITE)

func _get_item_texture() -> Texture2D:
	# Basit bir kare texture oluştur
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	
	# Rarity'ye göre renk
	var color = RARITY_COLORS.get(rarity, Color(0.8, 0.8, 0.8))
	image.fill(color)
	
	# Kenarları daha koyu yap
	for x in range(32):
		for y in range(32):
			if x < 2 or x >= 30 or y < 2 or y >= 30:
				image.set_pixel(x, y, color.darkened(0.5))
			elif (x == 15 and y == 15) or (x == 16 and y == 16):
				# Ortada parlak nokta
				image.set_pixel(x, y, color.lightened(0.3))
	
	var texture = ImageTexture.create_from_image(image)
	return texture

func _play_pickup_sound() -> void:
	var sound_name = item_data.get("sound", "item_pickup")
	EventBus.emit_now_static(EventBus.PLAY_SOUND, {
		"sound_name": sound_name,
		"position": position
	})

# === SERIALIZATION ===

func serialize() -> Dictionary:
	var data = super.serialize()
	
	data["item_id"] = item_id
	data["item_count"] = item_count
	data["item_data"] = item_data
	data["rarity"] = rarity
	data["is_collectible"] = is_collectible
	data["spawn_time"] = spawn_time
	
	return data

func deserialize(data: Dictionary) -> void:
	super.deserialize(data)
	
	if "item_id" in data:
		item_id = data["item_id"]
	if "item_count" in data:
		item_count = data["item_count"]
	if "item_data" in data:
		item_data = data["item_data"]
	if "rarity" in data:
		rarity = data["rarity"]
	if "is_collectible" in data:
		is_collectible = data["is_collectible"]
	if "spawn_time" in data:
		spawn_time = data["spawn_time"]
	
	_update_visuals()

# === DEBUG ===

func _to_string() -> String:
	return "[ItemEntity: %s x%d (%s)]" % [
		entity_name,
		item_count,
		rarity
	]

func print_debug_info() -> void:
	print("=== Item Debug: %s ===" % entity_name)
	print("ID: %s" % item_id)
	print("Count: %d" % item_count)
	print("Rarity: %s" % rarity)
	print("Type: %s" % item_data.get("type", "unknown"))
	print("Collectible: %s" % str(is_collectible))
	print("Position: %s" % str(position))