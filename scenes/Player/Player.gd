extends Spatial

var CONSTANTS = load("res://scenes/Util/constants.gd")

const GRAVITY     = -9.81
const SPEED_JUMP = 2.45
const SPEED_WALK = 60
const SPEED_AIR  = 60

const FLYING  = 0
const WALKING = 1
const MAX_JUMPS = 2
var MODE = FLYING

onready var camera = get_node("Camera")
onready var player = get_node(".")
onready var collider = get_node("PlayerCollider")

var movement_vector = Vector3(0,0,0)
var jumps = 0
var yaw   = 45
var pitch = 45
const view_sensitivity = 1

var EQUIPMENT = load("res://scenes/Player/Equipment.gd")


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

	collider.shape.height = CONSTANTS.CUBESIZE;

	# Enable processing input
	set_process_input(true)

	pass

func _input(event):

	if event.is_action_pressed("game_godmode"):
		if MODE == FLYING:
			MODE = WALKING
			player.set_collision_layer_bit(0,1)
			player.set_collision_mask_bit(0,1)
		else:
			movement_vector.y = 0
			MODE = FLYING
			player.set_collision_layer_bit(0,0)
			player.set_collision_mask_bit(0,0)

	if event is InputEventMouseMotion:
		var relative_x = event.relative.x
		var relative_y = event.relative.y

		yaw   = fmod(yaw - relative_x * view_sensitivity, 360)
		pitch = max(min(pitch - relative_y * view_sensitivity, 90), -90)
		camera.set_rotation(Vector3(deg2rad(pitch), deg2rad(yaw),0 ))

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

	if MODE == WALKING:
		if event.is_action_pressed("game_up") && jumps < MAX_JUMPS:
			print("JUMP TIME")
			jumps = jumps + 1
			movement_vector.y = SPEED_JUMP
	else:
		if event.is_action_pressed("game_up"):
			movement_vector.y = SPEED_JUMP
		elif event.is_action_released("game_up"):
			movement_vector.y = 0

		if event.is_action_pressed("game_down"):
			movement_vector.y = -SPEED_JUMP
		elif event.is_action_released("game_down"):
			movement_vector.y = 0

	# On click prepare raycast query to be executed in the physics loop
	# raycast is based on center of screen
	if event.is_action_pressed("game_click_left"):
		camera.cast_ray(EQUIPMENT.TYPES.ARM)
	if event.is_action_pressed("game_click_right"):
		camera.cast_ray(EQUIPMENT.TYPES.DIRT)

	if event.is_action_pressed("game_quit"):
		get_tree().quit()



func _physics_process(delta):

	var movement
	if MODE == WALKING:
		movement_vector.y = movement_vector.y + delta*GRAVITY
		movement = movement_vector * SPEED_WALK
	else:
		movement = movement_vector * SPEED_AIR
		movement = movement.rotated(Vector3(1,0,0),deg2rad(pitch))

	movement = movement.rotated(Vector3(0,1,0),deg2rad(yaw))

	player.move_and_slide( movement, Vector3(0,1,0) )

	if player.get_slide_count():
		var collision = player.get_slide_collision(0);

		if collision.normal.y == 1:
			jumps=0
			movement_vector.y = 0


