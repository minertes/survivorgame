extends CharacterBody2D

const BULLET_SCENE      = preload("res://bullet.tscn")
const HIT_EFFECT_SCRIPT = preload("res://hit_effect.gd")

# ── Temel istatistikler ────────────────────────────────────────
var max_health   := 100.0
var health       := 100.0
var speed        := 200.0
var damage       := 25.0
var fire_rate    := 0.5
var bullet_speed := 500.0
var multi_shot   := false
var life_steal   := 0.0
var crit_chance  := 0.0   # 0.0–0.75: mermi başına kritik ihtimali
var armor        := 0.0   # flat hasar azaltma

# ── Sihir halkası (silah değişmez, ek mermi) ──────────────────
var bonus_magic       := false
var bonus_magic_count := 4

# ── 3 Can sistemi ─────────────────────────────────────────────
var lives := 3
var _invincible_timer := 0.0
var _blink_timer      := 0.0

# ── Kill sayacı ───────────────────────────────────────────────
var _kills := 0

# ── Silah sistemi ──────────────────────────────────────────────
var weapon_id    := "sword"
var weapon_level := 1

const WEAPON_FIRE_RATES := {
	"sword":      0.65,
	"bow":        0.55,
	"pistol":     0.50,
	"shotgun":    1.10,
	"machinegun": 0.10,
	"magic":      1.80,
	"sniper":     2.40,
}

# ── Animasyon ─────────────────────────────────────────────────
var _anim_time    := 0.0
var _facing_right := true

# ── XP / Seviye ───────────────────────────────────────────────
var xp               := 0
var level            := 1
var xp_to_next_level := 30

# ── Dokunmatik joystick ───────────────────────────────────────
var touch_id       := -1
var touch_start    := Vector2.ZERO
var joystick_input := Vector2.ZERO

# ── Hedef ─────────────────────────────────────────────────────
var target_enemy: Node2D = null

signal health_changed(new_health: float, max_h: float)
signal lives_changed(new_lives: int)
signal xp_changed(cur_xp: int, needed: int, lvl: int)
signal leveled_up(new_level: int)
signal died


func _ready() -> void:
	add_to_group("player")

	match GameData.selected_character:
		"male":
			max_health = 1000.0
			health     = 1000.0
			speed      = 175.0
			damage     = 35.0
			weapon_id  = GameData.equipped_weapon_male
		"female":
			max_health = 1000.0
			health     = 1000.0
			speed      = 250.0
			damage     = 20.0
			fire_rate  = 0.42
			weapon_id  = GameData.equipped_weapon_female

	weapon_level = int(GameData.owned_weapons.get(weapon_id, 1))

	var cam := Camera2D.new()
	cam.zoom = Vector2(1.8, 1.8)
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed   = 8.0
	add_child(cam)

	_apply_weapon(weapon_id)
	$ShootTimer.timeout.connect(_on_shoot_timer_timeout)
	$ShootTimer.start()

	GameState.selected_character = GameData.selected_character
	GameState.sound_enabled      = GameData.sound_enabled


func _apply_weapon(wid: String) -> void:
	weapon_id = wid
	$ShootTimer.wait_time = WEAPON_FIRE_RATES.get(wid, 0.5)


# ── Girdi ─────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and touch_id == -1:
			touch_id       = touch.index
			touch_start    = touch.position
			joystick_input = Vector2.ZERO
		elif not touch.pressed and touch.index == touch_id:
			touch_id       = -1
			joystick_input = Vector2.ZERO
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == touch_id:
			var offset := drag.position - touch_start
			if offset.length() > 80.0:
				offset = offset.normalized() * 80.0
			joystick_input = offset / 80.0


func _physics_process(delta: float) -> void:
	if _invincible_timer > 0.0:
		_invincible_timer -= delta
		_blink_timer += delta
	else:
		_blink_timer = 0.0

	_anim_time += delta
	_handle_movement()
	_find_nearest_enemy()
	_update_facing()
	queue_redraw()


