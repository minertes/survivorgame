# Faz 3.3.3 – Çökme raporlama (production'da crash log toplama)
# Hata mesajını user://logs/crash_*.txt olarak yazar; isteğe bağlı analitik event.
extends Node

const LOG_DIR := "user://logs/"
const PREFIX := "crash_"

func _ready() -> void:
	var dir = DirAccess.open("user://")
	if dir and not dir.dir_exists("logs"):
		dir.make_dir("logs")


# Manuel çağrı: oyun içi yakalanan hatalar veya kritik durumlar
func log_crash(message: String, stack: String = "") -> void:
	var ts := Time.get_datetime_string_from_system().replace(":", "-").replace(" ", "_")
	var path := LOG_DIR + PREFIX + ts + ".txt"
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_line("Crash report: " + ts)
		f.store_line(message)
		if not stack.is_empty():
			f.store_line("---")
			f.store_line(stack)
		f.store_line("Platform: " + OS.get_name())
		f.store_line("Version: 1.0.0")
		f.close()
	if has_node("/root/AnalyticsService"):
		var analytics = get_node("/root/AnalyticsService")
		if analytics.has_method("log_event"):
			analytics.log_event("crash", {"message": message, "platform": OS.get_name()})
