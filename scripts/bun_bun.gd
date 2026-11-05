extends CharacterBody2D

@onready var launch_timer: Timer = $launch_timer
var holding_item: bool
var item_scene_name
var can_grab
var facing: float
var spawn_location
@onready var interact_collision: CollisionShape2D = $interact_box/interact_collision
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var jump: AudioStreamPlayer = $jump
@onready var die: AudioStreamPlayer = $die
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0
var direction
var vert_direction
var launch_vector = Vector2(0,0)
@export var bounce_launch: Vector2
@export var jump_gravity: Vector2
@export var reg_gravity: Vector2
var launch_y_multiplier: float = 1.0
var launch_x_multiplier: float = 1.0

func _ready() -> void:
	spawn_location = self.global_position
	EventBus.here_item_bunbun.connect(_catch_success) #issue is always lisstens...
	
func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed('reload'):
		get_tree().reload_current_scene()
	if launch_vector != Vector2(0,0):
		velocity.x = launch_vector.x #adjust so it doesn't match
		velocity.y = launch_vector.y #cuz timer before it sets to 0

		#may want to change grav & all to not activate if launch vector is on
	# Add the gravity.
	if not is_on_floor():
		if velocity.y < 0: #when going up
			velocity += reg_gravity * delta * launch_y_multiplier
		elif velocity.y > 0:
			velocity += reg_gravity * 1.5 * delta * launch_y_multiplier
		else: 
			velocity.y += 1 * launch_y_multiplier #added so not stuck in air when spawned in

	# Handle jump.
	if Input.is_action_just_pressed("bunbun_jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		jump.play()


	direction = Input.get_axis("bunbun_a", "bunbun_d")
	vert_direction = Input.get_axis("bunbun_w", "bunbun_s")
	if direction:
		animated_sprite_2d.flip_h = (direction < 0)
		facing = direction
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	if Input.is_action_just_pressed("bunbun_interact") && holding_item:
		if item_scene_name == "res://Impy & BunBun/scenes/ball_body.tscn":
			EventBus.spawn_ball.emit(self.global_position, item_scene_name, direction, vert_direction, facing)
			holding_item = false
			item_scene_name = null
			
	if can_grab && not holding_item && Input.is_action_just_pressed("bunbun_interact"):
		_catch_attempt()

	
	move_and_slide()
	
func _catch_attempt():
	EventBus.try_catch.emit(self.name)

func _catch_success(emitter, ball_velocity):
	item_scene_name = emitter
	holding_item = true
	launch_vector = ball_velocity
	if launch_vector != Vector2(0,0):
		audio_stream_player.play()
		launch_timer.start()
		
		await launch_timer.timeout
		launch_vector = Vector2(0,0)


func _on_interact_box_area_entered(_area: Area2D) -> void:
	can_grab = true


func _on_interact_box_area_exited(_area: Area2D) -> void:
	can_grab = false


func _on_interact_box_body_entered(_body: CharacterBody2D) -> void:
	EventBus.try_catch.connect(_yes_catch)
	EventBus.bounce.connect(_bounce)

func _on_interact_box_body_exited(_body: CharacterBody2D) -> void:
	EventBus.try_catch.disconnect(_yes_catch)
	EventBus.bounce.disconnect(_bounce)
	
func _yes_catch(char_name):
	if char_name == "Impy":
		if vert_direction == 0 && direction != 0:
			launch_vector = Vector2(direction, -0.5) * 700
		else:
			launch_vector = Vector2(direction, vert_direction) * 700 
		if launch_vector != Vector2(0,0):
			audio_stream_player.play()
			launch_timer.start() #shouldn't overlap
			await launch_timer.timeout
			launch_vector = Vector2(0,0)
			
func _bounce():
	launch_y_multiplier = 0.1 #this changes jump grav
	launch_timer.start() #shouldn't overlap
	await launch_timer.timeout
	launch_y_multiplier = 1.0

func _die():
	die.play()
	_on_die_finished()
	collision_shape_2d.set_deferred("disabled", true)
	interact_collision.set_deferred("disabled", true)
	call_deferred("_respawn")
	
	
	
func _respawn():
	EventBus.spawn_bunbun.emit(spawn_location)
	collision_shape_2d.set_deferred("disabled", false)
	interact_collision.set_deferred("disabled", false)


func _on_die_finished() -> void:
	return
