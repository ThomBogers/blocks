extends Spatial

# Load dependencies
var kubelet = preload("res://scenes/Kubelet/Kubelet.tscn")


func _ready():	
	# Render grid
	for i in range(20):
		for j in range(20):
			var kube  = kubelet.instance()
			
			
			var size = 2.1
			var xpos  = size * i
			var zpos  = size * j 
			var move  = Vector3(xpos, 0, zpos)
			
			kube.translate(move)		
			add_child(kube)
		
	pass


func _process(delta):
	#var camera = get_node("Camera")
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
	
	pass
