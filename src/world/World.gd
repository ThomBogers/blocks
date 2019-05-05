extends Spatial

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
onready var player = get_node("./Player")
onready var threadpool = get_node("../Threadpool")

var CONSTANTS = load("res://src/util/constants.gd")
var Chunk = preload("res://scenes/Chunk.tscn")

var _timer = null
var world_ready = false

var chunk_dict = Dictionary()


func logMessage(message: String):
	var name = self.get_script().get_path().get_file().replace('.gd', '')
	print( name, ": ", message)

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	logMessage("start")
	_timer = Timer.new()
	add_child(_timer)

	_timer.connect("timeout", self, "_on_Timer_timeout")
	_timer.set_wait_time(.2)
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

func hit(collision, type, origin):

	logMessage("collision, info " + str(collision))
	for key in chunk_dict.keys():
		var chunk = chunk_dict.get(key)
		chunk.hit(collision, type, origin)

func _draw_surround():
	var _worldseed = randi()
	var current_chunk = _get_player_chunk_loc()
	var id = 0

	for x in range(0, CONSTANTS.WORLDSIZE.x):
		for z in range(0, CONSTANTS.WORLDSIZE.z):
			for y in range(0,CONSTANTS.WORLDSIZE.y):
				var key = str(current_chunk.x+x)+":"+str(current_chunk.y+y)+":"+str(current_chunk.z+z)
				if not chunk_dict.has(key):
					var offset = Vector3(current_chunk.x+x, current_chunk.y+y, current_chunk.z+z)
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

func _get_chunks_initialized():
	var initialized = 0
	for key in chunk_dict.keys():
		var chunk = chunk_dict.get(key)
		if chunk.initialized:
			initialized = initialized + 1

	logMessage("chunk initialization status " + str(initialized) + " " + str(chunk_dict.size()) )
	return [initialized, chunk_dict.size()]

func _on_Timer_timeout():
	var clean_run = true

	for key in chunk_dict.keys():
		var chunk = chunk_dict.get(key)

		if not chunk.initialized:
			clean_run = false

		if not chunk.clean:
			logMessage("chunk: " + str(key) + " not clean")
			clean_run = false
			var thread = threadpool.get_thread()
			if(thread == null):
				return;
			chunk.render(thread)

	if clean_run:
		if !world_ready:
			logMessage("world ready")
			world_ready = true
			player.start()


