extends CharacterBody2D

const XP_GEM_SCENE      = preload("res://xp_gem.tscn")
const HIT_EFFECT_SCRIPT = preload("res://hit_effect.gd")

var max_health := 50.0
var health := 50.0
var speed := 100.0
var damage_per_second := 15.0
var xp_value := 5

# 0=Zombi  1=Koşucu  2=Dev  3=İblis
var enemy_type := 0

var player_ref: Node2D = null


func _ready() -> void:
	add_to_group("enemies")
	await get_tree().process_frame
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]


func _physics_process(delta: float) -> void:
	if not player_ref or not is_instance_valid(player_ref):
		return
	var dir := (player_ref.global_position - global_position).normalized()
	velocity = dir * speed
	move_and_slide()

	var hit_radius := _get_radius() + 20.0
	if global_position.distance_to(player_ref.global_position) < hit_radius:
		player_ref.take_damage(damage_per_second * delta)


func take_damage(amount: float) -> void:
	health = maxf(0.0, health - amount)
	queue_redraw()
	_spawn_hit_effect()
	if health <= 0.0:
		_die()


func _spawn_hit_effect() -> void:
	# Hafif efekt — sadece küçük bir daire, lag yapmaz
	var fx := Node2D.new()
	fx.set_script(HIT_EFFECT_SCRIPT)
	fx.global_position = global_position + Vector2(randf_range(-6, 6), randf_range(-6, 6))
	get_parent().add_child(fx)
	var hit_color := Color(1.0, 0.3, 0.1)
	match enemy_type:
		1: hit_color = Color(1.0, 0.6, 0.1)
		2: hit_color = Color(0.9, 0.1, 0.1)
		3: hit_color = Color(0.8, 0.2, 1.0)
	fx.setup(hit_color, _get_radius() * 0.8)


func _die() -> void:
	if player_ref and is_instance_valid(player_ref) and player_ref.life_steal > 0.0:
		player_ref.health = minf(player_ref.max_health, player_ref.health + player_ref.life_steal)
		player_ref.health_changed.emit(player_ref.health, player_ref.max_health)
		player_ref.queue_redraw()

	SoundManager.play_enemy_die()

	var gem := XP_GEM_SCENE.instantiate()
	gem.global_position = global_position
	gem.xp_value = xp_value
	get_parent().add_child(gem)
	queue_free()


func _get_radius() -> float:
	match enemy_type:
		1: return 13.0
		2: return 26.0
		_: return 18.0


