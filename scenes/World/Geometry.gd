extends StaticBody

onready var meshInstance = get_node("CollisionShape/MeshInstance")
onready var collInstance = get_node("CollisionShape")

var material = preload("res://materials/world_spatialmaterial.tres")

var chunksize = 10

func hit():
	print("Ooof")

func _ready():

	meshInstance.set_material_override(material)

	var surfTool = SurfaceTool.new()
	var mesh     = Mesh.new()

	surfTool.begin(Mesh.PRIMITIVE_TRIANGLES)



	for x in range(10):
		var xoffset = x * chunksize
		for z in range(10):
			var uvarray = []
			var varray  = []

			var zoffset = z * chunksize
			var y = randi()%2 * chunksize
			print("Y:", y)

			var uv1 = Vector2(0,0)
			var v1 = Vector3(xoffset+0,y,zoffset+0)

			var uv2 = Vector2(0,1)
			var v2 = Vector3(xoffset+0,y,zoffset+chunksize)

			var uv3 = Vector2(1,1)
			var v3 = Vector3(xoffset+chunksize,y,zoffset+chunksize)

			var uv4 = Vector2(1,0)
			var v4 = Vector3(xoffset+chunksize,y,zoffset+0)

			uvarray.append(uv4)
			uvarray.append(uv3)
			uvarray.append(uv2)
			uvarray.append(uv1)

			varray.append(v4)
			varray.append(v3)
			varray.append(v2)
			varray.append(v1)

			surfTool.add_triangle_fan(varray,uvarray)


	surfTool.generate_normals()
	surfTool.index()
	surfTool.commit(mesh)

	meshInstance.set_mesh(mesh)
	meshInstance.create_trimesh_collision()


