extends CharacterBody2D


@export var SPEED: float = 300.0
@export var JUMP_VELOCITY: float = -400.0
@export var grav: Vector2 = Vector2(0.0, 980.0)
@export var jump_grav: Vector2 = Vector2(0.0, 400.0)
@export var max_vel: Vector2
@export var air_resistance: float = 0.5
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
var is_cube: bool = false
var can_coyote_jump: bool = true
var can_double_jump: bool = true
@onready var cube_hitbox: CollisionShape2D = $Area2D/cube_hitbox
var facing: float #1.0 if face right, -1.0 if left
@onready var cube_box_small: CollisionShape2D = $cube_box_small
@onready var coyote_timer: Timer = $coyote_timer
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var interact_collision: CollisionShape2D = $interact_box/interact_collision
@onready var jump_1: AudioStreamPlayer = $jump_1
@onready var jump_2: AudioStreamPlayer = $jump_2
@onready var die: AudioStreamPlayer = $die



var holding_item: bool = false #ready in level will assign t/f
var item_scene_name
var can_grab: bool
var direction: float = 0.0 #starting at 0
var vert_direction
var spawn_location

func _ready() -> void:
	spawn_location = self.global_position
	cube_hitbox.disabled = true
	cube_box_small.disabled = true
	EventBus.here_item.connect(_catch_success)

func _physics_process(delta: float) -> void:
	
	if is_cube:
		velocity.y = 0
		if Input.is_action_pressed("impy_a"):
			velocity.x = -SPEED
		elif Input.is_action_pressed("impy_d"):
			velocity.x = SPEED
		else:
			velocity.x = 0
		if Input.is_action_just_pressed("impy_space"):
			velocity.y = JUMP_VELOCITY
			animated_sprite_2d.animation = "jump"
			jump_2.play()
			is_cube = false
			cube_hitbox.disabled = true
			cube_box_small.disabled = true
			collision_shape_2d.disabled = false
		
		move_and_slide()
		if is_cube:
			velocity.y = 0
		return

# Handle jump
	if Input.is_action_just_pressed("impy_space") and is_on_floor() && !is_cube: #
		velocity.y = JUMP_VELOCITY
		animated_sprite_2d.animation = "jump"
		jump_1.play()
		
	if not is_on_floor() && !is_cube:
		if coyote_timer.is_stopped(): #so it doesn't start every frame
			coyote_timer.start()
		if can_double_jump && !can_coyote_jump && Input.is_action_just_pressed("impy_space"):
			can_double_jump = false
			if randi_range(0,1) < 1:
				jump_1.play()
			else:
				jump_2.play()
			velocity.y = JUMP_VELOCITY #want to move so coyote jump doesn't eat double jump
		if direction: #TURNING IN AIR
			animated_sprite_2d.flip_h = (direction < 0)
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if velocity.y < 0: #grav when upward
			animated_sprite_2d.animation = "jump" #case for when jump while running tho makes ground jump redundant
			if Input.is_action_just_released("impy_space"): #cut velocity when jump released
				velocity /= 1.5
			if Input.is_action_pressed("impy_space"): #when jump is held
				velocity += jump_grav * delta
				
			else:
				velocity += grav * delta 
		elif velocity.y > 0 && !is_cube: #grav mul by a scalar when going down. may want to set a limit
			velocity += grav * 1.5 * delta
			animated_sprite_2d.animation = "fall"
			if can_coyote_jump && Input.is_action_just_pressed("impy_space"):
				velocity.y = JUMP_VELOCITY
				jump_1.play()
				can_double_jump = true
				
				
		else:
			velocity.y += 1 #added for spawning in so no freeze in air and falls down



#handle movement
	var direction_prev : float = direction #temp 
	direction = Input.get_axis("impy_a", "impy_d")
	vert_direction = Input.get_axis("impy_w", "impy_s")
		
	if is_on_floor() && !is_cube:
		can_coyote_jump = true
		can_double_jump = true
		if Input.is_action_pressed("impy_w"):
			animated_sprite_2d.animation = "look_up"
		elif Input.is_action_pressed("impy_s"):
			animated_sprite_2d.animation = "look_down"
		if direction:
			animated_sprite_2d.flip_h = (direction < 0) #true when -1, false when +1
			facing = direction 
			if facing != direction_prev && direction_prev != 0.0:
				animated_sprite_2d.animation = "turn_left"
			animated_sprite_2d.animation = "run"
			velocity.x = direction * SPEED
		elif !Input.is_action_pressed("impy_space") && !Input.is_action_pressed("impy_w") && !Input.is_action_pressed("impy_a") && !Input.is_action_pressed("impy_s") && !Input.is_action_pressed("impy_d"):
			velocity.x = move_toward(velocity.x, 0, SPEED)
			animated_sprite_2d.animation = "default"
	else: #air movement. maybe make an elif for not is_cube
		if direction: #I may want to adjust for if direction changes... keep momentum if hold forward
			velocity.x = direction * SPEED * air_resistance
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			
	if Input.is_action_just_pressed("impy_interact") && holding_item && !is_cube:
		if item_scene_name == "res://Impy & BunBun/scenes/ball_body.tscn":
			EventBus.spawn_ball.emit(self.global_position, item_scene_name, direction, vert_direction, facing)
			holding_item = false
			item_scene_name = null
		if item_scene_name == "res://Impy & BunBun/scenes/bun_bun.tscn":
			pass

	if can_grab && !is_cube && not holding_item && Input.is_action_just_pressed("impy_interact"):
		_catch_attempt()
		
	
	move_and_slide()
	
	

func _catch_attempt():
	EventBus.try_catch.emit(self.name)


func _catch_success(emitter, _launch_vector):
	item_scene_name = emitter
	holding_item = true

func _die():
	animated_sprite_2d.animation = "die"
	collision_shape_2d.set_deferred("disabled", true)
	cube_box_small.set_deferred("disabled", true)
	cube_hitbox.set_deferred("disabled", true)
	interact_collision.set_deferred("disabled", true)
	die.play()
	_on_die_finished()
	call_deferred("_respawn")
	
func _respawn():
	EventBus.spawn_impy.emit(spawn_location)
	collision_shape_2d.set_deferred("disabled", false)
	interact_collision.set_deferred("disabled", false)

func _on_interact_box_area_entered(_area: Area2D) -> void:
	can_grab = true

func _on_interact_box_area_exited(_area: Area2D) -> void:
	can_grab = false

func _on_interact_box_body_entered(body: CharacterBody2D) -> void:
	if body.name != "Impy":
	#if acts weird try if name is BunBun
		EventBus.try_catch.connect(_yes_catch)

func _on_interact_box_body_exited(body: CharacterBody2D) -> void:
	if body.name != "Impy": #needed cuz catches himself
		EventBus.try_catch.disconnect(_yes_catch)

func _yes_catch(char_name):
	if char_name == "BunBun":
		_cubify()
		
func _cubify():
	is_cube = true
	animated_sprite_2d.animation = "cube"
	velocity.y = 0
	cube_hitbox.disabled = false
	cube_box_small.disabled = false
	collision_shape_2d.disabled = true


func _on_area_2d_body_entered(body: CharacterBody2D) -> void:
	if body.name == "BunBun": #thinking this only emits when in box form
		EventBus.bounce.emit()
	else:
		return


func _on_coyote_timer_timeout() -> void:
	can_coyote_jump = false


func _on_die_finished() -> void:
	return
