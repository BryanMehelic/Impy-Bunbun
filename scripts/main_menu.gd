extends MarginContainer
@onready var start_button: Button = $HBoxContainer/VBoxContainer/MenuOptions/TextureRect/start_button
var start

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_start_button_pressed() -> void: #connects buton press from start to marginContainer.
	get_tree().change_scene_to_file("res://Impy & BunBun/scenes/level_one.tscn") #worried about spamming clicks
