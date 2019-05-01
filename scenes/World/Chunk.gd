extends StaticBody

var this = null

var meshInstance = null
var collInstance = null

export(Material) var material

var noise: OpenSimplexNoise = OpenSimplexNoise.new()

var EQUIPMENT = load("res://scenes/Player/Equipment.gd")
var CONSTANTS = load("res://scenes/Util/constants.gd")

var chunkoffset = Vector3(0,0,0)
var chunkId = 0

var cubesize
var chunksize
var chunk = []
var chunkInitialised = false
var clean = false

var COLOR_NONE = Color(0,0,0,0)
var carray = PoolColorArray([COLOR_NONE,COLOR_NONE,COLOR_NONE,COLOR_NONE])
var uvarray = []
var varray  = []

var xoffset
var zoffset
var yoffset

var should_ret  = false
var should_flip = false

# Seeds for terain gen
var worldseed
var thread

# type dict for checking noise distribution
var type_dict = Dictionary()

enum BLOCK_TYPE {
	AIR
	DIRT
	MINERAL
	BEDROCK
}

enum BLOCK_SIDE {
	TOP
	BOTTOM
	SIDE
}

func logMessage(message: String):
	print( "ID: ", chunkId, " ", message)

func init(id: int, offset: Vector3, _worldseed: int):
	cubesize = CONSTANTS.CUBESIZE
	chunksize = CONSTANTS.CHUNKSIZE

	chunkId = id
	chunkoffset = Vector3(offset.x*chunksize.x*cubesize, 0, offset.z*chunksize.z*cubesize)
	this = get_node(".")
	this.translate(chunkoffset)

	meshInstance = get_node("CollisionShape/MeshInstance")
	collInstance = get_node("CollisionShape")
	worldseed = _worldseed

func hit(collision, type, origin):

	logMessage("Collistion: " + str(collision))

	# Create position relative to chunk position
	var relPosition = Vector3(collision.position.x-chunkoffset.x, collision.position.y-chunkoffset.y, collision.position.z-chunkoffset.z)
	logMessage("Relative Position: " + str(relPosition))

	var hitDirection
	if type != EQUIPMENT.TYPES.ARM:
		hitDirection = Vector3(collision.normal.x*(cubesize/2.0), collision.normal.y*(cubesize/2.0), collision.normal.z*(cubesize/2.0))
	else:
		hitDirection = Vector3(-collision.normal.x*(cubesize/2.0), -collision.normal.y*(cubesize/2.0), -collision.normal.z*(cubesize/2.0))

	var x_pos = floor((relPosition.x+hitDirection.x)/cubesize)
	var z_pos = floor((relPosition.z+hitDirection.z)/cubesize)
	var y_pos = floor((relPosition.y+hitDirection.y)/cubesize) + 1

	logMessage("X: " + str(x_pos) + " Z: " + str(z_pos) + " Y: " + str(y_pos)  + "\n" )

	if x_pos > chunk.size()-1:
		print("Out of x_pos range")
		return
	if z_pos > chunk[x_pos].size()-1:
		print("Out of z_pos range")
		return
	if y_pos > chunk[x_pos][z_pos].size()-1:
		print("Out of y_pos range")
		return

	# TODO: Check distance from origin to center position of chunk[x_pos][z_pos][y_pos]
	# return if distance < CONSTANTS.CUBESIZE/2

	if chunk[x_pos][z_pos][y_pos] == BLOCK_TYPE.BEDROCK:
		return

	if type == EQUIPMENT.TYPES.ARM:
		chunk[x_pos][z_pos][y_pos] = BLOCK_TYPE.AIR
	elif type == EQUIPMENT.TYPES.DIRT:
		chunk[x_pos][z_pos][y_pos] = BLOCK_TYPE.DIRT
	else:
		logMessage("UNKOWN HIT TYPE: "+ str(type))

	clean = false


func render(_thread):
	if not _thread.is_active():
		thread = _thread
		clean = true
		thread.start(self, "_render_mesh_thread", {}, 2)

func renderEnd():
	logMessage("renderDone wait_to_finish ")
	thread.wait_to_finish();
	thread = null
	logMessage("renderDone end ")


