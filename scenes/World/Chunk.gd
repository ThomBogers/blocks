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

var uvarray = []
var varray  = []
var carray  = []
var xoffset
var zoffset
var yoffset

var should_ret  = false
var should_flip = false

# Seeds for terain gen
var worldseed

var thread

enum BLOCK_TYPE {
	AIR
	DIRT
	BEDROCK
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
					if type < 0:
						chunk[x][z].append(BLOCK_TYPE.DIRT)
					elif type >= 0:
						chunk[x][z].append(BLOCK_TYPE.AIR)

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

	carray = _get_carray(current_type)
	if should_flip:
		varray = [
			Vector3(xoffset+0,       yoffset, zoffset+0), #v1
			Vector3(xoffset+0,       yoffset, zoffset+cubesize), #v2
			Vector3(xoffset+cubesize,yoffset, zoffset+cubesize), #v3
			Vector3(xoffset+cubesize,yoffset, zoffset+0), #v4
		]
		uvarray = [
			Vector2(0,0), # uv1
			Vector2(0,1), # uv2
			Vector2(1,1), # uv3
			Vector2(1,0), # uv4
		]
	else:
		uvarray = [
			Vector2(1,0), # uv4
			Vector2(1,1), # uv3
			Vector2(0,1), # uv2
			Vector2(0,0),  # uv1
		]
		varray = [
			Vector3(xoffset+cubesize,yoffset, zoffset+0), #v1
			Vector3(xoffset+cubesize,yoffset, zoffset+cubesize), #v2
			Vector3(xoffset+0,       yoffset, zoffset+cubesize), #v3
			Vector3(xoffset+0,       yoffset, zoffset+0), #v4
		]


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

	carray = _get_carray(current_type)

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

	uvarray = [
		Vector2(0,0), # uv1
		Vector2(0,1), # uv2
		Vector2(1,1), # uv3
		Vector2(1,0), # uv4
	]

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

	carray = _get_carray(current_type)

	if !should_flip:
		varray = [
			Vector3(xoffset,yoff_top,zoffset+cubesize),
			Vector3(xoffset+cubesize,yoff_top,zoffset+cubesize),
			Vector3(xoffset+cubesize,yoff_bot,zoffset+cubesize),
			Vector3(xoffset,yoff_bot,zoffset+cubesize),
		]
	else:
		varray = [
			Vector3(xoffset,yoff_bot,zoffset+cubesize),
			Vector3(xoffset+cubesize,yoff_bot,zoffset+cubesize),
			Vector3(xoffset+cubesize,yoff_top,zoffset+cubesize),
			Vector3(xoffset,yoff_top,zoffset+cubesize),
		]
	uvarray = [
		Vector2(0,0), # uv1
		Vector2(0,1), # uv2
		Vector2(1,1), # uv3
		Vector2(1,0), # uv4
	]
	return [varray, uvarray, carray]

func _get_carray(type):
	var COLOR_GRAY = Color( 0.75, 0.75, 0.75, 1.0 )
	var COLOR_BEIGE = Color( 0.96, 0.96, 0.86, 1.0 )
	var COLOR_DARKGREEN = Color( 0, 0.39, 0, 1.0 )
	var COLOR_NONE = Color( 0, 0, 0, 0 )

	var dirtArray = PoolColorArray([COLOR_BEIGE,COLOR_BEIGE,COLOR_BEIGE,COLOR_BEIGE])
	var grayArray = PoolColorArray([COLOR_GRAY,COLOR_GRAY,COLOR_GRAY,COLOR_GRAY])
	var noneArray = PoolColorArray([COLOR_NONE,COLOR_NONE,COLOR_NONE,COLOR_NONE])

	if type == BLOCK_TYPE.DIRT:
		carray = dirtArray;
	elif type == BLOCK_TYPE.BEDROCK:
		carray = grayArray;
	else:
		carray = noneArray;
	return carray
