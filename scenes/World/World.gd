extends Spatial

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

var Chunk = preload("res://scenes/World/Chunk.tscn")

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	var world_size = 5
	var seeds = Vector2(randf()/15, randf()/3)
	for x in range(world_size):
		for z in range(world_size):

			var offset = Vector3(x, 0, z)
			var chunk = Chunk.instance()
			chunk.init(offset, seeds)
			add_child(chunk)

	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
