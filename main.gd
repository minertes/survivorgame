extends Node2D

const ENEMY_SCENE = preload("res://enemy.tscn")

@onready var player: Node           = $Player
@onready var health_bar: ProgressBar = $UI/HUD/HealthBar
@onready var xp_bar: ProgressBar     = $UI/HUD/XPBar
@onready var level_label: Label      = $UI/HUD/LevelLabel
@onready var wave_label: Label       = $UI/HUD/WaveLabel
@onready var spawn_timer: Timer      = $SpawnTimer
@onready var wave_timer: Timer       = $WaveTimer

var wave          := 1
var viewport_size := Vector2.ZERO
var upgrade_panel: UpgradePanel = null
var mini_map: MiniMap           = null
var background: Background      = null

var _kills_this_game := 0
var _heart_labels: Array[Label] = []
var _kill_label: Label = null


func _ready() -> void:
	viewport_size = get_viewport_rect().size

	background = Background.new()
	add_child(background)
	move_child(background, 0)

	player.health_changed.connect(_on_health_changed)
	player.lives_changed.connect(_on_lives_changed)
	player.xp_changed.connect(_on_xp_changed)
	player.leveled_up.connect(_on_level_up)
	player.died.connect(_on_player_died)

	spawn_timer.timeout.connect(_spawn_enemy)
	wave_timer.timeout.connect(_next_wave)

	wave_label.text  = "Dalga 1"
	level_label.text = "Lv 1"
	health_bar.value = 100.0
	xp_bar.value     = 0.0
	_style_bars()
	_setup_hearts()
	_setup_kill_counter()
	_setup_mini_map()
	_setup_upgrade_panel()
	_setup_flag_display()
	_setup_pause_button()


func _setup_hearts() -> void:
	var hx := 10.0
	var hy := 4.0
	for i in 3:
		var lbl := Label.new()
		lbl.text = "❤"
		lbl.add_theme_font_size_override("font_size", 32)
		lbl.add_theme_color_override("font_color", Color(0.95, 0.15, 0.15))
		lbl.position = Vector2(hx + i * 38, hy)
		$UI/HUD.add_child(lbl)
		_heart_labels.append(lbl)


func _on_lives_changed(new_lives: int) -> void:
	for i in _heart_labels.size():
		if i < new_lives:
			_heart_labels[i].add_theme_color_override("font_color", Color(0.95, 0.15, 0.15))
			_heart_labels[i].modulate.a = 1.0
		else:
			_heart_labels[i].add_theme_color_override("font_color", Color(0.35, 0.35, 0.35))
			_heart_labels[i].modulate.a = 0.45

	var flash := ColorRect.new()
	flash.color = Color(0.8, 0.0, 0.0, 0.35)
	flash.size  = viewport_size
	flash.position = Vector2.ZERO
	flash.process_mode = Node.PROCESS_MODE_ALWAYS
	$UI.add_child(flash)
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(flash, "modulate:a", 0.0, 0.6)
	tw.tween_callback(flash.queue_free)


func _setup_kill_counter() -> void:
	_kill_label = Label.new()
	_kill_label.text = "💀 0"
	_kill_label.add_theme_font_size_override("font_size", 20)
	_kill_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.15))
	_kill_label.position = Vector2(viewport_size.x / 2.0 - 35, 6)
	$UI/HUD.add_child(_kill_label)


func _style_bars() -> void:
	var hp_bg := StyleBoxFlat.new()
	hp_bg.bg_color = Color(0.25, 0.05, 0.05)
	hp_bg.set_corner_radius_all(4)
	health_bar.add_theme_stylebox_override("background", hp_bg)

	var hp_fill := StyleBoxFlat.new()
	hp_fill.bg_color = Color(0.9, 0.15, 0.15)
	hp_fill.set_corner_radius_all(4)
	health_bar.add_theme_stylebox_override("fill", hp_fill)

	var xp_bg := StyleBoxFlat.new()
	xp_bg.bg_color = Color(0.05, 0.1, 0.3)
	xp_bg.set_corner_radius_all(4)
	xp_bar.add_theme_stylebox_override("background", xp_bg)

	var xp_fill := StyleBoxFlat.new()
	xp_fill.bg_color = Color(0.2, 0.55, 1.0)
	xp_fill.set_corner_radius_all(4)
	xp_bar.add_theme_stylebox_override("fill", xp_fill)


