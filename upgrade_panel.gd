class_name UpgradePanel
extends CanvasLayer

# ── Stat yükseltmeleri ─────────────────────────────────────────
const STAT_UPGRADES := {
	"fire_rate": {
		"name": "Ateş Hızı",   "desc": "Çok daha hızlı ateş et!",
		"icon": "🔥",          "color": Color(1.0, 0.55, 0.1),
	},
	"damage": {
		"name": "Hasar +10",   "desc": "Her mermi daha fazla hasar verir.",
		"icon": "💥",          "color": Color(1.0, 0.2, 0.2),
	},
	"speed": {
		"name": "Hareket Hızı","desc": "Daha çabuk koş!",
		"icon": "⚡",          "color": Color(1.0, 0.95, 0.1),
	},
	"health": {
		"name": "Can +30",     "desc": "Max canını artır ve iyileş.",
		"icon": "❤️",          "color": Color(0.2, 1.0, 0.35),
	},
	"multi_shot": {
		"name": "Çoklu Atış",  "desc": "Tabancayla 3 mermi birden!",
		"icon": "🎯",          "color": Color(0.55, 0.2, 1.0),
	},
	"life_steal": {
		"name": "Can Çalma",   "desc": "Düşman öldürünce can kazan.",
		"icon": "🧛",          "color": Color(0.85, 0.1, 0.65),
	},
	"bonus_magic": {
		"name": "Sihir Halkası", "desc": "Silahın kalır + her yöne ek sihir mermisi!",
		"icon": "🔮",            "color": Color(0.80, 0.35, 1.0),
	},
	"critical": {
		"name": "Kritik Vuruş",  "desc": "+%15 kritik şans — kritik vurursan 3× hasar!",
		"icon": "⚡",            "color": Color(1.0, 0.90, 0.15),
	},
	"armor": {
		"name": "Zırh +8",       "desc": "Gelen her darbeden 8 hasar azaltır.",
		"icon": "🛡",            "color": Color(0.35, 0.65, 1.0),
	},
	# Faz 2.2.3 – en az 10 upgrade (10. stat)
	"bullet_speed": {
		"name": "Mermi Hızı",    "desc": "Mermiler daha hızlı gider.",
		"icon": "💨",            "color": Color(0.5, 0.9, 1.0),
	},
}

# ── Silahlar (lobby weapon_selector ile uyumlu) ────────────────
const WEAPONS := {
	"sword": {
		"name": "Kılıç",           "desc": "Yakın dövüş — çevredeki düşmanlara vurur.",
		"icon": "⚔️",              "color": Color(0.9, 0.85, 0.2),
	},
	"bow": {
		"name": "Yay",             "desc": "Uzak mesafe — hedefe ok atar.",
		"icon": "🏹",              "color": Color(0.6, 0.9, 0.3),
	},
	"pistol": {
		"name": "Tabanca",         "desc": "Dengeli. Çoklu atış alınabilir.",
		"icon": "🔫",              "color": Color(0.9, 0.7, 0.2),
	},
	"shotgun": {
		"name": "Pompalı Tüfek",   "desc": "5+ pellet, kısa menzil.",
		"icon": "💣",              "color": Color(0.85, 0.55, 0.1),
	},
	"machinegun": {
		"name": "Makineli Tüfek",  "desc": "Çok hızlı, düşük hasar.",
		"icon": "⚡",              "color": Color(0.35, 0.9, 0.2),
	},
	"magic": {
		"name": "Sihir",           "desc": "Tüm yönlerde mermi fırlat!",
		"icon": "✨",              "color": Color(0.75, 0.3, 1.0),
	},
	"magic_wand": {
		"name": "Sihir Asası",     "desc": "360° mermi, büyü hasarı.",
		"icon": "✨",              "color": Color(0.75, 0.3, 1.0),
	},
	"sniper": {
		"name": "Keskin Nişancı",  "desc": "4× hasar, yavaş ateş.",
		"icon": "🎯",              "color": Color(0.3, 0.75, 1.0),
	},
	"flamethrower": {
		"name": "Alev Makinesi",   "desc": "Sürekli hasar, alan etkisi.",
		"icon": "🔥",              "color": Color(1.0, 0.55, 0.1),
	},
	"rocket_launcher": {
		"name": "Roket Atar",      "desc": "Patlama hasarı, alan etkisi.",
		"icon": "🚀",              "color": Color(0.9, 0.5, 0.2),
	},
}

var _player_ref = null  # Duck typing — oyuncu script'ine doğrudan erişim


func show_upgrades(player: Node) -> void:
	_player_ref = player
	get_tree().paused = true
	_build_ui()


func _build_ui() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.78)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(overlay)

	var title := Label.new()
	title.text = "SEVİYE ATLADIN!"
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color.YELLOW)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 55.0
	title.offset_bottom = 110.0
	title.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(title)

	var sub := Label.new()
	sub.text = "Bir seçenek al:"
	sub.add_theme_font_size_override("font_size", 20)
	sub.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.set_anchors_preset(Control.PRESET_TOP_WIDE)
	sub.offset_top = 110.0
	sub.offset_bottom = 148.0
	sub.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(sub)

	var hbox := HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_CENTER)
	hbox.offset_left = -370.0
	hbox.offset_right = 370.0
	hbox.offset_top = -130.0
	hbox.offset_bottom = 170.0
	hbox.add_theme_constant_override("separation", 16)
	hbox.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(hbox)

	for choice in _random_choices(3):
		hbox.add_child(_make_card(choice))


