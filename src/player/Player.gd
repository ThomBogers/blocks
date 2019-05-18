extends Spatial

var CONSTANTS = load("res://src/util/constants.gd")

const GRAVITY     = -9.81
const SPEED_JUMP = 2.45
const SPEED_WALK = 60
const SPEED_AIR  = 180

const FLYING  = 0
const WALKING = 1
const MAX_JUMPS = 2
var MODE = FLYING

onready var camera = get_node("Camera")
onready var player = get_node(".")
onready var collider = get_node("PlayerCollider")
onready var light: OmniLight = get_node("Light")

onready var inGameUI: Control = get_node("InGameUI")
onready var inGameMenu: Control = get_node("InGameMenu")

onready var persistentState = get_node("../../PersistentState")

var movement_vector = Vector3(0,0,0)
var jumps = 0
var yaw   = 45
var pitch = 45
const view_sensitivity = 1

var EQUIPMENT = load("res://src/player/Equipment.gd")

var initialCameraPosition;
var cameraOffset = Vector3(0,0,0);

var started = false

enum ControlMode {
	play,
	menu,
}

var currentControlMode

func logMessage(message: String):
	var name = self.get_script().get_path().get_file().replace('.gd', '')
	print( name, ": ", message)

func start():
	if started:
		return

	started = true
	set_process_input(true)
	_setControlModePlay()
	_setWalkMode()
	logMessage("started")

func _setWalkMode():
	logMessage("switching to walk mode")
	MODE = WALKING
	player.set_collision_layer_bit(0,1)
	player.set_collision_mask_bit(0,1)

func _setFlyMode():
	logMessage("switching to fly mode")
	movement_vector.y = 0
	MODE = FLYING
	player.set_collision_layer_bit(0,0)
	player.set_collision_mask_bit(0,0)

func _setControlModeMenu():
	logMessage("switching to control mode: menu")
	currentControlMode = ControlMode.menu
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	inGameUI.visible = false
	inGameMenu.visible = true

func _setControlModePlay():
	logMessage("switching to control mode: play")
	currentControlMode = ControlMode.play
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	inGameUI.visible = true
	inGameMenu.visible = false

func _ready():
	collider.shape.height = CONSTANTS.CUBESIZE;
	initialCameraPosition = camera.translation
	
	var playerstate = persistentState.loadPlayerState()
	if playerstate:
		self.translation = playerstate.get('position')
		pitch = playerstate.get('pitch')
		yaw = playerstate.get('yaw')
		camera.set_rotation(Vector3(deg2rad(pitch), 0,0 ))
		player.set_rotation(Vector3(0,deg2rad(yaw),0 ))

func _input(event):
	if currentControlMode == ControlMode.play:
		_handlePlayModeInput(event)
	elif currentControlMode == ControlMode.menu:
		_handleMenuModeInput(event)

func _handleMenuModeInput(event):
	if event.is_action_pressed("escape"):
		_setControlModePlay();

func _on_saveState_pressed():
	logMessage("Save state!")
	persistentState.savePlayerState(self.translation, self.rotation, pitch, yaw);

func _handlePlayModeInput(event):

	if event.is_action_pressed("escape"):
		_setControlModeMenu();

	if event.is_action_pressed("zoom_in"):
		cameraOffset.z = cameraOffset.z - 10;
		if cameraOffset.z < 0:
			cameraOffset.z = 0

		camera.translation = initialCameraPosition + cameraOffset

	if event.is_action_pressed("zoom_out"):
		cameraOffset.z = cameraOffset.z + 10;
		if cameraOffset.z > 300:
			cameraOffset.z = 300
		camera.translation = initialCameraPosition + cameraOffset

	if event is InputEventMouseMotion:
		var relative_x = event.relative.x
		var relative_y = event.relative.y

		yaw   = fmod(yaw - relative_x * view_sensitivity, 360)
		pitch = max(min(pitch - relative_y * view_sensitivity, 90), -90)

		camera.set_rotation(Vector3(deg2rad(pitch), 0,0 ))
		player.set_rotation(Vector3(0,deg2rad(yaw),0 ))

	if event.is_action_pressed("game_godmode"):
		if MODE == FLYING:
			_setWalkMode()
		else:
			_setFlyMode()


	if event.is_action_pressed("toggle_light"):
		if light.light_energy == 0:
			light.light_energy = 1
		else:
			light.light_energy = 0

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

