extends Node2D
# ══════════════════════════════════════════════════════════════
#  HealthPickup — Object Pool tarafından yönetilen can topu
#  Kullanım:  pickup.activate(pos)  /  pickup.deactivate()
# ══════════════════════════════════════════════════════════════

const HEAL_AMOUNT := 150.0

var _active     := false
var _anim_time  := 0.0
var _player_ref: Node2D = null


func _ready() -> void:
	visible = false
	set_process(false)
	# Oyuncu referansını bir sonraki kareye bırak (sahne tam yüklü olsun)
	await get_tree().process_frame
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player_ref = players[0]


func activate(pos: Vector2) -> void:
	global_position = pos
	_anim_time = 0.0
	_active    = true
	visible    = true
	set_process(true)
	queue_redraw()


func deactivate() -> void:
	_active = false
	visible = false
	set_process(false)


func _process(delta: float) -> void:
	_anim_time += delta
	queue_redraw()

	if not _player_ref or not is_instance_valid(_player_ref):
		return
	if global_position.distance_to(_player_ref.global_position) < 30.0:
		_player_ref.health = minf(_player_ref.max_health, _player_ref.health + HEAL_AMOUNT)
		_player_ref.health_changed.emit(_player_ref.health, _player_ref.max_health)
		deactivate()


func _draw() -> void:
	if not _active:
		return

	var bob   := sin(_anim_time * 3.5) * 3.0
	var pulse := sin(_anim_time * 4.2) * 0.15 + 0.85

	# AssetDB'den texture dene (varsa)
	var tex: Texture2D = null
	var adb = get_node_or_null("/root/AssetDB")
	if adb and adb.has_method("get_pickup_icon"):
		tex = adb.get_pickup_icon("health")
	if tex != null:
		draw_texture_rect(tex,
			Rect2(Vector2(-20.0, -20.0 + bob), Vector2(40.0, 40.0)), false)
		return

	# Fallback: parlayan artı / kalp sembolü
	draw_circle(Vector2(0.0, bob), 18.0 * pulse, Color(0.88, 0.10, 0.10, 0.20))
	draw_circle(Vector2(0.0, bob), 18.0 * pulse, Color(0.95, 0.18, 0.18, 0.80), false, 2.2)
	# Artı gövdesi
	draw_rect(Rect2(-4.0, -11.5 + bob, 8.0, 23.0), Color(0.95, 0.18, 0.18))
	draw_rect(Rect2(-11.5, -4.0 + bob, 23.0,  8.0), Color(0.95, 0.18, 0.18))
	# Parlak merkez
	draw_circle(Vector2(0.0, bob), 5.0 * pulse, Color(1.0, 0.65, 0.65, 0.65))
