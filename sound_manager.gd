extends Node

# Tüm sesler kod ile üretilir, harici dosya gerekmez

func play_shoot() -> void:
	_tone(380.0, 0.07, 0.22)

func play_enemy_die() -> void:
	_tone(110.0, 0.20, 0.40)
	get_tree().create_timer(0.06).timeout.connect(func(): _tone(80.0, 0.15, 0.30))

func play_xp_collect() -> void:
	_tone(880.0, 0.08, 0.25)

func play_hurt() -> void:
	_tone(160.0, 0.18, 0.50)

func play_level_up() -> void:
	var notes := [523.25, 659.25, 783.99, 1046.5]
	for i in notes.size():
		get_tree().create_timer(float(i) * 0.11).timeout.connect(
			func(): _tone(notes[i], 0.20, 0.32)
		)

func _tone(freq: float, duration: float, volume: float) -> void:
	if not GameState.sound_enabled:
		return
	var player := AudioStreamPlayer.new()
	add_child(player)

	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 22050.0
	gen.buffer_length = duration + 0.1
	player.stream = gen
	player.play()

	var pb := player.get_stream_playback() as AudioStreamGeneratorPlayback
	if pb == null:
		player.queue_free()
		return

	var frames := int(gen.mix_rate * duration)
	for i in frames:
		var t := float(i) / gen.mix_rate
		var fade := 1.0 - (t / duration)
		var sample := sin(TAU * freq * t) * volume * fade
		pb.push_frame(Vector2(sample, sample))

	get_tree().create_timer(duration + 0.25).timeout.connect(player.queue_free)
