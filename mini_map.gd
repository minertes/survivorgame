class_name MiniMap
extends Control

const MAP_SIZE := Vector2(160.0, 160.0)
const MAP_RANGE := 650.0

var player_ref: Node2D = null
var show_map := true


func _ready() -> void:
	custom_minimum_size = MAP_SIZE
	size = MAP_SIZE
	await get_tree().process_frame
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]


func toggle() -> void:
	show_map = not show_map
	queue_redraw()


func _process(_delta: float) -> void:
	if show_map:
		queue_redraw()


func _draw() -> void:
	if not show_map:
		# Kapalıyken küçük bir ikon göster
		draw_rect(Rect2(Vector2.ZERO, Vector2(50, 24)), Color(0.05, 0.05, 0.15, 0.85))
		draw_rect(Rect2(Vector2.ZERO, Vector2(50, 24)), Color(0.4, 0.7, 1.0, 0.5), false, 1.0)
		return

	# Arka plan
	draw_rect(Rect2(Vector2.ZERO, MAP_SIZE), Color(0.04, 0.04, 0.14, 0.88))

	if not player_ref or not is_instance_valid(player_ref):
		return

	var center := MAP_SIZE / 2.0
	var scale_f := (MAP_SIZE / 2.0) / MAP_RANGE
	var inner := Rect2(Vector2(4, 4), MAP_SIZE - Vector2(8, 8))
	var dot_pos := Vector2.ZERO

	# XP gemleri
	for gem in get_tree().get_nodes_in_group("xp_gems"):
		if not is_instance_valid(gem):
			continue
		dot_pos = center + (gem.global_position - player_ref.global_position) * scale_f
		if inner.has_point(dot_pos):
			draw_circle(dot_pos, 2.0, Color(0.1, 0.95, 0.35, 0.85))

	# Düşmanlar
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		dot_pos = center + (enemy.global_position - player_ref.global_position) * scale_f
		if inner.has_point(dot_pos):
			draw_circle(dot_pos, 3.5, Color(1.0, 0.2, 0.2, 0.9))

	# Oyuncu (merkez)
	draw_circle(center, 5.0, Color(0.25, 0.65, 1.0))
	draw_arc(center, 6.5, 0.0, TAU, 16, Color.WHITE, 1.5)

	# Çerçeve
	draw_rect(Rect2(Vector2.ZERO, MAP_SIZE), Color(0.4, 0.7, 1.0, 0.75), false, 1.5)
