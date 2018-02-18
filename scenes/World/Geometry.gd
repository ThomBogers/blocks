extends StaticBody

onready var meshInstance = get_node("CollisionShape/MeshInstance")
onready var collInstance = get_node("CollisionShape")

var material = load("res://materials/world_spatialmaterial.tres")

var cubesize  = 5
var chunksize = 3

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

func _get_vertical_right(x,z,y):
	if x == 0 or z == 0:
		return null

	uvarray = []
	varray  = []
	var y_prev = chunk[x-1][z-1]

	var yoff_top
	var yoff_bot

	if y_prev == y:
		return null
	elif y_prev > y:
		yoff_top = y_prev*cubesize
		yoff_bot = y * cubesize
	else:
		yoff_top = y * cubesize
		yoff_bot = y_prev*cubesize


	uv1 = Vector2(0,0)
	v1 = Vector3(xoffset-cubesize,yoff_bot,zoffset)

	uv2 = Vector2(0,1)
	v2 = Vector3(xoffset-cubesize,yoff_bot,zoffset-cubesize)

	uv3 = Vector2(1,1)
	v3 = Vector3(xoffset-cubesize,yoff_top,zoffset-cubesize)

	uv4 = Vector2(1,0)
	v4 = Vector3(xoffset-cubesize,yoff_top,zoffset)

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

func _build_chunk2():
	for x in range(chunksize):
		chunk.append([])
		for z in range(chunksize):
			chunk[x].append(randi()%2)

func _build_chunk():
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
			res = _get_vertical_right(x,z,y)
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


