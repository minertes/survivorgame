extends Area2D

var xp_value := 5
var attract_radius := 120.0
var move_speed := 300.0

var player_ref: Node2D = null


func _ready() -> void:
	add_to_group("xp_gems")
	body_entered.connect(_on_body_entered)
	await get_tree().process_frame
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]


func _physics_process(delta: float) -> void:
	if not player_ref or not is_instance_valid(player_ref):
		return
	var dist := global_position.distance_to(player_ref.global_position)
	if dist < attract_radius:
		if dist < 10.0:
			# Doğrudan topla
			_on_body_entered(player_ref)
			return
		var dir := (player_ref.global_position - global_position).normalized()
		position += dir * move_speed * delta


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		var a = get_node_or_null("/root/AudioSystem")
		if a and a.has_method("play_sound"):
			a.play_sound("xp_collect")
		body.gain_xp(xp_value)
		queue_free()


func _draw() -> void:
	# Yeşil elmas şekli
	var pts := PackedVector2Array([
		Vector2(0, -10),
		Vector2(8, 0),
		Vector2(0, 10),
		Vector2(-8, 0),
	])
	draw_colored_polygon(pts, Color(0.1, 0.9, 0.3))
	# Parlak kısım
	var shine := PackedVector2Array([
		Vector2(-1, -9),
		Vector2(3, -3),
		Vector2(-1, -3),
	])
	draw_colored_polygon(shine, Color(0.7, 1.0, 0.8, 0.6))
	# Dış çizgi
	draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), Color.WHITE, 1.5)
