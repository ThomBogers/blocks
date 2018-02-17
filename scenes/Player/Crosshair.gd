extends TextureRect

onready var crosshair = get_node(".")
# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
		
	var viewport_size = get_viewport().get_visible_rect().size
	var crosshair_size = crosshair.get_rect().size
	
	crosshair.rect_position.x = (viewport_size.x / 2) - (crosshair_size.x /2 * crosshair.rect_scale.x)
	crosshair.rect_position.y = (viewport_size.y / 2) - (crosshair_size.y /2 * crosshair.rect_scale.y)
	
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