func _setup_mini_map() -> void:
	mini_map = MiniMap.new()
	mini_map.position = Vector2(viewport_size.x - 170.0, 10.0)
	$UI.add_child(mini_map)

	var toggle_btn := Button.new()
	toggle_btn.text = "Harita"
	toggle_btn.size = Vector2(100.0, 28.0)
	toggle_btn.position = Vector2(viewport_size.x - 170.0, 176.0)
	toggle_btn.add_theme_font_size_override("font_size", 14)
	toggle_btn.pressed.connect(func() -> void: mini_map.toggle())
	$UI.add_child(toggle_btn)


func _setup_upgrade_panel() -> void:
	upgrade_panel = UpgradePanel.new()
	add_child(upgrade_panel)


func _get_enemy_type() -> int:
	if wave >= 10:
		return randi() % 4
	elif wave >= 7:
		return randi_range(1, 3)
	elif wave >= 4:
		return randi_range(0, 1)
	else:
		return 0


func _spawn_enemy() -> void:
	var enemy := ENEMY_SCENE.instantiate()
	add_child(enemy)
	enemy.tree_exiting.connect(_on_enemy_killed.bind(enemy), CONNECT_ONE_SHOT)

	var angle      := randf() * TAU
	var spawn_dist := viewport_size.length() * 0.6
	enemy.global_position = player.global_position + Vector2(cos(angle), sin(angle)) * spawn_dist

	var base_hp    := 30.0 + wave * 10.0
	var base_speed := 80.0 + wave * 8.0
	var base_dmg   := 10.0 + wave * 2.0
	var etype      := _get_enemy_type()
	enemy.enemy_type = etype

	match etype:
		1:
			base_speed *= 1.65; base_hp *= 0.65; base_dmg *= 0.85
		2:
			base_speed *= 0.55; base_hp *= 2.8;  base_dmg *= 1.6
		3:
			base_speed *= 1.25; base_hp *= 1.6;  base_dmg *= 1.4

	enemy.speed             = base_speed
	enemy.max_health        = base_hp
	enemy.health            = base_hp
	enemy.xp_value          = (2 + etype * 2) * 3
	enemy.damage_per_second = base_dmg
	enemy.queue_redraw()


func _on_enemy_killed(_enemy: Node) -> void:
	_kills_this_game += 1
	if is_instance_valid(_kill_label):
		_kill_label.text = "💀 %d" % _kills_this_game


func _next_wave() -> void:
	wave += 1
	spawn_timer.wait_time = maxf(0.15, 1.0 - wave * 0.04)
	wave_label.text = "Dalga %d" % wave
	background.set_wave(wave)
	_show_wave_notification()


func _show_wave_notification() -> void:
	var notif := Label.new()
	notif.text = "DALGA %d!" % wave
	notif.add_theme_font_size_override("font_size", 52)
	notif.add_theme_color_override("font_color", Color.YELLOW)
	notif.position = viewport_size / 2.0 - Vector2(100, 30)
	$UI.add_child(notif)
	var tween := create_tween()
	tween.tween_interval(1.0)
	tween.tween_property(notif, "modulate:a", 0.0, 1.5)
	tween.tween_callback(notif.queue_free)


func _on_health_changed(new_health: float, max_h: float) -> void:
	health_bar.value = (new_health / max_h) * 100.0


func _on_xp_changed(cur_xp: int, needed: int, lvl: int) -> void:
	xp_bar.value     = (float(cur_xp) / needed) * 100.0
	level_label.text = "Lv %d" % lvl


func _on_level_up(new_level: int) -> void:
	upgrade_panel.show_upgrades(player)
	var notif := Label.new()
	notif.text = "SEVİYE %d!" % new_level
	notif.add_theme_font_size_override("font_size", 44)
	notif.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
	notif.position = viewport_size / 2.0 - Vector2(90, 60)
	notif.process_mode = Node.PROCESS_MODE_ALWAYS
	$UI.add_child(notif)
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_interval(0.8)
	tween.tween_property(notif, "modulate:a", 0.0, 1.0)
	tween.tween_callback(notif.queue_free)


func _setup_flag_display() -> void:
	var fid := GameData.equipped_flag if GameData.equipped_flag in GameData.FLAGS else "turkey"
	var fd  := GameData.FLAGS[fid] as Dictionary
	var lbl := Label.new()
	lbl.text = str(fd.get("emoji", "🏳")) + "  " + str(fd.get("name", ""))
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.6))
	lbl.position = Vector2(10.0, viewport_size.y - 38.0)
	$UI.add_child(lbl)


func _setup_pause_button() -> void:
	var btn := Button.new()
	btn.text = "⏸"
	btn.size = Vector2(50, 28)
	btn.position = Vector2(viewport_size.x - 60.0, 176.0)
	btn.add_theme_font_size_override("font_size", 18)
	var sty := StyleBoxFlat.new()
	sty.bg_color = Color(0.12, 0.12, 0.22, 0.88)
	sty.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", sty)
	btn.pressed.connect(_on_pause_pressed)
	$UI.add_child(btn)


