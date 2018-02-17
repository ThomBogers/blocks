extends Spatial

onready var camera = get_node("Camera")
onready var player = get_node(".")

var movement_vector = Vector3(0,0,0)

var view_sensitivity = 1
var yaw   = 45
var pitch = 45

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

	# Enable processing input
	set_process_input(true)

	pass

func _input(event):

	if event is InputEventMouseMotion:
		var relative_x = event.relative.x
		var relative_y = event.relative.y

		yaw   = fmod(yaw - relative_x * view_sensitivity, 360)
		pitch = max(min(pitch - relative_y * view_sensitivity, 90), -90)
		player.set_rotation(Vector3(deg2rad(pitch), deg2rad(yaw),0 ))


	if event.is_action_pressed("game_right"):
		movement_vector.x = +1
	elif event.is_action_released("game_right"):
		movement_vector.x = 0

	if event.is_action_pressed("game_left"):
		movement_vector.x = -1
	elif event.is_action_released("game_left"):
		movement_vector.x = 0

	if event.is_action_pressed("game_forward"):
		movement_vector.z = -1
	elif event.is_action_released("game_forward"):
		movement_vector.z = 0

	if event.is_action_pressed("game_back"):
		movement_vector.z = +1
	elif event.is_action_released("game_back"):
		movement_vector.z = 0

	if event.is_action_pressed("game_down"):
		movement_vector.y = -1
	elif event.is_action_released("game_down"):
		movement_vector.y = 0

	if event.is_action_pressed("game_up"):
		movement_vector.y = +1
	elif event.is_action_released("game_up"):
		movement_vector.y = 0

	# On click prepare raycast query to be executed in the physics loop
	# raycast is based on center of screen
	if event.is_action_pressed("game_click"):
		camera.cast_ray()


func _process(delta):

	player.translate(movement_vector)
	pass
