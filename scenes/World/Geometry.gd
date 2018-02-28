extends StaticBody

onready var meshInstance = get_node("CollisionShape/MeshInstance")
onready var collInstance = get_node("CollisionShape")

var material = load("res://materials/world_spatialmaterial.tres")

var simplex = load("res://modules/Godot-Helpers/Simplex/Simplex.gd")

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

func hit(collision):
	#print("Ooof", collision)
	var x = floor(collision.position.x/cubesize)
	var z = floor(collision.position.z/cubesize)
	var y = floor(collision.position.y/cubesize)

	print("Hit at x: ", x, " z: ", z, " y: ", y)
	chunk[x][z][y] = BLOCK_TYPE.AIR
	render_mesh()


func _build_chunk_simplex_2d():
	var hmin = chunksize

	var ox = chunkoffset.x
	var oz = chunkoffset.z
	var oy = chunkoffset.y
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


	#for x in range(0, chunk.size()):
	#	for z in range(15,20):
	#		for y in range(10,15):
	#			chunk[x][z][y] = BLOCK_TYPE.AIR




func _build_chunk_simplex_3d():
	var hmin = chunksize

	var ox = chunkoffset.x
	var oz = chunkoffset.z
	var oy = chunkoffset.y
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


func _build_chunk():
	for x in range(chunksize):
		chunk.append([])
		for z in range(chunksize):
			chunk[x].append([])
			var y_top = randi()%5
			for y in range(chunksize):
				if y <= y_top:
					chunk[x][z].append(BLOCK_TYPE.DIRT)
				else:
					chunk[x][z].append(BLOCK_TYPE.AIR)

func _build_chunk_test0():
	chunksize = 10

	for x in range(chunksize):
		chunk.append([])
		for z in range(chunksize):
			chunk[x].append([])
			var h = x*z

			for y in range(chunksize*2):
				var current
				if y <= h:
					current = BLOCK_TYPE.DIRT
				else:
					current = BLOCK_TYPE.AIR

				chunk[x][z].append(current)

	var y = 2
	for x in range(chunksize):
		for z in range(4,8):
			chunk[x][z][y] = BLOCK_TYPE.AIR
			chunk[x][z][y+1] = BLOCK_TYPE.AIR
	for z in range(chunksize):
		for x in range(4,8):
			chunk[x][z][y] = BLOCK_TYPE.AIR
			chunk[x][z][y+1] = BLOCK_TYPE.AIR

func _build_chunk_test1():
	chunksize = 3

	for x in range(chunksize*3):
		chunk.append([])
		for z in range(chunksize):
			chunk[x].append([])

			var h = 0
			if z == 1 and x%3 == 1:
				h = 2

			for y in range(chunksize):

				var current
				if y <= h:
					current = BLOCK_TYPE.DIRT
				else:
					current = BLOCK_TYPE.AIR

				chunk[x][z].append(current)


func _build_chunk_test2():
	chunksize = 1

	for x in range(chunksize):
		chunk.append([])
		for z in range(chunksize):
			chunk[x].append([])

			for y in range(chunksize):

				var current
				if y == 0:
					current = BLOCK_TYPE.DIRT
				else:
					current = BLOCK_TYPE.AIR

				chunk[x][z].append(current)

func _ready():

	_build_chunk_simplex_2d()
	#_build_chunk_test0()

	render_mesh()

func render_mesh():

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

func _get_random_y(x,z):
	randomize()
	var prev

	if x == 0 and z == 0:
		return randi()%4
	elif x == 0:
		prev = chunk[0][z-1]
	elif z == 0:
		prev = chunk[x-1][z]
	else:
		prev = (chunk[x][z-1] + chunk[x-1][z] + chunk[x-1][z-1]) / 3


	var up   = randi()%4

	if x+z%128 == 0:
		up   = randi()%10

	var down = randi()%4
	if x+z%256 == 0:
		down   = randi()%10

	var res = prev + up - down

	return res

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