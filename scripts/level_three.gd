extends Node2D

@onready var camera_2d: Camera2D = $Camera2D
@onready var impy: CharacterBody2D = $Impy
@onready var bun_bun: CharacterBody2D = $BunBun
var reset_pending: bool
var door
var ball
var ball_respawn_location
var target_count: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	door = $door
	ball = $ball_body
	ball_respawn_location = ball.global_position
	for child in get_children():
		if child.scene_file_path == "res://Impy & BunBun/scenes/target.tscn":
			target_count += 1
	EventBus.target_break.connect(_set_target_count)
	EventBus.spawn_ball.connect(_create_ball)
	EventBus.spawn_impy.connect(_create_impy)
	EventBus.spawn_bunbun.connect(_create_bunbun)
	EventBus.beat_level.connect(_beat_level)
	EventBus.reset_ball.connect(_reset_ball)

func _create_impy(spawn_pos):
	impy.global_position = spawn_pos
	
func _reset_ball():
	ball.global_position = ball_respawn_location
	
func _create_bunbun(spawn_pos):
	bun_bun.global_position = spawn_pos
	
func _create_ball(player_pos, scene_name, direction, vert_direction, facing):
	var scene = load(scene_name)
	var instance = scene.instantiate()
	ball = instance
	if vert_direction == 0:
		instance.global_position = player_pos - Vector2(0,5)
	else:
		if vert_direction == 1: #look down. want forward
			if facing == 1:
				instance.global_position = player_pos + Vector2(20,0)
			elif facing == -1:
				instance.global_position = player_pos - Vector2(20,0)
		else: #account for player facing and change +- accordingly
			if facing == 1:
				instance.global_position = player_pos - Vector2(20,0) #want pos behind
			if facing == -1:
				instance.global_position = player_pos + Vector2(20,0)
	add_child(instance)
	EventBus.launch_ball.emit(direction, vert_direction)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	if reset_pending:
		ball.sleeping = true
		ball.linear_velocity = Vector2.ZERO
		ball.angular_velocity = 0
		_reset_ball()
		ball.sleeping = false
		reset_pending = false


func _on_spikes_2_body_entered(body: Node2D) -> void:
	if (body.name == "ball_body"):
		reset_pending = true #need to wait for physics loop w/rigidbody
	elif body is CharacterBody2D:
		if body.name == "Impy":
			impy._die() 
		elif body.name == "BunBun":
			bun_bun._die()

func _set_target_count():
	target_count -= 1
	if target_count == 0:
		door._set_open()
				
func _beat_level():
	get_tree().quit() #change when more
