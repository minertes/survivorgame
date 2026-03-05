# 🌌 SPACE BACKGROUND ATOM
# Uzay arka planı ve partikül efektleri için atomic bileşen
class_name SpaceBackgroundAtom
extends Control

# === SIGNALS ===
signal background_initialized()
signal particle_effect_triggered(effect_name: String)

# === CONSTANTS ===
const VP := Vector2(720.0, 1280.0)

# === PARTICLE SYSTEMS ===
var _stars: Array[Dictionary] = []
var _sparks: Array[Dictionary] = []
var _nebula: Array[Dictionary] = []

# === ANIMATION ===
var _time: float = 0.0
var _scan_y: float = 0.0

# === SETTINGS ===
var star_count: int = 110
var spark_count: int = 22
var nebula_count: int = 4
var animation_speed: float = 1.0

# === STATE ===
var is_initialized: bool = false

# === LIFECYCLE ===

func _ready() -> void:
	_init_particles()
	_scan_y = randf() * VP.y
	is_initialized = true
	background_initialized.emit()

func _process(delta: float) -> void:
	_time += delta * animation_speed
	_update_particles(delta)
	_scan_y += delta * 175.0
	if _scan_y > VP.y + 50.0:
		_scan_y = -50.0
	queue_redraw()

# === PUBLIC API ===

func initialize(star_cnt: int = 110, spark_cnt: int = 22, nebula_cnt: int = 4) -> void:
	star_count = star_cnt
	spark_count = spark_cnt
	nebula_count = nebula_cnt
	_init_particles()

func set_animation_speed(speed: float) -> void:
	animation_speed = speed

func trigger_star_burst(count: int = 20) -> void:
	for i in count:
		_stars.append(_create_star_particle())
	particle_effect_triggered.emit("star_burst")

func trigger_spark_ring(center: Vector2, radius: float = 100.0) -> void:
	for i in 8:
		var angle = i * TAU / 8.0
		var spark = {
			"cx": center.x,
			"cy": center.y,
			"angle": angle,
			"speed": randf_range(0.8, 1.5),
			"r": radius,
			"size": randf_range(2.0, 4.0),
			"alpha": randf_range(0.2, 0.5),
			"color": Color(0.2, 0.7, 1.0),
			"pos": Vector2(center.x + cos(angle) * radius, center.y + sin(angle) * radius * 0.38)
		}
		_sparks.append(spark)
	particle_effect_triggered.emit("spark_ring")

func get_particle_counts() -> Dictionary:
	return {
		"stars": _stars.size(),
		"sparks": _sparks.size(),
		"nebula": _nebula.size()
	}

# === PRIVATE METHODS ===

func _init_particles() -> void:
	_stars.clear()
	_sparks.clear()
	_nebula.clear()
	
	var star_colors := [
		Color(0.45, 0.72, 1.0),
		Color(0.72, 0.42, 1.0),
		Color(1.0,  0.87, 0.35),
		Color(1.0,  1.0,  1.0),
		Color(0.35, 1.0,  0.72),
	]
	
	for _i in star_count:
		_stars.append(_create_star_particle(star_colors))
	
	var spark_colors := [Color(0.2, 0.7, 1.0), Color(0.7, 0.3, 1.0), Color(0.2, 1.0, 0.6)]
	for _i in spark_count:
		var scx := randf() * VP.x
		var scy := randf_range(320.0, 880.0)
		_sparks.append({
			"cx":    scx,
			"cy":    scy,
			"angle": randf() * TAU,
			"speed": randf_range(0.4, 1.1),
			"r":     randf_range(45.0, 110.0),
			"size":  randf_range(2.0, 5.0),
			"alpha": randf_range(0.12, 0.42),
			"color": spark_colors[randi() % spark_colors.size()],
			"pos":   Vector2(scx, scy),
		})
	
	var ncols := [
		Color(0.14, 0.04, 0.48, 0.08),
		Color(0.48, 0.04, 0.14, 0.07),
		Color(0.04, 0.20, 0.48, 0.07),
		Color(0.32, 0.06, 0.42, 0.055),
	]
	
	for i in nebula_count:
		_nebula.append({
			"pos":    Vector2(randf() * VP.x, randf() * VP.y),
			"vel":    Vector2(randf_range(-3.5, 3.5), randf_range(-3.5, 3.5)),
			"radius": randf_range(170.0, 310.0),
			"phase":  randf() * TAU,
			"color":  ncols[i],
		})

func _create_star_particle(colors: Array = []) -> Dictionary:
	if colors.is_empty():
		colors = [Color(1.0, 1.0, 1.0)]
	
	return {
		"pos":   Vector2(randf() * VP.x, randf() * VP.y),
		"vel":   Vector2(randf_range(-7.0, 7.0), randf_range(-30.0, -5.0)),
		"size":  randf_range(0.7, 3.4),
		"alpha": randf_range(0.25, 1.0),
		"phase": randf() * TAU,
		"color": colors[randi() % colors.size()],
	}

