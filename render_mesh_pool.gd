extends Node2D
class_name RenderMeshPool

# ## RPOLY POOLING

const renderMesh = preload("res://render_mesh.tscn")


func create_render_mesh(id:int) -> RenderMesh:
	assert(not renderMeshes.has(id))

	var p := _new_render_mesh() as RenderMesh
	p.id = id
	p.visible = true
	renderMeshes[id] = p
	return p


func _new_render_mesh() -> RenderMesh:
	var mesh:RenderMesh
	if renderMesh_pool:
		mesh = renderMesh_pool.pop_front()
	else:
		mesh = renderMesh.instantiate()
		add_child(mesh)

	return mesh


func free_render_mesh(id: int):
	var mesh = renderMeshes[id] as RenderMesh

	#mesh.end_tweens()
	mesh.render_attachments.clear()

	# Reset visual state
	mesh.mesh.position = Vector2.ZERO
	mesh.mesh.modulate = Color.WHITE

	mesh.visible = false

	renderMesh_pool.append(mesh)
	renderMeshes.erase(id)



var renderMesh_pool:Array[RenderMesh] = []
var renderMeshes := {}

func get_render_mesh(id) -> RenderMesh:
	return renderMeshes.get(id,null)