func _handle_movement() -> void:
	var direction := Vector2.ZERO
	direction.x = Input.get_axis("ui_left", "ui_right")
	direction.y = Input.get_axis("ui_up", "ui_down")
	if joystick_input.length() > 0.1:
		direction = joystick_input
	if direction != Vector2.ZERO:
		direction = direction.normalized()
	velocity = direction * speed
	move_and_slide()


func _update_facing() -> void:
	if target_enemy and is_instance_valid(target_enemy):
		_facing_right = target_enemy.global_position.x >= global_position.x
	elif velocity.length() > 10.0:
		_facing_right = velocity.x >= 0.0


func _find_nearest_enemy() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var nearest_dist := INF
	for e in enemies:
		if not is_instance_valid(e):
			continue
		var d := global_position.distance_to(e.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = e
	target_enemy = nearest


# ══════════════════════════════════════════════════════════════
#  KARAKTER ÇİZİMİ
# ══════════════════════════════════════════════════════════════

func _draw() -> void:
	# Göz kırpma (hasar sonrası)
	if _invincible_timer > 0.0 and fmod(_blink_timer, 0.18) < 0.09:
		return

	var bob := sin(_anim_time * 7.0) * 2.5 if velocity.length() > 15 else sin(_anim_time * 1.8) * 0.8
	var fx  := 1.0 if _facing_right else -1.0

	draw_set_transform(Vector2.ZERO, 0.0, Vector2(fx, 1.0))
	if GameData.selected_character == "male":
		_draw_warrior(bob)
	else:
		_draw_hunter(bob)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_ell(cx: float, cy: float, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 16:
		var a := i * TAU / 16.0
		pts.append(Vector2(cx + cos(a) * rx, cy + sin(a) * ry))
	draw_colored_polygon(pts, col)


func _draw_warrior(bob: float) -> void:
	var is_walking := velocity.length() > 15.0
	var lswing     := sin(_anim_time * 10.0) * 5.0 if is_walking else 0.0

	# Gölge
	_draw_ell(0, 22 + bob, 14, 4, Color(0, 0, 0, 0.28))

	# Bacaklar
	draw_rect(Rect2(-10, 5 + bob + lswing,  8, 16), Color(0.18, 0.38, 0.78))
	draw_rect(Rect2(  2, 5 + bob - lswing,  8, 16), Color(0.18, 0.38, 0.78))
	# Çizmeler
	draw_rect(Rect2(-11, 19 + bob + lswing, 10, 5), Color(0.18, 0.16, 0.28))
	draw_rect(Rect2(  2, 19 + bob - lswing, 10, 5), Color(0.18, 0.16, 0.28))

	# Gövde zırhı
	draw_rect(Rect2(-12, -8 + bob, 24, 16), Color(0.22, 0.48, 0.90))
	draw_rect(Rect2(-10, -6 + bob, 20,  4), Color(0.36, 0.62, 1.00, 0.65))
	draw_rect(Rect2( -4, -4 + bob,  8, 12), Color(0.28, 0.54, 0.94, 0.50))
	# Omuzluklar
	draw_circle(Vector2(-13, -6 + bob), 6, Color(0.30, 0.56, 1.00))
	draw_circle(Vector2( 13, -6 + bob), 6, Color(0.30, 0.56, 1.00))

	# Boyun
	draw_rect(Rect2(-3, -20 + bob, 6, 13), Color(0.85, 0.70, 0.58))

	# Kask
	draw_arc(Vector2(0, -22 + bob), 12, PI * 0.85, TAU + PI * 0.15, 24, Color(0.26, 0.50, 0.94), 12)
	draw_arc(Vector2(0, -22 + bob), 13, PI * 1.10, PI * 1.90,       12, Color(0.14, 0.28, 0.68),  4)

	# Yüz
	draw_circle(Vector2(0,  -19 + bob), 10, Color(0.88, 0.72, 0.60))
	draw_circle(Vector2(-3, -21 + bob), 1.8, Color(0.10, 0.20, 0.45))
	draw_circle(Vector2( 3, -21 + bob), 1.8, Color(0.10, 0.20, 0.45))
	draw_circle(Vector2(-2.2, -21.8 + bob), 0.6, Color(1, 1, 1, 0.6))
	draw_circle(Vector2( 3.8, -21.8 + bob), 0.6, Color(1, 1, 1, 0.6))

	# Kalkan (sol kol)
	draw_arc(Vector2(-18, 0 + bob), 12, -PI * 0.4, PI * 0.4, 8, Color(0.22, 0.48, 0.90), 10)
	draw_circle(Vector2(-18, 0 + bob), 3.5, Color(0.90, 0.75, 0.20))

	_draw_weapon_icon(bob)

	# Sihir halkası göstergesi
	if bonus_magic:
		var pulse := sin(_anim_time * 3.0) * 0.3 + 0.7
		draw_arc(Vector2(0, -5 + bob), 22, 0.0, TAU, 32, Color(0.75, 0.30, 1.0, 0.28 * pulse), 2.5)


func _draw_hunter(bob: float) -> void:
	var is_walking := velocity.length() > 15.0
	var lswing     := sin(_anim_time * 10.0) * 5.0 if is_walking else 0.0

	# Gölge
	_draw_ell(0, 20 + bob, 11, 3, Color(0, 0, 0, 0.28))

	# Pelerin
	var cape := PackedVector2Array([
		Vector2(-11, -5 + bob), Vector2(11, -5 + bob),
		Vector2( 14, 18 + bob), Vector2(-14, 18 + bob),
	])
	draw_colored_polygon(cape, Color(0.28, 0.07, 0.46, 0.80))

	# Bacaklar
	draw_rect(Rect2(-8, 5 + bob + lswing, 7, 14), Color(0.42, 0.14, 0.65))
	draw_rect(Rect2( 1, 5 + bob - lswing, 7, 14), Color(0.42, 0.14, 0.65))
	# Çizmeler
	draw_rect(Rect2(-9, 17 + bob + lswing, 8, 4), Color(0.12, 0.10, 0.18))
	draw_rect(Rect2( 1, 17 + bob - lswing, 8, 4), Color(0.12, 0.10, 0.18))

	# Gövde
	draw_rect(Rect2(-10, -8 + bob, 20, 16), Color(0.48, 0.14, 0.78))
	draw_rect(Rect2( -8, -6 + bob, 16,  3), Color(0.62, 0.34, 0.92, 0.70))
	# Kemer
	draw_rect(Rect2(-10, 6 + bob, 20, 4), Color(0.85, 0.65, 0.20))

	# Boyun
	draw_rect(Rect2(-3, -20 + bob, 6, 13), Color(0.88, 0.74, 0.62))

	# Hood
	draw_arc(Vector2(0, -22 + bob), 12, PI * 0.12, PI * 0.88, 14, Color(0.38, 0.09, 0.62), 12)
	# Saç
	draw_arc(Vector2(-10, -16 + bob), 6, -PI * 0.2, PI * 0.7,  8, Color(0.88, 0.44, 0.14), 4)
	draw_arc(Vector2( 10, -16 + bob), 6,  PI * 0.3, PI * 1.2,  8, Color(0.88, 0.44, 0.14), 4)

	# Yüz
	draw_circle(Vector2( 0, -18 + bob), 10, Color(0.90, 0.75, 0.63))
	draw_circle(Vector2(-3, -20 + bob), 1.6, Color(0.28, 0.10, 0.48))
	draw_circle(Vector2( 3, -20 + bob), 1.6, Color(0.28, 0.10, 0.48))
	draw_circle(Vector2(-2.2, -20.8 + bob), 0.5, Color(1, 1, 1, 0.6))
	draw_circle(Vector2( 3.8, -20.8 + bob), 0.5, Color(1, 1, 1, 0.6))

	# Yay (sol kol)
	draw_arc(Vector2(-20, 0 + bob), 16, -PI * 0.35, PI * 0.35, 12, Color(0.80, 0.65, 0.25), 3)
	draw_line(Vector2(-20, -15 + bob), Vector2(-20, 16 + bob), Color(0.65, 0.50, 0.20), 1.5)
	# Ok
	draw_line(Vector2(-14, -7 + bob), Vector2(12,  2 + bob), Color(0.90, 0.85, 0.50), 2)
	draw_line(Vector2( 12,  2 + bob), Vector2(16, -1 + bob), Color(0.80, 0.20, 0.20), 3)

	_draw_weapon_icon(bob)

	# Sihir halkası
	if bonus_magic:
		var pulse := sin(_anim_time * 3.0) * 0.3 + 0.7
		draw_arc(Vector2(0, -4 + bob), 20, 0.0, TAU, 32, Color(0.75, 0.30, 1.0, 0.28 * pulse), 2.5)


func _draw_weapon_icon(bob: float) -> void:
	match weapon_id:
		"sword":
			draw_rect(Rect2(14, -30 + bob, 5, 30), Color(0.78, 0.78, 0.82))
			draw_rect(Rect2(10,  -4 + bob, 13, 4), Color(0.65, 0.55, 0.20))
			draw_rect(Rect2(14, -38 + bob, 5, 10), Color(0.82, 0.78, 0.30))
		"bow":
			draw_arc(Vector2(18, -2 + bob), 18, -PI * 0.38, PI * 0.38, 10, Color(0.80, 0.65, 0.25), 3)
			draw_line(Vector2(18, -19 + bob), Vector2(18, 16 + bob), Color(0.65, 0.50, 0.20), 1.5)
		"pistol":
			draw_rect(Rect2(13, -6 + bob, 14, 8), Color(0.60, 0.60, 0.60))
			draw_rect(Rect2(20, -2 + bob,  8, 4), Color(0.38, 0.38, 0.38))
		"shotgun":
			draw_rect(Rect2(13, -5 + bob, 18, 10), Color(0.58, 0.48, 0.32))
			draw_rect(Rect2(24, -3 + bob, 10,  6), Color(0.72, 0.62, 0.42))
		"machinegun":
			draw_rect(Rect2(13, -4 + bob, 22, 8), Color(0.40, 0.40, 0.45))
			draw_rect(Rect2(13, -7 + bob,  8, 4), Color(0.50, 0.50, 0.55))
		"magic":
			var pulse := sin(_anim_time * 5.0) * 0.3 + 0.7
			draw_circle(Vector2(20, -2 + bob), 7, Color(0.50, 0.10, 0.90, 0.75 * pulse))
			draw_circle(Vector2(20, -2 + bob), 5, Color(0.72, 0.30, 1.00, 0.90 * pulse))
			draw_circle(Vector2(20, -2 + bob), 3, Color(1.00, 0.85, 1.00))
		"sniper":
			draw_rect(Rect2(13, -3 + bob, 28, 6), Color(0.42, 0.42, 0.48))
			draw_rect(Rect2(13, -5 + bob,  6, 3), Color(0.52, 0.52, 0.58))
			draw_rect(Rect2(32, -5 + bob,  8, 3), Color(0.55, 0.55, 0.60))


# ── İsabet efekti ─────────────────────────────────────────────
func _spawn_hit_effect(pos: Vector2, color: Color, radius: float, slash: bool = false) -> void:
	var fx := Node2D.new()
	fx.set_script(HIT_EFFECT_SCRIPT)
	fx.global_position = pos
	get_parent().add_child(fx)
	fx.setup(color, radius, slash)


# ── Mermi ─────────────────────────────────────────────────────
func _fire_bullet(dir: Vector2, dmg_mult: float) -> void:
	var bullet := BULLET_SCENE.instantiate()
	bullet.global_position = global_position
	bullet.direction       = dir
	var base_dmg := damage * dmg_mult * (1.0 + (weapon_level - 1) * 0.45)
	if crit_chance > 0.0 and randf() < crit_chance:
		base_dmg *= 3.0
	bullet.damage      = base_dmg
	bullet.speed       = bullet_speed
	bullet.weapon_type = weapon_id
	get_parent().add_child(bullet)


func _on_shoot_timer_timeout() -> void:
	var has_target := target_enemy and is_instance_valid(target_enemy)
	var dir := Vector2.RIGHT
	if has_target:
		dir = (target_enemy.global_position - global_position).normalized()

	match weapon_id:
		"sword":
			var attack_range := 90.0 + (weapon_level - 1) * 28.0
			for e in get_tree().get_nodes_in_group("enemies"):
				if not is_instance_valid(e):
					continue
				if global_position.distance_to(e.global_position) <= attack_range:
					e.take_damage(damage * (1.0 + (weapon_level - 1) * 0.5))
					if life_steal > 0.0:
						health = minf(max_health, health + life_steal * 0.5)
						health_changed.emit(health, max_health)
			_spawn_hit_effect(global_position + dir * attack_range * 0.55,
				Color(1.0, 0.88, 0.3), attack_range * 0.4, true)
			SoundManager.play_shoot()

		"bow":
			if not has_target: return
			if multi_shot:
				_fire_bullet(dir.rotated(-0.22), 1.0)
				_fire_bullet(dir, 1.1)
				_fire_bullet(dir.rotated(0.22), 1.0)
			else:
				_fire_bullet(dir, 1.0)
			SoundManager.play_shoot()

		"pistol":
			if not has_target: return
			if multi_shot:
				_fire_bullet(dir.rotated(-0.25), 1.0)
				_fire_bullet(dir, 1.0)
				_fire_bullet(dir.rotated(0.25), 1.0)
			else:
				_fire_bullet(dir, 1.0)
			SoundManager.play_shoot()

		"shotgun":
			if not has_target: return
			var pellets := 5 + (weapon_level - 1) * 2
			for i in pellets:
				_fire_bullet(dir.rotated((i - pellets / 2) * 0.18), 0.55)
			SoundManager.play_shoot()

		"machinegun":
			if not has_target: return
			_fire_bullet(dir.rotated(randf_range(-0.12, 0.12)), 0.60)
			SoundManager.play_shoot()

		"magic":
			var count := 6 + (weapon_level - 1) * 2
			for i in count:
				_fire_bullet(Vector2.RIGHT.rotated(i * TAU / count), 0.65)
			SoundManager.play_shoot()

		"sniper":
			if not has_target: return
			_fire_bullet(dir, 4.0)
			if weapon_level >= 3:
				_fire_bullet(dir.rotated(0.08), 2.5)
			SoundManager.play_shoot()

	# Sihir halkası — silahını değiştirmeden ek mermi
	if bonus_magic and weapon_id != "magic":
		for i in bonus_magic_count:
			_fire_bullet(Vector2.RIGHT.rotated(i * TAU / bonus_magic_count), 0.30)


# ── Hasar / 3 Can ─────────────────────────────────────────────
func take_damage(amount: float) -> void:
	if _invincible_timer > 0.0:
		return

	health = maxf(0.0, health - maxf(1.0, amount - armor))
	health_changed.emit(health, max_health)
	SoundManager.play_hurt()

	if health <= 0.0:
		lives -= 1
		lives_changed.emit(lives)
		if lives <= 0:
			died.emit()
		else:
			health = max_health
			health_changed.emit(health, max_health)
			_invincible_timer = 2.0
			_blink_timer      = 0.0


func gain_xp(amount: int) -> void:
	xp += amount
	GameData.add_xp(amount)
	while xp >= xp_to_next_level:
		_level_up()
	xp_changed.emit(xp, xp_to_next_level, level)


func register_kill() -> void:
	_kills += 1


func _level_up() -> void:
	xp -= xp_to_next_level
	level += 1
	xp_to_next_level = int(xp_to_next_level * 1.55)
	leveled_up.emit(level)
	SoundManager.play_level_up()
