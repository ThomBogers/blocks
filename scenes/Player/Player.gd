extends Spatial

onready var camera = get_node("Camera")
onready var player = get_node(".")

var movement_vector = Vector3(0,0,0)

var view_sensitivity = 1
var yaw   = 45
var pitch = 45

var raycast_from     = null
var raycast_to       = null
const ray_length     = 1000

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	#var start = Vector3(90,0,0)
	#camera.rotate(start, 0)
	#player.rotate(start, 0)

	# Enable processing input
	set_process_input(true)
	
	pass

func _input(event):
	
	if event is InputEventMouseMotion:
		
		# TODO Misschien position van muis pakken, en dan de camera roteren van af basis orientatie ipv dit?
		var relative_x = event.relative.x
		var relative_y = event.relative.y
		
		yaw   = fmod(yaw - relative_x * view_sensitivity, 360)
		pitch = max(min(pitch - relative_y * view_sensitivity, 90), -90)
		print("Movement", yaw, " : ", pitch)
		player.set_rotation(Vector3(deg2rad(pitch), deg2rad(yaw),0 ))
		#var viewport = get_viewport()
		
		#viewport.warp_mouse(Vector2(viewport.get_visible_rect().size.x/2,viewport.get_visible_rect().size.y/2))

	
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
	if event.is_action_pressed("game_click"):
		
		raycast_from = camera.project_ray_origin(event.position)
		raycast_to   = raycast_from + camera.project_ray_normal(event.position) * ray_length
		
func _physics_process(delta):
	if raycast_from != null && raycast_to != null:
		var space_state = get_world().get_direct_space_state()
		var result = space_state.intersect_ray(raycast_from, raycast_to, [self])
		if not result.empty():
			result.collider.hit()
				
		raycast_from = null
		raycast_to   = null
	pass

func _process(delta):
	
	player.translate(movement_vector)
	pass
