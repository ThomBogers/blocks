extends StaticBody

var this = null

var meshInstance = null
var collInstance = null

export(Material) var material

#var material = load("res://materials/world_spatialmaterial.tres")
var simplex = load("res://modules/Godot-Helpers/Simplex/Simplex.gd")

var EQUIPMENT = load("res://scenes/Player/Equipment.gd")

const cubesize  = 2
const chunksize = Vector3(16, 64, 16)
var chunkoffset = Vector3(0,0,0)

var chunk = []

var uvarray = []
var varray  = []
var carray  = []
var xoffset
var zoffset
var yoffset

var uv1
var uv2
var uv3
var uv4

var v1
var v2
var v3
var v4

var c1
var c2
var c3
var c4

var should_ret  = false
var should_flip = false

var thread = Thread.new()

# Seeds for terain gen
var chunkSeeds = Vector2(0,0)

enum BLOCK_TYPE {
	AIR
	DIRT
	BEDROCK
}

func init(offset, seeds):
	chunkoffset = Vector3(offset.x*chunksize.x*cubesize, 0, offset.z*chunksize.x*cubesize)
	this = get_node(".")
	this.translate(chunkoffset)

	meshInstance = get_node("CollisionShape/MeshInstance")
	collInstance = get_node("CollisionShape")
	chunkSeeds = seeds

	#_build_chunk_simplex_3d()
	_build_chunk_simplex_2d()
	_render_mesh()

func hit(collision, type):

	print("Collistion: ", collision)

	# Calculate direction of collision

	# Create position relative to chunk position
	var relPosition = Vector3(collision.position.x-chunkoffset.x, collision.position.y-chunkoffset.y, collision.position.z-chunkoffset.z)
	print("Relative Position: ", relPosition)

	var hitDirection
	if type != EQUIPMENT.TYPES.ARM:
		hitDirection = Vector3(collision.normal.x*(cubesize/2), collision.normal.y*(cubesize/2), collision.normal.z*(cubesize/2))
	else:
		hitDirection = Vector3(-collision.normal.x*(cubesize/2), -collision.normal.y*(cubesize/2), -collision.normal.z*(cubesize/2))

	var x_pos = floor((relPosition.x+hitDirection.x)/cubesize)
	var z_pos = floor((relPosition.z+hitDirection.z)/cubesize)
	var y_pos = floor((relPosition.y+hitDirection.y)/cubesize) + 1

	print("X: ", x_pos, " Z: ", z_pos, " Y: ", y_pos , "\n" )

	if x_pos > chunk.size()-1:
		print("Out of x_pos range")
		return
	if z_pos > chunk[x_pos].size()-1:
		print("Out of z_pos range")
		return
	if y_pos > chunk[x_pos][z_pos].size()-1:
		print("Out of y_pos range")
		return

	if chunk[x_pos][z_pos][y_pos] == BLOCK_TYPE.BEDROCK:
		return

	if type == EQUIPMENT.TYPES.ARM:
		chunk[x_pos][z_pos][y_pos] = BLOCK_TYPE.AIR
	elif type == EQUIPMENT.TYPES.DIRT:
		chunk[x_pos][z_pos][y_pos] = BLOCK_TYPE.DIRT
	else:
		print("UNKOWN HIT TYPE: ", type)

	_render_mesh()


func _build_chunk_simplex_2d():
	var ymin = chunksize.y

	var ox = (chunkoffset.x/cubesize)
	var oz = (chunkoffset.z/cubesize)
	var oy = (chunkoffset.y/cubesize)
	var empty = true
	var yoffset = 17

	for x in range(chunksize.x):
		chunk.append([])
		for z in range(chunksize.z):
			chunk[x].append([])

			var n1 = simplex.simplex2(chunkSeeds.x*(ox+x), chunkSeeds.x*(oz+z))
			var n2 = simplex.simplex2(chunkSeeds.y*(ox+x+100.0), chunkSeeds.y*(oz+z))
			var h = 16.0*n1 + 4.0*n2 + yoffset - oy

			if h < ymin:
				ymin = h

			for y in range(chunksize.y):
				if y == 0:
					chunk[x][z].append(BLOCK_TYPE.BEDROCK)
				elif y <= h:
					chunk[x][z].append(BLOCK_TYPE.DIRT)
				else:
					chunk[x][z].append(BLOCK_TYPE.AIR)