func _update_particles(delta: float) -> void:
	# Yıldızları güncelle
	for s in _stars:
		var p := s["pos"] as Vector2
		p.x += (s["vel"] as Vector2).x * delta
		p.y += (s["vel"] as Vector2).y * delta
		s["phase"] = float(s["phase"]) + delta * (1.1 + float(s["size"]) * 0.4)
		if p.y < -6.0:
			p.y = VP.y + 6.0
			p.x = randf() * VP.x
		if p.x < -6.0:    p.x = VP.x + 6.0
		elif p.x > VP.x + 6.0: p.x = -6.0
		s["pos"] = p
	
	# Kıvılcımları güncelle
	for sp in _sparks:
		sp["angle"] = float(sp["angle"]) + float(sp["speed"]) * delta
		var ang := float(sp["angle"])
		var r   := float(sp["r"])
		sp["pos"] = Vector2(
			float(sp["cx"]) + cos(ang) * r,
			float(sp["cy"]) + sin(ang) * r * 0.38
		)
	
	# Nebulaları güncelle
	for n in _nebula:
		n["phase"] = float(n["phase"]) + delta * 0.18
		var np := n["pos"] as Vector2
		np += (n["vel"] as Vector2) * delta
		if np.x < -320.0:         np.x = VP.x + 320.0
		elif np.x > VP.x + 320.0: np.x = -320.0
		if np.y < -320.0:         np.y = VP.y + 320.0
		elif np.y > VP.y + 320.0: np.y = -320.0
		n["pos"] = np

func _draw() -> void:
	# Koyu uzay arka planı
	draw_rect(Rect2(Vector2.ZERO, VP), Color(0.04, 0.02, 0.10))
	
	# Nebula lekeleri
	for n in _nebula:
		var np  := n["pos"] as Vector2
		var nr  := float(n["radius"])
		var nc  := n["color"] as Color
		var pls := sin(float(n["phase"])) * 0.3 + 0.7
		for ring in 5:
			var rr := nr * (1.0 - float(ring) * 0.18)
			var ra := nc.a * float(ring + 1) / 5.0 * pls
			draw_circle(np, rr, Color(nc.r, nc.g, nc.b, ra))
	
	# Izgara deseni
	for gx in range(0, int(VP.x) + 1, 60):
		draw_line(Vector2(gx, 0), Vector2(gx, VP.y), Color(0.25, 0.35, 0.75, 0.018), 1.0)
	for gy in range(0, int(VP.y) + 1, 60):
		draw_line(Vector2(0, gy), Vector2(VP.x, gy), Color(0.25, 0.35, 0.75, 0.018), 1.0)
	
	# Yıldızlar
	for s in _stars:
		var twinkle := (sin(float(s["phase"])) * 0.4 + 0.6) * float(s["alpha"])
		var c  := s["color"] as Color
		var r  := float(s["size"])
		var sp := s["pos"] as Vector2
		if r > 2.2:
			draw_line(sp - Vector2(r * 2.8, 0), sp + Vector2(r * 2.8, 0),
				Color(c.r, c.g, c.b, twinkle * 0.35), 1.0)
			draw_line(sp - Vector2(0, r * 2.8), sp + Vector2(0, r * 2.8),
				Color(c.r, c.g, c.b, twinkle * 0.35), 1.0)
		draw_circle(sp, r, Color(c.r, c.g, c.b, twinkle))
	
	# Enerji kıvılcımları
	for sp in _sparks:
		var spos := sp["pos"] as Vector2
		var sc   := sp["color"] as Color
		var sa   := float(sp["alpha"])
		var ss   := float(sp["size"])
		draw_circle(spos, ss,       Color(sc.r, sc.g, sc.b, sa))
		draw_circle(spos, ss * 2.2, Color(sc.r, sc.g, sc.b, sa * 0.18))
	
	# Tarama çizgisi
	draw_rect(Rect2(0, _scan_y - 1.5, VP.x, 4.0), Color(0.42, 0.72, 1.0, 0.055))
	draw_rect(Rect2(0, _scan_y,       VP.x, 1.5), Color(0.65, 0.88, 1.0, 0.08))
	
	# Köşe karartmaları
	for i in 10:
		var a := float(i) / 10.0 * 0.3
		var m := float(i) * 24.0
		draw_rect(Rect2(0,        0, m,  VP.y), Color(0, 0, 0, a * 0.5))
		draw_rect(Rect2(VP.x - m, 0, m,  VP.y), Color(0, 0, 0, a * 0.5))
	draw_rect(Rect2(0, VP.y - 220.0, VP.x, 220.0), Color(0, 0, 0, 0.45))
	
	# Tarama çizgisi overlay
	for i in range(0, int(VP.y), 4):
		draw_line(Vector2(0, i), Vector2(VP.x, i), Color(0, 0, 0, 0.02), 1.0)

# === DEBUG ===
func print_debug_info() -> void:
	print("=== SpaceBackgroundAtom ===")
	print("Initialized: %s" % str(is_initialized))
	print("Star Count: %d" % _stars.size())
	print("Spark Count: %d" % _sparks.size())
	print("Nebula Count: %d" % _nebula.size())
	print("Animation Speed: %.2f" % animation_speed)