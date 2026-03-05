# ✨ BUTTON EFFECTS ATOM
# Butonlar için glow ve parçacık efektleri
class_name ButtonEffectsAtom
extends Control

# === SIGNALS ===
signal effects_initialized()
signal glow_effect_triggered(button_name: String)
signal particle_effect_triggered(effect_name: String)

# === CONSTANTS ===
const VP := Vector2(720.0, 1280.0)

# === EXPORT VARIABLES ===
@export var show_glow: bool = true
@export var show_particles: bool = true
@export var animation_speed: float = 1.0
@export var glow_intensity: float = 1.0
@export var particle_count: int = 14

# === ANIMATION ===
var _time: float = 0.0
var _glow_time: float = 0.0
var _particle_time: float = 0.0

# === STATE ===
var is_initialized: bool = false
var is_active: bool = false
var button_position: Vector2 = Vector2(VP.x / 2.0, 728.0)
var button_size: Vector2 = Vector2(400, 80)

# === PARTICLE DATA ===
var _particles: Array[Dictionary] = []

# === COLORS ===
var glow_color_1 := Color(0.18, 0.72, 0.28)
var glow_color_2 := Color(0.22, 0.90, 0.40)
var particle_color := Color(0.22, 0.90, 0.40, 0.18)

# === LIFECYCLE ===

func _ready() -> void:
	_init_particles()
	is_initialized = true
	effects_initialized.emit()

func _process(delta: float) -> void:
	if not is_active:
		return
	
	_time += delta * animation_speed
	_glow_time += delta * 2.2
	_particle_time += delta * 1.4
	
	_update_particles(delta)
	queue_redraw()

# === PUBLIC API ===

func activate() -> void:
	is_active = true
	_init_particles()
	glow_effect_triggered.emit("button_glow")

func deactivate() -> void:
	is_active = false
	_particles.clear()
	queue_redraw()

func set_button_position(position: Vector2) -> void:
	button_position = position
	_init_particles()
	queue_redraw()

func set_button_size(size: Vector2) -> void:
	button_size = size
	queue_redraw()

func set_glow_colors(color1: Color, color2: Color) -> void:
	glow_color_1 = color1
	glow_color_2 = color2
	queue_redraw()

func set_particle_color(color: Color) -> void:
	particle_color = color
	queue_redraw()

func trigger_glow_pulse() -> void:
	_glow_time = 0.0
	glow_effect_triggered.emit("glow_pulse")

func trigger_particle_burst(count: int = 8) -> void:
	for i in count:
		var angle = randf() * TAU
		var speed = randf_range(1.0, 2.0)
		var radius = randf_range(30.0, 80.0)
		
		_particles.append({
			"angle": angle,
			"speed": speed,
			"radius": radius,
			"size": randf_range(1.5, 3.0),
			"alpha": randf_range(0.2, 0.4),
			"life": 1.0,
			"max_life": randf_range(0.8, 1.5),
			"position": button_position
		})
	
	particle_effect_triggered.emit("particle_burst")

func get_effect_status() -> Dictionary:
	return {
		"active": is_active,
		"particle_count": _particles.size(),
		"glow_intensity": glow_intensity,
		"animation_speed": animation_speed
	}

# === PRIVATE METHODS ===

func _init_particles() -> void:
	if not show_particles:
		return
	
	_particles.clear()
	
	for i in particle_count:
		var angle = _time * 1.4 + float(i) * TAU / particle_count
		var radius_x = button_size.x * 0.6
		var radius_y = button_size.y * 0.3
		
		_particles.append({
			"angle": angle,
			"speed": randf_range(0.8, 1.2),
			"radius_x": radius_x,
			"radius_y": radius_y,
			"size": randf_range(1.8, 3.2),
			"alpha": randf_range(0.12, 0.25),
			"life": 1.0,
			"max_life": 999.0, # Sürekli dönen parçacıklar
			"position": button_position
		})

func _update_particles(delta: float) -> void:
	if not show_particles:
		return
	
	# Sürekli dönen parçacıkları güncelle
	for i in range(_particles.size()):
		var p = _particles[i]
		
		# Yaşam süresi kontrolü
		if p.get("max_life", 999.0) < 999.0:
			p["life"] = float(p["life"]) - delta / float(p["max_life"])
			if float(p["life"]) <= 0:
				_particles.remove_at(i)
				continue
		
		# Açıyı güncelle
		p["angle"] = float(p["angle"]) + float(p["speed"]) * delta * animation_speed

func _draw() -> void:
	if not is_active:
		return
	
	var glow_pulse := sin(_glow_time) * 0.5 + 0.5
	
	# Glow efektleri
	if show_glow:
		# Arkaya geniş yumuşak halo
		for i in 5:
			var br := (4 - i) * 30.0 + 22.0 + glow_pulse * 15.0
			var ba := float(i + 1) / 5.0 * 0.048 * glow_intensity
			draw_circle(button_position, br * 3.8, Color(glow_color_1.r, glow_color_1.g, glow_color_1.b, ba))
		
		# Daha yoğun iç glow
		for i in 3:
			var br := (2 - i) * 20.0 + 15.0 + glow_pulse * 10.0
			var ba := float(i + 1) / 3.0 * 0.08 * glow_intensity
			draw_circle(button_position, br * 2.5, Color(glow_color_2.r, glow_color_2.g, glow_color_2.b, ba))
	
	# Parçacık efektleri
	if show_particles and not _particles.is_empty():
		for p in _particles:
			var angle = float(p["angle"])
			var radius_x = float(p.get("radius_x", button_size.x * 0.6))
			var radius_y = float(p.get("radius_y", button_size.y * 0.3))
			var size = float(p["size"])
			var alpha = float(p["alpha"]) * float(p.get("life", 1.0))
			
			# Oval yörünge
			var pos_x = button_position.x + cos(angle) * radius_x
			var pos_y = button_position.y + sin(angle) * radius_y * 0.5
			var pos = Vector2(pos_x, pos_y)
			
			# Parçacık rengi
			var color = Color(particle_color.r, particle_color.g, particle_color.b, alpha)
			
			# Parçacığı çiz
			draw_circle(pos, size, color)
			
			# Küçük kuyruk efekti
			var tail_length = size * 1.5
			var tail_angle = angle - 0.2
			var tail_pos = Vector2(
				pos_x + cos(tail_angle) * tail_length,
				pos_y + sin(tail_angle) * tail_length * 0.5
			)
			draw_line(pos, tail_pos, Color(color.r, color.g, color.b, alpha * 0.3), 1.0)
	
	# Buton sınır glow'u
	if show_glow:
		var border_glow = glow_pulse * 0.3 + 0.2
		draw_rect(
			Rect2(button_position - button_size / 2, button_size),
			Color(glow_color_2.r, glow_color_2.g, glow_color_2.b, border_glow * 0.1),
			false,
			3.0
		)

# === DEBUG ===

func print_debug_info() -> void:
	print("=== ButtonEffectsAtom ===")
	print("Initialized: %s" % str(is_initialized))
	print("Active: %s" % str(is_active))
	print("Show Glow: %s" % str(show_glow))
	print("Show Particles: %s" % str(show_particles))
	print("Animation Speed: %.2f" % animation_speed)
	print("Glow Intensity: %.2f" % glow_intensity)
	print("Particle Count: %d" % _particles.size())
	print("Button Position: %s" % str(button_position))
	print("Button Size: %s" % str(button_size))