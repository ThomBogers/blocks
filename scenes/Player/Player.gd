extends Spatial


const GRAVITY    = -9.8/2
const SPEED_JUMP = 2
const SPEED_WALK = 15
const SPEED_AIR  = 15

onready var camera = get_node("Camera")
onready var player = get_node(".")

var on_floor = false

var movement_vector = Vector3(0,0,0)
var yaw   = 45
var pitch = 45
const view_sensitivity = 1

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

	if on_floor && event.is_action_pressed("game_up"):
		movement_vector.y = SPEED_JUMP
		on_floor = false

	# On click prepare raycast query to be executed in the physics loop
	# raycast is based on center of screen
	if event.is_action_pressed("game_click"):
		camera.cast_ray()

	if event.is_action_pressed("game_quit"):
		get_tree().quit()



func _physics_process(delta):
	# Kinematicbody.move_and_collide moves relative to the world, not the object itself.
	# The movement vector is rotated before being applied, this makes movement follow the camera direction
	# Horizontal and vertical movement is hanled seperately because:
	#	- We want to ignore rotation for direction of vertical movement
	#	- Vertical movement causes collision while walking (camera angle looking into the floor), slowing the movement
	_h_move(delta)
	_v_move(delta)

func _h_move(delta):
	var movement = Vector3(movement_vector.x, 0, movement_vector.z).normalized()
	movement = movement.rotated(Vector3(0,1,0),deg2rad(yaw))

	if on_floor:
		movement = movement * SPEED_WALK * delta
	else:
		movement = movement * SPEED_AIR * delta
	player.move_and_collide(movement)

func _v_move(delta):
	# Apply gravity every tick
	movement_vector.y = movement_vector.y + delta*GRAVITY

	var movement = Vector3(0, movement_vector.y, 0)
	var collision = player.move_and_collide(movement)

	if collision != null and collision.normal.y != 0:
		on_floor = true
		movement_vector.y = 0

#func _process(delta):
#	pass