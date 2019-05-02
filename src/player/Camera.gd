extends InterpolatedCamera

onready var viewport_size
onready var camera = get_node(".")
onready var player = get_node("..")
onready var shap   = get_node("../PlayerCollider")

const ray_length     = 1000

var raycast_from     = null
var raycast_to       = null
var raycast_type     = null

func _ready():
	get_tree().get_root().connect("size_changed", self, "set_viewport_size")
	set_viewport_size()

	camera.fov = 100

	pass

func set_viewport_size():
	viewport_size = get_viewport().get_visible_rect().size

func cast_ray(type):
	var screen_center = Vector2(viewport_size.x/2, viewport_size.y/2)
	raycast_from = camera.project_ray_origin(screen_center)
	raycast_to   = raycast_from + camera.project_ray_normal(screen_center) * ray_length
	raycast_type = type

func hit_ray(target, origin):
	target.collider.get_node("../../..").hit(target, raycast_type, origin)

func _physics_process(delta):
	if raycast_from != null && raycast_to != null:
		var space_state = get_world().get_direct_space_state()
		var result = space_state.intersect_ray(raycast_from, raycast_to, [self, camera, player, shap])
		if not result.empty():
			#Go from mesh in mesh instance to Geometry
			hit_ray(result, raycast_from)

		raycast_from = null
		raycast_to   = null
	pass