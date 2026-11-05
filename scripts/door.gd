extends Area2D
var open: bool
var body_count: int
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	open = false
	body_count = 0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if body_count == 2 && open == true:
		EventBus.emit_signal("beat_level")


func _on_body_entered(_body: CharacterBody2D) -> void:
	body_count += 1
	if (open):
		pass
		
func _on_body_exited(_body: CharacterBody2D) -> void:
	body_count -= 1
	
func _set_open():
	open = true
	