func _build_chunk_opensimplex_3d():
	noise.seed = worldseed
	noise.lacunarity = 2
	noise.octaves = 4
	noise.period = 100.0
	noise.persistence = 0.8

	for x in range(chunksize.x):
		chunk.append([])
		for z in range(chunksize.z):
			chunk[x].append([])

			for y in range(chunksize.y):
				var cube_x = (chunkoffset.x) + x
				var cube_z = (chunkoffset.z) + z
				var cube_y = (chunkoffset.y) + y

				if cube_y == 0:
					chunk[x][z].append(BLOCK_TYPE.BEDROCK)
				else:
					var type = noise.get_noise_3d(cube_x, cube_z, cube_y)

					var key = floor(type * 10) / 10
					if not type_dict.has(key):
						type_dict[key] = 1
					else:
						type_dict[key] = type_dict[key] + 1

					if type < 0:
						if type < -0.5:
							chunk[x][z].append(BLOCK_TYPE.MINERAL)
						else:
							chunk[x][z].append(BLOCK_TYPE.DIRT)

					elif type >= 0:
						chunk[x][z].append(BLOCK_TYPE.AIR)


func _print_type_dict():
	var opts = [-1, -0.9, -0.8, -0.7, -0.6, -0.5, -0.4, -0.3, -0.2, -0.1, 0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1]
	for key in opts:
		print()
		if type_dict.has(key):
			print("ID: ", chunkId, ' KEY: ', key, " VAL: ", type_dict[key])
		else:
			print("ID: ", chunkId, ' KEY: ', key,  " VAL: ", 0)

func _build_test_chunk():

	for x in range(chunksize.x):
		chunk.append([])
		for z in range(chunksize.z):
			chunk[x].append([])

			for y in range(chunksize.y):
				if x == 10:
					chunk[x][z].append(BLOCK_TYPE.DIRT)
				elif z == 10:
					chunk[x][z].append(BLOCK_TYPE.DIRT)
				# elif z == 10:
				# 	chunk[x][z].append(BLOCK_TYPE.DIRT)
				else:
					chunk[x][z].append(BLOCK_TYPE.AIR)

func _render_mesh_thread(params):

	if(!chunkInitialised):
		_build_chunk_opensimplex_3d()
		# _build_test_chunk()
		chunkInitialised = true

	var surfTool = SurfaceTool.new()
	var mesh     = Mesh.new()

	surfTool.begin(Mesh.PRIMITIVE_TRIANGLES)
	surfTool.set_material(material)

	var res
	var next_type
	var current_type

	for x in range(0,chunk.size()):
		for z in range(0,chunk[x].size()):
			for y in range(0,chunk[x][z].size()):
				current_type = chunk[x][z][y]

				#Cube left if on chunk edge
				if z == 0:
					res = _get_vertical_z(x,z-1,y, BLOCK_TYPE.AIR, current_type)
					if res != null:
						surfTool.add_triangle_fan(res[0],res[1], res[2])

				#Cube front if on chunk edge
				if x == 0:

					res = _get_vertical_x(x-1,z,y, BLOCK_TYPE.AIR, current_type)
					if res != null:
						surfTool.add_triangle_fan(res[0],res[1], res[2])

				#Cube right
				if z >= (chunk[x].size() -1):
					next_type = BLOCK_TYPE.AIR
				else:
					next_type = chunk[x][z+1][y]
				res = _get_vertical_z(x,z,y, current_type, next_type)
				if res != null:
					surfTool.add_triangle_fan(res[0],res[1], res[2])

				# Cube back
				if x >= (chunk.size() - 1):
					next_type = BLOCK_TYPE.AIR
				else:
					next_type = chunk[x+1][z][y]
				res = _get_vertical_x(x,z,y, current_type, next_type)
				if res != null:
					surfTool.add_triangle_fan(res[0],res[1], res[2])

				# Cube top
				if y >= (chunk[x][z].size() - 1):
					next_type = BLOCK_TYPE.AIR
				else:
					next_type = chunk[x][z][y+1]
				res = _get_horizontal(x,z,y, current_type, next_type)
				if res != null:
					surfTool.add_triangle_fan(res[0],res[1], res[2])


	surfTool.generate_normals()
	surfTool.index()
	surfTool.commit(mesh)

	# meshInstance.set_material_override(material)
	meshInstance.set_mesh(mesh)

	# Remove old collision mesh if present
	meshInstance.create_trimesh_collision()
	var coll = meshInstance.get_children()
	if coll.size() > 1:
		coll[0].queue_free()

	call_deferred('renderEnd')
	return;


func _get_texture_slot(current_type, next_type, side, flip):
	var column
	var row
	var type

	if !_block_type_is_transparent(current_type):
		type = current_type
	elif !_block_type_is_transparent(next_type):
		type = next_type
	else:
		print("This should not happen right?")

	if type == BLOCK_TYPE.BEDROCK:
		column = 0
		row = 2
	elif type == BLOCK_TYPE.DIRT && side == BLOCK_SIDE.TOP:
		column = 1
		row = 2
	elif type == BLOCK_TYPE.DIRT:
		column = 1
		row = 0
	elif type == BLOCK_TYPE.MINERAL:
		column = 0
		row = 0
	else:
		column = 0
		row = 0

	if flip:
		return [
			Vector2(column,row), # uv4
			Vector2(column+1,row),  # uv1
			Vector2(column+1,row+1), # uv2
			Vector2(column,row+1), # uv3
		]
	else:
		return [
			Vector2(column+1,row+1), # uv2
			Vector2(column,row+1), # uv3
			Vector2(column,row), # uv4
			Vector2(column+1,row),  # uv1
		]

