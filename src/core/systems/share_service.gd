# Faz 5.4 – Basit sosyal: skor/ekran paylaşımı
# Pano kopyalama; mobilde ileride native paylaşım (share sheet) eklenebilir.
extends Node

signal share_completed(success: bool)

func share_score(wave: int, kills: int) -> void:
	var text := "Survivor oyununda Dalga %d'e ulaştım, %d düşman öldürdüm! 🎮" % [wave, kills]
	DisplayServer.clipboard_set(text)
	if has_node("/root/GameData") and GameData.has_method("update_daily_quest_progress"):
		GameData.update_daily_quest_progress("share_score", 1)
	share_completed.emit(true)

func share_score_text(custom_text: String) -> void:
	if custom_text.is_empty():
		share_completed.emit(false)
		return
	DisplayServer.clipboard_set(custom_text)
	share_completed.emit(true)

func get_share_message(wave: int, kills: int) -> String:
	return "Survivor oyununda Dalga %d'e ulaştım, %d düşman öldürdüm! 🎮" % [wave, kills]
