extends Area2D
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var timer: Timer = $Timer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _on_body_entered(body: Node2D) -> void:
	if (body.name == "ball_body"):
		EventBus.emit_signal("target_break")
		audio_stream_player.play()
		timer.start()

	elif(body is CharacterBody2D):
		EventBus.emit_signal("target_break")
		audio_stream_player.play()
		timer.start()



func _on_timer_timeout() -> void:
	queue_free()
