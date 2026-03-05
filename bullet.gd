extends Area2D

# Faz 2.1.2 – Havuz için: sinyal ve geri dönüş
signal bullet_finished(bullet: Node)

var speed := 500.0
var direction := Vector2.RIGHT
var damage := 25.0
var weapon_type := "pistol"
var from_pool := false

var _lifetime_timer: Timer


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_lifetime_timer = Timer.new()
	add_child(_lifetime_timer)
	_lifetime_timer.wait_time = 3.0
	_lifetime_timer.one_shot = true
	_lifetime_timer.timeout.connect(_on_lifetime_timeout)
	_lifetime_timer.start()


func set_from_pool(value: bool) -> void:
	from_pool = value


func restart_timer() -> void:
	if _lifetime_timer:
		_lifetime_timer.start()


func _finish() -> void:
	bullet_finished.emit(self)
	if not from_pool:
		queue_free()


func _on_lifetime_timeout() -> void:
	_finish()


func _physics_process(delta: float) -> void:
	position += direction * speed * delta


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		body.take_damage(damage)
		_finish()


func _draw() -> void:
	match weapon_type:
		"bow":
			# Ok gövdesi + kırmızı uç + tüy
			var tip  := direction * 10.0
			var tail := direction * -10.0
			draw_line(tail, tip, Color(0.85, 0.65, 0.2), 2.5)
			var perp := Vector2(-direction.y, direction.x) * 3.5
			var pts  := PackedVector2Array([tip + direction * 4.0, tip - perp, tip + perp])
			draw_colored_polygon(pts, Color(0.9, 0.2, 0.1))
			var fth := tail - direction * 2.0
			draw_line(fth, fth + perp * 2.2, Color(0.6, 0.9, 0.5, 0.85), 1.5)
			draw_line(fth, fth - perp * 2.2, Color(0.6, 0.9, 0.5, 0.85), 1.5)
		"pistol":
			draw_circle(Vector2.ZERO, 6.0, Color(1.0, 0.9, 0.0))
			draw_circle(Vector2.ZERO, 3.5, Color(1.0, 1.0, 0.6))
		"shotgun":
			draw_circle(Vector2.ZERO, 5.0, Color(1.0, 0.55, 0.05))
			draw_circle(Vector2.ZERO, 2.5, Color(1.0, 0.8, 0.4))
		"machinegun":
			draw_circle(Vector2.ZERO, 4.0, Color(0.4, 1.0, 0.2))
			draw_circle(Vector2.ZERO, 2.0, Color(0.8, 1.0, 0.6))
		"magic":
			draw_circle(Vector2.ZERO, 9.0, Color(0.75, 0.2, 1.0, 0.5))
			draw_circle(Vector2.ZERO, 6.0, Color(0.85, 0.4, 1.0))
			draw_arc(Vector2.ZERO, 10.0, 0.0, TAU, 12, Color(1.0, 0.7, 1.0, 0.4), 1.5)
		"sniper":
			var back := direction * -14.0
			draw_line(back, Vector2.ZERO, Color(0.3, 0.75, 1.0, 0.6), 2.5)
			draw_circle(Vector2.ZERO, 5.5, Color(0.3, 0.75, 1.0))
			draw_circle(Vector2.ZERO, 3.0, Color(0.8, 1.0, 1.0))
		_:
			draw_circle(Vector2.ZERO, 6.0, Color(1.0, 0.9, 0.0))
