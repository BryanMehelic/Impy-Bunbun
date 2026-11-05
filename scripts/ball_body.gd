extends RigidBody2D
var launch_vector: Vector2 = Vector2(0,0)
@export var launch_scalar: float
@onready var launch_timer: Timer = $launch_timer
var spawn_location

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	spawn_location = self.global_position
	EventBus.launch_ball.connect(_launch_ball)

func _integrate_forces(_state: PhysicsDirectBodyState2D) -> void:
	if launch_vector != Vector2(0,0):
		apply_central_impulse(launch_vector)
		launch_vector = Vector2(0,0)

func _yes_catch(char_name):
	print("yes can catch")
	if char_name == "Impy":
		EventBus.here_item.emit(self.scene_file_path, launch_vector)
	elif char_name == "BunBun":
		EventBus.here_item_bunbun.emit(self.scene_file_path, linear_velocity)
	queue_free()

func _launch_ball(x, y):
	launch_vector = Vector2(x, y) * launch_scalar
	launch_timer.start()
	gravity_scale = 0.0
	await launch_timer.timeout
	gravity_scale = 1.0


func _on_grabbox_area_entered(_area: Area2D) -> void:
	EventBus.try_catch.connect(_yes_catch) 


func _on_grabbox_area_exited(_area: Area2D) -> void:
	EventBus.try_catch.disconnect(_yes_catch)
