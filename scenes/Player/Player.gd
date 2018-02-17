extends Spatial

onready var camera = get_node("Camera")
var camera_move_vect = Vector3(0,0,0)
var camera_rotation_y  = 0
var camera_rotation_x  = 0
var look_vector = Vector2(0,0)

var raycast_from     = null
var raycast_to       = null
const ray_length     = 1000

func _ready():
	
	# Enable processing input
	set_process_input(true)
	
	pass

func _input(event):
	
	if event is InputEventMouseMotion:
		
		# TODO Misschien position van muis pakken, en dan de camera roteren van af basis orientatie ipv dit?
		#print("Movement", event, event.speed.x, " : ", event.speed.y)
		camera_rotation_x = -(event.speed.x / 10000)
		camera_rotation_y = -(event.speed.y / 10000)
		
	
	#if event.is_action_pressed("game_right"):
	#	camera_rotation = -0.1
	#elif event.is_action_released("game_right"):
	#	camera_rotation = 0
	#elif event.is_action_pressed("game_left"):
	#	camera_rotation = +0.1
	#elif event.is_action_released("game_left"):
	#	camera_rotation = 0
				
	if event.is_action_pressed("game_forward"):
		camera_move_vect.z = -1
	elif event.is_action_released("game_forward"):
		camera_move_vect.z = 0
		
	if event.is_action_pressed("game_back"):
		camera_move_vect.z = +1
	elif event.is_action_released("game_back"):
		camera_move_vect.z = 0
	
	if event.is_action_pressed("game_down"):
		camera_move_vect.y = -1
	elif event.is_action_released("game_down"):
		camera_move_vect.y = 0
	
	if event.is_action_pressed("game_up"):
		camera_move_vect.y = +1
	elif event.is_action_released("game_up"):
		camera_move_vect.y = 0
	
	# On click prepare raycast query to be executed in the physics loop
	if event.is_action_pressed("game_click"):
		var camera = get_node("Camera")
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
	
	camera.translate(camera_move_vect)
	camera.rotate_z(camera_rotation_y)
	camera.rotate_y(camera_rotation_x)
	pass
