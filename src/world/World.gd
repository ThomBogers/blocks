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

var _worldseed = randi()

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

	# _draw_surround()
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
	var current_chunk = _get_player_chunk_loc()
	var id = 0


	var x_start = current_chunk.x + floor(-CONSTANTS.WORLDSIZE.x/2)
	var x_end = current_chunk.x + ceil(CONSTANTS.WORLDSIZE.x/2)

	var z_start = current_chunk.z + floor(-CONSTANTS.WORLDSIZE.z/2)
	var z_end = current_chunk.z + ceil(CONSTANTS.WORLDSIZE.z/2)

	var y_start = current_chunk.y + floor(-CONSTANTS.WORLDSIZE.y/2)
	var y_end

	if y_start < 0:
		y_end = current_chunk.y + ceil(CONSTANTS.WORLDSIZE.y) - y_start
	else:
		y_end = current_chunk.y + ceil(CONSTANTS.WORLDSIZE.y)

	for x in range(x_start, x_end):
		for z in range(z_start,z_end):
			for y in range(y_start,y_end):
				if y < 0:
					continue;

				var key = str(x)+":"+str(y)+":"+str(z)
				if not chunk_dict.has(key):
					var offset = Vector3(x, y, z)
					var chunk = Chunk.instance()
					chunk.init(id, offset, _worldseed)
					id+=1
					add_child(chunk)
					chunk_dict[key] = weakref(chunk)
					# ref_dict[key] = weakref(chunk)
	
	var removeKeys = []

	for key in chunk_dict.keys():
		var chunk = _get_chunk(key)

		if chunk.offset.x < x_start || chunk.offset.x > x_end:
			removeKeys.append(key)
		if chunk.offset.z < z_start || chunk.offset.z > z_end:
			removeKeys.append(key)
		if chunk.offset.y < y_start || chunk.offset.y > y_end:
			removeKeys.append(key)
	
	for key in removeKeys:
		_free_chunk(key)



func _free_chunk(key):
	var chunk = _get_chunk(key)
	if chunk:
		chunk_dict.erase(key)
		self.remove_child(chunk)
		chunk.call_deferred("free")

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

	_draw_surround()

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