func _make_card(choice_id: String) -> Button:
	var info: Dictionary = {}
	var wid := ""

	if choice_id.begins_with("weapon_upgrade_"):
		wid = choice_id.substr("weapon_upgrade_".length())
		var next_lv: int = _player_ref.weapon_level + 1
		var wd: Dictionary = WEAPONS.get(wid, {"name": wid, "icon": "⚔️", "color": Color.WHITE})
		info = {
			"name": str(wd.get("name", "")) + " Lv" + str(next_lv),
			"desc": "Silahını güçlendir! (Seviye " + str(next_lv) + "/3)",
			"icon": wd.get("icon", "⚔️"),
			"color": wd.get("color", Color.WHITE),
		}
	elif choice_id.begins_with("weapon_"):
		wid = choice_id.substr(7)
		var wd2: Dictionary = WEAPONS.get(wid, {"name": wid, "desc": "", "icon": "⚔️", "color": Color.WHITE})
		info = wd2.duplicate()
		info["name"] = "Silah: " + str(info.get("name", ""))
	else:
		var wd3: Dictionary = STAT_UPGRADES.get(choice_id, {"name": choice_id, "desc": "", "icon": "?", "color": Color.WHITE})
		info = wd3.duplicate()

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(225, 270)
	btn.process_mode = Node.PROCESS_MODE_ALWAYS

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 12)
	btn.add_child(vbox)

	var icon_lbl := Label.new()
	icon_lbl.text = str(info.get("icon", "?"))
	icon_lbl.add_theme_font_size_override("font_size", 52)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(icon_lbl)

	var name_lbl := Label.new()
	name_lbl.text = str(info.get("name", ""))
	name_lbl.add_theme_font_size_override("font_size", 21)
	name_lbl.add_theme_color_override("font_color", info.get("color", Color.WHITE) as Color)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = str(info.get("desc", ""))
	desc_lbl.add_theme_font_size_override("font_size", 15)
	desc_lbl.add_theme_color_override("font_color", Color(0.82, 0.82, 0.82))
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_lbl)

	btn.pressed.connect(func() -> void: _select(choice_id))
	return btn


func _select(choice_id: String) -> void:
	_apply(choice_id)
	for child in get_children():
		child.queue_free()
	get_tree().paused = false


func _apply(choice_id: String) -> void:
	if not _player_ref or not is_instance_valid(_player_ref):
		return

	if choice_id.begins_with("weapon_upgrade_"):
		_player_ref.weapon_level = mini(_player_ref.weapon_level + 1, 5)
		# GameData'ya da yaz
		var cur_wid: String = str(_player_ref.weapon_id)
		GameData.owned_weapons[cur_wid] = _player_ref.weapon_level
		GameData.save_data()
		return

	# Stat upgrades
	match choice_id:
		"fire_rate":
			_player_ref.fire_rate = maxf(0.08, _player_ref.fire_rate - 0.06)
			_player_ref.get_node("ShootTimer").wait_time = _player_ref.fire_rate
		"damage":
			_player_ref.damage += 10.0
		"speed":
			_player_ref.speed += 25.0
		"health":
			_player_ref.max_health += 30.0
			_player_ref.health = _player_ref.max_health
			_player_ref.health_changed.emit(_player_ref.max_health, _player_ref.max_health)
		"multi_shot":
			_player_ref.multi_shot = true
		"life_steal":
			_player_ref.life_steal += 4.0
		"bonus_magic":
			_player_ref.bonus_magic = true
			_player_ref.bonus_magic_count = mini(_player_ref.bonus_magic_count + 4, 16)
		"critical":
			_player_ref.crit_chance = minf(0.75, _player_ref.crit_chance + 0.15)
		"armor":
			_player_ref.armor = minf(50.0, _player_ref.armor + 8.0)
		"bullet_speed":
			_player_ref.bullet_speed = minf(1200.0, _player_ref.bullet_speed + 80.0)


func _random_choices(count: int) -> Array[String]:
	var pool: Array[String] = []

	# Stat upgrades
	for k: String in STAT_UPGRADES.keys():
		pool.append(k)

	# Aktif silah upgrade (max seviye değilse)
	if _player_ref.weapon_level < 5:
		pool.append("weapon_upgrade_" + _player_ref.weapon_id)

	# Max'a ulaşan upgrade'leri havuzdan çıkar
	if _player_ref.bonus_magic_count >= 16:
		pool.erase("bonus_magic")
	if _player_ref.fire_rate <= 0.08:
		pool.erase("fire_rate")
	if _player_ref.crit_chance >= 0.75:
		pool.erase("critical")
	if _player_ref.armor >= 50.0:
		pool.erase("armor")
	if _player_ref.get("bullet_speed") != null and _player_ref.bullet_speed >= 1200.0:
		pool.erase("bullet_speed")
	if _player_ref.multi_shot:
		pool.erase("multi_shot")

	pool.shuffle()
	var result: Array[String] = []
	for i in mini(count, pool.size()):
		result.append(pool[i])
	return result
