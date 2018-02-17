extends InterpolatedCamera

onready var viewport_size
onready var camera = get_node(".")

var raycast_from     = null
var raycast_to       = null
const ray_length     = 1000


func _ready():
	get_tree().get_root().connect("size_changed", self, "set_viewport_size")
	set_viewport_size()
	pass

func set_viewport_size():
	viewport_size = get_viewport().get_visible_rect().size

func cast_ray():
	var screen_center= Vector2(viewport_size.x/2, viewport_size.y/2)
	raycast_from = camera.project_ray_origin(screen_center)
	raycast_to   = raycast_from + camera.project_ray_normal(screen_center) * ray_length

func _physics_process(delta):
	if raycast_from != null && raycast_to != null:
		var space_state = get_world().get_direct_space_state()
		var result = space_state.intersect_ray(raycast_from, raycast_to, [self])
		if not result.empty():
			result.collider.hit()

		raycast_from = null
		raycast_to   = null
	pass
#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
