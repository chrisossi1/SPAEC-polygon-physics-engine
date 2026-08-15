class_name GameObject

var name := ""
var geometry:GeometryData

var physicsShape:PhysicsShape

























static func from_query_result(result:Dictionary):
	var body = result["collider"]
	var shape_idx = result["shape"]
	var body_shape_owner_id = body.shape_find_owner(shape_idx)
	var cpoly = body.shape_owner_get_owner(body_shape_owner_id)
	if not cpoly:return
	assert(cpoly is CollisionPolygon2D_)
	cpoly = cpoly as CollisionPolygon2D_
	var obj = cpoly.physicsShape.object
	assert(obj)
	return obj
