extends StaticBody

var this = null

var meshInstance = null
var collInstance = null

var material = load("res://materials/world_spatialmaterial.tres")
var simplex = load("res://modules/Godot-Helpers/Simplex/Simplex.gd")

var EQUIPMENT = load("res://scenes/Player/Equipment.gd")

var cubesize  = 2
var chunksize = 16
var chunkoffset = Vector3(0,0,0)

var chunk = []

var uvarray = []
var varray  = []
var carray  = []
var xoffset
var zoffset
var yoffset

var uv1
var v1
var c1
var uv2
var v2
var c2
var uv3
var v3
var c3
var uv4
var v4
var c4

enum BLOCK_TYPE {
	AIR
	DIRT
}

func init(offset):
	chunkoffset = Vector3(offset.x*chunksize*cubesize, 0, offset.z*chunksize*cubesize)
	this = get_node(".")
	this.translate(chunkoffset)

	meshInstance = get_node("CollisionShape/MeshInstance")
	collInstance = get_node("CollisionShape")

	#_build_chunk_simplex_3d()
	_build_chunk_simplex_2d()
	#_build_chunk_test2()
	_render_mesh()


func hit(collision, type):

	# Calculate direction of collision

	# Create position relative to chunk position
	var relPosition = Vector3(collision.position.x-chunkoffset.x, collision.position.y-chunkoffset.y, collision.position.z-chunkoffset.z)

	print("COLL: ", collision)
	print("ISARM: ", type == EQUIPMENT.TYPES.ARM)

	var DIRFLIP = 0
	if type != EQUIPMENT.TYPES.ARM:
		DIRFLIP = 1

	var x_pos = floor(relPosition.x/cubesize)
	var z_pos = floor(relPosition.z/cubesize)
	var y_pos = floor(relPosition.y/cubesize)

	var x_tar = x_pos
	var z_tar = z_pos
	var y_tar = y_pos

	if collision.normal.x == -1:
		x_tar += (DIRFLIP * collision.normal.x)
		y_tar += DIRFLIP
	elif collision.normal.x == 1:
		y_tar += DIRFLIP

	elif collision.normal.z == -1:
		z_tar += (DIRFLIP * collision.normal.z)
		y_tar += DIRFLIP
	elif collision.normal.z == 1:
		y_tar += DIRFLIP

	elif collision.normal.y == -1:
		y_tar += (DIRFLIP * collision.normal.y)
	elif collision.normal.y == 1:
		y_tar += (DIRFLIP * collision.normal.y)


	print("Norm: ", collision.normal)
	print("Hit at x_pos: ", x_pos, " x_tar: ", x_tar)
	print("Hit at z_pos: ", z_pos, " z_tar: ", z_tar)
	print("Hit at y_pos: ", y_pos, " y_tar: ", y_tar)


	if x_tar > chunk.size()-1:
		print("Out of x_tar range")
		return
	if z_tar > chunk[x_tar].size()-1:
		print("Out of z_tar range")
		return
	if y_tar > chunk[x_tar][z_tar].size()-1:
		print("Out of y_tar range")
		return

	if type == EQUIPMENT.TYPES.ARM:
		chunk[x_tar][z_tar][y_tar] = BLOCK_TYPE.AIR
	elif type == EQUIPMENT.TYPES.DIRT:
		chunk[x_tar][z_tar][y_tar] = BLOCK_TYPE.DIRT
	else:
		print("UNKOWN HIT TYPE: ", type)

	_render_mesh()


func _build_chunk_simplex_2d():
	var hmin = chunksize

	var ox = (chunkoffset.x/chunksize)/cubesize
	var oz = (chunkoffset.z/chunksize)/cubesize
	var oy = (chunkoffset.y/chunksize)/cubesize
	var empty = true
	var ns1 = randf()/10
	var ns2 = randf()/2

	for x in range(chunksize):
		chunk.append([])
		for z in range(chunksize):
			chunk[x].append([])

			var n1 = simplex.simplex2(ns1*(ox+x), ns1*(oz+z))
			var n2 = simplex.simplex2(ns2*(ox+x+100.0), ns2*(oz+z))
			var h = 16.0*n1 + 4.0*n2 + 20 - oy

			if h < hmin:
				hmin = h

			for y in range(chunksize):
				if y <= h:
					chunk[x][z].append(BLOCK_TYPE.DIRT)
				else:
					chunk[x][z].append(BLOCK_TYPE.AIR)


func _build_chunk_simplex_3d():
	var hmin = chunksize

	var ox = (chunkoffset.x/chunksize)/cubesize
	var oz = (chunkoffset.z/chunksize)/cubesize
	var oy = (chunkoffset.y/chunksize)/cubesize
	var empty = true
	var ns1 = randf()/10
	var ns2 = randf()/2

	var yfact = 5

	for x in range(chunksize):
		chunk.append([])
		for z in range(chunksize):
			chunk[x].append([])

			for y in range(chunksize):
				var n1 = simplex.simplex3(ns1*(ox+x), ns1*(oz+z), ns1*(oy+y)*yfact)
				var n2 = simplex.simplex3(ns2*(ox+x+100.0), ns2*(oz+z), ns2*(oy+y)*yfact)
				var h = 16.0*n1 + 4.0*n2 + 16 - oy

				if h < hmin:
					hmin = h

				if y <= h:
					chunk[x][z].append(BLOCK_TYPE.DIRT)
				else:
					chunk[x][z].append(BLOCK_TYPE.AIR)

