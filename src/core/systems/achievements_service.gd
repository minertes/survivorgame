# Faz 5.2 – Başarılar (achievements): tanımlı rozetler, ilerleme takibi, bildirim
extends Node

signal achievement_unlocked(achievement_id: String, data: Dictionary)

# id -> { name, description, icon, condition_type, target }
const ACHIEVEMENTS: Dictionary = {
	"first_blood": {
		"name": "İlk Kan",
		"description": "İlk düşmanı öldür",
		"icon": "🩸",
		"condition_type": "total_kills",
		"target": 1
	},
	"killer_10": {
		"name": "Avcı",
		"description": "10 düşman öldür",
		"icon": "🎯",
		"condition_type": "total_kills",
		"target": 10
	},
	"killer_100": {
		"name": "Katil",
		"description": "100 düşman öldür",
		"icon": "💀",
		"condition_type": "total_kills",
		"target": 100
	},
	"wave_5": {
		"name": "Hayatta Kalan",
		"description": "5. dalgaya ulaş",
		"icon": "🌊",
		"condition_type": "best_wave",
		"target": 5
	},
	"wave_10": {
		"name": "Dalga Ustası",
		"description": "10. dalgaya ulaş",
		"icon": "⚓",
		"condition_type": "best_wave",
		"target": 10
	},
	"wave_20": {
		"name": "Efsane",
		"description": "20. dalgaya ulaş",
		"icon": "👑",
		"condition_type": "best_wave",
		"target": 20
	},
	"games_5": {
		"name": "Sadık Oyuncu",
		"description": "5 oyun tamamla",
		"icon": "🎮",
		"condition_type": "total_games",
		"target": 5
	},
	"first_purchase": {
		"name": "Destekçi",
		"description": "İlk elmas satın al",
		"icon": "💎",
		"condition_type": "gems_earned_total",
		"target": 1
	}
}

func _ready() -> void:
	pass

func get_all() -> Dictionary:
	return ACHIEVEMENTS.duplicate()

func get_achievement(achievement_id: String) -> Dictionary:
	return ACHIEVEMENTS.get(achievement_id, {})

func check_all() -> void:
	if not has_node("/root/GameData"):
		return
	var gd = get_node("/root/GameData")
	for aid in ACHIEVEMENTS:
		if aid in gd.achievement_unlocked:
			continue
		var a: Dictionary = ACHIEVEMENTS[aid]
		var cond: String = a.get("condition_type", "")
		var target: int = int(a.get("target", 0))
		var current: int = 0
		match cond:
			"total_kills":
				current = gd.total_kills
			"best_wave":
				current = gd.best_wave
			"total_games":
				current = gd.total_games
			"gems_earned_total":
				current = gd.gems + _sum_spent_gems(gd)
			_:
				continue
		if current >= target:
			_unlock(gd, aid, a)

func _sum_spent_gems(gd: Node) -> int:
	var sum := 0
	for e in gd.gem_spend_log:
		if e is Dictionary:
			sum += int(e.get("amount", 0))
	return sum

func _unlock(gd: Node, achievement_id: String, data: Dictionary) -> void:
	if achievement_id in gd.achievement_unlocked:
		return
	gd.achievement_unlocked.append(achievement_id)
	gd.save_data()
	achievement_unlocked.emit(achievement_id, data)

func is_unlocked(achievement_id: String) -> bool:
	if not has_node("/root/GameData"):
		return false
	return achievement_id in get_node("/root/GameData").achievement_unlocked

func get_progress(achievement_id: String) -> Dictionary:
	var a := get_achievement(achievement_id)
	if a.is_empty():
		return {}
	if not has_node("/root/GameData"):
		return {"current": 0, "target": a.get("target", 0), "unlocked": false}
	var gd = get_node("/root/GameData")
	var cond: String = a.get("condition_type", "")
	var target: int = int(a.get("target", 0))
	var current: int = 0
	match cond:
		"total_kills":
			current = gd.total_kills
		"best_wave":
			current = gd.best_wave
		"total_games":
			current = gd.total_games
		"gems_earned_total":
			current = gd.gems + _sum_spent_gems(gd)
	return {"current": current, "target": target, "unlocked": achievement_id in gd.achievement_unlocked}
