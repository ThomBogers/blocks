extends Spatial

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
onready var player = get_node("./Player")
onready var threadpool = get_node("../Threadpool")

var CONSTANTS = load("res://src/util/constants.gd")
var EQUIPMENT = load("res://src/player/Equipment.gd")
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
	_timer.set_wait_time(.5)
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

	var hitDirection
	if type != EQUIPMENT.TYPES.ARM:
		hitDirection = Vector3(collision.normal.x*(CONSTANTS.CUBESIZE/2.0), collision.normal.y*(CONSTANTS.CUBESIZE/2.0), collision.normal.z*(CONSTANTS.CUBESIZE/2.0))
	else:
		hitDirection = Vector3(-collision.normal.x*(CONSTANTS.CUBESIZE/2.0), -collision.normal.y*(CONSTANTS.CUBESIZE/2.0), -collision.normal.z*(CONSTANTS.CUBESIZE/2.0))

	var x_pos = floor((collision.position.x+hitDirection.x)/CONSTANTS.CUBESIZE)
	var z_pos = floor((collision.position.z+hitDirection.z)/CONSTANTS.CUBESIZE)
	var y_pos = floor((collision.position.y+hitDirection.y)/CONSTANTS.CUBESIZE) + 1

	var x_chunk = floor(x_pos/CONSTANTS.CHUNKSIZE.x)
	var z_chunk = floor(z_pos/CONSTANTS.CHUNKSIZE.z)
	var y_chunk = floor(y_pos/CONSTANTS.CHUNKSIZE.y)

	var chunk_x_pos = x_pos - x_chunk * CONSTANTS.CHUNKSIZE.x
	var chunk_z_pos = z_pos - z_chunk * CONSTANTS.CHUNKSIZE.z
	var chunk_y_pos = y_pos - y_chunk * CONSTANTS.CHUNKSIZE.y

	var key = str(x_chunk)+":"+str(y_chunk)+":"+str(z_chunk)

	var chunk = _get_chunk(key)
	if chunk:
		chunk.hit(chunk_x_pos, chunk_z_pos, chunk_y_pos, type, origin)

func _draw_surround():
	var _worldseed = randi()
	var current_chunk = _get_player_chunk_loc()
	var id = 0

	for x in range(floor(-CONSTANTS.WORLDSIZE.x/2), ceil(CONSTANTS.WORLDSIZE.x/2)):
		for z in range(floor(-CONSTANTS.WORLDSIZE.z/2), ceil(CONSTANTS.WORLDSIZE.z/2)):
			for y in range(floor(-CONSTANTS.WORLDSIZE.y/2),ceil(CONSTANTS.WORLDSIZE.y/2)):
				var key = str(current_chunk.x+x)+":"+str(current_chunk.y+y)+":"+str(current_chunk.z+z)
				if not chunk_dict.has(key):
					var offset = Vector3(current_chunk.x+x, current_chunk.y+y, current_chunk.z+z)
					var chunk = Chunk.instance()
					chunk.init(id, offset, _worldseed)
					id+=1
					add_child(chunk)
					chunk_dict[key] = weakref(chunk)
					# ref_dict[key] = weakref(chunk)


func _get_chunk(key):
	if not chunk_dict.get(key):
		logMessage('chunk missing from dict id: ' + str(key))
		return

	if not chunk_dict.get(key).get_ref():
		logMessage('chunk ref free id: ' + str(key))
		return

	return chunk_dict.get(key).get_ref()

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
		var chunk = _get_chunk(key)

		if chunk && chunk.initialized:
			initialized = initialized + 1

	logMessage("chunk initialization status " + str(initialized) + " " + str(chunk_dict.size()) )
	return [initialized, chunk_dict.size()]

func _on_Timer_timeout():
	var clean_run = true

	for key in chunk_dict.keys():
		var chunk = _get_chunk(key)

		if not chunk:
			continue;

		if not chunk.clean || not chunk.initialized:
			clean_run = false
			_render_chunk_threaded(key, chunk)

	if clean_run:
		if !world_ready:
			logMessage("world ready")
			world_ready = true
			player.start()


func _render_chunk(key, chunk):
	logMessage("_render_chunk chunk: " + str(key))
	var thread = null
	chunk._render_mesh_thread(thread)
	chunk.clean = true

func _render_chunk_threaded(key, chunk):
	var thread = threadpool.get_thread()
	if(thread == null):
		return;
	logMessage("_render_chunk_threaded chunk: " + str(key))
	chunk.render(thread)