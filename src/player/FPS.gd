extends Label

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
	self.set_text("FPS: " + str(Engine.get_frames_per_second()))
	pass
