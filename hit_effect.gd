extends Node2D

var _life    := 0.28
var _max_life := 0.28
var _color   := Color.WHITE
var _radius  := 20.0
var _is_slash := false   # kılıç darbesi için farklı şekil


func setup(col: Color, rad: float, slash: bool = false) -> void:
	_color    = col
	_radius   = rad
	_is_slash = slash


func _process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var t := _life / _max_life          # 1.0 → 0.0
	var a := t * 0.85

	if _is_slash:
		# Kılıç darbesi: sarı/beyaz yay parçaları
		draw_arc(Vector2.ZERO, _radius * (1.0 + (1.0 - t) * 0.6),
			-0.6, 0.6, 10,
			Color(1.0, 0.9, 0.3, a), 5.0 * t)
		draw_arc(Vector2.ZERO, _radius * (0.6 + (1.0 - t) * 0.4),
			-0.4, 0.4, 8,
			Color(1.0, 1.0, 0.8, a * 0.6), 3.0 * t)
	else:
		# Ok / mermi isabet: daire + dış halka
		var r := _radius * (1.4 - t * 0.4)
		draw_circle(Vector2.ZERO, r * 0.5,
			Color(_color.r, _color.g, _color.b, a * 0.7))
		draw_arc(Vector2.ZERO, r, 0, TAU, 10,
			Color(_color.r, _color.g, _color.b, a * 0.5), 2.5)