func _block_type_is_transparent(type):
	if type == BLOCK_TYPE.AIR:
		return true

	return false

func _flip_or_return(current_type, next_type):
	should_ret  = false
	should_flip = false

	if current_type == next_type:
		should_ret = true

	elif _block_type_is_transparent(current_type) and _block_type_is_transparent(next_type):
		should_ret = true

	elif _block_type_is_transparent(current_type) and not _block_type_is_transparent(next_type):
		should_flip = true

	return [should_ret, should_flip]



func _get_horizontal(x, z, y, current_type, next_type):
	xoffset = x*cubesize
	zoffset = z*cubesize
	yoffset = y*cubesize

	[should_ret, should_flip] = _flip_or_return(current_type, next_type)
	if should_ret:
		return null

	if should_flip:
		varray = [
			Vector3(xoffset+0,       yoffset, zoffset+0), #v1
			Vector3(xoffset+0,       yoffset, zoffset+cubesize), #v2
			Vector3(xoffset+cubesize,yoffset, zoffset+cubesize), #v3
			Vector3(xoffset+cubesize,yoffset, zoffset+0), #v4
		]
		uvarray = _get_texture_slot(current_type, next_type, BLOCK_SIDE.BOTTOM, should_flip )

	else:
		varray = [
			Vector3(xoffset+cubesize,yoffset, zoffset+0), #v1
			Vector3(xoffset+cubesize,yoffset, zoffset+cubesize), #v2
			Vector3(xoffset+0,       yoffset, zoffset+cubesize), #v3
			Vector3(xoffset+0,       yoffset, zoffset+0), #v4
		]

		uvarray = _get_texture_slot(current_type, next_type, BLOCK_SIDE.TOP, should_flip )

	return [varray, uvarray, carray]

func _get_vertical_x(x,z,y, current_type, next_type):
	xoffset = x*cubesize
	zoffset = z*cubesize
	yoffset = y*cubesize

	[should_ret, should_flip] = _flip_or_return(current_type, next_type)
	if should_ret:
		return null

	# This z compensation is strange
	var yoff_top = (y) * cubesize
	var yoff_bot = (y-1)*cubesize

	if should_flip:
		varray = [
			Vector3(xoffset+cubesize,yoff_top,zoffset), # v1 =
			Vector3(xoffset+cubesize,yoff_top,zoffset+cubesize), # v2 =
			Vector3(xoffset+cubesize,yoff_bot,zoffset+cubesize), # v3 =
			Vector3(xoffset+cubesize,yoff_bot,zoffset), # v4 =
		]
	else:
		varray  = [
			Vector3(xoffset+cubesize,yoff_bot,zoffset), #v1
			Vector3(xoffset+cubesize,yoff_bot,zoffset+cubesize), #v2,
			Vector3(xoffset+cubesize,yoff_top,zoffset+cubesize), #v3,
			Vector3(xoffset+cubesize,yoff_top,zoffset), #v4,
		]


	uvarray = _get_texture_slot(current_type, next_type, BLOCK_SIDE.SIDE, should_flip )

	return [varray, uvarray, carray]

func _get_vertical_z(x,z,y, current_type, next_type):
	xoffset = x*cubesize
	zoffset = z*cubesize
	yoffset = y*cubesize

	[should_ret, should_flip] = _flip_or_return(current_type, next_type)
	if should_ret:
		return null

	# This z compensation is strange
	var yoff_top = (y) * cubesize
	var yoff_bot = (y-1)*cubesize

	if should_flip:
		varray = [
			Vector3(xoffset,yoff_bot,zoffset+cubesize),
			Vector3(xoffset+cubesize,yoff_bot,zoffset+cubesize),
			Vector3(xoffset+cubesize,yoff_top,zoffset+cubesize),
			Vector3(xoffset,yoff_top,zoffset+cubesize),
		]
	else:
		varray = [
			Vector3(xoffset,yoff_top,zoffset+cubesize),
			Vector3(xoffset+cubesize,yoff_top,zoffset+cubesize),
			Vector3(xoffset+cubesize,yoff_bot,zoffset+cubesize),
			Vector3(xoffset,yoff_bot,zoffset+cubesize),
		]


	uvarray = _get_texture_slot(current_type, next_type, BLOCK_SIDE.SIDE, !should_flip )


	return [varray, uvarray, carray]