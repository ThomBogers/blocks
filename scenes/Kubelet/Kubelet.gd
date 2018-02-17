extends StaticBody

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
var health = 1
onready var kubelet = get_node(".")

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func hit():
	print("Got hit")
	health -= 1

	if health == 0:
		self.queue_free()

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
