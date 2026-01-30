extends Node

var cough_player: AudioStreamPlayer
var heartbeat_player: AudioStreamPlayer
var alert_player: AudioStreamPlayer
var swap_player: AudioStreamPlayer
var footstep_player: AudioStreamPlayer

func _ready():
	cough_player = AudioStreamPlayer.new()
	cough_player.bus = "SFX"
	add_child(cough_player)

	heartbeat_player = AudioStreamPlayer.new()
	heartbeat_player.bus = "SFX"
	add_child(heartbeat_player)

	alert_player = AudioStreamPlayer.new()
	alert_player.bus = "SFX"
	add_child(alert_player)

	swap_player = AudioStreamPlayer.new()
	swap_player.bus = "SFX"
	add_child(swap_player)

	footstep_player = AudioStreamPlayer.new()
	footstep_player.bus = "SFX"
	add_child(footstep_player)

func play_cough():
	if cough_player.stream:
		cough_player.play()

func play_heartbeat(intensity: float):
	if heartbeat_player.stream:
		heartbeat_player.pitch_scale = 1.0 + (1.0 - intensity) * 0.5
		if not heartbeat_player.playing:
			heartbeat_player.play()

func stop_heartbeat():
	if heartbeat_player.playing:
		heartbeat_player.stop()

func play_alert():
	if alert_player.stream:
		alert_player.play()

func play_filter_swap():
	if swap_player.stream:
		swap_player.play()

func play_footstep():
	if footstep_player.stream and not footstep_player.playing:
		footstep_player.play()

func set_cough_stream(stream: AudioStream):
	cough_player.stream = stream

func set_heartbeat_stream(stream: AudioStream):
	heartbeat_player.stream = stream

func set_alert_stream(stream: AudioStream):
	alert_player.stream = stream

func set_swap_stream(stream: AudioStream):
	swap_player.stream = stream

func set_footstep_stream(stream: AudioStream):
	footstep_player.stream = stream