func _render_mesh():

	# Remove old collision mesh if present
	var coll = meshInstance.get_children()
	if not coll.empty():
		for item in coll:
			item.queue_free()

	meshInstance.set_material_override(material)

	var surfTool = SurfaceTool.new()
	var mesh     = Mesh.new()

	surfTool.begin(Mesh.PRIMITIVE_TRIANGLES)

	for x in range(0,chunk.size()):
		xoffset = x*cubesize
		for z in range(0,chunk[x].size()):
			zoffset = z*cubesize

			for y in range(0,chunk[x][z].size()):

				yoffset = y*cubesize
				var res
				res = _get_vertical_z(x,z,y)
				if res != null:
					surfTool.add_triangle_fan(res[0],res[1], res[2])

				res = _get_vertical_x(x,z,y)
				if res != null:
					surfTool.add_triangle_fan(res[0],res[1], res[2])

				res = _get_horizontal(x,z,y)
				if res != null:
					surfTool.add_triangle_fan(res[0],res[1], res[2])


	surfTool.generate_normals()
	surfTool.index()
	surfTool.commit(mesh)

	meshInstance.set_mesh(mesh)
	meshInstance.create_trimesh_collision()


func _get_horizontal(x, z, y):
	var current_type  = chunk[x][z][y]

	var next_type
	if y >= (chunk[x][z].size() - 1):
		next_type = BLOCK_TYPE.AIR
	else:
		next_type = chunk[x][z][y+1]


	if current_type == next_type:
		return null

	if current_type == BLOCK_TYPE.AIR and next_type == BLOCK_TYPE.AIR:
		return null

	uvarray = []
	varray  = []
	carray  = []

	uv1 = Vector2(0,0)
	v1 = Vector3(xoffset+0,yoffset,zoffset+0)
	c1 = Color(0,0,0.5)

	uv2 = Vector2(0,1)
	v2 = Vector3(xoffset+0,yoffset,zoffset+cubesize)
	c2 = Color(0,0,0.5)

	uv3 = Vector2(1,1)
	v3 = Vector3(xoffset+cubesize,yoffset,zoffset+cubesize)
	c3 = Color(0,0,0.5)

	uv4 = Vector2(1,0)
	v4 = Vector3(xoffset+cubesize,yoffset,zoffset+0)
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

func _get_vertical_x(x,z,y):
	var current_type  = chunk[x][z][y]

	var next_type
	if x >= (chunk.size() - 1):
		next_type = BLOCK_TYPE.AIR
	else:
		next_type = chunk[x+1][z][y]

	if current_type == next_type:
		return null

	if current_type == BLOCK_TYPE.AIR and next_type == BLOCK_TYPE.AIR:
		return null


	uvarray = []
	varray  = []
	carray  = []

	# This z compensation is strange
	var yoff_top = (y) * cubesize
	var yoff_bot = (y-1)*cubesize

	uv1 = Vector2(0,0)
	v1 = Vector3(xoffset+cubesize,yoff_top,zoffset)
	c1 = Color(0,0,0.5)

	uv2 = Vector2(0,1)
	v2 = Vector3(xoffset+cubesize,yoff_top,zoffset+cubesize)
	c2 = Color(0,0,0.5)

	uv3 = Vector2(1,1)
	v3 = Vector3(xoffset+cubesize,yoff_bot,zoffset+cubesize)
	c3 = Color(0,0,0.5)

	uv4 = Vector2(1,0)
	v4 = Vector3(xoffset+cubesize,yoff_bot,zoffset)
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

func _get_vertical_z(x,z,y):

	var current_type  = chunk[x][z][y]

	var next_type
	if z >= (chunk[x].size() -1):
		next_type = BLOCK_TYPE.AIR
	else:
		next_type = chunk[x][z+1][y]

	if current_type == next_type:
		return null

	if current_type == BLOCK_TYPE.AIR and next_type == BLOCK_TYPE.AIR:
		return null


	uvarray = []
	varray  = []
	carray  = []

	# This z compensation is strange
	var yoff_top = (y) * cubesize
	var yoff_bot = (y-1)*cubesize


	uv1 = Vector2(0,0)
	v1 = Vector3(xoffset,yoff_top,zoffset+cubesize)
	c1 = Color(0,0,0.5)

	uv2 = Vector2(0,1)
	v2 = Vector3(xoffset+cubesize,yoff_top,zoffset+cubesize)
	c2 = Color(0,0,0.5)

	uv3 = Vector2(1,1)
	v3 = Vector3(xoffset+cubesize,yoff_bot,zoffset+cubesize)
	c3 = Color(0,0,0.5)

	uv4 = Vector2(1,0)
	v4 = Vector3(xoffset,yoff_bot,zoffset+cubesize)
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

func _get_vertical():