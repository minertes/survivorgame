# 🏢 LOBBY STATS MANAGER
# Lobi istatistik yöneticisi
class_name LobbyStatsManager
extends Node

# === STATS DATA ===
var stats: Dictionary = {
	"best_wave": 0,
	"total_kills": 0,
	"total_games": 0,
	"total_xp_earned": 0,
	"total_play_time": 0,
	"accuracy": 0.0,
	"survival_rate": 0.0
}

# === SIGNALS ===
signal stats_updated()
signal stat_changed(stat_name: String, old_value, new_value)

# === PUBLIC API ===

func set_stats(new_stats: Dictionary) -> void:
	for key in new_stats:
		if key in stats:
			var old_value = stats[key]
			stats[key] = new_stats[key]
			stat_changed.emit(key, old_value, new_stats[key])
	
	stats_updated.emit()

func get_stats() -> Dictionary:
	return stats.duplicate()

func update_stat(stat_name: String, value) -> void:
	if stat_name in stats:
		var old_value = stats[stat_name]
		stats[stat_name] = value
		stat_changed.emit(stat_name, old_value, value)
		stats_updated.emit()

func increment_stat(stat_name: String, amount = 1) -> void:
	if stat_name in stats:
		var old_value = stats[stat_name]
		if typeof(old_value) == TYPE_INT:
			stats[stat_name] += amount
			stat_changed.emit(stat_name, old_value, stats[stat_name])
			stats_updated.emit()
		elif typeof(old_value) == TYPE_FLOAT:
			stats[stat_name] += float(amount)
			stat_changed.emit(stat_name, old_value, stats[stat_name])
			stats_updated.emit()

func get_stat(stat_name: String):
	return stats.get(stat_name)

func get_best_wave() -> int:
	return stats.get("best_wave", 0)

func get_total_kills() -> int:
	return stats.get("total_kills", 0)

func get_total_games() -> int:
	return stats.get("total_games", 0)

func get_total_xp_earned() -> int:
	return stats.get("total_xp_earned", 0)

func get_total_play_time() -> int:
	return stats.get("total_play_time", 0)

func get_accuracy() -> float:
	return stats.get("accuracy", 0.0)

func get_survival_rate() -> float:
	return stats.get("survival_rate", 0.0)

func calculate_kd_ratio() -> float:
	var kills = stats.get("total_kills", 0)
	var games = stats.get("total_games", 1)
	return float(kills) / float(games)

func calculate_avg_wave() -> float:
	var best_wave = stats.get("best_wave", 0)
	var games = stats.get("total_games", 1)
	return float(best_wave) / float(games)

func calculate_avg_xp_per_game() -> float:
	var total_xp = stats.get("total_xp_earned", 0)
	var games = stats.get("total_games", 1)
	return float(total_xp) / float(games)

# === DEBUG ===

func print_debug_info() -> void:
	print("=== LobbyStatsManager ===")
	print("Best Wave: %d" % stats["best_wave"])
	print("Total Kills: %d" % stats["total_kills"])
	print("Total Games: %d" % stats["total_games"])
	print("Total XP Earned: %d" % stats["total_xp_earned"])
	print("Total Play Time: %d" % stats["total_play_time"])
	print("Accuracy: %.2f%%" % (stats["accuracy"] * 100))
	print("Survival Rate: %.2f%%" % (stats["survival_rate"] * 100))
	print("KD Ratio: %.2f" % calculate_kd_ratio())
	print("Average Wave: %.2f" % calculate_avg_wave())
	print("Average XP/Game: %.2f" % calculate_avg_xp_per_game())