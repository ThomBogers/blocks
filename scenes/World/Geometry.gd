extends StaticBody

onready var meshInstance = get_node("CollisionShape/MeshInstance")
onready var collInstance = get_node("CollisionShape")

var material = load("res://materials/world_spatialmaterial.tres")

var cubesize  = 2
var chunksize = 64

var chunk = []

var uvarray = []
var varray  = []
var xoffset
var zoffset
var yoffset

var uv1
var v1
var uv2
var v2
var uv3
var v3
var uv4
var v4

func hit():
	print("Ooof")

func _build_chunk():
	var y
	for x in range(chunksize):
		chunk.append([])
		for z in range(chunksize):
			y = _get_random_y(x,z)
			chunk[x].append(y)

func _build_chunk_test():
	chunksize = 3

	for x in range(chunksize*3):
		chunk.append([])
		for z in range(chunksize):
			var y = 0
			if z == 1 and x%3 == 1:
				y = 1

			chunk[x].append(y)

func _ready():
	_build_chunk()

	meshInstance.set_material_override(material)

	var surfTool = SurfaceTool.new()
	var mesh     = Mesh.new()

	surfTool.begin(Mesh.PRIMITIVE_TRIANGLES)

	for x in range(chunk.size()):
		xoffset = x*cubesize
		for z in range(chunk[x].size()):
			zoffset = z*cubesize

			var y = chunk[x][z]
			yoffset = y*cubesize

			var res
			res = _get_vertical_z(x,z,y)
			if res != null:
				surfTool.add_triangle_fan(res[0],res[1])

			res = _get_vertical_x(x,z,y)
			if res != null:
				surfTool.add_triangle_fan(res[0],res[1])

			res = _get_horizontal(x,z,y)
			if res != null:
				surfTool.add_triangle_fan(res[0],res[1])


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
	uvarray = []
	varray  = []

	uv1 = Vector2(0,0)
	v1 = Vector3(xoffset+0,yoffset,zoffset+0)

	uv2 = Vector2(0,1)
	v2 = Vector3(xoffset+0,yoffset,zoffset+cubesize)

	uv3 = Vector2(1,1)
	v3 = Vector3(xoffset+cubesize,yoffset,zoffset+cubesize)

	uv4 = Vector2(1,0)
	v4 = Vector3(xoffset+cubesize,yoffset,zoffset+0)

	uvarray.append(uv4)
	uvarray.append(uv3)
	uvarray.append(uv2)
	uvarray.append(uv1)

	varray.append(v4)
	varray.append(v3)
	varray.append(v2)
	varray.append(v1)

	return [varray, uvarray]

func _get_vertical_z(x,z,y):
	if z == 0:
		#Should check previous chunk
		return null

	uvarray = []
	varray  = []
	var y_prev = chunk[x][z-1]

	var yoff_top
	var yoff_bot

	if y_prev == y:
		#No vertical needed
		return null
	else:
		yoff_top = y * cubesize
		yoff_bot = y_prev*cubesize


	uv1 = Vector2(0,0)
	v1 = Vector3(xoffset,yoff_top,zoffset)

	uv2 = Vector2(0,1)
	v2 = Vector3(xoffset+cubesize,yoff_top,zoffset)

	uv3 = Vector2(1,1)
	v3 = Vector3(xoffset+cubesize,yoff_bot,zoffset)

	uv4 = Vector2(1,0)
	v4 = Vector3(xoffset,yoff_bot,zoffset)

	uvarray.append(uv4)
	uvarray.append(uv3)
	uvarray.append(uv2)
	uvarray.append(uv1)

	varray.append(v4)
	varray.append(v3)
	varray.append(v2)
	varray.append(v1)

	return [varray, uvarray]

	return null

func _get_vertical_x(x,z,y):
	if x == 0:
		#Should check previous chunk
		return null

	uvarray = []
	varray  = []
	var y_prev = chunk[x-1][z]

	var yoff_top
	var yoff_bot

	if y_prev == y:
		#No vertical needed
		return null
	else:
		yoff_top = y * cubesize
		yoff_bot = y_prev*cubesize


	uv1 = Vector2(0,0)
	v1 = Vector3(xoffset,yoff_top,zoffset)

	uv2 = Vector2(0,1)
	v2 = Vector3(xoffset,yoff_top,zoffset+cubesize)

	uv3 = Vector2(1,1)
	v3 = Vector3(xoffset,yoff_bot,zoffset+cubesize)

	uv4 = Vector2(1,0)
	v4 = Vector3(xoffset,yoff_bot,zoffset)

	uvarray.append(uv4)
	uvarray.append(uv3)
	uvarray.append(uv2)
	uvarray.append(uv1)

	varray.append(v4)
	varray.append(v3)
	varray.append(v2)
	varray.append(v1)

	return [varray, uvarray]

	return null

