extends StaticBody

onready var meshInstance = get_node("CollisionShape/MeshInstance")
onready var collInstance = get_node("CollisionShape")

var material = load("res://materials/world_spatialmaterial.tres")

var cubesize  = 3
var chunksize = 32

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

func hit():
	print("Ooof")

func _build_chunk():
	var y
	for x in range(chunksize):
		chunk.append([])
		for z in range(chunksize):
			chunk[x].append([])
			var y_top = randi()%chunksize
			for y in range(chunksize):
				if y <= y_top:
					chunk[x][z].append(BLOCK_TYPE.DIRT)
				else:
					chunk[x][z].append(BLOCK_TYPE.AIR)

func _build_chunk_test():
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

	var z = 4
	var y = 2
	for x in range(chunksize):
		chunk[x][z][y] = BLOCK_TYPE.AIR

func _ready():
	#_build_chunk()
	_build_chunk_test()

	meshInstance.set_material_override(material)

	var surfTool = SurfaceTool.new()
	var mesh     = Mesh.new()

	surfTool.begin(Mesh.PRIMITIVE_TRIANGLES)

	for x in range(chunk.size() - 1):
		xoffset = x*cubesize
		for z in range(chunk[x].size() - 1):
			zoffset = z*cubesize

			for y in range(0, (chunk[x][z].size() )):
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
	print("PREV :", prev, "RES : ", res)

	return res

func _get_horizontal(x, z, y):
	var current_type  = chunk[x][z][y]

	var next_type
	if y == (chunk[x][z].size() - 1):
		next_type = BLOCK_TYPE.AIR
	else:
		next_type = chunk[x][z][y+1]


	#print("x: ", x, " z: ", z, " y: ", y, " tc: ", current_type, " tn ", next_type)

	if current_type == next_type:
		return null

	if current_type != BLOCK_TYPE.AIR and next_type != BLOCK_TYPE.AIR:
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
	if x == 0:
		#Should check previous chunk
		return null

	var current_type  = chunk[x][z][y]

	var next_type
	if x == (chunk.size() - 1):
		next_type = BLOCK_TYPE.AIR
	else:
		next_type = chunk[x+1][z][y]


	#print("x: ", x, " z: ", z, " y: ", y, " tc: ", current_type, " tn ", next_type)

	if current_type == next_type:
		return null

	if current_type != BLOCK_TYPE.AIR and next_type != BLOCK_TYPE.AIR:
		return null


	uvarray = []
	varray  = []
	carray  = []

	# This z compensation is strange
	var yoff_top = (y) * cubesize
	var yoff_bot = (y-1)*cubesize


	uv1 = Vector2(0,0)
	v1 = Vector3(xoffset,yoff_top,zoffset)
	c1 = Color(0,0,0.5)

	uv2 = Vector2(0,1)
	v2 = Vector3(xoffset,yoff_top,zoffset+cubesize)
	c2 = Color(0,0,0.5)

	uv3 = Vector2(1,1)
	v3 = Vector3(xoffset,yoff_bot,zoffset+cubesize)
	c3 = Color(0,0,0.5)

	uv4 = Vector2(1,0)
	v4 = Vector3(xoffset,yoff_bot,zoffset)
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
	if z == 0:
		#Should check previous chunk
		return null

	var current_type  = chunk[x][z][y]

	var next_type
	if x == (chunk.size() - 1):
		next_type = BLOCK_TYPE.AIR
	else:
		next_type = chunk[x][z+1][y]


	#print("x: ", x, " z: ", z, " y: ", y, " tc: ", current_type, " tn ", next_type)

	if current_type == next_type:
		return null

	if current_type != BLOCK_TYPE.AIR and next_type != BLOCK_TYPE.AIR:
		return null


	uvarray = []
	varray  = []
	carray  = []

	# This z compensation is strange
	var yoff_top = (y) * cubesize
	var yoff_bot = (y-1)*cubesize


	uv1 = Vector2(0,0)
	v1 = Vector3(xoffset,yoff_top,zoffset)
	c1 = Color(0,0,0.5)

	uv2 = Vector2(0,1)
	v2 = Vector3(xoffset+cubesize,yoff_top,zoffset)
	c2 = Color(0,0,0.5)

	uv3 = Vector2(1,1)
	v3 = Vector3(xoffset+cubesize,yoff_bot,zoffset)
	c3 = Color(0,0,0.5)

	uv4 = Vector2(1,0)
	v4 = Vector3(xoffset,yoff_bot,zoffset)
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