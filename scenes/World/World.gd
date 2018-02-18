extends Spatial

onready var meshInstance = get_node("StaticBody/CollisionShape/MeshInstance")
onready var collInstance = get_node("StaticBody/CollisionShape")

var material = preload("res://materials/world_spatialmaterial.tres")

var chunksize = 10

func _ready():

	meshInstance.set_material_override(material)

	var surfTool = SurfaceTool.new()
	var mesh     = Mesh.new()

	surfTool.begin(Mesh.PRIMITIVE_TRIANGLES)

	var uv1 = Vector2(0,0)
	var v1 = Vector3(0,0,0)

	var uv2 = Vector2(0,1)
	var v2 = Vector3(0,0,chunksize)

	var uv3 = Vector2(1,1)
	var v3 = Vector3(chunksize,0,chunksize)

	var uv4 = Vector2(1,0)
	var v4 = Vector3(chunksize,0,0)

	var uvarray = [ uv4, uv3, uv2, uv1]
	var varray = [ v4, v3, v2, v1 ]

	surfTool.add_triangle_fan(varray,uvarray)
	surfTool.generate_normals()
	surfTool.index()
	surfTool.commit(mesh)

	meshInstance.set_mesh(mesh)
	meshInstance.create_trimesh_collision()