func _build_chunk_simplex_3d():
	var ymin = chunksize.y

	var ox = (chunkoffset.x/chunksize.x)/cubesize
	var oz = (chunkoffset.z/chunksize.z)/cubesize
	var oy = (chunkoffset.y/chunksize.y)/cubesize
	var empty = true
	var ns1 = randf()/10
	var ns2 = randf()/2

	var yfact = 5

	for x in range(chunksize.x):
		chunk.append([])
		for z in range(chunksize.z):
			chunk[x].append([])

			for y in range(chunksize.y):
				var n1 = simplex.simplex3(ns1*(ox+x), ns1*(oz+z), ns1*(oy+y)*yfact)
				var n2 = simplex.simplex3(ns2*(ox+x+100.0), ns2*(oz+z), ns2*(oy+y)*yfact)
				var h = 16.0*n1 + 4.0*n2 + 16 - oy

				if h < ymin:
					ymin = h

				if y == 0:
					chunk[x][z].append(BLOCK_TYPE.BEDROCK)
				elif y <= h:
					chunk[x][z].append(BLOCK_TYPE.DIRT)
				else:
					chunk[x][z].append(BLOCK_TYPE.AIR)

func _render_mesh():
	thread.start(self, "_render_mesh_thread", null, 0)

func _render_mesh_thread(params):

	# Remove old collision mesh if present
	var coll = meshInstance.get_children()
	if not coll.empty():
		for item in coll:
			item.queue_free()

	meshInstance.set_material_override(material)

	var surfTool = SurfaceTool.new()
	var mesh     = Mesh.new()

	surfTool.begin(Mesh.PRIMITIVE_TRIANGLES)

	var x = 0
	var z = 0
	var y = 0
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

	meshInstance.set_mesh(mesh)
	meshInstance.create_trimesh_collision()
	params.thread.call_deferred("wait_to_finish")


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
		v4 = Vector3(xoffset+0,       yoffset, zoffset+0)
		v3 = Vector3(xoffset+0,       yoffset, zoffset+cubesize)
		v2 = Vector3(xoffset+cubesize,yoffset, zoffset+cubesize)
		v1 = Vector3(xoffset+cubesize,yoffset, zoffset+0)
	else:
		v1 = Vector3(xoffset+0,       yoffset, zoffset+0)
		v2 = Vector3(xoffset+0,       yoffset, zoffset+cubesize)
		v3 = Vector3(xoffset+cubesize,yoffset, zoffset+cubesize)
		v4 = Vector3(xoffset+cubesize,yoffset, zoffset+0)

	return _get_rect(v1,v2,v3,v4)

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
		v4 = Vector3(xoffset+cubesize,yoff_top,zoffset)
		v3 = Vector3(xoffset+cubesize,yoff_top,zoffset+cubesize)
		v2 = Vector3(xoffset+cubesize,yoff_bot,zoffset+cubesize)
		v1 = Vector3(xoffset+cubesize,yoff_bot,zoffset)
	else:
		v1 = Vector3(xoffset+cubesize,yoff_top,zoffset)
		v2 = Vector3(xoffset+cubesize,yoff_top,zoffset+cubesize)
		v3 = Vector3(xoffset+cubesize,yoff_bot,zoffset+cubesize)
		v4 = Vector3(xoffset+cubesize,yoff_bot,zoffset)

	return _get_rect(v1,v2,v3,v4)

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
		v1 = Vector3(xoffset,yoff_top,zoffset+cubesize)
		v2 = Vector3(xoffset+cubesize,yoff_top,zoffset+cubesize)
		v3 = Vector3(xoffset+cubesize,yoff_bot,zoffset+cubesize)
		v4 = Vector3(xoffset,yoff_bot,zoffset+cubesize)
	else:
		v4 = Vector3(xoffset,yoff_top,zoffset+cubesize)
		v3 = Vector3(xoffset+cubesize,yoff_top,zoffset+cubesize)
		v2 = Vector3(xoffset+cubesize,yoff_bot,zoffset+cubesize)
		v1 = Vector3(xoffset,yoff_bot,zoffset+cubesize)


	return _get_rect(v1,v2,v3,v4)

func _get_rect(v1,v2,v3,v4):
	uvarray = []
	varray  = []
	carray  = []

	uv1 = Vector2(0,0)
	uv2 = Vector2(0,1)
	uv3 = Vector2(1,1)
	uv4 = Vector2(1,0)

	c1 = Color(0,0,0.5)
	c2 = Color(0,0,0.5)
	c3 = Color(0,0,0.5)
	c4 = Color(0,0,0.5)

	uvarray.append(uv4)
	uvarray.append(uv3)
	uvarray.append(uv2)
	uvarray.append(uv1)

	varray.append(v4)
	varray.append(v3)
	varray.append(v2)
	varray.append(v1)

	carray.append(c4)
	carray.append(c3)
	carray.append(c2)
	carray.append(c1)

	return [varray, uvarray, carray]