func _draw_ell(cx: float, cy: float, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 20:
		var a := i * TAU / 20.0
		pts.append(Vector2(cx + cos(a) * rx, cy + sin(a) * ry))
	draw_colored_polygon(pts, col)


func _draw() -> void:
	var r := _get_radius()

	match enemy_type:
		0: _draw_ant(r)
		1: _draw_spider(r)
		2: _draw_beetle(r)
		3: _draw_mantis(r)

	# Can barı
	var bw := r * 2.4
	var bx := -bw / 2.0
	var by := -r - 13.0
	draw_rect(Rect2(bx, by, bw, 5.0), Color(0.40, 0.00, 0.00))
	draw_rect(Rect2(bx, by, bw * (health / max_health), 5.0), Color(0.10, 0.90, 0.10))


# ── Karınca ────────────────────────────────────────────────────
func _draw_ant(r: float) -> void:
	var bc  := Color(0.42, 0.18, 0.06)
	var drk := Color(0.26, 0.10, 0.03)

	_draw_ell(0, r * 0.7, r, r * 0.28, Color(0, 0, 0, 0.25))

	# 6 bacak
	for i in 3:
		var ly := (float(i) - 1.0) * (r * 0.45)
		var lx := r * 0.40
		var le := r * 0.88
		draw_line(Vector2(-lx, ly), Vector2(-le, ly - r * 0.22), drk, 2.0)
		draw_line(Vector2(-le, ly - r * 0.22), Vector2(-le - 4, ly + r * 0.22), drk, 1.5)
		draw_line(Vector2(lx, ly), Vector2(le, ly - r * 0.22), drk, 2.0)
		draw_line(Vector2(le, ly - r * 0.22), Vector2(le + 4, ly + r * 0.22), drk, 1.5)

	# Abdomen
	_draw_ell(0, r * 0.28, r * 0.65, r * 0.52, bc)
	_draw_ell(0, r * 0.26, r * 0.50, r * 0.38, Color(bc.r + 0.07, bc.g + 0.04, bc.b))
	# Thorax
	draw_circle(Vector2(0, -r * 0.10), r * 0.32, bc)
	# Baş
	draw_circle(Vector2(0, -r * 0.52), r * 0.34, bc)
	draw_circle(Vector2(0, -r * 0.52), r * 0.22, Color(bc.r + 0.07, bc.g + 0.04, bc.b))
	# Gözler
	draw_circle(Vector2(-r * 0.18, -r * 0.62), r * 0.10, Color(0.85, 0.30, 0.0))
	draw_circle(Vector2( r * 0.18, -r * 0.62), r * 0.10, Color(0.85, 0.30, 0.0))
	draw_circle(Vector2(-r * 0.18, -r * 0.62), r * 0.05, Color(0.05, 0.0, 0.0))
	draw_circle(Vector2( r * 0.18, -r * 0.62), r * 0.05, Color(0.05, 0.0, 0.0))
	# Anten
	draw_line(Vector2(-r * 0.12, -r * 0.82), Vector2(-r * 0.42, -r * 1.38), drk, 1.5)
	draw_line(Vector2( r * 0.12, -r * 0.82), Vector2( r * 0.42, -r * 1.38), drk, 1.5)
	draw_circle(Vector2(-r * 0.44, -r * 1.40), r * 0.08, drk)
	draw_circle(Vector2( r * 0.44, -r * 1.40), r * 0.08, drk)


# ── Örümcek ────────────────────────────────────────────────────
func _draw_spider(r: float) -> void:
	var bc  := Color(0.85, 0.42, 0.05)
	var drk := Color(0.50, 0.22, 0.02)

	_draw_ell(0, r * 0.6, r * 0.9, r * 0.22, Color(0, 0, 0, 0.25))

	# 8 bacak (4 çift)
	for i in 4:
		var base_ang := (float(i) / 4.0) * PI * 0.85 + PI * 0.08
		for s in [-1, 1]:
			var sf   := float(s)
			var kx   := sf * cos(base_ang) * r * 1.10
			var ky   :=      sin(base_ang) * r * 0.70 - r * 0.05
			var fx2  := sf * cos(base_ang) * r * 1.85
			var fy2  :=      sin(base_ang) * r * 1.05 + r * 0.15
			draw_line(Vector2(sf * r * 0.30, -r * 0.12 + float(i - 1.5) * r * 0.22), Vector2(kx, ky), drk, 1.8)
			draw_line(Vector2(kx, ky), Vector2(fx2, fy2), drk, 1.4)

	# Abdomen
	_draw_ell(0, r * 0.20, r * 0.65, r * 0.55, bc)
	draw_rect(Rect2(-r * 0.14, -r * 0.08, r * 0.28, r * 0.10), Color(0.95, 0.60, 0.0, 0.70))
	draw_rect(Rect2(-r * 0.10,  r * 0.06, r * 0.20, r * 0.08), Color(0.95, 0.60, 0.0, 0.55))
	# Cephalothorax
	draw_circle(Vector2(0, -r * 0.48), r * 0.36, bc)
	draw_circle(Vector2(0, -r * 0.48), r * 0.22, Color(bc.r + 0.05, bc.g + 0.03, bc.b))
	# 8 göz
	for i in 4:
		var ex := (float(i) - 1.5) * r * 0.18
		draw_circle(Vector2(ex, -r * 0.58), r * 0.07, Color(0.1, 0.9, 0.1))
		draw_circle(Vector2(ex, -r * 0.58), r * 0.035, Color(0, 0, 0))
	# Chelicerae
	draw_line(Vector2(-r * 0.10, -r * 0.76), Vector2(-r * 0.22, -r * 0.94), drk, 2.0)
	draw_line(Vector2( r * 0.10, -r * 0.76), Vector2( r * 0.22, -r * 0.94), drk, 2.0)
	draw_circle(Vector2(-r * 0.23, -r * 0.95), r * 0.08, drk)
	draw_circle(Vector2( r * 0.23, -r * 0.95), r * 0.08, drk)


# ── Zırhlı Böcek ──────────────────────────────────────────────
func _draw_beetle(r: float) -> void:
	var bc   := Color(0.35, 0.06, 0.05)
	var shel := Color(0.44, 0.09, 0.07)
	var drk  := Color(0.20, 0.03, 0.02)

	_draw_ell(0, r * 0.65, r * 1.05, r * 0.30, Color(0, 0, 0, 0.30))

	# 6 kalın bacak
	for i in 3:
		var ly := (float(i) - 1.0) * (r * 0.55)
		var lx := r * 0.58
		var le := r * 1.05
		draw_line(Vector2(-lx, ly), Vector2(-le, ly + r * 0.20), drk, 3.5)
		draw_line(Vector2(-le, ly + r * 0.20), Vector2(-le + 2, ly + r * 0.48), drk, 3.0)
		draw_line(Vector2( lx, ly), Vector2( le, ly + r * 0.20), drk, 3.5)
		draw_line(Vector2( le, ly + r * 0.20), Vector2( le - 2, ly + r * 0.48), drk, 3.0)

	# Ana kabuk
	_draw_ell(0, 0, r * 0.90, r * 0.78, shel)
	_draw_ell(0, 0, r * 0.74, r * 0.62, bc)
	# Kabuk orta çizgisi
	draw_line(Vector2(0, -r * 0.72), Vector2(0, r * 0.72), drk, 2.0)
	# Kabuk yayları
	for i in 3:
		var sr := r * (0.26 + float(i) * 0.22)
		draw_arc(Vector2(0, 0), sr, PI * 0.18, PI * 0.82, 10, Color(drk.r, drk.g, drk.b, 0.5), 1.5)
		draw_arc(Vector2(0, 0), sr, PI * 1.18, PI * 1.82, 10, Color(drk.r, drk.g, drk.b, 0.5), 1.5)

	# Baş
	draw_circle(Vector2(0, -r * 0.88), r * 0.32, bc)
	draw_circle(Vector2(0, -r * 0.88), r * 0.20, Color(bc.r + 0.05, bc.g + 0.02, bc.b))
	# Mandibles
	draw_line(Vector2(-r * 0.12, -r * 1.10), Vector2(-r * 0.32, -r * 1.30), drk, 3.0)
	draw_line(Vector2( r * 0.12, -r * 1.10), Vector2( r * 0.32, -r * 1.30), drk, 3.0)
	# Gözler
	draw_circle(Vector2(-r * 0.20, -r * 0.92), r * 0.10, Color(0.85, 0.10, 0.10))
	draw_circle(Vector2( r * 0.20, -r * 0.92), r * 0.10, Color(0.85, 0.10, 0.10))
	draw_circle(Vector2(-r * 0.20, -r * 0.92), r * 0.05, Color(0.05, 0.0, 0.0))
	draw_circle(Vector2( r * 0.20, -r * 0.92), r * 0.05, Color(0.05, 0.0, 0.0))
	# Boynuz dikenleri
	for i in 6:
		var ang := i * TAU / 6.0
		var p1  := Vector2(cos(ang), sin(ang)) * r * 0.90
		var p2  := Vector2(cos(ang), sin(ang)) * (r * 0.90 + 8.0)
		draw_line(p1, p2, drk, 3.0)


# ── Dua Böceği ────────────────────────────────────────────────
func _draw_mantis(r: float) -> void:
	var bc   := Color(0.35, 0.05, 0.58)
	var lght := Color(0.55, 0.18, 0.82)
	var drk  := Color(0.22, 0.02, 0.38)

	_draw_ell(0, r * 0.65, r * 0.72, r * 0.22, Color(0, 0, 0, 0.28))

	# Kanatlar (hafif)
	var wing_l := PackedVector2Array([
		Vector2(-r * 0.22, -r * 0.55),
		Vector2(-r * 1.12, -r * 0.18),
		Vector2(-r * 1.02,  r * 0.42),
		Vector2(-r * 0.28,  r * 0.18),
	])
	draw_colored_polygon(wing_l, Color(lght.r, lght.g, lght.b, 0.22))
	draw_polyline(wing_l, Color(lght.r, lght.g, lght.b, 0.38), 1.0)
	var wing_r := PackedVector2Array([
		Vector2( r * 0.22, -r * 0.55),
		Vector2( r * 1.12, -r * 0.18),
		Vector2( r * 1.02,  r * 0.42),
		Vector2( r * 0.28,  r * 0.18),
	])
	draw_colored_polygon(wing_r, Color(lght.r, lght.g, lght.b, 0.22))
	draw_polyline(wing_r, Color(lght.r, lght.g, lght.b, 0.38), 1.0)

	# 4 normal bacak
	for i in 2:
		var ly := float(i) * r * 0.55 + r * 0.05
		draw_line(Vector2(-r * 0.35, ly), Vector2(-r * 0.95, ly + r * 0.28), drk, 2.0)
		draw_line(Vector2(-r * 0.95, ly + r * 0.28), Vector2(-r * 1.12, ly + r * 0.58), drk, 1.5)
		draw_line(Vector2( r * 0.35, ly), Vector2( r * 0.95, ly + r * 0.28), drk, 2.0)
		draw_line(Vector2( r * 0.95, ly + r * 0.28), Vector2( r * 1.12, ly + r * 0.58), drk, 1.5)

	# Uzun abdomen
	_draw_ell(0, r * 0.32, r * 0.40, r * 0.60, bc)
	_draw_ell(0, r * 0.28, r * 0.28, r * 0.48, lght)
	for i in 4:
		var ry2 := float(i) * r * 0.28 - r * 0.30
		draw_rect(Rect2(-r * 0.28, ry2, r * 0.56, r * 0.06), Color(drk.r, drk.g, drk.b, 0.55))

	# Thorax
	draw_circle(Vector2(0, -r * 0.62), r * 0.30, bc)

	# Ön kollar (raptorial — karakteristik)
	draw_line(Vector2(-r * 0.22, -r * 0.56), Vector2(-r * 0.70, -r * 1.20), drk, 3.5)
	draw_line(Vector2(-r * 0.70, -r * 1.20), Vector2(-r * 0.30, -r * 1.50), drk, 3.0)
	draw_line(Vector2(-r * 0.30, -r * 1.50), Vector2(-r * 0.58, -r * 1.20), Color(lght.r, lght.g, lght.b, 0.8), 2.0)
	draw_line(Vector2( r * 0.22, -r * 0.56), Vector2( r * 0.70, -r * 1.20), drk, 3.5)
	draw_line(Vector2( r * 0.70, -r * 1.20), Vector2( r * 0.30, -r * 1.50), drk, 3.0)
	draw_line(Vector2( r * 0.30, -r * 1.50), Vector2( r * 0.58, -r * 1.20), Color(lght.r, lght.g, lght.b, 0.8), 2.0)

	# Üçgen baş
	var head := PackedVector2Array([
		Vector2(0, -r * 1.30),
		Vector2(-r * 0.28, -r * 0.94),
		Vector2( r * 0.28, -r * 0.94),
	])
	draw_colored_polygon(head, bc)

	# Büyük gözler
	draw_circle(Vector2(-r * 0.22, -r * 1.06), r * 0.14, Color(1.0, 0.88, 0.0))
	draw_circle(Vector2( r * 0.22, -r * 1.06), r * 0.14, Color(1.0, 0.88, 0.0))
	draw_circle(Vector2(-r * 0.22, -r * 1.06), r * 0.07, Color(0.0, 0.0, 0.0))
	draw_circle(Vector2( r * 0.22, -r * 1.06), r * 0.07, Color(0.0, 0.0, 0.0))
	draw_circle(Vector2(-r * 0.17, -r * 1.09), r * 0.03, Color(1, 1, 1, 0.7))
	draw_circle(Vector2( r * 0.27, -r * 1.09), r * 0.03, Color(1, 1, 1, 0.7))
