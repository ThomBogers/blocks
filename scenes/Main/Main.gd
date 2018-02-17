extends Spatial

# Load dependencies
var kubelet = preload("res://scenes/Kubelet/Kubelet.tscn")
var chunksize = 10

func _ready():
	# Render grid
	var size = 2.1

	for i in range(-chunksize, chunksize):
		for j in range(-chunksize, chunksize):
			for k in range(-chunksize, 0):
				var kube  = kubelet.instance()

				var xpos  = size * i
				var ypos  = size * k
				var zpos  = size * j
				var move  = Vector3(xpos, ypos, zpos)

				kube.translate(move)
				add_child(kube)
	pass


#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