func _on_pause_pressed() -> void:
	get_tree().paused = true

	var pause_root := Control.new()
	pause_root.size         = viewport_size
	pause_root.process_mode = Node.PROCESS_MODE_ALWAYS
	$UI.add_child(pause_root)

	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.78)
	overlay.size  = viewport_size
	pause_root.add_child(overlay)

	var title := Label.new()
	title.text = "⏸  DURAKLANDI"
	title.add_theme_font_size_override("font_size", 54)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.position = viewport_size / 2.0 - Vector2(180, 110)
	pause_root.add_child(title)

	var resume_btn := Button.new()
	resume_btn.text = "▶  Devam Et"
	resume_btn.size = Vector2(280, 64)
	resume_btn.position = viewport_size / 2.0 - Vector2(140, 20)
	resume_btn.add_theme_font_size_override("font_size", 26)
	var rs := StyleBoxFlat.new()
	rs.bg_color = Color(0.15, 0.55, 0.15)
	rs.set_corner_radius_all(10)
	resume_btn.add_theme_stylebox_override("normal", rs)
	resume_btn.pressed.connect(func() -> void:
		get_tree().paused = false
		pause_root.queue_free())
	pause_root.add_child(resume_btn)

	var lobby_btn2 := Button.new()
	lobby_btn2.text = "🏠  Lobiye Dön"
	lobby_btn2.size = Vector2(280, 64)
	lobby_btn2.position = viewport_size / 2.0 - Vector2(140, -56)
	lobby_btn2.add_theme_font_size_override("font_size", 22)
	var ls := StyleBoxFlat.new()
	ls.bg_color = Color(0.18, 0.18, 0.35)
	ls.set_corner_radius_all(10)
	lobby_btn2.add_theme_stylebox_override("normal", ls)
	lobby_btn2.pressed.connect(func() -> void:
		get_tree().paused = false
		get_tree().change_scene_to_file("res://lobby.tscn"))
	pause_root.add_child(lobby_btn2)


func _on_player_died() -> void:
	GameData.record_game(wave, _kills_this_game)
	get_tree().paused = true

	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.82)
	overlay.size  = viewport_size
	overlay.position = Vector2.ZERO
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	$UI.add_child(overlay)

	var game_over := Label.new()
	game_over.text = "OYUN BİTTİ"
	game_over.add_theme_font_size_override("font_size", 72)
	game_over.add_theme_color_override("font_color", Color.RED)
	game_over.position = viewport_size / 2.0 - Vector2(210, 120)
	game_over.process_mode = Node.PROCESS_MODE_ALWAYS
	$UI.add_child(game_over)

	var wave_info := Label.new()
	wave_info.text = "En yüksek dalga: %d" % wave
	wave_info.add_theme_font_size_override("font_size", 30)
	wave_info.add_theme_color_override("font_color", Color.WHITE)
	wave_info.position = viewport_size / 2.0 - Vector2(140, 58)
	wave_info.process_mode = Node.PROCESS_MODE_ALWAYS
	$UI.add_child(wave_info)

	var kill_info := Label.new()
	kill_info.text = "Öldürme: %d   |   Toplam XP: %d" % [_kills_this_game, GameData.xp_coins]
	kill_info.add_theme_font_size_override("font_size", 20)
	kill_info.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	kill_info.position = viewport_size / 2.0 - Vector2(160, 18)
	kill_info.process_mode = Node.PROCESS_MODE_ALWAYS
	$UI.add_child(kill_info)

	var restart_btn := Button.new()
	restart_btn.text = "🔄  Yeniden Oyna"
	restart_btn.size = Vector2(280, 62)
	restart_btn.position = viewport_size / 2.0 - Vector2(140, -20)
	restart_btn.add_theme_font_size_override("font_size", 24)
	restart_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	restart_btn.pressed.connect(func():
		get_tree().paused = false
		get_tree().reload_current_scene())
	$UI.add_child(restart_btn)

	var lobby_btn := Button.new()
	lobby_btn.text = "🏠  Lobiye Dön"
	lobby_btn.size = Vector2(280, 62)
	lobby_btn.position = viewport_size / 2.0 - Vector2(140, -96)
	lobby_btn.add_theme_font_size_override("font_size", 24)
	lobby_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	lobby_btn.pressed.connect(func():
		get_tree().paused = false
		get_tree().change_scene_to_file("res://lobby.tscn"))
	$UI.add_child(lobby_btn)
