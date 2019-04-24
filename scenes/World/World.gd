extends Spatial

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
onready var player = get_node("./Player")
onready var threadpool = get_node("../Threadpool")

var CONSTANTS = load("res://scenes/Util/constants.gd")
var Chunk = preload("res://scenes/World/Chunk.tscn")

var _timer = null

var chunk_dict = Dictionary()


func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	_timer = Timer.new()
	add_child(_timer)

	_timer.connect("timeout", self, "_on_Timer_timeout")
	_timer.set_wait_time(1.0)
	_timer.set_one_shot(false) # Make sure it loops
	_timer.start()

	player.translate(Vector3(
		CONSTANTS.CUBESIZE*CONSTANTS.CHUNKSIZE.x/2,
		CONSTANTS.CUBESIZE*CONSTANTS.CHUNKSIZE.y/2,
		CONSTANTS.CUBESIZE*CONSTANTS.CHUNKSIZE.z/2
		)
	)

	_draw_surround()
	pass

func _draw_surround():
	var _worldseed = randi()
	var current_chunk = _get_player_chunk_loc()
	var id = 0

	for x in range(-CONSTANTS.WORLDRADIUS, CONSTANTS.WORLDRADIUS):
		for z in range(-CONSTANTS.WORLDRADIUS, CONSTANTS.WORLDRADIUS):
			var key = str(current_chunk.x+x)+":"+str(current_chunk.z+z)
			if not chunk_dict.has(key):
				var offset = Vector3(current_chunk.x+x, 0, current_chunk.z+z)
				var chunk = Chunk.instance()
				chunk.init(id, offset, _worldseed)
				id+=1
				add_child(chunk)
				chunk_dict[key] = chunk


func _get_player_chunk_loc():
	var location = player.translation

	var current_chunk = Vector3(
		floor(location.x/(CONSTANTS.CUBESIZE*CONSTANTS.CHUNKSIZE.x)),
		floor(location.y/(CONSTANTS.CUBESIZE*CONSTANTS.CHUNKSIZE.y)),
		floor(location.z/(CONSTANTS.CUBESIZE*CONSTANTS.CHUNKSIZE.z))
	)

	return current_chunk

func _on_Timer_timeout():
	for key in chunk_dict.keys():
		var chunk = chunk_dict.get(key)
		if not chunk.clean:
			var thread = threadpool.get_thread()
			if(thread == null):
				return;
			chunk.render(thread)

